#!/bin/bash

VERSION="1.3"
TARGET="/usr/local/bin/system-info"

# Farbcodes
RESET="\e[0m"
BOLD="\e[1m"
CYAN="\e[36m"
YELLOW="\e[33m"
MAGENTA="\e[35m"

# Hilfetext
print_help() {
    echo ""
    echo "🖥️ system-info – Systemdiagnose-Tool (v$VERSION)"
    echo ""
    echo "Verwendung:"
    echo "  system-info                – Zeigt Systeminformationen"
    echo "  system-info --version      – Zeigt die aktuelle Version"
    echo "  system-info --uninstall    – Entfernt das Tool"
    echo "  system-info --help         – Zeigt diese Hilfe an"
    echo "  system-info --no-color     – Deaktiviert Farbige Ausgabe"
    echo ""
}

# Parameterbehandlung
USE_COLOR=true
for arg in "$@"; do
    case "$arg" in
        --help)
            print_help
            exit 0
            ;;
        --version)
            echo "system-info v$VERSION"
            exit 0
            ;;
        --uninstall)
            echo "🗑️ Entferne $TARGET ..."
            rm -f "$TARGET"
            echo "✅ system-info wurde entfernt."
            exit 0
            ;;
        --no-color)
            RESET=""
            BOLD=""
            CYAN=""
            YELLOW=""
            MAGENTA=""
            USE_COLOR=false
            ;;
    esac
done

echo ""
echo -e "${BOLD}${CYAN}System Info:${RESET}"
echo "------------"

# OS & Kernel
OS=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2- | tr -d '"')
KERNEL=$(uname -r)
echo "OS:       $OS"
echo "Kernel:   $KERNEL"

# Hostname & Uptime
echo "Hostname: $(hostname)"
echo "Uptime:   $(uptime -p)"

# Systemtyp
if dmidecode -s system-product-name | grep -qiE "virtual|vmware|kvm|qemu"; then
    echo "System Type: Virtual Machine"
else
    echo "System Type: Physical"
fi

# Netzwerkinterfaces
echo -e "${BOLD}Network Interfaces:${RESET}"
ip -o -4 addr show | awk '{print "  - " $2 ": " $4}'

# CPU Info
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
CORES=$(nproc --all)
THREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
echo "CPU:      $CPU"
echo "Cores:    $CORES"
echo "Threads:  $THREADS"

# RAM gesamt
TOTAL_RAM=$(dmidecode -t memory | awk '
/Size: [0-9]+ [MG]B/ {
    if ($2 == "No") next
    if ($3 == "MB") sum += $2
    if ($3 == "GB") sum += $2 * 1024
}
END {
    printf "%.1f GB", sum / 1024
}')
echo "Total RAM: $TOTAL_RAM"

# RAM Module
echo -e "${BOLD}${YELLOW}RAM Module:${RESET}"
dmidecode -t memory | awk '
/Memory Device/,/^$/ {
    if ($0 ~ /Size:/ && $2 != "No") size=$2 " " $3
    if ($0 ~ /Type:/ && $1 == "Type:") type=$2
    if ($0 ~ /Part Number:/) {
        sub(/^\s+/, "", $0)
        split($0, a, ": ")
        part=a[2]
    }
    if (size != "" && type != "" && part != "") {
        printf "  - %s %s - %s\n", size, type, part
        size=""; type=""; part=""
    }
}'

# SMART Status
echo -e "${BOLD}${CYAN}SMART Status:${RESET}"
lsblk -d -o NAME,TYPE | grep -E 'disk' | awk '{print $1}' | while read -r disk; do
    DEVICE="/dev/$disk"
    if [[ "$disk" == nvme* ]]; then
        OUT=$(smartctl -H -d nvme "$DEVICE" 2>/dev/null)
    else
        OUT=$(smartctl -H "$DEVICE" 2>/dev/null)
    fi
    STATUS=$(echo "$OUT" | grep -iE "SMART overall-health self-assessment|SMART Health Status" | awk -F: '{print $2}' | xargs)
    if [[ -z "$STATUS" ]]; then
        echo "  - $DEVICE: ❓ Kein Status"
    echo "DEBUG: raw output from smartctl:"
    echo "$OUT" | sed 's/^/    /'
    elif echo "$STATUS" | grep -qi "fail"; then
        echo "  - $DEVICE: ⚠️ $STATUS"
    else
        echo "  - $DEVICE: $STATUS"
    fi
done

# Disks
echo -e "${BOLD}${YELLOW}Disk(s):${RESET}"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\n" "$NAME" "$MODEL" "$SIZE"
done

# RAID Status
echo -e "${BOLD}${MAGENTA}RAID Status:${RESET}"
MDADM_STATUS=$(cat /proc/mdstat | grep -E "^md[0-9]+")
if [[ -n "$MDADM_STATUS" ]]; then
    echo "$MDADM_STATUS" | while read -r line; do
        RAID_NAME=$(echo "$line" | awk '{print $1}')
        DETAIL=$(mdadm --detail "/dev/$RAID_NAME" 2>/dev/null | grep "State :" | xargs)
        echo "  - Software-RAID (mdadm): $RAID_NAME : $DETAIL"
    done
else
    echo "  - Kein Software-RAID (mdadm) erkannt"
fi

if command -v zpool >/dev/null 2>&1; then
    ZPOOL_LIST=$(zpool list -H -o name 2>/dev/null)
    if [[ -n "$ZPOOL_LIST" ]]; then
        echo "$ZPOOL_LIST" | while read -r pool; do
            STATUS=$(zpool status -x "$pool" 2>/dev/null)
            echo "$STATUS" | sed 's/^/  - ZFS: /'
        done
    else
        echo "  - Kein ZFS-Pool gefunden"
    fi
else
    echo "  - zfsutils-linux nicht installiert"
fi
