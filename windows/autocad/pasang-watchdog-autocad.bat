@echo off
rem ============================================================
rem  PASANG-WATCHDOG-AUTOCAD.BAT - GTG COMPUTER
rem  Pasang watchdog monitoring AutoCAD (cek tiap 30 menit).
rem  Cara pakai: DOUBLE-CLICK biasa. JANGAN Run as Administrator.
rem ============================================================

net session >nul 2>&1
if %errorLevel%==0 (
    echo  Berjalan sebagai admin - membuka ulang sebagai user biasa...
    runas /trustlevel:0x20000 "cmd /c \"%~f0\""
    if errorlevel 1 (
        echo  !! Gagal. Tutup ini, lalu double-click file ini biasa saja.
        pause
    )
    exit /b 0
)

set "DST=%LOCALAPPDATA%\GTG"
if not exist "%DST%" mkdir "%DST%" >nul 2>&1

echo.
echo  [1] Pasang watchdog - cek tiap 1 menit (ketat)
echo  [2] Pasang watchdog - cek tiap 5 menit
echo  [3] Pasang watchdog - cek tiap 30 menit (hemat)
echo  [4] Hapus watchdog
echo  [0] Batal
echo.
set /p P="  Pilih: "
if "%P%"=="1" set WDINT=1
if "%P%"=="2" set WDINT=5
if "%P%"=="3" set WDINT=30
if defined WDINT goto INSTALL
if "%P%"=="4" goto REMOVE
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
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/run-watchdog-hidden.vbs' -OutFile '%DST%\run-watchdog-hidden.vbs' -UseBasicParsing"
if not exist "%DST%\run-watchdog-hidden.vbs" (
    echo  GAGAL mengunduh launcher. Cek internet lalu coba lagi.
    pause
    exit /b 1
)
echo  Membuat jadwal tiap %WDINT% menit (tanpa popup)...
powershell -NoProfile -Command "try { $vbsArg = [char]34 + '%DST%\run-watchdog-hidden.vbs' + [char]34; $a = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument $vbsArg; $t = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes %WDINT%); Register-ScheduledTask -TaskName 'AutoCAD Watchdog GTG' -Action $a -Trigger $t -Force | Out-Null; 'TASKOK' } catch { 'TASKFAIL' }" > "%TEMP%\wdt.txt" 2>nul
findstr /i "TASKOK" "%TEMP%\wdt.txt" >nul 2>&1
if errorlevel 1 (
    echo  GAGAL membuat jadwal.
    pause
    exit /b 1
)
echo  Tes notifikasi...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DST%\autocad-watchdog.ps1" -Test
echo.
echo  BERES! Watchdog aktif, cek tiap %WDINT% menit (tanpa jendela).
echo  - Koneksi Autodesk yg lolos: langsung dimatikan + notifikasi.
echo  - Rule/hosts/service bermasalah: notifikasi, jalankan toolkit [1].
echo  - Saat toolkit [9] dipakai: watchdog nonaktif otomatis.
echo  Log: %DST%\watchdog.log
pause
exit /b 0

:REMOVE
schtasks /delete /tn "AutoCAD Watchdog GTG" /f >nul 2>&1
del "%DST%\autocad-watchdog.ps1" 2>nul
del "%DST%\run-watchdog-hidden.vbs" 2>nul
del "%DST%\watchdog.state" 2>nul
echo  Watchdog dihapus.
pause
exit /b 0
