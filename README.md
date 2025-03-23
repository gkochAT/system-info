# 🔧 system-info – Umfassendes Systemdiagnose-Tool für Linux

**system-info** ist ein leistungsfähiges Bash-Skript, das detaillierte Informationen speziell zu Proxmox-Hosts sowie Festplatten-, RAID-Status und allgemeine Hardware-Infos übersichtlich darstellt.

---

## 🚀 Schnellstart

**Installation auf Debian/Ubuntu** (kopiere diesen Befehl direkt ins Terminal):

```bash
wget -qO /tmp/install-system-info.sh https://raw.githubusercontent.com/gkochAT/system-info/main/install-system-info.sh && bash /tmp/install-system-info.sh
```

Dieser Befehl lädt das Installationsskript herunter und führt es direkt aus.

---

## 📖 Beschreibung

Das **system-info** Tool gibt dir folgende umfassende Informationen zu deinem System aus:

- 🖥️ Betriebssystem (OS) und Kernel-Version
- ⏱️ Hostname und Betriebszeit (Uptime)
- 🖧 Netzwerk-Interfaces mit IPv4-Adressen
- 🔍 Hardware-Typ (virtuell oder physisch)
- 📟 CPU-Typ, Anzahl Kerne und Threads
- 💾 Arbeitsspeicher (RAM), inkl. Moduldaten
- 📀 Festplatteninformationen und SMART-Status
- 🗃️ RAID-Konfiguration (mdadm)
- 🗂️ ZFS-Pool-Status

---

## 🛠️ Verfügbare Parameter

| Option         | Beschreibung                           |
|----------------|----------------------------------------|
| `--version`    | Version des Skripts anzeigen           |
| `--uninstall`  | Skript entfernen                       |
| `--nocolor`    | Ausgabe ohne Farbcodierung anzeigen    |
| `--help`       | Hilfe und Übersicht der Optionen       |

**Beispiele:**

```bash
system-info --version
system-info --nocolor
system-info --help
system-info --uninstall
```

---

## 📥 Manuelle Installation

Alternativ kannst du **system-info** auch manuell installieren:

### 1. Installationsskript herunterladen

```bash
wget -qO /tmp/install-system-info.sh https://raw.githubusercontent.com/gkochAT/system-info/main/install-system-info.sh
```

### 2. Installationsskript ausführbar machen

```bash
chmod +x /tmp/install-system-info.sh
```

### 3. Installation starten

```bash
sudo bash /tmp/install-system-info.sh
```

---

## ⚙️ Voraussetzungen

- **Linux Betriebssystem** (optimal: Debian-basierte Distribution wie Ubuntu)
- **sudo** Rechte für die Installation von Paketen
- Einer der unterstützten Paketmanager (`apt-get`, `yum`, `pacman`)

---

## 🖥️ Unterstützte Distributionen

- ✅ Debian / Ubuntu

---

## 📄 Lizenz

Dieses Projekt ist unter der **MIT License** veröffentlicht – siehe [LICENSE](LICENSE)-Datei im Repository.

---

## 🤝 Mitwirkung

Deine Vorschläge und Verbesserungen sind willkommen! 

Öffne gerne ein [Issue](https://github.com/gkochAT/system-info/issues) oder erstelle einen [Pull Request](https://github.com/gkochAT/system-info/pulls).

---

## 📬 Kontakt & Support

Guenther Koch  
GitHub: [gkochAT](https://github.com/gkochAT) 

---

🎉 **Viel Spaß mit system-info!** 🎉

