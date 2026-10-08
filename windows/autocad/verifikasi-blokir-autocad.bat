@echo off
rem ============================================================
rem  VERIFIKASI-BLOKIR-AUTOCAD.BAT
rem  Memastikan blokir internet AutoCAD 2018 BENAR-BENAR jalan:
rem   [1] Cek semua firewall rule ada & aktif (block outbound)
rem   [2] Cek hosts: 9 domain Autodesk -> 127.0.0.1
rem   [3] Cek service Autodesk disabled / tidak ada
rem   [4] Tes koneksi live ke server Autodesk -> harus GAGAL
rem  Jalankan SETELAH blokir-autocad-2018.bat
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set PASS=0
set FAIL=0

echo.
echo  ===============================================
echo   VERIFIKASI BLOKIR INTERNET AUTOCAD 2018
echo  ===============================================
echo.

echo [1/4] Cek firewall rules...
call :ChkRule "Blokir AutoCAD2018 - acad.exe"
call :ChkRule "Blokir AutoCAD2018 - acad.exe x86"
call :ChkRule "Blokir AutoCAD2018 - AdSSO"
call :ChkRule "Blokir AutoCAD2018 - LicensingService"
call :ChkRule "Blokir AutoCAD2018 - DesktopApp"
call :ChkRule "Blokir AutoCAD2018 - AcWebBrowser"
call :ChkRule "Blokir AutoCAD2018 - senddmp"
echo.

echo [2/4] Cek hosts file (domain Autodesk harus ada di daftar blokir)...
call :ChkHost genuine-software.autodesk.com
call :ChkHost genuine-software1.autodesk.com
call :ChkHost cur.autodesk.com
call :ChkHost accounts.autodesk.com
call :ChkHost api.autodesk.com
call :ChkHost metapi.autodesk.com
call :ChkHost edge.api.autodesk.com
call :ChkHost ipservice.api.autodesk.com
call :ChkHost cm-sso-prod.arkoselabs.com
echo.

echo [3/4] Cek service Autodesk (harus disabled / tidak ada)...
call :ChkSvc "AdskLicensingService"
call :ChkSvc "Autodesk Desktop App Service"
call :ChkSvc "FlexNet Licensing Service"
echo.

echo [4/4] Tes koneksi live ke server Autodesk (harus GAGAL)...
call :ChkTcp genuine-software.autodesk.com
call :ChkTcp cur.autodesk.com
call :ChkTcp accounts.autodesk.com
echo.

echo  ===============================================
echo   HASIL: %PASS% lolos, %FAIL% gagal
if %FAIL% equ 0 (
    echo   STATUS: AMAN - AutoCAD 2018 bener-bener terblokir.
) else (
    echo   STATUS: ADA YANG BOCOR - jalankan ulang
    echo   blokir-autocad-2018.bat lalu verifikasi lagi.
)
echo  ===============================================
echo.
pause
exit /b 0

:: ================= Subrutin =================
:ChkRule
netsh advfirewall firewall show rule name="%~1" 2>nul | findstr /i /c:"Enabled:" | findstr /i "Yes" >nul
if not errorlevel 1 (
    echo      [OK]   %~1
    set /a PASS+=1
) else (
    echo      [GAGAL] %~1 tidak ada / tidak aktif
    set /a FAIL+=1
)
exit /b 0

:ChkHost
findstr /i /c:"%~1" "%SystemRoot%\System32\drivers\etc\hosts" >nul 2>&1
if not errorlevel 1 (
    echo      [OK]   %~1 ada di hosts file
    set /a PASS+=1
) else (
    echo      [GAGAL] %~1 tidak ada di hosts file
    set /a FAIL+=1
)
exit /b 0

:ChkSvc
sc qc "%~1" 2>nul | findstr /i "DISABLED" >nul
if not errorlevel 1 (
    echo      [OK]   %~1 disabled
    set /a PASS+=1
    exit /b 0
)
sc query "%~1" >nul 2>&1
if errorlevel 1 (
    echo      [OK]   %~1 tidak terinstall
    set /a PASS+=1
) else (
    echo      [GAGAL] %~1 masih aktif
    set /a FAIL+=1
)
exit /b 0

:ChkTcp
set "TRES=ERROR"
for /f %%R in ('powershell -NoProfile -Command "try { $r=Test-NetConnection -ComputerName '%~1' -Port 443 -WarningAction SilentlyContinue; if($r.TcpTestSucceeded){'BOCOR'}else{'OK'} } catch { 'ERROR' }" 2^>nul') do set "TRES=%%R"
if "%TRES%"=="OK" (
    echo      [OK]   %~1:443 tidak bisa dihubungi (terblokir)
    set /a PASS+=1
) else if "%TRES%"=="BOCOR" (
    echo      [GAGAL] %~1:443 MASIH BISA dihubungi!
    set /a FAIL+=1
) else (
    echo      [?]    %~1:443 tidak bisa dites (cek koneksi internet PC)
    set /a FAIL+=1
)
exit /b 0
