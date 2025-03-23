#!/bin/bash
# system-info-install.sh
# Dieses Skript überprüft die Abhängigkeiten, installiert das system-info Skript
# nach /usr/local/bin/system-info und fragt am Ende, ob es direkt ausgeführt werden soll.

# Versionsinfo und Hinweis
echo "system-info-install v1.0"
echo "Hinweis: Dieses Installationsskript ist für Debian-basierte Systeme optimiert."

TARGET="/usr/local/bin/system-info"

# Funktion zur Überprüfung der Abhängigkeiten inkl. Installation fehlender Pakete
check_dependencies() {
    missing=()
    # Alle Befehle werden jetzt als erforderlich betrachtet
    required=("dmidecode" "ip" "awk" "nproc" "lscpu" "smartctl" "lsblk" "mdadm" "zpool")
    
    # Assoziatives Array zur Zuordnung von Befehlen zu Paketnamen (Beispiel für Debian/Ubuntu)
    declare -A cmd_to_pkg
    cmd_to_pkg=(
        [dmidecode]="dmidecode"
        [ip]="iproute2"
        [awk]="gawk"
        [nproc]="coreutils"
        [lscpu]="util-linux"
        [smartctl]="smartmontools"
        [lsblk]="util-linux"
        [mdadm]="mdadm"
        [zpool]="zfsutils-linux"
    )
    
    echo "Überprüfe Abhängigkeiten..."
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
            echo "Fehlende Abhängigkeit: $cmd (erforderlich)"
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo ""
        echo "Die folgenden erforderlichen Module fehlen: ${missing[*]}"
        read -p "Möchten Sie diese Module automatisch installieren? (y/n): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            # Erstelle eine Liste der Paketnamen (ohne Duplikate)
            packages=()
            for cmd in "${missing[@]}"; do
                pkg=${cmd_to_pkg[$cmd]}
                if [[ ! " ${packages[*]} " =~ " ${pkg} " ]]; then
                    packages+=("$pkg")
                fi
            done
            echo "Die folgenden Pakete werden installiert: ${packages[*]}"
            # Erkennen des Paketmanagers und Installation durchführen
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y "${packages[@]}"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "${packages[@]}"
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm "${packages[@]}"
            else
                echo "Kein unterstützter Paketmanager gefunden. Bitte installieren Sie die fehlenden Pakete manuell."
                exit 1
            fi
            echo "Installation abgeschlossen. Überprüfe erneut die Abhängigkeiten..."
            check_dependencies
        else
            echo "Bitte installieren Sie die fehlenden Module: ${missing[*]}"
            exit 1
        fi
    fi
}

# Abhängigkeiten prüfen
check_dependencies

echo "Installiere system-info nach $TARGET ..."

# Schreibe das eigentliche system-info Skript nach TARGET
cat << 'EOF' > "$TARGET"
#!/bin/bash
# system-info v1.5
# Ein umfangreiches Systemdiagnose-Tool zur Ausgabe wichtiger Hardware- und Systeminformationen
# Hinweis: Dieses Skript überprüft NICHT die Abhängigkeiten.
# Alle Parameter gelten für system-info.

# Versionsvariable
version="v1.5"

TARGET="/usr/local/bin/system-info"

# Farben definieren
BOLD="\e[1m"
CYAN="\e[36m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
RESET="\e[0m"

# Optionen verarbeiten
while [[ "$1" == --* ]]; do
    case "$1" in
        --nocolor)
            BOLD=""
            CYAN=""
            YELLOW=""
            MAGENTA=""
            RESET=""
            shift
            ;;
        --version)
            echo "system-info $version"
            exit 0
            ;;
        --uninstall)
            rm -f "$TARGET"
            echo "✅ system-info wurde entfernt."
            exit 0
            ;;
        --help)
            echo "Verwendung: system-info [OPTIONEN]"
            echo ""
            echo "Optionen:"
            echo "  --version    Version anzeigen"
            echo "  --uninstall  system-info entfernen"
            echo "  --nocolor    Ausgabe ohne Farbcodierung"
            echo "  --help       Diese Hilfe anzeigen"
            exit 0
            ;;
        *)
            echo "Unbekannte Option: $1"
            echo "Verwenden Sie --help für weitere Informationen."
            exit 1
            ;;
    esac
done

# Header mit Versionsangabe ausgeben
echo -e "${BOLD}${CYAN}System Info ${version}:${RESET}"
echo "------------"

echo "OS:      $(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2- | tr -d '\"')"
echo "Kernel:  $(uname -r)"
echo "Hostname: $(hostname)"
echo "Uptime:   $(uptime -p)"

if dmidecode -s system-product-name | grep -qiE "virtual|vmware|kvm|qemu"; then
    echo "System Type: Virtual Machine"
else
    echo "System Type: Physical"
fi

echo -e "${BOLD}Network Interfaces:${RESET}"
ip -o -4 addr show | awk '{print "  - " $2 ": " $4}'

CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
echo "CPU:      $CPU"
echo "Cores:    $(nproc --all)"
echo "Threads:  $(lscpu | awk '/^CPU\(s\):/ {print $2}')"

TOTAL_RAM=$(dmidecode -t memory | awk '
/Size: [0-9]+ [MG]B/ {
    if ($2 == "No") next
    if ($3 == "MB") sum += $2
    if ($3 == "GB") sum += $2 * 1024
}
END { printf "%.1f GB", sum / 1024 }')
echo "Total RAM: $TOTAL_RAM"

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

echo -e "${BOLD}${CYAN}SMART Status:${RESET}"
for disk in $(lsblk -dn -o NAME,TYPE | awk '/disk/{print $1}'); do
    DEVICE="/dev/$disk"
    SMART_OUTPUT=$(smartctl -H -d auto "$DEVICE" 2>/dev/null)
    STATUS=$(echo "$SMART_OUTPUT" | grep -Ei "overall-health|health status" | awk -F: '{print $2}' | xargs)
    if [[ -z "$STATUS" ]]; then
        echo "  - $DEVICE: ❓ Kein Status erkannt"
        echo "DEBUG: $SMART_OUTPUT"
        continue
    fi
    echo "  - $DEVICE: $STATUS"
done

echo -e "${BOLD}${YELLOW}Disk(s):${RESET}"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | awk '{printf "  - /dev/%s: %s - %s\n", $1, $2, $3}'

echo -e "${BOLD}${MAGENTA}RAID Status:${RESET}"
if grep -q "^md" /proc/mdstat; then
    grep "^md" /proc/mdstat | while read -r line; do
        RAID_NAME=$(echo "$line" | awk '{print $1}')
        DETAIL=$(mdadm --detail "/dev/$RAID_NAME" | grep "State :" | xargs)
        echo "  - Software-RAID (mdadm): $RAID_NAME : $DETAIL"
    done
else
    echo "  - Kein Software-RAID (mdadm) erkannt"
fi

if command -v zpool &>/dev/null; then
    ZPOOL_LIST=$(zpool list -H -o name)
    if [[ -n "$ZPOOL_LIST" ]]; then
        for pool in $ZPOOL_LIST; do
            STATUS=$(zpool status -x "$pool")
            echo "  - ZFS: $STATUS"
        done
    else
        echo "  - Kein ZFS-Pool gefunden"
    fi
else
    echo "  - zfsutils-linux nicht installiert"
fi
EOF

# Mache das system-info Skript ausführbar
chmod +x "$TARGET"
echo "Installation abgeschlossen. system-info ist nun unter $TARGET verfügbar."

# Frage, ob system-info direkt ausgeführt werden soll
read -p "Möchten Sie system-info jetzt ausführen? (y/n): " run_answer
if [[ "$run_answer" =~ ^[Yy]$ ]]; then
    echo "Starte system-info..."
    "$TARGET"
else
    echo "Ausführung abgebrochen. Sie können system-info später über '$TARGET' starten."
fi
