#!/bin/bash

TARGET="/usr/local/bin/system-info"

# ------------------------------------------------------------------------------
# 1) Uninstall-Funktion (vom Installationsskript selbst)
# ------------------------------------------------------------------------------
if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne $TARGET falls vorhanden ..."
    rm -f "$TARGET"
    echo "✅ system-info wurde entfernt."
    exit 0
fi

echo "📦 Installing or updating system-info to $TARGET ..."
echo ""

# ------------------------------------------------------------------------------
# 2) Abhängigkeiten prüfen & installieren
# ------------------------------------------------------------------------------
DEP_PKGS=""
if ! command -v dmidecode >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS dmidecode"
fi
if ! command -v mdadm >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS mdadm"
fi
if ! command -v zpool >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS zfsutils-linux"
fi
if ! command -v smartctl >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS smartmontools"
fi

if [[ -n "$DEP_PKGS" ]]; then
    echo "🔧 Installiere fehlende Abhängigkeiten: $DEP_PKGS"
    apt update && apt install -y $DEP_PKGS
else
    echo "✅ Alle benötigten Pakete sind bereits installiert."
fi

# ------------------------------------------------------------------------------
# 3) Das eigentliche Tool nach /usr/local/bin schreiben
# ------------------------------------------------------------------------------
cat > "$TARGET" << 'EOF'
#!/bin/bash

###############################################################################
# Farb-Definitionen (abschaltbar via --no-color)
###############################################################################
USE_COLOR=true

# Falls --no-color an erster Stelle steht, aktivieren wir Farblos-Modus
if [[ "$1" == "--no-color" ]]; then
    USE_COLOR=false
    shift
fi

# ANSI-Farbcodes abhängig von USE_COLOR
if [[ "$USE_COLOR" == "true" ]]; then
    RESET="\e[0m"
    BOLD="\e[1m"
    BLUE="\e[34m"
    GREEN="\e[32m"
    YELLOW="\e[33m"
    RED="\e[31m"
    CYAN="\e[36m"
    MAGENTA="\e[35m"
else
    RESET=""
    BOLD=""
    BLUE=""
    GREEN=""
    YELLOW=""
    RED=""
    CYAN=""
    MAGENTA=""
fi

###############################################################################
# CLI-Optionen: --help, --version, --uninstall
###############################################################################

# --help anzeigen
if [[ "$1" == "--help" ]]; then
    echo ""
    echo "🖥️ system-info – Systemdiagnose-Tool"
    echo ""
    echo "Verwendung:"
    echo "  system-info                – Zeigt Systeminformationen"
    echo "  system-info --version      – Zeigt die aktuelle Version"
    echo "  system-info --uninstall    – Entfernt das Tool"
    echo "  system-info --help         – Zeigt diese Hilfe an"
    echo "  system-info --no-color     – Deaktiviert Farbige Ausgabe"
    echo ""
    exit 0
fi

# --version anzeigen
if [[ "$1" == "--version" ]]; then
    echo "system-info v1.1.1"
    exit 0
fi

# --uninstall (Tool selbst entfernen)
if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne $0 ..."
    rm -f "$0"
    echo "✅ system-info wurde entfernt."
    exit 0
fi

###############################################################################
# 4) Systeminformationen ausgeben
###############################################################################

echo ""
echo -e "${BOLD}${BLUE}System Info:${RESET}"

# OS & Kernel
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d '=' -f2- | tr -d '"')
KERNEL=$(uname -r)
echo -e "${BOLD}OS:${RESET}       $OS"
echo -e "${BOLD}Kernel:${RESET}   $KERNEL"

# Hostname
HOST=$(hostname)
echo -e "${BOLD}Hostname:${RESET} $HOST"

# Uptime
UPTIME=$(uptime -p)
echo -e "${BOLD}Uptime:${RESET}   $UPTIME"

# Virtuell oder physisch
if dmidecode -s system-product-name 2>/dev/null | grep -qiE "virtual|vmware|kvm|qemu"; then
    echo -e "${BOLD}System Type:${RESET} Virtual Machine"
else
    echo -e "${BOLD}System Type:${RESET} Physical"
fi

# Netzwerkinterfaces
echo -e "${BOLD}Network Interfaces:${RESET}"
ip -o -4 addr show | awk '{print "  - " $2 ": " $4}'

# CPU
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
echo -e "${BOLD}CPU:${RESET}      $CPU"

# Cores/Threads
CORES=$(nproc --all)
THREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
echo -e "${BOLD}Cores:${RESET}    $CORES"
echo -e "${BOLD}Threads:${RESET}  $THREADS"

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
echo -e "${BOLD}Total RAM:${RESET} $TOTAL_RAM"

# RAM-Module
echo -e "${BOLD}${YELLOW}RAM Module:${RESET}"
dmidecode -t memory | awk '
/Memory Device/,/^$/ {
    if ($0 ~ /Size:/ && $2 != "No") size=$2 " " $3
    if ($0 ~ /Type:/ && $1 == "Type:") type=$2
    if ($0 ~ /Part Number:/) {
        sub(/^\\s+/, "", $0)
        split($0, a, ": ")
        part=a[2]
    }
    if (size != "" && type != "" && part != "") {
        printf "  - %s %s - %s\\n", size, type, part
        size=""; type=""; part=""
    }
}'

# Disks
echo -e "${BOLD}${YELLOW}Disk(s):${RESET}"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\\n" "$NAME" "$MODEL" "$SIZE"
done

###############################################################################
# RAID Status
###############################################################################
echo -e "${BOLD}${MAGENTA}RAID Status:${RESET}"

# mdadm (Software RAID)
if command -v mdadm >/dev/null 2>&1; then
    MDADM_STATUS=$(grep -E "^md[0-9]+" /proc/mdstat)
    if [[ -n "$MDADM_STATUS" ]]; then
        echo "$MDADM_STATUS" | while read -r line; do
            RAID_NAME=$(echo "$line" | awk '{print $1}')
            DETAIL=$(mdadm --detail "/dev/$RAID_NAME" 2>/dev/null | grep "State :" | xargs)
            echo "  - Software-RAID (mdadm): $RAID_NAME : $DETAIL"
        done
    else
        echo "  - Kein Software-RAID (mdadm) erkannt"
    fi
else
    echo "  - mdadm nicht installiert"
fi

# ZFS
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

###############################################################################
# SMART Status
###############################################################################
echo -e "${BOLD}${CYAN}SMART Status:${RESET}"
lsblk -d -o NAME,TYPE | grep -E 'disk' | awk '{print $1}' | while read -r disk; do
    DEVICE="/dev/$disk"
    if [[ "$disk" == nvme* ]]; then
        OUT=$(smartctl -H -d nvme "$DEVICE" 2>/dev/null)
    else
        OUT=$(smartctl -H "$DEVICE" 2>/dev/null)
    fi

    STATUS=$(echo "$OUT" | grep -i "SMART overall-health self-assessment" | awk -F: '{print $2}' | xargs)
    if [[ -z "$STATUS" ]]; then
        STATUS=$(echo "$OUT" | grep -i "SMART Health Status" | awk -F: '{print $2}' | xargs)
    fi
    if [[ -z "$STATUS" ]]; then
        echo "  - $DEVICE: ❓ Kein Status erkannt (Debug-Ausgabe folgt):"
        echo "$OUT" | sed 's/^/      /'
        continue
    fi

    if echo "$STATUS" | grep -qi "fail"; then
        echo "  - $DEVICE: ⚠️ $STATUS"
    else
        echo "  - $DEVICE: $STATUS"
    fi
done

EOF

# ------------------------------------------------------------------------------
# 4) Rechte setzen und Testlauf
# ------------------------------------------------------------------------------
chmod +x "$TARGET"

echo "✅ Installation abgeschlossen! Du kannst das Tool jetzt mit dem Befehl 'system-info' verwenden."
echo ""
echo "🔍 Testlauf:"
echo "---------------------------"
"$TARGET"
