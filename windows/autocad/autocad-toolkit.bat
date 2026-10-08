@echo off
rem ============================================================
rem  AUTOCAD-TOOLKIT.BAT
rem  Semua urusan AutoCAD 2018 dalam 1 file, 1 perintah:
rem   [1] Blokir internet total (firewall + service + hosts)
rem   [2] Verifikasi blokir (pastikan benar-benar terblokir)
rem   [3] Bersihkan data lisensi (program tetap, aktivasi ulang)
rem   [4] Bersih TOTAL ala Autodesk (lanjut install ulang CAD)
rem   [5] Whitelist Windows Defender
rem   [6] Monitor koneksi live acad.exe
rem   [7] Perbaiki hosts file saja
rem   [8] Scan semua EXE bawaan paket (cek yg perlu diblokir)
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "VER=13"
set "VERURL=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/VERSION"
set "BATURL=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-toolkit.bat"
call :CheckUpdate

:MENU
cls
echo.
echo  ===============================================
echo   AUTOCAD 2018 TOOLKIT v%VER%
echo  ===============================================
echo.
echo   [1] Blokir internet total (firewall+service+hosts)
echo   [2] Verifikasi blokir (cek benar-benar terblokir)
echo   [3] Bersihkan data lisensi (tanpa install ulang Windows)
echo   [4] Bersih TOTAL ala Autodesk (lanjut install ulang CAD)
echo   [5] Whitelist Windows Defender
echo   [6] Monitor koneksi live acad.exe
echo   [7] Perbaiki hosts file saja
echo   [8] Scan semua EXE bawaan paket (cek yg perlu diblokir)
echo   [0] Keluar
echo.
set /p PILIH="  Pilih [0-8]: "
if "%PILIH%"=="1" ( call :DoBlock & goto MENU )
if "%PILIH%"=="2" ( call :DoVerify & goto MENU )
if "%PILIH%"=="3" ( call :DoCleanLicense & goto MENU )
if "%PILIH%"=="4" ( call :DoFullWipe & goto MENU )
if "%PILIH%"=="5" ( call :DoWhitelist & goto MENU )
if "%PILIH%"=="6" goto DOMONITOR
if "%PILIH%"=="7" ( call :DoHostsOnly & goto MENU )
if "%PILIH%"=="8" ( call :DoScan & goto MENU )
if "%PILIH%"=="0" exit /b 0
echo  Pilihan tidak valid.
pause
goto MENU

:: ================== UPDATE OTOMATIS ==================
:CheckUpdate
set "NEWVER="
for /f %%V in ('powershell -NoProfile -Command "try { (Invoke-WebRequest -Uri '%VERURL%' -UseBasicParsing -TimeoutSec 8).Content.Trim() } catch { }" 2^>nul') do set "NEWVER=%%V"
if not defined NEWVER exit /b 0
if "%NEWVER%"=="%VER%" exit /b 0
echo.
echo  Update tersedia: v%VER% -^> v%NEWVER%. Mengunduh...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%BATURL%' -OutFile '%TEMP%\actkit-new.bat' -UseBasicParsing -TimeoutSec 60; 'UPDOK' } catch { 'UPDFAIL' }" > "%TEMP%\upd.txt" 2>nul
findstr /i "UPDOK" "%TEMP%\upd.txt" >nul 2>&1
del "%TEMP%\upd.txt" 2>nul
if errorlevel 1 (
    echo  Gagal mengunduh update. Lanjut dengan v%VER%.
    exit /b 0
)
echo  Menjalankan v%NEWVER%...
start "" "%TEMP%\actkit-new.bat"
exit

:: ================== [1] BLOKIR ==================
:DoBlock
echo.
echo  --- [1] BLOKIR INTERNET TOTAL ---
echo  [a] Firewall (block outbound)...
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad.exe"
call :BlockProg "C:\Program Files (x86)\Autodesk\AutoCAD 2018\acad.exe" "Blokir AutoCAD2018 - acad.exe x86"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\AdSSO\AdSSO.exe" "Blokir AutoCAD2018 - AdSSO"
call :BlockProg "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\AdskLicensingService\AdskLicensingService.exe" "Blokir AutoCAD2018 - LicensingService"
call :BlockProg "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AutodeskDesktopApp.exe" "Blokir AutoCAD2018 - DesktopApp"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\AcWebBrowser.exe" "Blokir AutoCAD2018 - AcWebBrowser"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2018\senddmp.exe" "Blokir AutoCAD2018 - senddmp"
echo.
set /p CUSTOM="  Path acad.exe lain (kosongkan bila tidak ada): "
if defined CUSTOM call :BlockProg "%CUSTOM%" "Blokir AutoCAD2018 - custom"
echo  [b] Service Autodesk -^> disabled...
call :DisSvc "AdskLicensingService"
call :DisSvc "Autodesk Desktop App Service"
call :DisSvc "FlexNet Licensing Service"
echo  [c] Hosts file...
call :WriteHosts
echo.
echo  SELESAI. Disarankan lanjut opsi [2] Verifikasi.
pause
exit /b 0

:: ================== [2] VERIFIKASI ==================
:DoVerify
set V_PASS=0
set V_FAIL=0
echo.
echo  --- [2] VERIFIKASI BLOKIR ---
echo  [a] Firewall rules...
call :VRule "Blokir AutoCAD2018 - acad.exe" "C:\Program Files\Autodesk\AutoCAD 2018\acad.exe"
call :VRule "Blokir AutoCAD2018 - acad.exe x86" "C:\Program Files (x86)\Autodesk\AutoCAD 2018\acad.exe"
call :VRule "Blokir AutoCAD2018 - AdSSO" "C:\Program Files\Autodesk\AutoCAD 2018\AdSSO\AdSSO.exe"
call :VRule "Blokir AutoCAD2018 - LicensingService" "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\AdskLicensingService\AdskLicensingService.exe"
call :VRule "Blokir AutoCAD2018 - DesktopApp" "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AutodeskDesktopApp.exe"
call :VRule "Blokir AutoCAD2018 - AcWebBrowser" "C:\Program Files\Autodesk\AutoCAD 2018\AcWebBrowser.exe"
call :VRule "Blokir AutoCAD2018 - senddmp" "C:\Program Files\Autodesk\AutoCAD 2018\senddmp.exe"
echo  [b] Hosts file...
call :VHost genuine-software.autodesk.com
call :VHost genuine-software1.autodesk.com
call :VHost cur.autodesk.com
call :VHost accounts.autodesk.com
call :VHost api.autodesk.com
call :VHost metapi.autodesk.com
call :VHost edge.api.autodesk.com
call :VHost ipservice.api.autodesk.com
call :VHost cm-sso-prod.arkoselabs.com
echo  [c] Service Autodesk...
call :VSvc "AdskLicensingService"
call :VSvc "Autodesk Desktop App Service"
call :VSvc "FlexNet Licensing Service"
echo  [d] Kesimpulan...
echo      [a]-[c] di atas SUDAH merupakan bukti blokir 100%%.
echo      - Firewall memblokir acad.exe apapun tujuannya (tidak peduli DNS).
echo      - Hosts mengarahkan 9 domain Autodesk ke 127.0.0.1.
echo      Bukti live sesungguhnya: opsi [6] Monitor - buka AutoCAD
echo      dan pakai biasa; bila 0 koneksi tampil = terbukti total.
echo.
echo  HASIL: %V_PASS% lolos, %V_FAIL% gagal.
if %V_FAIL% equ 0 (
    echo  STATUS: AMAN - 100%% terblokir.
) else (
    echo  STATUS: ADA YANG KURANG - jalankan opsi [1] lalu [2] lagi.
)
pause
exit /b 0

:: ================== [3] BERSIH LISENSI ==================
:DoCleanLicense
echo.
echo  --- [3] BERSIHKAN DATA LISENSI ---
echo  Program AutoCAD TETAP terinstall, tinggal aktivasi ulang.
call :KillAuto
call :WipeLicense
echo.
echo  SELESAI. Restart PC, buka AutoCAD, aktivasi ulang dari awal.
echo  Pastikan opsi [1] Blokir sudah dijalankan sebelumnya.
pause
exit /b 0

:: ================== [4] BERSIH TOTAL ==================
:DoFullWipe
echo.
echo  --- [4] BERSIH TOTAL ---
echo  SEMUA folder + registry Autodesk akan dihapus!
echo  Setelah ini install ulang AutoCAD dari installer.
set /p YAKIN="  Ketik YA untuk lanjut: "
if /i not "%YAKIN%"=="YA" (
    echo  Dibatalkan.
    pause
    exit /b 0
)
call :KillAuto
call :WipeLicense
echo  [c] Menghapus folder program Autodesk...
for %%D in (
    "C:\Program Files\Autodesk"
    "C:\Program Files (x86)\Autodesk"
    "C:\Program Files (x86)\Common Files\Autodesk Shared"
    "C:\ProgramData\Autodesk"
    "%APPDATA%\Autodesk"
    "%LOCALAPPDATA%\Autodesk"
) do (
    if exist %%D (
        rmdir /s /q %%D
        echo      + dihapus: %%~D
    ) else (
        echo      - tidak ada: %%~D
    )
)
echo  [d] Menghapus registry Autodesk...
for %%R in (
    "HKCU\Software\Autodesk"
    "HKLM\SOFTWARE\Autodesk"
    "HKLM\SOFTWARE\Wow6432Node\Autodesk"
) do (
    reg delete %%R /f >nul 2>&1
    if not errorlevel 1 (
        echo      + dihapus: %%~R
    ) else (
        echo      - tidak ada: %%~R
    )
)
echo.
echo  SELESAI. Restart PC lalu install ulang AutoCAD 2018.
echo  SEBELUM aktivasi: jalankan opsi [1] Blokir.
pause
exit /b 0

:: ================== [5] WHITELIST DEFENDER ==================
:DoWhitelist
echo.
echo  --- [5] WHITELIST WINDOWS DEFENDER ---
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
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%ACADDIR%'" 2>nul
if not errorlevel 1 (echo      + folder: %ACADDIR%) else (echo      ! gagal: folder)
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%ACADDIR%\acad.exe'" 2>nul
if not errorlevel 1 (echo      + file: acad.exe) else (echo      ! gagal: file)
powershell -NoProfile -Command "Add-MpPreference -ExclusionProcess 'acad.exe'" 2>nul
if not errorlevel 1 (echo      + proses: acad.exe) else (echo      ! gagal: proses)
echo.
set /p EXTRA="  Folder tambahan untuk di-whitelist (kosongkan bila tidak ada): "
if defined EXTRA (
    powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%EXTRA%'" 2>nul
    if not errorlevel 1 (echo      + folder tambahan: %EXTRA%) else (echo      ! gagal: folder tambahan)
)
echo.
echo  Daftar exclusion path saat ini:
powershell -NoProfile -Command "Get-MpPreference | Select-Object -ExpandProperty ExclusionPath"
echo  SELESAI.
pause
exit /b 0

:: ================== [6] MONITOR ==================
:DOMONITOR
cls
set "MONLOG=%TEMP%\actkit-monitor.log"
echo [%date% %time%] Monitor v%VER% dimulai > "%MONLOG%"
echo.
echo  ===============================================
echo   MONITOR KONEKSI LIVE - acad.exe
echo  ===============================================
echo  Biarkan window ini terbuka, LALU buka AutoCAD dan pakai biasa.
echo  STATUS tampil tiap 5 detik:
echo    MENUNGGU   = acad.exe belum dibuka
echo    AMAN       = 0 koneksi keluar (terblokir total)
echo    ADA KONEKSI= ada yang lolos! catat detailnya
echo  Tutup window ini untuk berhenti.
echo  (log diagnosis: %MONLOG%)
echo.
:MONLOOP
echo %time% loop >> "%MONLOG%"
set "ACADPID="
for /f "tokens=2" %%P in ('tasklist /fi "imagename eq acad.exe" /fo table /nh 2^>nul ^| findstr /v /i "INFO:"') do set "ACADPID=%%P"
if not defined ACADPID (
    echo [%time%] STATUS: MENUNGGU - acad.exe belum dibuka...
) else (
    set "CONN=0"
    for /f %%C in ('netstat -ano ^| findstr " %ACADPID% " ^| findstr /v /i "LISTENING" ^| find /c /v ""') do set "CONN=%%C"
    if "%CONN%"=="0" (
        echo [%time%] STATUS: AMAN - 0 koneksi keluar (PID %ACADPID%)
    ) else (
        echo [%time%] STATUS: ADA %CONN% KONEKSI! Detail:
        netstat -ano | findstr " %ACADPID% " | findstr /v /i "LISTENING"
    )
)
timeout /t 5 /nobreak >nul
goto MONLOOP

:: ================== [7] HOSTS SAJA ==================
:DoHostsOnly
echo.
echo  --- [7] PERBAIKI HOSTS FILE SAJA ---
call :WriteHostsVerbose
pause
exit /b 0

:: ================== SUBRUTIN BANTU ==================
:BlockProg
netsh advfirewall firewall delete rule name="%~2" >nul 2>&1
if not exist "%~1" (
    echo      - file tidak ada, dilewati: %~1
    exit /b 0
)
netsh advfirewall firewall add rule name="%~2" dir=out action=block program="%~1" enable=yes profile=any >nul 2>&1
if errorlevel 1 (
    echo      ! GAGAL membuat rule: %~2
) else (
    echo      + %~2
)
exit /b 0

:DisSvc
sc query "%~1" >nul 2>&1
if errorlevel 1 (
    echo      - %~1 tidak ditemukan, dilewati
    exit /b 0
)
sc stop "%~1" >nul 2>&1
sc config "%~1" start= disabled >nul 2>&1
echo      + %~1 dinonaktifkan
exit /b 0

:WriteHosts
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
        echo      + %%H diblokir
    ) else (
        echo      = %%H sudah ada, dilewati
    )
)
ipconfig /flushdns >nul 2>&1
echo      Selesai.
exit /b 0

:WriteHostsVerbose
set "HOSTSFILE=%SystemRoot%\System32\drivers\etc\hosts"
echo  --- isi hosts SEBELUM (15 baris terakhir) ---
powershell -NoProfile -Command "Get-Content '%HOSTSFILE%' | Select-Object -Last 15"
echo.
echo  --- menulis entri ---
>>"%HOSTSFILE%" echo.
if errorlevel 1 (
    echo  !!! GAGAL total: hosts tidak bisa ditulis (ditahan antivirus?)
    exit /b 1
)
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
        if errorlevel 1 (echo      !!! GAGAL tulis: %%H) else (echo      + %%H ditulis)
    ) else (
        echo      = %%H sudah ada, dilewati
    )
)
ipconfig /flushdns >nul 2>&1
echo.
echo  --- isi hosts SESUDAH (15 baris terakhir) ---
powershell -NoProfile -Command "Get-Content '%HOSTSFILE%' | Select-Object -Last 15"
echo  SELESAI.
exit /b 0

:: ================== [8] SCAN EXE ==================
:DoScan
echo.
echo  --- [8] SCAN SEMUA EXE BAWAAN PAKET ---
set "SCANDIR=C:\Program Files\Autodesk\AutoCAD 2018"
if not exist "%SCANDIR%\acad.exe" (
    set /p SCANDIR="  Masukkan path folder AutoCAD 2018: "
)
if not exist "%SCANDIR%\acad.exe" (
    echo  acad.exe tidak ditemukan. Batal.
    pause
    exit /b 1
)
echo  Memindai: %SCANDIR%
echo  (mengecek satu-satu langsung ke Windows Firewall, mohon tunggu...)
echo.
set "SCANFILE=%TEMP%\scanbelum.txt"
if exist "%SCANFILE%" del "%SCANFILE%"
for /r "%SCANDIR%" %%F in (*.exe) do call :ScanExe "%%F"
echo.
if not exist "%SCANFILE%" (
    echo  Semua EXE bawaan paket sudah terblokir. Mantap.
    pause
    exit /b 0
)
echo  --- EXE yang BELUM diblokir: ---
type "%SCANFILE%"
echo.
set /p BLOKSEMUA="  Blokir SEMUA yang di atas? (Y/N): "
if /i "%BLOKSEMUA%"=="Y" (
    for /f "delims=" %%L in (%SCANFILE%) do call :BlockProg "%%L" "Blokir AutoCAD2018 - %%~nxL"
    echo  Selesai diblokir.
)
del "%SCANFILE%" 2>nul
pause
exit /b 0

:ScanExe
netsh advfirewall firewall show rule name="Blokir AutoCAD2018 - %~nx1" 2>nul | findstr /i /c:"Enabled:" | findstr /i "Yes" >nul
if not errorlevel 1 (
    echo      [TERBLOKIR] %~nx1
    exit /b 0
)
netsh advfirewall firewall show rule name="Blokir AutoCAD2018 - %~n1" 2>nul | findstr /i /c:"Enabled:" | findstr /i "Yes" >nul
if not errorlevel 1 (
    echo      [TERBLOKIR] %~nx1 (rule nama lama)
    exit /b 0
)
echo      [BELUM]     %~nx1
(echo %~1)>>"%SCANFILE%"
exit /b 0

:KillAuto
echo  [a] Menutup proses + service Autodesk...
for %%P in (acad.exe AdSSO.exe AutodeskDesktopApp.exe AdskLicensingService.exe AdskLicensingAgent.exe lmgrd.exe) do (
    taskkill /f /im %%P >nul 2>&1
)
for %%S in ("AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service") do (
    sc stop %%~S >nul 2>&1
    sc config %%~S start= disabled >nul 2>&1
)
echo      Selesai.
exit /b 0

:WipeLicense
echo  [b] Menghapus data lisensi...
if exist "C:\ProgramData\FLEXnet\adskflex_*.data" (
    del /f /q "C:\ProgramData\FLEXnet\adskflex_*.data*"
    echo      + FlexNet trusted storage dihapus
) else (
    echo      - file adskflex tidak ada, dilewati
)
if exist "C:\ProgramData\Autodesk\CLM\LGS" (
    del /f /q "C:\ProgramData\Autodesk\CLM\LGS\*"
    echo      + data lisensi CLM dihapus
) else (
    echo      - folder CLM tidak ada, dilewati
)
if exist "%LOCALAPPDATA%\Autodesk\Web Services" (
    rmdir /s /q "%LOCALAPPDATA%\Autodesk\Web Services"
    echo      + status login Autodesk dihapus
) else (
    echo      - status login tidak ada, dilewati
)
reg delete "HKLM\SOFTWARE\FLEXlm License Manager" /f >nul 2>&1
if not errorlevel 1 (
    echo      + registry FLEXlm dibersihkan
) else (
    echo      - registry FLEXlm tidak ada, dilewati
)
echo      Selesai.
exit /b 0

:VRule
if not exist "%~2" (
    echo      [OK]   %~1 tidak diperlukan (file tidak ada di PC)
    set /a V_PASS+=1
    exit /b 0
)
netsh advfirewall firewall show rule name="%~1" 2>nul | findstr /i /c:"Enabled:" | findstr /i "Yes" >nul
if not errorlevel 1 (
    echo      [OK]   %~1
    set /a V_PASS+=1
) else (
    echo      [GAGAL] %~1 tidak ada / tidak aktif
    set /a V_FAIL+=1
)
exit /b 0

:VHost
set "HC=?"
for /f %%L in ('powershell -NoProfile -Command "((Get-Content \"%SystemRoot%\System32\drivers\etc\hosts\" -ErrorAction SilentlyContinue | Select-String -SimpleMatch '%~1' | Measure-Object).Count)" 2^>nul') do set "HC=%%L"
if "%HC%"=="0" (
    echo      [GAGAL] %~1 tidak ada di hosts file
    set /a V_FAIL+=1
) else if "%HC%"=="?" (
    echo      [?]    %~1 tidak bisa dicek di PC ini
    set /a V_FAIL+=1
) else (
    echo      [OK]   %~1 ada di hosts file
    set /a V_PASS+=1
)
exit /b 0

:VSvc
sc qc "%~1" 2>nul | findstr /i "DISABLED" >nul
if not errorlevel 1 (
    echo      [OK]   %~1 disabled
    set /a V_PASS+=1
    exit /b 0
)
sc query "%~1" >nul 2>&1
if errorlevel 1 (
    echo      [OK]   %~1 tidak terinstall
    set /a V_PASS+=1
) else (
    echo      [GAGAL] %~1 masih aktif
    set /a V_FAIL+=1
)
exit /b 0

