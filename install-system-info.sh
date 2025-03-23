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

# Skript schreiben
cat > "$TARGET" << 'EOF'
#!/bin/bash

echo ""
echo "System Info:"
echo "------------"

# CPU-Modell
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2- | xargs)
echo "CPU:    $CPU"

# Alle RAM-Module
echo "RAM Module:"
dmidecode -t memory | awk '
/Memory Device/,/^$/' | awk '
/Size:|Type:|Part Number:/ {
  gsub(/^ +| +$/, "", $0)
  if ($0 ~ /Size:/) size=$2 " " $3
  if ($0 ~ /Type:/) type=$2
  if ($0 ~ /Part Number:/) part=$3
  if (size && type && part) {
    printf "  - %s %s - %s\n", size, type, part
    size=""; type=""; part=""
  }
}'

# Alle SSD/NVMe Laufwerke auflisten
echo "Disk(s):"
lsblk -d -o NAME,MODEL,SIZE | grep -iE 'sd|nvme' | while read -r NAME MODEL SIZE; do
    printf "  - /dev/%s: %s - %s\n" "$NAME" "$MODEL" "$SIZE"
done

echo ""
EOF

chmod +x "$TARGET"

echo "✅ Installation abgeschlossen! Du kannst das Tool jetzt mit dem Befehl 'system-info' verwenden."
echo ""
echo "🔍 Testlauf:"
echo "---------------------------"
"$TARGET"
