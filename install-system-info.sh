#!/bin/bash

VERSION="1.4"
COLOR=true

# Farbdefinitionen
RESET="\e[0m"
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"

# Farblose Ausgabe bei --no-color
for arg in "$@"; do
    [[ "$arg" == "--no-color" ]] && COLOR=false
done
$COLOR || RESET="" && BOLD="" && RED="" && GREEN="" && YELLOW="" && BLUE="" && MAGENTA="" && CYAN=""

# Hilfe anzeigen
if [[ "$1" == "--help" ]]; then
    echo -e "\n🖥️ ${BOLD}system-info${RESET} – Systemdiagnose-Tool"
    echo -e "\nVerwendung:"
    echo "  system-info                – Zeigt Systeminformationen"
    echo "  system-info --version      – Zeigt die aktuelle Version"
    echo "  system-info --uninstall    – Entfernt das Tool"
    echo "  system-info --help         – Zeigt diese Hilfe an"
    echo "  system-info --no-color     – Deaktiviert Farbige Ausgabe"
    echo ""
    exit 0
fi

# Versionsinfo
if [[ "$1" == "--version" ]]; then
    echo "system-info v${VERSION}"
    exit 0
fi

# Uninstall
if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne /usr/local/bin/system-info ..."
    rm -f /usr/local/bin/system-info
    echo "✅ system-info wurde entfernt."
    exit 0
fi

# Ausgabe der Systeminformationen
echo ""
echo -e "${BOLD}${CYAN}System Info:${RESET}"
echo "------------"

OS=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2- | tr -d '"')
KERNEL=$(uname -r)
HOST=$(hostname)
UPTIME=$(uptime -p)
TYPE="Physical"
dmidecode -s system-product-name | grep -qiE "virtual|vmware|kvm|qemu" && TYPE="Virtual Machine"
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
CORES=$(nproc --all)
THREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
TOTAL_RAM=$(dmidecode -t memory | awk '
/Size: [0-9]+ [MG]B/ {
    if ($2 == "No") next
    if ($3 == "MB") sum += $2
    if ($3 == "GB") sum += $2 * 1024
}
END {
    printf "%.1f GB", sum / 1024
}')

echo "OS:        $OS"
echo "Kernel:    $KERNEL"
echo "Hostname:  $HOST"
echo "Uptime:    $UPTIME"
echo "System Type: $TYPE"
echo -e "${BOLD}Network Interfaces:${RESET}"
ip -o -4 addr show | awk '{print "  - " $2 ": " $4}'
echo "CPU:       $CPU"
echo "Cores:     $CORES"
echo "Threads:   $THREADS"
echo "Total RAM: $TOTAL_RAM"

# RAM-Module
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

# SMART-Status
echo -e "${BOLD}${CYAN}SMART Status:${RESET}"
lsblk -d -o NAME,TYPE | grep -E 'disk' | awk '{print $1}' | while read -r disk; do
    DEVICE="/dev/$disk"
    if [[ "$disk" == nvme* ]]; then
        OUT=$(smartctl -H -d nvme "$DEVICE" 2>/dev/null)
    else
        OUT=$(smartctl -H "$DEVICE" 2>/dev/null)
    fi

    STATUS=$(echo "$OUT" | grep -i "SMART overall-health self-assessment" | awk -F: '{print $2}' | xargs)
    [[ -z "$STATUS" ]] && STATUS=$(echo "$OUT" | grep -i "SMART Health Status" | awk -F: '{print $2}' | xargs)

    if [[ -z "$STATUS" ]]; then
        echo -e "  - $DEVICE: ${RED}❓ Kein Status${RESET}"
        echo -e "    DEBUG: raw output from smartctl:"
        echo "$OUT" | sed 's/^/      /'
        continue
    fi

    if echo "$STATUS" | grep -qi "fail"; then
        echo -e "  - $DEVICE: ${RED}⚠️ $STATUS${RESET}"
    else
        echo "  - $DEVICE: $STATUS"
    fi
done

# Festplatten
echo -e "${BOLD}${YELLOW}Disk(s):${RESET}"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\n" "$NAME" "$MODEL" "$SIZE"
done

# RAID
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
