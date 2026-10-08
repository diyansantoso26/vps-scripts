@echo off
rem ============================================================
rem  BLOKIR-AUTOCAD-2018.BAT
rem  Memutus total akses internet AutoCAD 2018, sekali jalan:
rem   [1] Firewall : block koneksi KELUAR (outbound) acad.exe dkk
rem   [2] Service  : disable semua service Autodesk
rem   [3] Hosts    : arahkan server lisensi Autodesk ke 127.0.0.1
rem  Aman dijalankan berulang-ulang (idempotent).
rem ============================================================

:: ---------- Minta hak Administrator kalau belum ----------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  ===============================================
echo   BLOKIR INTERNET AUTOCAD 2018 - sekali jalan
echo  ===============================================
echo.

:: ---------- [1/3] FIREWALL ----------
echo [1/3] Membuat firewall rule (block outbound)...
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad.exe"
call :BlockProg "C:\Program Files (x86)\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad.exe x86"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\AdSSO\AdSSO.exe" "Blokir AutoCAD2018 - AdSSO"
call :BlockProg "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\AdskLicensingService\AdskLicensingService.exe" "Blokir AutoCAD2018 - LicensingService"
call :BlockProg "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AutodeskDesktopApp.exe" "Blokir AutoCAD2018 - DesktopApp"
echo.
set /p CUSTOM="  Path acad.exe lain (mis. drive D:, kosongkan bila tidak ada): "
if defined CUSTOM call :BlockProg "%CUSTOM%" "Blokir AutoCAD2018 - custom"
echo       Selesai.
echo.

:: ---------- [2/3] SERVICE ----------
echo [2/3] Menonaktifkan service Autodesk...
call :DisSvc "AdskLicensingService"
call :DisSvc "Autodesk Desktop App Service"
call :DisSvc "FlexNet Licensing Service"
echo       Selesai.
echo.

:: ---------- [3/3] HOSTS ----------
echo [3/3] Menulis hosts file (redirect server Autodesk)...
set "HOSTSFILE=%SystemRoot%\System32\drivers\etc\hosts"
>>"%HOSTSFILE%" echo.
for %%H in (
    genuine-software.autodesk.com
    genuine-software1.autodesk.com
    cur.autodesk.com
    accounts.autodesk.com
    api.autodesk.com
    metapi.autodesk.com
    edge.api.autodesk.com
    ipservice.api.autodesk.com
    cm-sso-prod.arkoselabs.com
) do (
    findstr /i /m /c:"%%H" "%HOSTSFILE%" >nul 2>&1
    if errorlevel 1 (
        >>"%HOSTSFILE%" echo 127.0.0.1 %%H
        echo       + %%H diblokir
    ) else (
        echo       = %%H sudah ada, dilewati
    )
)
ipconfig /flushdns >nul 2>&1
echo       Selesai.
echo.

echo  ===============================================
echo   BERES!
echo   - Restart AutoCAD / PC biar efeknya penuh.
echo   - Langkah manual terakhir (sekali saja):
echo     di AutoCAD ketik OPTIONS, tab System,
echo     matikan "Automatically check for updates".
echo  ===============================================
echo.
pause
exit /b 0

:: ================= Subrutin =================
:BlockProg
netsh advfirewall firewall delete rule name="%~2" >nul 2>&1
if not exist "%~1" (
    echo       - file tidak ada, dilewati: %~1
    exit /b 0
)
netsh advfirewall firewall add rule name="%~2" dir=out action=block program="%~1" enable=yes profile=any >nul 2>&1
if errorlevel 1 (
    echo       ! GAGAL membuat rule: %~2
) else (
    echo       + %~2
)
exit /b 0

:DisSvc
sc query "%~1" >nul 2>&1
if errorlevel 1 (
    echo       - %~1 tidak ditemukan, dilewati
    exit /b 0
)
sc stop "%~1" >nul 2>&1
sc config "%~1" start= disabled >nul 2>&1
echo       + %~1 dinonaktifkan
exit /b 0
