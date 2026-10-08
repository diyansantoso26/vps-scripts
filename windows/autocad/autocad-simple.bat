@echo off
rem ============================================================
rem  AUTOCAD-SIMPLE.BAT v1
rem  Blokir internet AutoCAD 2018 + verifikasi cepat.
rem  Sekali jalan, tanpa menu. Untuk fitur lengkap:
rem  autocad-toolkit.bat
rem ============================================================
rem  Dibuat oleh GTG COMPUTER

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  AUTOCAD SIMPLE - oleh GTG COMPUTER
echo.
echo  [1/3] Firewall: blokir outbound...
call :B "C:\Program Files\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad.exe"
call :B "C:\Program Files (x86)\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad.exe x86"
call :B "C:\Program Files\Autodesk\AutoCAD 2018\AdSSO\AdSSO.exe" "Blokir AutoCAD2018 - AdSSO"
call :B "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\AdskLicensingService\AdskLicensingService.exe" "Blokir AutoCAD2018 - LicensingService"
call :B "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AutodeskDesktopApp.exe" "Blokir AutoCAD2018 - DesktopApp"
call :B "C:\Program Files\Autodesk\AutoCAD 2018\AcWebBrowser.exe" "Blokir AutoCAD2018 - AcWebBrowser"
call :B "C:\Program Files\Autodesk\AutoCAD 2018\senddmp.exe" "Blokir AutoCAD2018 - senddmp"

echo.
echo  [2/3] Service Autodesk: disable...
for %%S in ("AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service") do (
    sc query %%~S >nul 2>&1
    if not errorlevel 1 (
        sc stop %%~S >nul 2>&1
        sc config %%~S start= disabled >nul 2>&1
        echo      + %%~S dimatikan
    )
)

echo.
echo  [3/3] Hosts: redirect server Autodesk ke 127.0.0.1...
set "HF=%SystemRoot%\System32\drivers\etc\hosts"
>>"%HF%" echo.
for %%H in (
    genuine-software.autodesk.com genuine-software1.autodesk.com
    cur.autodesk.com accounts.autodesk.com api.autodesk.com
    metapi.autodesk.com edge.api.autodesk.com
    ipservice.api.autodesk.com cm-sso-prod.arkoselabs.com
) do (
    findstr /i /m /c:"%%H" "%HF%" >nul 2>&1
    if errorlevel 1 (
        >>"%HF%" echo 127.0.0.1 %%H
        echo      + %%H
    )
)
ipconfig /flushdns >nul 2>&1

echo.
echo  Verifikasi cepat...
netsh advfirewall firewall show rule name="Blokir AutoCAD2018 - acad.exe" 2>nul | findstr /i "Yes" >nul
if not errorlevel 1 (echo      [OK] Firewall acad.exe aktif) else (echo      [GAGAL] Firewall acad.exe)
set "HC=0"
for /f %%L in ('powershell -NoProfile -Command "((Get-Content \"%HF%\" -ErrorAction SilentlyContinue | Select-String -SimpleMatch 'autodesk.com' | Measure-Object).Count)" 2^>nul') do set "HC=%%L"
echo      [OK] Hosts: %HC% entri autodesk.com

echo.
echo  ===============================================
echo   SELESAI. Restart PC biar efek penuh.
echo  ===============================================
pause
exit /b 0

:B
netsh advfirewall firewall delete rule name="%~2" >nul 2>&1
if not exist "%~1" exit /b 0
netsh advfirewall firewall add rule name="%~2" dir=out action=block program="%~1" enable=yes profile=any >nul 2>&1
if not errorlevel 1 (echo      + %~nx1 diblokir) else (echo      ! gagal: %~nx1)
exit /b 0
