#!/bin/bash

TARGET="/usr/local/bin/system-info"

# Uninstall-Funktion im Installationsskript
if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne /usr/local/bin/system-info falls vorhanden ..."
    rm -f /usr/local/bin/system-info
    echo "✅ system-info wurde entfernt."
    exit 0
fi

# Starte Installation des Tools
echo "📦 Installing or updating system-info to $TARGET ..."
echo ""

# Prüfen, ob dmidecode installiert ist – benötigt für RAM/CPU/Hardwareinfos
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

# Prüfen, ob ZFS-Werkzeuge vorhanden sind – zpool wird für ZFS-RAID-Status benötigt
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

# Erstelle das Tool '/usr/local/bin/system-info' mit allen Hardwareausgaben
cat > "$TARGET" << 'EOF'
#!/bin/bash

# Prüfen auf '--uninstall' – entfernt das Tool bei Bedarf
if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne /usr/local/bin/system-info ..."
    rm -f /usr/local/bin/system-info
    echo "✅ system-info wurde entfernt."
    exit 0
fi

echo ""
echo "System Info:"
echo "------------"

# OS & Kernel-Version anzeigen
OS=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2- | tr -d '"')
KERNEL=$(uname -r)
echo "OS:      $OS"
echo "Kernel:  $KERNEL"

# Hostname des Systems
HOST=$(hostname)
echo "Hostname: $HOST"

# Systemlaufzeit (Uptime)
UPTIME=$(uptime -p)
echo "Uptime:   $UPTIME"

# Prüfen, ob das System eine VM ist oder Bare Metal
if dmidecode -s system-product-name | grep -qiE "virtual|vmware|kvm|qemu"; then
    echo "System Type: Virtual Machine"
else
    echo "System Type: Physical"
fi

# IPv4-Adressen aller Netzwerkinterfaces ausgeben
IP_OUTPUT=$(ip -o -4 addr show | awk '{print "  - " $2 ": " $4}')
echo "Network Interfaces:"
echo "$IP_OUTPUT"

# CPU-Name (Modell)
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
echo "CPU:      $CPU"

# Anzahl CPU-Kerne und Threads
CORES=$(nproc --all)
THREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
echo "Cores:    $CORES"
echo "Threads:  $THREADS"

# RAM-Summe (alle Module), unabhängig ob MB oder GB
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

# Details aller RAM-Bausteine (Größe, Typ, Part-Nummer)
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

# Liste aller physischen Datenträger (SSD/NVMe) mit Modell und Größe
echo "Disk(s):"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\n" "$NAME" "$MODEL" "$SIZE"
done

# RAID-Status prüfen: mdadm und ZFS
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

# Selbstlöschung nach erfolgreicher Installation
# Selbstlöschung entfernt – nicht notwendig bei Ausführung aus /tmp
