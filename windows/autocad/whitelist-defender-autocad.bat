@echo off
rem ============================================================
rem  WHITELIST-DEFENDER-AUTOCAD.BAT
rem  Masukkan AutoCAD 2018 ke daftar exclusion (whitelist)
rem  Windows Defender supaya tidak di-scan / dikarantina:
rem   - Exclusion folder instalasi
rem   - Exclusion file acad.exe
rem   - Exclusion proses acad.exe
rem  Catatan: hanya berpengaruh jika Windows Defender adalah
rem  antivirus utama yang aktif di PC ini.
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  ===============================================
echo   WHITELIST DEFENDER UNTUK AUTOCAD 2018
echo  ===============================================
echo.

:: --- Cek antivirus utama ---
for /f %%A in ('powershell -NoProfile -Command "(Get-MpComputerStatus -ErrorAction SilentlyContinue).AntivirusEnabled" 2^>nul') do set "AVON=%%A"
if /i not "%AVON%"=="True" (
    echo  PERINGATAN: Windows Defender tampaknya BUKAN antivirus utama
    echo  yang aktif di PC ini. Exclusion mungkin tidak berpengaruh.
    echo  Lanjut tetap dibuatkan? (Y/N)
    set /p LANJUT="  "
    if /i not "%LANJUT%"=="Y" exit /b 0
)
echo.

:: --- Tentukan folder AutoCAD ---
set "ACADDIR=C:\Program Files\Autodesk\AutoCAD 2018"
if not exist "%ACADDIR%\acad.exe" (
    echo  acad.exe tidak ketemu di lokasi default.
    set /p ACADDIR="  Masukkan path folder AutoCAD 2018: "
)
if not exist "%ACADDIR%\acad.exe" (
    echo  File acad.exe tetap tidak ditemukan. Batal.
    pause
    exit /b 1
)
echo  Folder AutoCAD: %ACADDIR%
echo.

:: --- Tambahkan exclusions ---
echo  Menambahkan ke whitelist Defender...
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%ACADDIR%'" 2>nul
if not errorlevel 1 (echo      + folder: %ACADDIR%) else (echo      ! gagal: folder)
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%ACADDIR%\acad.exe'" 2>nul
if not errorlevel 1 (echo      + file: acad.exe) else (echo      ! gagal: file)
powershell -NoProfile -Command "Add-MpPreference -ExclusionProcess 'acad.exe'" 2>nul
if not errorlevel 1 (echo      + proses: acad.exe) else (echo      ! gagal: proses)

:: --- Folder tambahan (opsional, mis. folder crack/keygen) ---
echo.
set /p EXTRA="  Folder tambahan untuk di-whitelist (kosongkan bila tidak ada): "
if defined EXTRA (
    powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%EXTRA%'" 2>nul
    if not errorlevel 1 (echo      + folder tambahan: %EXTRA%) else (echo      ! gagal: folder tambahan)
)
echo.

:: --- Verifikasi ---
echo  Daftar exclusion saat ini:
powershell -NoProfile -Command "Get-MpPreference | Select-Object -ExpandProperty ExclusionPath"
powershell -NoProfile -Command "Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess"
echo.
echo  SELESAI.
pause
exit /b 0
