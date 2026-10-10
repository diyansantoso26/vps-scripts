@echo off
rem ============================================================
rem  PASANG-WATCHDOG-AUTOCAD.BAT - GTG COMPUTER
rem  Pasang watchdog monitoring AutoCAD (cek tiap 30 menit).
rem  Cara pakai: DOUBLE-CLICK biasa. JANGAN Run as Administrator.
rem ============================================================

net session >nul 2>&1
if %errorLevel%==0 (
    echo  !! Jangan dijalankan sebagai Administrator.
    echo  !! Tutup jendela ini, lalu double-click file ini biasa saja.
    pause
    exit /b 1
)

set "DST=%LOCALAPPDATA%\GTG"
if not exist "%DST%" mkdir "%DST%" >nul 2>&1

echo.
echo  [1] Pasang watchdog (cek tiap 30 menit)
echo  [2] Hapus watchdog
echo  [0] Batal
echo.
set /p P="  Pilih: "
if "%P%"=="1" goto INSTALL
if "%P%"=="2" goto REMOVE
exit /b 0

:INSTALL
echo.
echo  Mengunduh script watchdog...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-watchdog.ps1' -OutFile '%DST%\autocad-watchdog.ps1' -UseBasicParsing"
if not exist "%DST%\autocad-watchdog.ps1" (
    echo  GAGAL mengunduh. Cek internet lalu coba lagi.
    pause
    exit /b 1
)
echo  Membuat jadwal tiap 30 menit...
schtasks /create /tn "AutoCAD Watchdog GTG" /tr "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File '%DST%\autocad-watchdog.ps1'" /sc minute /mo 30 /f
if errorlevel 1 (
    echo  GAGAL membuat jadwal.
    pause
    exit /b 1
)
echo  Tes notifikasi...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DST%\autocad-watchdog.ps1" -Test
echo.
echo  BERES! Watchdog aktif, cek tiap 30 menit (tanpa jendela).
echo  - Koneksi Autodesk yg lolos: langsung dimatikan + notifikasi.
echo  - Rule/hosts/service bermasalah: notifikasi, jalankan toolkit [1].
echo  - Saat toolkit [9] dipakai: watchdog nonaktif otomatis.
echo  Log: %DST%\watchdog.log
pause
exit /b 0

:REMOVE
schtasks /delete /tn "AutoCAD Watchdog GTG" /f >nul 2>&1
del "%DST%\autocad-watchdog.ps1" 2>nul
del "%DST%\watchdog.state" 2>nul
echo  Watchdog dihapus.
pause
exit /b 0
