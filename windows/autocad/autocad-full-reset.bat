@echo off
rem ============================================================
rem  AUTOCAD-FULL-RESET.BAT
rem  SATU script: kill + bersih + blokir total, siap aktivasi ulang.
rem  Setiap langkah lapor BERHASIL/GAGAL dan menunggu
rem  tombol konfirmasi sebelum lanjut.
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set R1=BERHASIL
set R2=BERHASIL
set R3=BERHASIL
set R4=BERHASIL
set R5=BERHASIL
set R6=BERHASIL

echo.
echo  ===============================================
echo   AUTOCAD FULL RESET - kill + bersih + blokir
echo  ===============================================
echo.
echo [1/6] Kill proses Autodesk...
for %%P in (acad.exe AcWebBrowser.exe AcCefSubprocess.exe AdSync.exe AdSSO.exe AutodeskDesktopApp.exe AdAppMgr.exe AdAppMgrSvc.exe AdskLicensingService.exe AdskLicensingAgent.exe GenuineService.exe senddmp.exe) do ( taskkill /f /im %%P >nul 2>&1 )
set "MISS1="
for %%P in (acad.exe AcWebBrowser.exe AcCefSubprocess.exe AdSync.exe AdSSO.exe AutodeskDesktopApp.exe AdAppMgrSvc.exe AdskLicensingService.exe GenuineService.exe) do (
    tasklist /fi "imagename eq %%P" 2>nul ^| findstr /i /c:"%%P" >nul ^&^& set "MISS1=%%P"
)
if defined MISS1 ( set R1=GAGAL ^& echo      ! Masih jalan: %MISS1% ) else ( echo       Selesai. )
call :Notice "1/6" "Kill proses Autodesk" "%R1%"
echo.
echo [2/6] Sapu koneksi aktif yang tersisa...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=$false; foreach ($c in (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue)) { try { $p = Get-Process -Id $c.OwningProcess -ErrorAction Stop } catch { continue }; if ($p.Path -and $p.Path -like '*Autodesk*') { try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-Output ('      x {0} dimatikan' -f $p.ProcessName); $f=$true } catch {} } }; if (-not $f) { Write-Output '      - bersih.' }"
for /f %%N in ('powershell -NoProfile -Command "(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue ^| Where-Object { try { (Get-Process -Id $_.OwningProcess -ErrorAction Stop).Path -like '*Autodesk*' } catch { $false } } ^| Measure-Object).Count" 2^>nul') do set LEFT2=%%N
if "%LEFT2%"=="0" ( echo       Selesai. ) else ( set R2=GAGAL ^& echo      ! Sisa %LEFT2% koneksi Autodesk! )
call :Notice "2/6" "Sapu koneksi aktif" "%R2%"
echo.
echo [3/6] Disable service Autodesk...
for %%S in ("AdskGenuineService" "AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service") do (
    sc stop %%~S >nul 2>&1
    sc config %%~S start= disabled >nul 2>&1
)
for %%S in ("AdskGenuineService" "AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service") do (
    sc query %%~S >nul 2>&1
    if not errorlevel 1 (
        sc qc %%~S 2>nul ^| findstr /i "DISABLED" >nul
        if errorlevel 1 set R3=GAGAL
    )
)
if "%R3%"=="GAGAL" ( echo      ! Ada service belum disabled ) else ( echo       Selesai. )
call :Notice "3/6" "Disable service" "%R3%"
echo.
echo [4/6] Hapus data Genuine Service + lisensi (deep wipe)...
if exist "C:\Program Files\Autodesk\Autodesk Genuine Service" rmdir /s /q "C:\Program Files\Autodesk\Autodesk Genuine Service"
if exist "C:\ProgramData\Autodesk\Autodesk Genuine Service" rmdir /s /q "C:\ProgramData\Autodesk\Autodesk Genuine Service"
if exist "%LOCALAPPDATA%\Autodesk\Autodesk Genuine Service" rmdir /s /q "%LOCALAPPDATA%\Autodesk\Autodesk Genuine Service"
reg delete "HKLM\SOFTWARE\Autodesk\Autodesk Genuine Service" /f >nul 2>&1
if exist "C:\ProgramData\FLEXnet\adskflex_*.data" del /f /q "C:\ProgramData\FLEXnet\adskflex_*.data*"
if exist "C:\ProgramData\Autodesk\CLM\LGS" del /f /q "C:\ProgramData\Autodesk\CLM\LGS\*"
if exist "%LOCALAPPDATA%\Autodesk\Web Services" rmdir /s /q "%LOCALAPPDATA%\Autodesk\Web Services"
reg delete "HKLM\SOFTWARE\FLEXlm License Manager" /f >nul 2>&1
echo       Deep wipe tambahan...
if exist "C:\ProgramData\Autodesk\AdskLicensingService" rmdir /s /q "C:\ProgramData\Autodesk\AdskLicensingService"
if exist "%APPDATA%\Autodesk\AdskLicensingService" rmdir /s /q "%APPDATA%\Autodesk\AdskLicensingService"
if exist "%LOCALAPPDATA%\Autodesk\Identity Services" rmdir /s /q "%LOCALAPPDATA%\Autodesk\Identity Services"
call :WipeAdLM
if exist "C:\ProgramData\Autodesk\Autodesk Genuine Service" set R4=GAGAL
call :CheckAdLM
if "%R4%"=="GAGAL" ( echo      ! Masih ada sisa data lisensi ) else ( echo       Selesai. )
call :Notice "4/6" "Hapus data Genuine Service + lisensi" "%R4%"
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
netsh advfirewall firewall show rule name="Blokir AutoCAD2018 - GenuineService" >nul 2>&1
if errorlevel 1 set R5=GAGAL
if "%R5%"=="BERHASIL" call :CheckAcadRule
if "%R5%"=="GAGAL" ( echo      ! Rule kunci tidak terbentuk ) else ( echo       Selesai. )
call :Notice "5/6" "Firewall block total" "%R5%"
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
findstr /i /c:"genuine-software.autodesk.com" "%HOSTSFILE%" >nul 2>&1
if errorlevel 1 ( set R6=GAGAL ^& echo      ! Hosts tidak tertulis ) else ( echo       Selesai. )
call :Notice "6/6" "Hosts + flush DNS" "%R6%"
echo.
echo  ===============================================
echo   RINGKASAN HASIL:
echo   [1/6] Kill proses ............ %R1%
echo   [2/6] Sapu koneksi ........... %R2%
echo   [3/6] Disable service ........ %R3%
echo   [4/6] Hapus data ............. %R4%
echo   [5/6] Firewall ............... %R5%
echo   [6/6] Hosts .................. %R6%
echo  ===============================================
echo   Langkah terakhir:
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

:WipeAdLM
rem hapus kunci AdLM (status lisensi) semua versi AutoCAD R22-R25
for %%V in (R22.0 R23.0 R23.1 R24.0 R24.1 R24.2 R24.3 R25.0) do (
    for /f "tokens=*" %%K in ('reg query "HKCU\SOFTWARE\Autodesk\AutoCAD\%%V" 2^>nul ^| findstr /i "ACAD-"') do (
        reg delete "%%K\AdLM" /f >nul 2>&1
    )
    for /f "tokens=*" %%K in ('reg query "HKLM\SOFTWARE\Autodesk\AutoCAD\%%V" 2^>nul ^| findstr /i "ACAD-"') do (
        reg delete "%%K\AdLM" /f >nul 2>&1
    )
)
exit /b 0

:CheckAdLM
rem verifikasi: tidak boleh ada subkey AdLM tersisa
for %%V in (R22.0 R23.0 R23.1 R24.0 R24.1 R24.2 R24.3 R25.0) do (
    reg query "HKCU\SOFTWARE\Autodesk\AutoCAD\%%V" 2>nul ^| findstr /i "AdLM" >nul
    if not errorlevel 1 set R4=GAGAL
    reg query "HKLM\SOFTWARE\Autodesk\AutoCAD\%%V" 2>nul ^| findstr /i "AdLM" >nul
    if not errorlevel 1 set R4=GAGAL
)
exit /b 0
:CheckAcadRule
set ACADOK=0
netsh advfirewall firewall show rule name="Blokir AutoCAD2018 - acad.exe" >nul 2>&1
if not errorlevel 1 set ACADOK=1
netsh advfirewall firewall show rule name="Blokir AutoCAD2025 - acad.exe" >nul 2>&1
if not errorlevel 1 set ACADOK=1
if "%ACADOK%"=="0" set R5=GAGAL
exit /b 0
:Notice
rem %1=nomor  %2=nama  %3=BERHASIL/GAGAL
echo.
if "%~3"=="BERHASIL" (
    echo  +------------------------------------------+
    echo   [%~1] %~2 : BERHASIL
    echo  +------------------------------------------+
) else (
    echo  +------------------------------------------+
    echo   [%~1] %~2 : GAGAL !! periksa pesan di atas
    echo  +------------------------------------------+
)
echo   Tekan tombol untuk lanjut...
pause >nul
exit /b 0
