# AutoCAD 2025 Toolkit — Script Blokir Internet & Utilitas

Varian AutoCAD 2025 dari [AutoCAD 2018 Toolkit](../autocad/). Fungsi sama
persis, disesuaikan untuk path instalasi `C:\Program Files\Autodesk\AutoCAD 2025`.

Dibuat oleh GTG COMPUTER - WA 085738127969.

## Cara pakai (copy-paste di PowerShell)

**Versi TOOLKIT** — menu 8 opsi, self-update otomatis:
```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad-2025/autocad-toolkit.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

**Versi SIMPLE** — blokir + verifikasi dasar, sekali jalan:
```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad-2025/autocad-simple.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

## Menu toolkit

| Opsi | Fungsi |
|---|---|
| **[1]** | Blokir internet total — firewall + matikan service + tulis hosts |
| **[2]** | Verifikasi blokir — cek firewall, hosts, service |
| **[3]** | Bersihkan data lisensi — hapus file lisensi/aktivasi, perlu aktivasi ulang! (konfirmasi YA) |
| **[4]** | Bersih TOTAL — hapus SEMUA file + registry Autodesk, hanya sebelum install ulang! (konfirmasi YA) |
| **[5]** | Whitelist Windows Defender — kecualikan AutoCAD dari scan |
| **[6]** | Monitor live — dashboard statis semua proses Autodesk, 0 koneksi = terblokir total |
| **[7]** | Perbaiki hosts — tulis ulang 9 domain Autodesk |
| **[8]** | Scan semua EXE bawaan paket + status blokirnya |
| **[9]** | Nonaktifkan blokir (unblock 2018+2025) — hapus rule firewall + hosts (konfirmasi YA) |

## Catatan

- File temp memakai prefix `actkit25-` agar tidak tabrakan dengan toolkit 2018.
- Idempotent, CRLF, auto-elevate, self-update via file `VERSION`.
- Hosts: 9 domain Autodesk → `127.0.0.1` (sama seperti versi 2018).
