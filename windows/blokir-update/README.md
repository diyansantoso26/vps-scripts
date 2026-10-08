# Blokir Update — Windows & Microsoft Office

Script `.bat` sekali-jalan untuk memblokir permanen Windows Update dan
Microsoft Office Update (Click-to-Run), dengan **backup registry otomatis**
sebelum setiap perubahan — jadi bisa di-restore kapan saja.

## Cara pakai (copy-paste di PowerShell)

```powershell
irm https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/blokir-update/blokir-update.bat -OutFile $env:TEMP\s.bat; saps $env:TEMP\s.bat -Verb RunAs
```

Script self-update otomatis (cek file `VERSION` tiap dibuka).

## Menu

| Opsi | Fungsi |
|---|---|
| **[1]** | Blokir Windows Update saja — backup registry dulu, lalu disable permanen |
| **[2]** | Blokir Microsoft Office Update saja — backup registry dulu, lalu disable permanen |
| **[3]** | Blokir keduanya (Windows + Office) |
| **[4]** | Restore — kembalikan registry + service dari backup terakhir (wajib konfirmasi ketik YA) |
| **[5]** | Cek status — lihat service & registry saat ini |

## Cara kerja

**Windows Update diblokir via:**
- Service di-disable: `wuauserv`, `BITS`, `UsoSvc`, `WaaSMedicSvc`, `DoSvc`
  (WaaSMedicSvc penting — ini "tukang servis" yang biasa menghidupkan lagi Windows Update)
- Registry policy: `NoAutoUpdate=1`, `AUOptions=2`
- Scheduled task di-disable: `Scheduled Start`, `sih`, `sihboot`

**Office Update diblokir via:**
- `UpdatesEnabled=False` (ClickToRun Configuration)
- Policy `enableautomaticupdates=0`
- Scheduled task di-disable: `Office Automatic Updates 2.0`, `Office ClickToRun Service Monitor`
- `ClickToRunSvc` **sengaja TIDAK di-disable** — service itu dibutuhkan Office untuk berjalan.

## Backup & Restore

- Setiap aksi blokir membuat folder backup:
  `%SystemDrive%\Backup-Blokir-Update\<tahunbulantanggal-jammenitdetik>\`
- Isi: file `.reg` (hasil `reg export` key yang sudah ada) + `manifest.txt`
  (catatan key/value yang *belum ada* sebelum diblokir).
- Opsi **[4]** Restore: import semua `.reg`, hapus key/value yang dibuat
  saat blokir (sesuai manifest), aktifkan lagi scheduled task.
- Konfirmasi ketik `YA` wajib sebelum restore jalan.

## Catatan

- Idempotent: aman dijalankan berulang-ulang.
- Butuh hak Administrator (auto-elevate).
- Setelah restore, restart PC disarankan agar service kembali normal.
