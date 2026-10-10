@echo off
rem ============================================================
rem  AUTOCAD-TOOLKIT.BAT
rem  Semua urusan AutoCAD 2025 dalam 1 file, 1 perintah:
rem   [1] Blokir internet total (firewall + service + hosts)
rem   [2] Verifikasi blokir (pastikan benar-benar terblokir)
rem   [3] Bersihkan data lisensi (program tetap, aktivasi ulang)
rem   [4] Bersih TOTAL ala Autodesk (lanjut install ulang CAD)
rem   [5] Whitelist Windows Defender
rem   [6] Monitor koneksi live acad.exe
rem   [7] Perbaiki hosts file saja
rem   [8] Scan semua EXE bawaan paket (cek yg perlu diblokir)
rem ============================================================
rem  Dibuat oleh GTG COMPUTER

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "VER=11"
set "VERURL=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad-2025/VERSION"
set "BATURL=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad-2025/autocad-toolkit.bat"
call :CheckUpdate

:MENU
cls
echo.
echo  ===============================================
echo   AUTOCAD 2025 TOOLKIT v%VER%
echo   oleh GTG COMPUTER - WA 085738127969
echo  ===============================================
echo.
echo   [1] Blokir internet total
echo       - firewall+service+hosts. JALANKAN INI DULUAN.
echo   [2] Verifikasi blokir
echo       - cek firewall, hosts, service. Target: 19/19 lolos.
echo   [3] Bersihkan data lisensi
echo       - hapus file lisensi/aktivasi. Perlu aktivasi ulang!
echo   [4] Bersih TOTAL ala Autodesk
echo       - hapus SEMUA file+registry Autodesk. HANYA sblm install ulang!
echo   [5] Whitelist Windows Defender
echo       - kecualikan AutoCAD dr scan Defender biar enteng.
echo   [6] Monitor koneksi live SEMUA proses Autodesk
echo       - dashboard statis tiap 5 dtk: 0 koneksi = terblokir total.
echo       - bukti final: 0 koneksi saat CAD dipakai = terblokir total.
echo   [7] Perbaiki hosts file saja
echo       - tulis ulang 9 domain Autodesk (tanpa ubah firewall).
echo   [8] Scan semua EXE bawaan paket
echo       - daftar semua .exe + status blokir firewall-nya.
echo   [9] Nonaktifkan blokir AutoCAD 2025
echo       - hapus rule firewall + hosts. Konfirmasi YA.
echo   [10] FULL RESET sekaligus (kill+bersih+blokir)
echo       - 1x jalan: bersih flag Genuine Service + blokir total.
echo   [11] Pasang watchdog monitoring
echo       - cek tiap 1 mnt: koneksi lolos dibunuh + notifikasi.
echo   [12] Cek status lisensi aktif
echo       - lihat data aktivasi AutoCAD yg terpasang.
echo   [0] Keluar
echo.
set /p PILIH="  Pilih [0-12]: "
if "%PILIH%"=="1" ( call :DoBlock & goto MENU )
if "%PILIH%"=="2" ( call :DoVerify & goto MENU )
if "%PILIH%"=="3" ( call :DoCleanLicense & goto MENU )
if "%PILIH%"=="4" ( call :DoFullWipe & goto MENU )
if "%PILIH%"=="5" ( call :DoWhitelist & goto MENU )
if "%PILIH%"=="6" goto DOMONITOR
if "%PILIH%"=="7" ( call :DoHostsOnly & goto MENU )
if "%PILIH%"=="8" ( call :DoScan & goto MENU )
if "%PILIH%"=="9" ( call :DoUnblock & goto MENU )
if "%PILIH%"=="10" ( call :DoFullReset & goto MENU )
if "%PILIH%"=="11" ( call :DoWatchdogInstall & goto MENU )
if "%PILIH%"=="12" ( call :DoLicenseCheck & goto MENU )
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
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%BATURL%' -OutFile '%TEMP%\actkit25-new.bat' -UseBasicParsing -TimeoutSec 60; 'UPDOK' } catch { 'UPDFAIL' }" > "%TEMP%\upd25.txt" 2>nul
findstr /i "UPDOK" "%TEMP%\upd25.txt" >nul 2>&1
del "%TEMP%\upd25.txt" 2>nul
if errorlevel 1 (
    echo  Gagal mengunduh update. Lanjut dengan v%VER%.
    exit /b 0
)
echo  Menjalankan v%NEWVER%...
start "" "%TEMP%\actkit25-new.bat"
exit

:: ================== [1] BLOKIR ==================
:DoBlock
echo.
echo  --- [1] BLOKIR INTERNET TOTAL ---
echo  [a] Firewall (block outbound)...
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\acad.exe" "Blokir AutoCAD2025 - acad.exe"
call :BlockProg "C:\Program Files (x86)\Autodesk\AutoCAD 2025\acad.exe" "Blokir AutoCAD2025 - acad.exe x86"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\AdSSO\AdSSO.exe" "Blokir AutoCAD2025 - AdSSO"
call :BlockProg "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\AdskLicensingService\AdskLicensingService.exe" "Blokir AutoCAD2025 - LicensingService"
call :BlockProg "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AutodeskDesktopApp.exe" "Blokir AutoCAD2025 - DesktopApp"
call :BlockProg "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AdAppMgrSvc.exe" "Blokir AutoCAD2025 - AdAppMgrSvc"
call :BlockProg "C:\Program Files\Autodesk\Autodesk Sync\AdSync.exe" "Blokir AutoCAD2025 - AdSync"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\AcWebBrowser.exe" "Blokir AutoCAD2025 - AcWebBrowser"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\AcCefSubprocess.exe" "Blokir AutoCAD2025 - AcCefSubprocess"
call :BlockProg "C:\Program Files\Autodesk\AutoCAD 2025\senddmp.exe" "Blokir AutoCAD2025 - senddmp"
call :BlockProg "C:\Program Files\Autodesk\Autodesk Genuine Service\GenuineService.exe" "Blokir AutoCAD2025 - GenuineService"
echo.
set /p CUSTOM="  Path acad.exe lain (kosongkan bila tidak ada): "
if defined CUSTOM call :BlockProg "%CUSTOM%" "Blokir AutoCAD2025 - custom"
echo  [b] Service Autodesk -^> disabled...
call :DisSvc "AdskLicensingService"
call :DisSvc "Autodesk Desktop App Service"
call :DisSvc "FlexNet Licensing Service"
call :DisSvc "AdskGenuineService"
echo  [c] Hosts file...
call :WriteHosts
echo.
echo  SELESAI. Disarankan lanjut opsi [2] Verifikasi.
schtasks /change /tn "AutoCAD Watchdog GTG" /enable >nul 2>&1
if not errorlevel 1 echo  + Watchdog monitoring: AKTIF.
pause
exit /b 0

:: ================== [2] VERIFIKASI ==================
:DoVerify
set V_PASS=0
set V_FAIL=0
echo.
echo  --- [2] VERIFIKASI BLOKIR ---
echo  [a] Firewall rules...
call :VRule "Blokir AutoCAD2025 - acad.exe" "C:\Program Files\Autodesk\AutoCAD 2025\acad.exe"
call :VRule "Blokir AutoCAD2025 - acad.exe x86" "C:\Program Files (x86)\Autodesk\AutoCAD 2025\acad.exe"
call :VRule "Blokir AutoCAD2025 - AdSSO" "C:\Program Files\Autodesk\AutoCAD 2025\AdSSO\AdSSO.exe"
call :VRule "Blokir AutoCAD2025 - LicensingService" "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\Current\AdskLicensingService\AdskLicensingService.exe"
call :VRule "Blokir AutoCAD2025 - DesktopApp" "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AutodeskDesktopApp.exe"
call :VRule "Blokir AutoCAD2025 - AdAppMgrSvc" "C:\Program Files (x86)\Autodesk\Autodesk Desktop App\AdAppMgrSvc.exe"
call :VRule "Blokir AutoCAD2025 - AdSync" "C:\Program Files\Autodesk\Autodesk Sync\AdSync.exe"
call :VRule "Blokir AutoCAD2025 - AcWebBrowser" "C:\Program Files\Autodesk\AutoCAD 2025\AcWebBrowser.exe"
call :VRule "Blokir AutoCAD2025 - AcCefSubprocess" "C:\Program Files\Autodesk\AutoCAD 2025\AcCefSubprocess.exe"
call :VRule "Blokir AutoCAD2025 - senddmp" "C:\Program Files\Autodesk\AutoCAD 2025\senddmp.exe"
call :VRule "Blokir AutoCAD2025 - GenuineService" "C:\Program Files\Autodesk\Autodesk Genuine Service\GenuineService.exe"
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
call :VSvc "AdskGenuineService"
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
call :Confirm "Menghapus SEMUA data lisensi/aktivasi AutoCAD." "Setelah ini AutoCAD WAJIB aktivasi ulang dari awal."
if errorlevel 1 (
    pause
    exit /b 0
)
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
call :Confirm "SEMUA folder + registry Autodesk akan dihapus!" "Lakukan HANYA bila mau install ulang AutoCAD dari installer."
if errorlevel 1 (
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
echo  SELESAI. Restart PC lalu install ulang AutoCAD 2025.
echo  SEBELUM aktivasi: jalankan opsi [1] Blokir.
pause
exit /b 0

:: ================== [5] WHITELIST DEFENDER ==================
:DoWhitelist
echo.
echo  --- [5] WHITELIST WINDOWS DEFENDER ---
set "ACADDIR=C:\Program Files\Autodesk\AutoCAD 2025"
if not exist "%ACADDIR%\acad.exe" (
    echo  acad.exe tidak ketemu di lokasi default.
    set /p ACADDIR="  Masukkan path folder AutoCAD 2025: "
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
set "MONLOG=%TEMP%\actkit25-monitor.log"
set "NETTMP=%TEMP%\actkit25-net.txt"
set "TLTMP=%TEMP%\actkit25-task.txt"
set "WATCH=%TEMP%\actkit25-watch.txt"
echo [%date% %time%] Monitor v%VER% dimulai > "%MONLOG%"
echo.
echo  ===============================================
echo   MONITOR KONEKSI LIVE - Semua Proses Autodesk
echo   oleh GTG COMPUTER - WA 085738127969
echo  ===============================================
echo  Membangun daftar proses yang dipantau...
set "SCANDIR=C:\Program Files\Autodesk\AutoCAD 2025"
type nul > "%WATCH%"
if exist "%SCANDIR%\acad.exe" (
    for /r "%SCANDIR%" %%F in (*.exe) do (
        findstr /i /x /c:"%%~nxF" "%WATCH%" >nul 2>&1
        if errorlevel 1 echo %%~nxF>>"%WATCH%"
    )
)
for %%E in (AdskLicensingService.exe AutodeskDesktopApp.exe AdSSO.exe) do (
    findstr /i /x /c:"%%E" "%WATCH%" >nul 2>&1
    if errorlevel 1 echo %%E>>"%WATCH%"
)
set "WN=0"
for /f "usebackq delims=" %%L in ("%WATCH%") do set /a WN+=1
echo  Memantau %WN% proses Autodesk.
echo  Biarkan window ini terbuka, LALU buka AutoCAD dan pakai biasa.
echo  Dashboard me-refresh tiap 5 detik (tampilan statis, tidak hilang).
echo  Tutup window ini untuk berhenti. Log: %MONLOG%
echo.
echo  Tekan tombol apa saja untuk mulai...
pause >nul
:MONLOOP
netstat -ano > "%NETTMP%" 2>nul
tasklist /fo table /nh > "%TLTMP%" 2>nul
cls
echo  ===============================================
echo   MONITOR LIVE - %WN% proses Autodesk - %time%
echo  ===============================================
echo.
echo   PROSES                   STATUS       KONEKSI
echo   ------------------------------------------------------
set "ALERT=0"
for /f "usebackq delims=" %%E in ("%WATCH%") do call :CheckOne "%%E"
echo   ------------------------------------------------------
echo   Refresh tiap 5 detik. Tutup window untuk berhenti.
if "%ALERT%"=="1" (
    echo.
    echo   *** ADA KONEKSI TERDETEKSI! Lihat detail di atas. ***
)
echo [%time%] loop, alert=%ALERT% >> "%MONLOG%"
timeout /t 5 /nobreak >nul
goto MONLOOP

:CheckOne
set "PN=%~1"
set "RXP=%PN:.=\.%"
set "FOUND=0"
set "CONN=0"
for /f "tokens=1,2" %%A in ('findstr /i /r /c:"^ *%RXP% " "%TLTMP%" 2^>nul') do (
    set "FOUND=1"
    set "PID=%%B"
    call :AddConn
)
if "%FOUND%"=="0" (
    call :PadRow "%PN%" "TIDAK JALAN" "-"
) else if "%CONN%"=="0" (
    call :PadRow "%PN%" "JALAN" "AMAN (0)"
) else (
    call :PadRow "%PN%" "JALAN" "ADA %CONN% KONEKSI!"
    set "ALERT=1"
    call :ShowDetail "%PN%"
)
exit /b 0

:AddConn
for /f %%C in ('findstr " %PID% " "%NETTMP%" 2^>nul ^| findstr /v /i "LISTENING" ^| find /c /v ""') do set /a CONN+=%%C
exit /b 0

:ShowDetail
set "RXP2=%~1"
set "RXP2=%RXP2:.=\.%"
for /f "tokens=1,2" %%A in ('findstr /i /r /c:"^ *%RXP2% " "%TLTMP%" 2^>nul') do (
    findstr " %%B " "%NETTMP%" 2>nul | findstr /v /i "LISTENING"
)
exit /b 0

:PadRow
set "PA=%~1                        "
set "PB=%~2             "
echo   %PA:~0,24% %PB:~0,12% %~3
exit /b 0

:: ================== [10] FULL RESET ==================
:DoFullReset
echo.
echo  --- [10] FULL RESET SEKALIGUS ---
echo  kill koneksi + bersih flag Genuine Service + blokir total.
echo  Setelah ini: restart PC, baru aktivasi ulang.
echo.
set "FRURL=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/autocad-full-reset.bat"
set "FRBAT=%TEMP%\autocad-full-reset.bat"
echo  Mengunduh script full-reset...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%FRURL%' -OutFile '%FRBAT%' -UseBasicParsing -TimeoutSec 60; 'FRDOK' } catch { 'FRDFAIL' }" > "%TEMP%\frd.txt" 2>nul
findstr /i "FRDOK" "%TEMP%\frd.txt" >nul 2>&1
del "%TEMP%\frd.txt" 2>nul
if errorlevel 1 (
    echo  GAGAL mengunduh. Cek koneksi internet lalu coba lagi.
    pause
    exit /b 1
)
echo  Menjalankan full-reset...
call "%FRBAT%"
del "%FRBAT%" 2>nul
exit /b 0
:: ================== [11] PASANG WATCHDOG ==================
:DoWatchdogInstall
echo.
echo  --- [11] PASANG WATCHDOG MONITORING ---
echo  Download installer, lalu dibuka otomatis sebagai user biasa.
echo.
set "WDURL=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/autocad/pasang-watchdog-autocad.bat"
set "WDBAT=%TEMP%\pasang-watchdog-autocad.bat"
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%WDURL%' -OutFile '%WDBAT%' -UseBasicParsing -TimeoutSec 60; 'WDOK' } catch { 'WDFAIL' }" > "%TEMP%\wd.txt" 2>nul
findstr /i "WDOK" "%TEMP%\wd.txt" >nul 2>&1
del "%TEMP%\wd.txt" 2>nul
if errorlevel 1 (
    echo  GAGAL mengunduh. Cek koneksi internet.
    pause
    exit /b 1
)
echo  Menjalankan installer (ikuti jendela yang terbuka)...
call "%WDBAT%"
exit /b 0

:: ================== [12] CEK LISENSI ==================
:DoLicenseCheck
echo.
echo  --- [12] CEK STATUS LISENSI AKTIF ---
echo.
set LCFOUND=0
for %%V in (R22.0 R23.0 R23.1 R24.0 R24.1 R24.2 R24.3 R25.0) do (
    for /f "tokens=*" %%K in ('reg query "HKCU\SOFTWARE\Autodesk\AutoCAD\%%V" 2^>nul ^| findstr /i "ACAD-"') do (
        set LCFOUND=1
        echo  [*] %%K
        reg query "%%K\AdLM" >nul 2>&1
        if not errorlevel 1 (
            echo      AdLM: ADA - ada data aktivasi tersimpan
        ) else (
            echo      AdLM: TIDAK ADA - belum aktivasi / sudah di-wipe
        )
    )
)
if "%LCFOUND%"=="0" echo  Tidak ada instalasi AutoCAD terdeteksi di registry.
echo.
echo  [FLEXnet trusted storage]
dir /b "C:\ProgramData\FLEXnet\adskflex_*" 2>nul
if errorlevel 1 echo      - kosong (tidak ada data lisensi)
echo.
echo  [Genuine Service]
sc query AdskGenuineService >nul 2>&1
if errorlevel 1 (
    echo      Service: tidak terinstall
) else (
    sc qc AdskGenuineService 2>nul ^| findstr /i "DISABLED" >nul
    if not errorlevel 1 (
        echo      Service: DISABLED (aman)
    ) else (
        echo      Service: TIDAK DISABLED (warning!)
    )
)
if exist "C:\ProgramData\Autodesk\Autodesk Genuine Service" (
    echo      Flag: ADA - berisiko error 'no longer have access'
) else (
    echo      Flag: bersih
)
echo.
pause
exit /b 0
:DoUnblock
echo.
echo  --- [9] NONAKTIFKAN BLOKIR AUTOCAD 2025 ---
call :Confirm "Menghapus rule firewall Blokir AutoCAD2025 + entri hosts Autodesk." "AutoCAD 2025 bisa akses internet lagi setelah ini."
if errorlevel 1 (
    pause
    exit /b 0
)
schtasks /change /tn "AutoCAD Watchdog GTG" /disable >nul 2>&1
if not errorlevel 1 echo  ! Watchdog monitoring: NONAKTIF sementara.
echo  [a] Hapus rule firewall...powershell -NoProfile -Command "Get-NetFirewallRule -DisplayName 'Blokir AutoCAD2025*' -ErrorAction SilentlyContinue | Remove-NetFirewallRule" >nul 2>&1
set "RN=?"
for /f %%N in ('powershell -NoProfile -Command "(Get-NetFirewallRule -DisplayName 'Blokir AutoCAD2025*' -ErrorAction SilentlyContinue | Measure-Object).Count" 2^>nul') do set "RN=%%N"
echo      + sisa rule blokir: %RN%
echo  [b] Bersihkan entri Autodesk dari hosts...
set "HF=%SystemRoot%\System32\drivers\etc\hosts"
for %%H in (
    genuine-software.autodesk.com genuine-software1.autodesk.com
    cur.autodesk.com accounts.autodesk.com api.autodesk.com
    metapi.autodesk.com edge.api.autodesk.com
    ipservice.api.autodesk.com cm-sso-prod.arkoselabs.com
) do (
    findstr /v /i /c:"%%H" "%HF%" > "%HF%.tmp" 2>nul
    move /y "%HF%.tmp" "%HF%" >nul 2>&1
)
ipconfig /flushdns >nul 2>&1
echo      + hosts dibersihkan
echo  [c] Service Autodesk kembali ke Manual...
for %%S in ("AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service" "AdskGenuineService") do (
    sc query %%~S >nul 2>&1
    if not errorlevel 1 sc config %%~S start= demand >nul 2>&1
)
echo.
echo  SELESAI. Blokir AutoCAD 2025 dinonaktifkan.
pause
exit /b 0

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
set "SCANDIR=C:\Program Files\Autodesk\AutoCAD 2025"
if not exist "%SCANDIR%\acad.exe" (
    set /p SCANDIR="  Masukkan path folder AutoCAD 2025: "
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
    for /f "delims=" %%L in (%SCANFILE%) do call :BlockProg "%%L" "Blokir AutoCAD2025 - %%~nxL"
    echo  Selesai diblokir.
)
del "%SCANFILE%" 2>nul
pause
exit /b 0

:ScanExe
netsh advfirewall firewall show rule name="Blokir AutoCAD2025 - %~nx1" 2>nul | findstr /i /c:"Enabled:" | findstr /i "Yes" >nul
if not errorlevel 1 (
    echo      [TERBLOKIR] %~nx1
    exit /b 0
)
netsh advfirewall firewall show rule name="Blokir AutoCAD2025 - %~n1" 2>nul | findstr /i /c:"Enabled:" | findstr /i "Yes" >nul
if not errorlevel 1 (
    echo      [TERBLOKIR] %~nx1 (rule nama lama)
    exit /b 0
)
echo      [BELUM]     %~nx1
(echo %~1)>>"%SCANFILE%"
exit /b 0

:KillAuto
echo  [a] Menutup proses + service Autodesk...
for %%P in (acad.exe AdSSO.exe AutodeskDesktopApp.exe AdskLicensingService.exe AdskLicensingAgent.exe lmgrd.exe GenuineService.exe AcWebBrowser.exe AcCefSubprocess.exe AdAppMgrSvc.exe AdSync.exe) do (
    taskkill /f /im %%P >nul 2>&1
)
for %%S in ("AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service" "AdskGenuineService") do (
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
if exist "C:\ProgramData\Autodesk\Autodesk Genuine Service" (
    rmdir /s /q "C:\ProgramData\Autodesk\Autodesk Genuine Service"
    echo      + data Autodesk Genuine Service dihapus
) else (
    echo      - data Genuine Service tidak ada, dilewati
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
:: Konfirmasi ganda untuk tindakan destruktif.
:: %1 = apa yang akan dilakukan, %2 = dampaknya.
:: return 0 = lanjut, 1 = batal.
:Confirm
echo.
echo  +++++ PERINGATAN +++++
echo  %~1
echo  %~2
echo.
set "CF="
set /p "CF=Ketik YA (huruf besar) untuk lanjut, Enter untuk batal: "
if /i "%CF%"=="YA" exit /b 0
echo  Dibatalkan - tidak ada yang diubah.
exit /b 1
