@echo off
rem ============================================================
rem  AUTOCAD-FULL-RESET.BAT
rem  SATU script untuk semua: kill koneksi + bersih flag
rem  Genuine Service + blokir permanen, siap aktivasi ulang.
rem.
rem  Isi: [1] kill proses  [2] sapu koneksi aktif  [3] disable
rem  service  [4] hapus data Genuine Service + lisensi
rem  [5] firewall block total  [6] hosts.
rem  Setelah selesai: RESTART PC, baru aktivasi ulang.
rem  Idempotent, aman diulang-ulang.
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  ===============================================
echo   AUTOCAD FULL RESET - kill + bersih + blokir
echo  ===============================================
echo.
echo [1/6] Kill proses Autodesk...
for %%P in (
    acad.exe AcWebBrowser.exe AcCefSubprocess.exe AdSync.exe
    AdSSO.exe AutodeskDesktopApp.exe AdAppMgr.exe AdAppMgrSvc.exe
    AdskLicensingService.exe AdskLicensingAgent.exe GenuineService.exe
    senddmp.exe
) do ( taskkill /f /im %%P >nul 2>&1 )
echo       Selesai.
echo.
echo [2/6] Sapu koneksi aktif yang tersisa...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=$false; foreach ($c in (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue)) { try { $p = Get-Process -Id $c.OwningProcess -ErrorAction Stop } catch { continue }; if ($p.Path -and $p.Path -like '*Autodesk*') { try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-Output ('      x {0} dimatikan' -f $p.ProcessName); $f=$true } catch {} } }; if (-not $f) { Write-Output '      - bersih.' }"
echo.
echo [3/6] Disable service Autodesk...
for %%S in ("AdskGenuineService" "AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service") do (
    sc stop %%~S >nul 2>&1
    sc config %%~S start= disabled >nul 2>&1
)
echo       Selesai.
echo.
echo [4/6] Hapus data Genuine Service + lisensi...
if exist "C:\Program Files\Autodesk\Autodesk Genuine Service" rmdir /s /q "C:\Program Files\Autodesk\Autodesk Genuine Service"
if exist "C:\ProgramData\Autodesk\Autodesk Genuine Service" rmdir /s /q "C:\ProgramData\Autodesk\Autodesk Genuine Service"
if exist "%LOCALAPPDATA%\Autodesk\Autodesk Genuine Service" rmdir /s /q "%LOCALAPPDATA%\Autodesk\Autodesk Genuine Service"
reg delete "HKLM\SOFTWARE\Autodesk\Autodesk Genuine Service" /f >nul 2>&1
if exist "C:\ProgramData\FLEXnet\adskflex_*.data" del /f /q "C:\ProgramData\FLEXnet\adskflex_*.data*"
if exist "C:\ProgramData\Autodesk\CLM\LGS" del /f /q "C:\ProgramData\Autodesk\CLM\LGS\*"
if exist "%LOCALAPPDATA%\Autodesk\Web Services" rmdir /s /q "%LOCALAPPDATA%\Autodesk\Web Services"
reg delete "HKLM\SOFTWARE\FLEXlm License Manager" /f >nul 2>&1
echo       Selesai.
echo.
echo [5/6] Pasang firewall block total...
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad"
call :BlockProg "C:\Program Files (x86)\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\AdSSO\AdSSO.exe" "Blokir AutoCAD2018 - AdSSO"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\AcWebBrowser.exe" "Blokir AutoCAD2018 - AcWebBrowser"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\AcCefSubprocess.exe" "Blokir AutoCAD2018 - AcCefSubprocess"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\senddmp.exe" "Blokir AutoCAD2018 - senddmp"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\acad.exe" "Blokir AutoCAD2025 - acad"
call :BlockProg "C:\Program Files (x86)\Autodesk\AutoCAD 2025\acad.exe" "Blokir AutoCAD2025 - acad"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\AdSSO\AdSSO.exe" "Blokir AutoCAD2025 - AdSSO"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\AcWebBrowser.exe" "Blokir AutoCAD2025 - AcWebBrowser"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\AcCefSubprocess.exe" "Blokir AutoCAD2025 - AcCefSubprocess"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\senddmp.exe" "Blokir AutoCAD2025 - senddmp"
call :BlockProg "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\AdskLicensingService\AdskLicensingService.exe" "Blokir AutoCAD2018 - AdskLicensingService"
call :BlockProg "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AutodeskDesktopApp.exe" "Blokir AutoCAD2018 - AutodeskDesktopApp"
call :BlockProg "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AdAppMgrSvc.exe" "Blokir AutoCAD2018 - AdAppMgrSvc"
call :BlockProg "C:\Program Files\Autodesk\Autodesk Genuine Service\GenuineService.exe" "Blokir AutoCAD2018 - GenuineService"
call :BlockProg "C:\Program Files\Autodesk\Autodesk Sync\AdSync.exe" "Blokir AutoCAD2018 - AdSync"
echo       Selesai.
echo.
echo [6/6] Tulis hosts + flush DNS...
set "HOSTSFILE=%SystemRoot%\System32\drivers\etc\hosts"
for %%H in (
    genuine-software.autodesk.com genuine-software1.autodesk.com
    cur.autodesk.com accounts.autodesk.com api.autodesk.com
    metapi.autodesk.com edge.api.autodesk.com
    ipservice.api.autodesk.com cm-sso-prod.arkoselabs.com
) do (
    findstr /i /m /c:"%%H" "%HOSTSFILE%" >nul 2>&1
    if errorlevel 1 ( >>"%HOSTSFILE%" echo 127.0.0.1 %%H )
)
ipconfig /flushdns >nul 2>&1
echo       Selesai.
echo.
echo  ===============================================
echo   BERES! Terakhir:
echo   1. RESTART PC sekarang (wajib).
echo   2. Jangan buka apapun Autodesk dulu.
echo   3. Buka AutoCAD -^> aktivasi ulang dari awal.
echo  ===============================================
echo.
set /p RST="  Restart sekarang? [Y/n]: "
if /i "%RST%"=="n" ( echo     OK, restart manual sebelum aktivasi. ) else ( shutdown /r /t 15 /c "Full reset AutoCAD selesai - restart" )
pause
exit /b 0

:: ================= Subrutin ==================
:BlockProg
netsh advfirewall firewall delete rule name="%~2" >nul 2>&1
if not exist "%~1" ( echo       - lewati: %~1 & exit /b 0 )
netsh advfirewall firewall add rule name="%~2" dir=out action=block program="%~1" enable=yes profile=any >nul 2>&1
if errorlevel 1 ( echo       ! GAGAL: %~2 ) else ( echo       + %~2 )
exit /b 0
