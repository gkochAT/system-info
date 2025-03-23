#!/bin/bash

TARGET="/usr/local/bin/system-info"

# Uninstall aus Installer heraus
if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne $TARGET falls vorhanden ..."
    rm -f "$TARGET"
    echo "✅ system-info wurde entfernt."
    exit 0
fi

echo "📦 Installing or updating system-info v1.2 to $TARGET ..."
echo ""

# Abhängigkeiten prüfen
MISSING_PKGS=""
for pkg in dmidecode mdadm zfsutils-linux smartmontools; do
    if ! command -v "${pkg%%-*}" &>/dev/null; then
        MISSING_PKGS+=" $pkg"
    fi
done

if [[ -n "$MISSING_PKGS" ]]; then
    echo "🔧 Installiere fehlende Pakete:$MISSING_PKGS"
    apt update && apt install -y $MISSING_PKGS
else
    echo "✅ Alle benötigten Pakete sind installiert."
fi

# Skript schreiben
cat > "$TARGET" << 'EOF'
#!/bin/bash

VERSION="1.2"

BOLD="\e[1m"
RESET="\e[0m"
CYAN="\e[36m"
YELLOW="\e[33m"
MAGENTA="\e[35m"

NO_COLOR=false
[[ "$1" == "--no-color" ]] && NO_COLOR=true && shift

# Farblose Ausgabe?
if $NO_COLOR; then
    BOLD=""; RESET=""; CYAN=""; YELLOW=""; MAGENTA=""
fi

# Hilfe
if [[ "$1" == "--help" ]]; then
    echo -e "\n🖥️ system-info – Systemdiagnose-Tool v$VERSION\n"
    echo "Verwendung:"
    echo "  system-info             – Zeigt Systeminformationen"
    echo "  system-info --no-color  – Ausgabe ohne Farben"
    echo "  system-info --version   – Zeigt die aktuelle Version"
    echo "  system-info --uninstall – Entfernt das Tool"
    echo "  system-info --help      – Zeigt diese Hilfe"
    echo ""
    exit 0
fi

if [[ "$1" == "--version" ]]; then
    echo "system-info v$VERSION"
    exit 0
fi

if [[ "$1" == "--uninstall" ]]; then
    echo "🗑️ Entferne /usr/local/bin/system-info ..."
    rm -f /usr/local/bin/system-info
    echo "✅ system-info wurde entfernt."
    exit 0
fi

echo ""
echo -e "${BOLD}${CYAN}System Info:${RESET}"
echo "------------"

# Systemdaten
echo "OS:        $(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2- | tr -d '\"')"
echo "Kernel:    $(uname -r)"
echo "Hostname:  $(hostname)"
echo "Uptime:    $(uptime -p)"

# Typ
if dmidecode -s system-product-name | grep -qiE "virtual|kvm|vmware|qemu"; then
    echo "System Type: Virtual Machine"
else
    echo "System Type: Physical"
fi

# Netzwerk
echo -e "${BOLD}Network Interfaces:${RESET}"
ip -o -4 addr show | awk '{print "  - " $2 ": " $4}'

# CPU
echo "CPU:       $(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)"
echo "Cores:     $(nproc --all)"
echo "Threads:   $(lscpu | awk '/^CPU\(s\):/ {print $2}')"

# RAM gesamt
TOTAL_RAM=$(dmidecode -t memory | awk '
/Size: [0-9]+ [MG]B/ {
  if ($2 != "No") {
    if ($3 == "MB") sum += $2
    if ($3 == "GB") sum += $2 * 1024
  }
}
END {
  printf "%.1f GB", sum / 1024
}')
echo "Total RAM: $TOTAL_RAM"

# RAM Details
echo -e "${BOLD}${YELLOW}RAM Module:${RESET}"
dmidecode -t memory | awk '
/Memory Device/,/^$/ {
  if ($0 ~ /Size:/ && $2 != "No") size=$2 " " $3
  if ($0 ~ /Type:/ && $1 == "Type:") type=$2
  if ($0 ~ /Part Number:/) {
    sub(/^\s+/, "", $0)
    split($0, a, ": "); part=a[2]
  }
  if (size && type && part) {
    printf "  - %s %s - %s\n", size, type, part
    size=""; type=""; part=""
  }
}'

# SMART Status
echo -e "${BOLD}${CYAN}SMART Status:${RESET}"
lsblk -d -o NAME,TYPE | grep disk | awk '{print $1}' | while read -r disk; do
    DEVICE="/dev/$disk"
    OUT=$(smartctl -H ${DEVICE/\/dev\//-d nvme } "$DEVICE" 2>/dev/null)
    STATUS=$(echo "$OUT" | grep -iE "overall-health|SMART Health Status" | awk -F: '{print $2}' | xargs)
    [[ -z "$STATUS" ]] && STATUS="❓ Kein Status"
    echo "  - $DEVICE: $STATUS"
done

# Disks
echo -e "${BOLD}${YELLOW}Disk(s):${RESET}"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\n" "$NAME" "$MODEL" "$SIZE"
done

# RAID
echo -e "${BOLD}${MAGENTA}RAID Status:${RESET}"
if grep -q "^md" /proc/mdstat; then
    grep "^md" /proc/mdstat | while read -r line; do
        RAID=$(echo "$line" | awk '{print $1}')
        DETAIL=$(mdadm --detail "/dev/$RAID" 2>/dev/null | grep "State :" | xargs)
        echo "  - Software-RAID (mdadm): $RAID : $DETAIL"
    done
else
    echo "  - Kein Software-RAID (mdadm) erkannt"
fi

# ZFS
if command -v zpool &>/dev/null; then
    ZPOOLS=$(zpool list -H -o name 2>/dev/null)
    if [[ -n "$ZPOOLS" ]]; then
        echo "$ZPOOLS" | while read -r pool; do
            STATUS=$(zpool status -x "$pool" 2>/dev/null)
            echo "$STATUS" | sed 's/^/  - ZFS: /'
        done
    else
        echo "  - Kein ZFS-Pool gefunden"
    fi
else
    echo "  - ZFS nicht installiert"
fi

echo ""
EOF

chmod +x "$TARGET"
echo "✅ Installation abgeschlossen! Du kannst das Tool jetzt mit dem Befehl 'system-info' verwenden."
"$TARGET"
