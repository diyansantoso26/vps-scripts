# vps-scripts
Script keamanan &amp; backup VPS (Ubuntu)

## Script Windows — AutoCAD 2018 Toolkit

Kumpulan script `.bat` sekali-jalan: blokir total internet AutoCAD 2018
(firewall + service + hosts), verifikasi, bersih lisensi, whitelist
Defender, monitor koneksi live, scan semua EXE bawaan paket, dll.

Dokumentasi lengkap: [windows/autocad/](windows/autocad/)

### Pakai cepat (copy-paste di PowerShell)

Versi **simple** — blokir + verifikasi dasar, sekali jalan:
```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-simple.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

Versi **toolkit lengkap** — menu 8 opsi, self-update otomatis:
```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-toolkit.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

## Script Windows — Blokir Update (Windows & Office)

Script `.bat` sekali-jalan: blokir permanen Windows Update & Microsoft Office
Update. Setiap aksi blokir **backup registry dulu** ke
`C:\Backup-Blokir-Update\<timestamp>\`, bisa di-restore kapan saja
(opsi [4]).

Dokumentasi lengkap: [windows/blokir-update/](windows/blokir-update/)

### Pakai cepat (copy-paste di PowerShell)

```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/blokir-update/blokir-update.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```
