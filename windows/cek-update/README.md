# Cek Update — Status & Toggle Windows/Office Update

Script `.bat` sekali-jalan: dashboard status update + toggle gampang.
Dibuka langsung kelihatan Windows Update dan Office Update lagi
**TERBLOKIR** atau **AKTIF**, terus tinggal pilih mau diapain.

## Cara pakai (copy-paste di PowerShell)

```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/cek-update/cek-update.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

Script self-update otomatis (cek file `VERSION` tiap dibuka).

## Tampilan menu

```
 Windows Update : TERBLOKIR
 Office Update  : AKTIF

 [1] Windows Update -> AKTIFKAN lagi
 [2] Office Update  -> BLOKIR sekarang
 [3] Blokir keduanya
 [4] Aktifkan keduanya (restore dari backup)
 [0] Keluar
```

Label opsi **[1]** dan **[2]** otomatis menyesuaikan status saat ini
(kalau lagi terblokir → tawarannya "AKTIFKAN lagi", sebaliknya "BLOKIR").

## Cara kerja

- **Deteksi status**: cek `START_TYPE` service `wuauserv` + policy
  `NoAutoUpdate` (Windows), dan `UpdatesEnabled` + `enableautomaticupdates`
  (Office).
- **BLOKIR**: sama persis seperti `blokir-update.bat` — backup registry
  dulu ke `%SystemDrive%\Backup-Blokir-Update\<timestamp>\`, baru disable.
- **AKTIFKAN lagi (per komponen)**: restore selektif dari backup terakhir
  (hanya bagian Windows atau hanya Office), plus fallback cara langsung
  bila tidak ada backup.
- **[4] Aktifkan keduanya**: restore penuh dari backup terakhir
  (wajib konfirmasi ketik YA).
- Format backup/manifest **sama** dengan `blokir-update.bat`, jadi kedua
  script bisa saling membaca backup satu sama lain.

## Catatan

- Idempotent: aman dijalankan berulang-ulang.
- Butuh hak Administrator (auto-elevate).
- Pasangan script ini: [../blokir-update/](../blokir-update/) (fokus blokir).
