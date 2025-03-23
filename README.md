# 🖥️ system-info

Ein praktisches Shell-Tool zur Anzeige grundlegender Hardwareinformationen – ideal für Linux- und Proxmox-Umgebungen.

---

## 🚀 Features

✅ Zeigt dir auf einen Blick:

- 🩺 SMART-Status aller Disks (SATA & NVMe), inkl. Debug-Ausgabe bei unbekanntem Zustand

- 🧠 CPU-Modell, Cores und Threads
- 🧬 Gesamter RAM & alle Module mit Typ und Part-Nummer
- 💾 SSD/NVMe-Modelle mit Größe
- 🧱 RAID-Erkennung (Software-RAID via mdadm + ZFS)
- 🖥️ Systeminfos: Hostname, Uptime, OS-Version, Kernel, virtuell oder physisch
- 🌐 Netzwerkinterfaces inkl. IP-Adressen

---

## ⚙️ Installation

Du kannst das Skript einfach per `wget` herunterladen und ausführen:

### 📦 Mit `wget` nach /tmp:
```bash
wget -qO /tmp/install-system-info.sh https://raw.githubusercontent.com/gkochAT/system-info/main/install-system-info.sh && bash /tmp/install-system-info.sh
```

🔹 Das Skript wird **nicht dauerhaft gespeichert** – es wird in `/tmp` abgelegt und beim nächsten Reboot automatisch gelöscht.

🔹 Das Tool wird nach der Installation unter folgendem Pfad abgelegt:

```bash
/usr/local/bin/system-info
```

Du kannst es danach überall im Terminal mit folgendem Befehl aufrufen:

```bash
system-info
```

---

## 🧹 Deinstallation

### 🔸 Direkt über das Tool:

```bash
system-info --uninstall
```

Löscht das Tool (`/usr/local/bin/system-info`) wieder sauber vom System.

---

## 🧪 Beispielausgabe

### 🧠 SMART Debug:
Falls keine SMART-Informationen erkannt werden, wird die vollständige `smartctl`-Ausgabe angezeigt, z. B.:
```bash
SMART Status:
/dev/nvme0n1: ❓ Kein Status erkannt (Debug-Ausgabe folgt):
      SMART support is: Available – device has SMART capability.
      SMART support is: Enabled
```


### 📦 Beispiel mit SMART Status:
```bash
SMART Status:
  - /dev/sda: PASSED
  - /dev/nvme0n1: ⚠️ FAILED!
```



```bash
System Info:
------------

OS:       Debian GNU/Linux 12 (bookworm)
Kernel:   6.8.12-8-pve
Hostname: pve
Uptime:   up 5 days, 17 hours, 41 minutes
System Type: Physical
Network Interfaces:
  - lo: 127.0.0.1/8
  - enp0s31f6: 5.9.10.155
  - vmbr0: 5.9.10.155/32
CPU:      Intel(R) Xeon(R) CPU E3-1275 v5 @ 3.60GHz
Cores:    8
Threads:  8
Total RAM: 64.0 GB
RAM Module:
  - 16 GB DDR4 - M391A2K43BB1-CPB
  - 16 GB DDR4 - M391A2K43BB1-CPB
  - 16 GB DDR4 - M391A2K43BB1-CPB
  - 16 GB DDR4 - M391A2K43BB1-CPB
Disk(s):
  - /dev/nvme0n1: SAMSUNG - MZVPV512HDGL-00000 - 476.9G
  - /dev/nvme1n1: SAMSUNG - MZVPV512HDGL-00000 - 476.9G
RAID Status:
  - Software-RAID (mdadm): md1 : active raid1 nvme0n1p2[1] nvme1n1p2[0]
  - Software-RAID (mdadm): md0 : active raid1 nvme0n1p1[1] nvme1n1p1[0]
  - Kein ZFS-Pool gefunden
```

---

## 📁 Struktur nach der Installation

| Komponente             | Pfad                          |
|------------------------|-------------------------------|
| Ausführbares Tool      | `/usr/local/bin/system-info`  |
| Installationsskript    | temporär: `/tmp/install-system-info.sh` |
| dmidecode              | wird bei Bedarf installiert   |
| zfsutils-linux         | wird bei Bedarf installiert   |

---

## 🔍 Was passiert bei der Installation?

- `dmidecode` wird installiert (falls nicht vorhanden)
- `zfsutils-linux` wird installiert (falls nicht vorhanden)
- Das Tool wird unter `/usr/local/bin/system-info` gespeichert

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
