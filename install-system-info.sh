#!/bin/bash

TARGET="/usr/local/bin/system-info"

# If called with --uninstall, remove the tool and exit
if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne $TARGET falls vorhanden ..."
    rm -f "$TARGET"
    echo "✅ system-info wurde entfernt."
    exit 0
fi

echo "📦 Installing or updating system-info to $TARGET ..."
echo ""

# Check dependencies
DEP_PKGS=""

# dmidecode for hardware info
if ! command -v dmidecode >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS dmidecode"
fi

# mdadm for RAID detection
if ! command -v mdadm >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS mdadm"
fi

# zpool (ZFS) for ZFS RAID detection
if ! command -v zpool >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS zfsutils-linux"
fi

# smartctl for SMART status
if ! command -v smartctl >/dev/null 2>&1; then
    DEP_PKGS="$DEP_PKGS smartmontools"
fi

# Install missing packages if needed
if [[ -n "$DEP_PKGS" ]]; then
    echo "🔧 Installiere fehlende Abhängigkeiten: $DEP_PKGS"
    apt update && apt install -y $DEP_PKGS
else
    echo "✅ Alle benötigten Pakete sind installiert."
fi

# Double-check dmidecode
if ! command -v dmidecode >/dev/null 2>&1; then
    echo "🔍 'dmidecode' ist nicht installiert. Versuche Installation ..."
    apt update && apt install -y dmidecode
    if [ $? -ne 0 ]; then
        echo "❌ Fehler: Konnte 'dmidecode' nicht installieren. Bitte manuell prüfen."
        exit 1
    else
        echo "✅ 'dmidecode' erfolgreich installiert."
    fi
else
    echo "✅ 'dmidecode' ist bereits installiert."
fi

# Double-check ZFS
if ! command -v zpool >/dev/null 2>&1; then
    echo "🔍 'zfsutils-linux' (ZFS) ist nicht installiert. Versuche Installation ..."
    apt update && apt install -y zfsutils-linux
    if [ $? -ne 0 ]; then
        echo "⚠️ Hinweis: Konnte 'zfsutils-linux' nicht installieren. ZFS-Ausgabe wird ggf. übersprungen."
    else
        echo "✅ 'zfsutils-linux' erfolgreich installiert."
    fi
else
    echo "✅ ZFS-Tools (zfsutils-linux) sind bereits installiert."
fi

# Create the actual system-info tool
cat > "$TARGET" << 'EOF'
#!/bin/bash

# Handle arguments
if [[ "$1" == "--help" ]]; then
    echo ""
    echo "🖥️ system-info – Systemdiagnose-Tool"
    echo ""
    echo "Verwendung:"
    echo "  system-info             – Zeigt Systeminformationen"
    echo "  system-info --version   – Zeigt die aktuelle Version"
    echo "  system-info --uninstall – Entfernt das Tool"
    echo "  system-info --help      – Zeigt diese Hilfe an"
    echo ""
    exit 0
fi

if [[ "$1" == "--version" ]]; then
    echo "system-info v1.2"
    exit 0
fi

if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne /usr/local/bin/system-info ..."
    rm -f /usr/local/bin/system-info
    echo "✅ system-info wurde entfernt."
    exit 0
fi

echo ""
echo -e "\e[1m\e[34mSystem Info:\e[0m"
echo "------------"

# OS & Kernel
OS=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2- | tr -d '"')
KERNEL=$(uname -r)
echo "OS:      $OS"
echo "Kernel:  $KERNEL"

# Hostname
HOST=$(hostname)
echo "Hostname: $HOST"

# Uptime
UPTIME=$(uptime -p)
echo "Uptime:   $UPTIME"

# Check if VM
if dmidecode -s system-product-name | grep -qiE "virtual|vmware|kvm|qemu"; then
    echo "System Type: Virtual Machine"
else
    echo "System Type: Physical"
fi

# Network Interfaces
IP_OUTPUT=$(ip -o -4 addr show | awk '{print "  - " $2 ": " $4}')
echo -e "\e[1mNetwork Interfaces:\e[0m"
echo "$IP_OUTPUT"

# CPU Info
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
echo "CPU:      $CPU"
CORES=$(nproc --all)
THREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
echo "Cores:    $CORES"
echo "Threads:  $THREADS"

# Total RAM (simpler approach via /proc/meminfo)
TOTAL_RAM=$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
echo "Total RAM: $TOTAL_RAM"

# RAM Module details (dmidecode)
echo -e "\e[1m\e[33mRAM Module:\e[0m"
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
echo -e "\e[1m\e[36mSMART Status:\e[0m"
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
        STATUS="❓ Unbekannt"
    fi

    if echo "$STATUS" | grep -qi "fail"; then
        echo "  - $DEVICE: ⚠️ $STATUS"
    else
        echo "  - $DEVICE: $STATUS"
    fi
done

# Disk(s)
echo -e "\e[1m\e[33mDisk(s):\e[0m"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\n" "$NAME" "$MODEL" "$SIZE"
done

# RAID-Status (mdadm)
if grep -q "^md" /proc/mdstat; then
    grep "^md" /proc/mdstat | while read -r line; do
        echo "  - Software-RAID (mdadm): $line"
        if echo "$line" | grep -q '\[.*_.*\]'; then
            echo "    ⚠️ RAID-Status: Möglicherweise degraded oder Resync läuft"
        fi
    done
else
    echo "  - Kein Software-RAID (mdadm) erkannt"
fi

# ZFS RAID
if command -v zpool >/dev/null 2>&1; then
    ZPOOLS=$(zpool list -H -o name)
    if [[ -n "$ZPOOLS" ]]; then
        STATUS=$(zpool status -x)
        if [[ "$STATUS" != "all pools are healthy" ]]; then
            echo "  ⚠️ ZFS Fehlerstatus:"
            echo "$STATUS" | sed 's/^/    /'
        else
            echo "  ✅ Alle ZFS-Pools sind gesund"
        fi
    else
        echo "  - Kein ZFS-Pool gefunden"
    fi
else
    echo "  - ZFS ist nicht installiert"
fi

echo -e "\e[1m\e[35mRAID Status:\e[0m"
if grep -q "^md" /proc/mdstat; then
    grep "^md" /proc/mdstat | while read -r line; do
        echo "  - Software-RAID (mdadm): $line"
    done
else
    echo "  - Kein Software-RAID (mdadm) erkannt"
fi

if command -v zpool >/dev/null 2>&1; then
    ZPOOLS=$(zpool list -H -o name)
    if [[ -n "$ZPOOLS" ]]; then
        for pool in $ZPOOLS; do
            echo "  - ZFS-Pool '$pool':"
            zpool status "$pool" | awk '/mirror|raidz|stripe|NAME/{print "    " $0}'
        done
    else
        echo "  - Kein ZFS-Pool gefunden"
    fi
else
    echo "  - ZFS ist nicht installiert"
fi

echo ""
EOF

chmod +x "$TARGET"

echo "✅ Installation abgeschlossen! Du kannst das Tool jetzt mit dem Befehl 'system-info' verwenden."
echo ""
echo "🔍 Testlauf:"
echo "---------------------------"
"$TARGET"
