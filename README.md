# 🖥️ system-info

**system-info** ist ein schlankes Shell-Skript zur Anzeige grundlegender Hardwareinformationen wie CPU, RAM und SSD/NVMe – ideal für Linux-Server, Proxmox-Hosts, Bare-Metal-Setups oder Mini-PCs.

---

## 🚀 Features

- 🔍 Zeigt CPU-Modellnamen
- 💾 Erkennt installierten RAM (Größe, Typ, Hersteller, Part-Nummer)
- 📦 Listet Modell und Kapazität der SSD/NVMe
- 🧠 Erkennt automatisch, ob `dmidecode` installiert ist – und installiert es bei Bedarf
- 📥 Per Einzeiler installierbar
- 🧹 Deinstallation mit einem simplen Schalter
- 📂 Legt Skript unter `/usr/local/bin/system-info` ab – systemweit verfügbar

---

## 📸 Beispielausgabe

```bash
System Info:
------------

CPU:    Intel(R) N150
RAM:    16 GB DDR4 - AD4AS3200QG
Disk:   AirDisk 512GB SSD - 476.9G
