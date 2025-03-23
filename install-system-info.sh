#!/bin/bash

TARGET="/usr/local/bin/system-info"

# Uninstall-Funktion
if [[ "$1" == "--uninstall" ]]; then
    if [ -f "$TARGET" ]; then
        echo "🗑️ Entferne $TARGET ..."
        rm -f "$TARGET"
        echo "✅ 'system-info' wurde entfernt."
    else
        echo "ℹ️ 'system-info' ist nicht installiert."
    fi
    exit 0
fi

echo "📦 Installing or updating system-info to $TARGET ..."
echo ""

# Prüfen, ob dmidecode installiert ist
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

# Prüfen, ob zpool verfügbar ist (ZFS)
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

# Skript schreiben
cat > "$TARGET" << 'EOF'
#!/bin/bash

echo ""
echo "System Info:"
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

# Virtuell oder physisch
if dmidecode -s system-product-name | grep -qiE "virtual|vmware|kvm|qemu"; then
    echo "System Type: Virtual Machine"
else
    echo "System Type: Physical"
fi

# Netzwerkinterfaces
IP_OUTPUT=$(ip -o -4 addr show | awk '{print "  - " $2 ": " $4}')
echo "Network Interfaces:"
echo "$IP_OUTPUT"

# CPU-Modell
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
echo "CPU:      $CPU"

# CPU Cores/Threads
CORES=$(nproc --all)
THREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
echo "Cores:    $CORES"
echo "Threads:  $THREADS"

# RAM gesamt
TOTAL_RAM=$(free -g | awk '/^Mem:/ {print $2 " GB"}')
echo "Total RAM: $TOTAL_RAM"

# RAM-Module
echo "RAM Module:"
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

# Alle SSD/NVMe Laufwerke auflisten
echo "Disk(s):"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\n" "$NAME" "$MODEL" "$SIZE"
done

# RAID-Erkennung
echo "RAID Status:"

# mdadm RAID
if grep -q "^md" /proc/mdstat; then
    grep "^md" /proc/mdstat | while read -r line; do
        echo "  - Software-RAID (mdadm): $line"
    done
else
    echo "  - Kein Software-RAID (mdadm) erkannt"
fi

# ZFS RAID
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
