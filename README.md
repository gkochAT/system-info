# 🖥️ system-info

[![Shell Script](https://img.shields.io/badge/script-shell-brightgreen.svg)](https://bash.sh)  
Ein praktisches Shell-Tool zur Anzeige grundlegender Hardwareinformationen – speziell für Linux- und Proxmox-Umgebungen entwickelt.

---

## 🚀 Features

✅ Zeigt dir auf einen Blick:

- 🧠 CPU-Modellname
- 🧬 RAM-Informationen: Größe, Typ, Hersteller (Hex oder Name), Part-Nummer
- 💾 SSD/NVMe-Modellname & Kapazität

⚙️ Weitere Funktionen:

- Erkennt automatisch, ob `dmidecode` installiert ist
- Installiert `dmidecode` bei Bedarf automatisch über `apt`
- Legt sich als global ausführbares Kommando `system-info` unter `/usr/local/bin` ab
- Unterstützt Deinstallation mit `--uninstall`-Flag

---

## ⚙️ Installation

Du kannst das Skript ganz einfach über `curl` oder `wget` installieren:

### 🔸 Mit `curl`:
```bash
curl -sSL https://raw.githubusercontent.com/gkochAT/system-info/main/install-system-info.sh | bash
```

### 🔸 Mit `wget`:
```bash
wget -qO- https://raw.githubusercontent.com/gkochAT/system-info/main/install-system-info.sh | bash
```

🔹 Das Skript wird nach der Installation unter folgendem Pfad abgelegt:

```bash
/usr/local/bin/system-info
```

Du kannst es danach überall im Terminal mit folgendem Befehl aufrufen:

```bash
system-info
```

---

## 🧹 Deinstallation

Falls du das Tool wieder entfernen möchtest, kannst du es mit folgendem Befehl deinstallieren:

```bash
curl -sSL https://raw.githubusercontent.com/gkochAT/system-info/main/install-system-info.sh | bash -s -- --uninstall
```

---

## 🧪 Beispielausgabe

Beispiel einer typischen Ausgabe:

```bash
System Info:
------------

CPU:    Intel(R) N150
RAM:    16 GB DDR4 - AD4AS3200QG
Disk:   AirDisk 512GB SSD - 476.9G
```

---

## 📁 Struktur nach der Installation

| Komponente            | Pfad                          |
|-----------------------|-------------------------------|
| Ausführbares Tool     | `/usr/local/bin/system-info`  |
| Installationsskript   | temporär, manuell heruntergeladen |
| `dmidecode` (falls fehlend) | wird über `apt install` nachinstalliert |

---

## 🔍 Was passiert bei der Installation?

- Das Skript prüft, ob `dmidecode` installiert ist
- Falls nicht, wird es automatisch per `apt install` installiert
- Danach wird das `system-info`-Kommando unter `/usr/local/bin` erstellt
- Zum Schluss wird ein Testlauf ausgeführt und die Hardwareinformationen werden angezeigt

---

## 📥 Manuelle Nutzung des Installers

### 1. Skript lokal speichern:
```bash
wget https://raw.githubusercontent.com/gkochAT/system-info/main/install-system-info.sh
chmod +x install-system-info.sh
```

### 2. Installation starten:
```bash
./install-system-info.sh
```

### 3. Deinstallation:
```bash
./install-system-info.sh --uninstall
```

---

## 🧑‍💻 Autor

**Guenther Koch**  
🔗 [github.com/gkochAT](https://github.com/gkochAT)

---

## 📝 Lizenz

Dieses Projekt steht unter der [MIT License](https://opensource.org/licenses/MIT).  
Du darfst den Code frei verwenden, verändern und verbreiten – auch kommerziell.

---

## ❤️ Feedback & Beiträge

Hast du Ideen, Vorschläge oder möchtest mithelfen?  
Erstelle ein [Issue](https://github.com/gkochAT/system-info/issues) oder sende einen Pull Request! 🙂
