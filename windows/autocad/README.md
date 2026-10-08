# AutoCAD 2018 Toolkit — Script Blokir Internet & Utilitas

Kumpulan script sekali-jalan untuk memutus total akses internet AutoCAD 2018
(tanpa install ulang Windows), verifikasi, dan utilitas pendukung.

## Cara pakai tercepat (copy-paste di PowerShell)

**Versi SIMPLE** — blokir + verifikasi dasar, sekali jalan tanpa menu:
```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-simple.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

**Versi TOOLKIT LENGKAP** — menu 8 opsi (v12+, self-update otomatis):
```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-toolkit.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

> `irm` = download, `saps` = jalankan sebagai Administrator.
> Kompatibel PowerShell 5.1 dan 7.x.

## Daftar file

| File | Fungsi |
|---|---|
| `autocad-simple.bat` | Blokir + verifikasi dasar, sekali jalan tanpa menu (75 baris) |
| `autocad-toolkit.bat` | Menu 8 opsi (self-update otomatis):<br>**[1]** Blokir total — firewall + matikan service + tulis hosts. Jalankan ini duluan.<br>**[2]** Verifikasi — cek firewall, hosts, service. Target 19/19 lolos.<br>**[3]** Bersihkan data lisensi — hapus file lisensi/aktivasi (perlu aktivasi ulang!).<br>**[4]** Bersih TOTAL — hapus SEMUA file + registry Autodesk. Hanya sebelum install ulang CAD!<br>**[5]** Whitelist Defender — kecualikan AutoCAD dari scan biar enteng.<br>**[6]** Monitor live — bukti final: 0 koneksi saat CAD dipakai = terblokir total.<br>**[7]** Perbaiki hosts — tulis ulang 9 domain Autodesk (tanpa ubah firewall).<br>**[8]** Scan EXE — daftar semua .exe bawaan paket + status blokir firewall-nya. |
| `blokir-autocad-2018.bat` | Standalone: blokir firewall + disable service + hosts |
| `verifikasi-blokir-autocad.bat` | Standalone: verifikasi 4 lapis (firewall, hosts, service, tes TCP) |
| `bersih-lisensi-autocad.bat` | Hapus data lisensi (mode 1) / bersih total ala Autodesk (mode 2) |
| `cek-koneksi-autocad.bat` | Monitor live koneksi `acad.exe` tiap 5 detik |
| `whitelist-defender-autocad.bat` | Masukkan folder + proses AutoCAD ke exclusion Windows Defender |
| `perbaiki-hosts-autocad.bat` | Tulis ulang 9 domain Autodesk ke hosts (verbose) |

## One-liner versi LENGKAP (dengan proteksi download)

Versi di atas sudah cukup untuk pemakaian normal. Kalau mau yang ada
proteksi (hapus file lama dulu + pesan jelas kalau download gagal):

```powershell
# SIMPLE
Remove-Item "$env:TEMP\s.bat" -Force -ErrorAction SilentlyContinue; irm "https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-simple.bat" -OutFile "$env:TEMP\s.bat"; if (Test-Path "$env:TEMP\s.bat") { Start-Process "$env:TEMP\s.bat" -Verb RunAs } else { Write-Host "DOWNLOAD GAGAL, cek internet" -ForegroundColor Red }

# TOOLKIT
Remove-Item "$env:TEMP\actkit.bat" -Force -ErrorAction SilentlyContinue; irm "https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-toolkit.bat" -OutFile "$env:TEMP\actkit.bat"; if (Test-Path "$env:TEMP\actkit.bat") { Start-Process "$env:TEMP\actkit.bat" -Verb RunAs } else { Write-Host "DOWNLOAD GAGAL, cek internet" -ForegroundColor Red }
```

## Alur rekomendasi

1. **Blokir dulu** — simple, atau toolkit opsi `[1]`
2. **Verifikasi** — toolkit opsi `[2]` (atau cek `verifikasi-blokir-autocad.bat`)
3. **Restart PC** — penting! Rule firewall tidak memutus koneksi yang sudah telanjur nyambung
4. **Bukti traffic** — toolkit opsi `[6]` monitor, buka AutoCAD, pakai 5–10 menit; 0 koneksi = terbukti terblokir
5. Opsional: toolkit opsi `[5]` whitelist Defender, `[8]` scan semua EXE bawaan paket

## Catatan teknis

- Semua script `.bat` memakai CRLF line ending dan self-elevate (minta Administrator otomatis).
- Idempotent: aman dijalankan berulang-ulang.
- `VERSION` — file penanda versi untuk mekanisme self-update toolkit.
- hosts: 9 domain Autodesk diarahkan ke `127.0.0.1`
  (`genuine-software(1).autodesk.com`, `cur`, `accounts`, `api`, `metapi`,
  `edge.api`, `ipservice.api`, `cm-sso-prod.arkoselabs.com`).
