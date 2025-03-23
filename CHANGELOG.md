# 📋 Changelog

Alle relevanten Änderungen und Releases des Projekts.

---

## [v1.0] – Initial Release – 2025-03-23

### ✨ Neu
- Installation per `wget` nach `/tmp` mit automatischer Prüfung und Installation von Abhängigkeiten
- Systeminformationen:
  - OS, Kernel, Hostname, Uptime
  - CPU-Modell, Kerne, Threads
  - RAM gesamt & pro Modul
  - Disks: NVMe/SATA inkl. Modell + Größe
- RAID-Status:
  - mdadm Software-RAID (inkl. Warnung bei degraded)
  - ZFS Pools mit `zpool status -x`
- SMART-Status:
  - Erkennung für NVMe & SATA
  - Debug-Ausgabe bei fehlendem Health-Wert
- Deinstallation via:
  - `system-info --uninstall`
