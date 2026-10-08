@echo off
rem ============================================================
rem  CEK-UPDATE.BAT v1
rem  Dashboard status + toggle Windows/Office Update.
rem  - Tampilkan status: TERBLOKIR atau AKTIF
rem  - Toggle per komponen: blokir lagi / aktifkan lagi
rem  - Backup memakai format yang sama dengan blokir-update.bat
rem    (folder %SystemDrive%\Backup-Blokir-Update\<timestamp>\)
rem  Dibuat oleh GTG COMPUTER
rem ============================================================
set "VER=2"
set "REPO=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/cek-update"

:: ---------- cek update otomatis ----------
if /i "%~1"=="--noupdate" goto ADM
echo  Mengecek update...
set "LATEST="
for /f %%V in ('powershell -NoProfile -Command "try { (Invoke-RestMethod '%REPO%/VERSION' -TimeoutSec 10).Trim() } catch { '' }" 2^>nul') do set "LATEST=%%V"
if not defined LATEST goto ADM
if "%LATEST%"=="%VER%" goto ADM
echo  Versi baru v%LATEST% tersedia, mengunduh...
set "TMPBAT=%TEMP%\cek-update-%LATEST%.bat"
powershell -NoProfile -Command "Invoke-RestMethod '%REPO%/cek-update.bat' -OutFile '%TMPBAT%'" >nul 2>&1
if not exist "%TMPBAT%" (
    echo  Gagal mengunduh, lanjut versi lokal.
    goto ADM
)
findstr /i /c:"CEK-UPDATE.BAT" "%TMPBAT%" >nul 2>&1
if errorlevel 1 (
    echo  File update rusak, lanjut versi lokal.
    del "%TMPBAT%" 2>nul
    goto ADM
)
echo  Update ke v%LATEST%...
start "" "%TMPBAT%" --noupdate
exit /b 0

:: ---------- minta admin ----------
:ADM
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -ArgumentList '--noupdate' -Verb RunAs"
    exit /b
)

:MENU
call :DetectState
cls
echo  ===============================================
echo   CEK UPDATE v%VER% - Status ^& Toggle
echo   oleh GTG COMPUTER
echo  ===============================================
echo.
echo   Windows Update : %WSTATE%
echo   Office Update  : %OSTATE%
echo.
if "%WSTATE%"=="TERBLOKIR" (set "WACT=AKTIFKAN lagi") else (set "WACT=BLOKIR sekarang")
if "%OSTATE%"=="TERBLOKIR" (set "OACT=AKTIFKAN lagi") else (set "OACT=BLOKIR sekarang")
if "%OSTATE%"=="TIDAK ADA" (set "OACT=(Office tidak terinstall)")
echo   [1] Windows Update -^> %WACT%
echo   [2] Office Update -^> %OACT%
echo   [3] Blokir keduanya
echo   [4] Aktifkan keduanya (restore dari backup)
echo   [0] Keluar
echo.
set "PIL="
set /p "PIL=Pilih [0-4]: "
if "%PIL%"=="1" (
    if "%WSTATE%"=="TERBLOKIR" (call :EnableWindows) else (call :InitBackup & call :BlockWindows)
    goto MENU
)
if "%PIL%"=="2" (
    if "%OSTATE%"=="TIDAK ADA" (echo  Office tidak terinstall, dilewati. & pause) else if "%OSTATE%"=="TERBLOKIR" (call :EnableOffice) else (call :InitBackup & call :BlockOffice)
    goto MENU
)
if "%PIL%"=="3" (call :InitBackup & call :BlockWindows & call :BlockOffice & goto MENU)
if "%PIL%"=="4" (call :RestoreAll & goto MENU)
if "%PIL%"=="0" exit /b 0
goto MENU

:: ================== DETEKSI STATUS ==================
:DetectState
set "WSTATE=AKTIF"
sc qc wuauserv 2>nul | findstr /i "DISABLED" >nul && set "WSTATE=TERBLOKIR"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate 2>nul | findstr /r /c:"0x1$" >nul && set "WSTATE=TERBLOKIR"
set "OSTATE=AKTIF"
reg query "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" >nul 2>&1
if errorlevel 1 (
    set "OSTATE=TIDAK ADA"
) else (
    reg query "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" /v UpdatesEnabled 2>nul | findstr /i "False" >nul && set "OSTATE=TERBLOKIR"
    reg query "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" /v enableautomaticupdates 2>nul | findstr /r /c:"0x0$" >nul && set "OSTATE=TERBLOKIR"
)
exit /b 0

:: ================== BACKUP ==================
:InitBackup
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss" 2^>nul') do set "TS=%%T"
if not defined TS set "TS=manual"
set "BKDIR=%SystemDrive%\Backup-Blokir-Update\%TS%"
set "MANIFEST=%BKDIR%\manifest.txt"
mkdir "%BKDIR%" 2>nul
(echo # Manifest backup cek-update %TS%)>"%MANIFEST%"
echo  Backup ke: %BKDIR%
exit /b 0

:: %1=key, %2=value, %3=nama file backup
:BackupVal
reg query "%~1" /v "%~2" >nul 2>&1
if not errorlevel 1 (
    reg export "%~1" "%BKDIR%\%~3.reg" /y >nul 2>&1
    echo backup:%~3.reg>>"%MANIFEST%"
    echo      + backup %~3.reg
    exit /b 0
)
reg query "%~1" >nul 2>&1
if errorlevel 1 (
    echo created-key:%~1>>"%MANIFEST%"
    echo      - key baru, dicatat untuk restore
) else (
    echo created-val:%~1^|%~2>>"%MANIFEST%"
    echo      - value baru, dicatat untuk restore
)
exit /b 0

:FindLatest
set "LATEST="
for /f "delims=" %%D in ('dir /b /ad /o-n "%SystemDrive%\Backup-Blokir-Update\*" 2^>nul') do (
    if not defined LATEST set "LATEST=%SystemDrive%\Backup-Blokir-Update\%%D"
)
exit /b 0

:: ================== BLOKIR ==================
:BlockWindows
echo.
echo  --- BLOKIR WINDOWS UPDATE ---
echo  [a] Backup registry...
call :BackupVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" "WU-Policy-AU"
call :BackupVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" "WU-Policy-AU"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" "Start" "Svc-wuauserv"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\BITS" "Start" "Svc-BITS"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" "Start" "Svc-UsoSvc"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" "Start" "Svc-WaaSMedicSvc"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" "Start" "Svc-DoSvc"
echo  [b] Disable service...
for %%S in (wuauserv BITS UsoSvc WaaSMedicSvc DoSvc) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
    echo      + %%S disabled
)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul
echo  [c] Policy NoAutoUpdate=1 diterapkan
for %%T in ("Scheduled Start" "sih" "sihboot") do (
    schtasks /query /tn "\Microsoft\Windows\WindowsUpdate\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\%%~T" /disable >nul 2>&1
)
echo  [d] Scheduled task di-disable
echo.
echo  SELESAI. Windows Update TERBLOKIR.
pause
exit /b 0

:BlockOffice
echo.
echo  --- BLOKIR OFFICE UPDATE ---
echo  [a] Backup registry...
call :BackupVal "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" "UpdatesEnabled" "Office-C2R-Config"
call :BackupVal "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" "enableautomaticupdates" "Office-Policy-Update"
reg add "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" /v UpdatesEnabled /t REG_SZ /d False /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" /v enableautomaticupdates /t REG_DWORD /d 0 /f >nul
echo  [b] UpdatesEnabled=False diterapkan
for %%T in ("Office Automatic Updates 2.0" "Office ClickToRun Service Monitor") do (
    schtasks /query /tn "\Microsoft\Office\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Office\%%~T" /disable >nul 2>&1
)
echo  [c] Scheduled task di-disable
echo.
echo  SELESAI. Office Update TERBLOKIR.
pause
exit /b 0

:: ================== AKTIFKAN LAGI ==================
:EnableWindows
echo.
echo  --- AKTIFKAN WINDOWS UPDATE ---
call :FindLatest
if defined LATEST (
    echo  Backup: %LATEST%
    echo  [a] Import registry Windows dari backup...
    for %%F in ("%LATEST%\WU-*.reg") do (
        if exist "%%F" (
            reg import "%%F" >nul 2>&1
            echo      + %%~nxF
        )
    )
    for %%F in ("%LATEST%\Svc-*.reg") do (
        if exist "%%F" (
            reg import "%%F" >nul 2>&1
            echo      + %%~nxF
        )
    )
    set "MAN=%LATEST%\manifest.txt"
    if exist "%MAN%" (
        echo  [b] Hapus key/value yang dibuat saat blokir...
        for /f "tokens=1* delims=:" %%A in ('findstr /b "created-key:" "%MAN%" 2^>nul ^| findstr /i "windowsupdate"') do (
            reg delete "%%B" /f >nul 2>&1
            echo      - key: %%B
        )
        for /f "tokens=1* delims=:" %%A in ('findstr /b "created-val:" "%MAN%" 2^>nul ^| findstr /i "windowsupdate"') do (
            for /f "tokens=1,2 delims=|" %%K in ("%%B") do (
                reg delete "%%K" /v "%%L" /f >nul 2>&1
                echo      - value: %%L
            )
        )
    )
) else (
    echo  (tidak ada backup - pakai cara langsung)
)
echo  [c] Service ke Manual + task diaktifkan...
for %%S in (wuauserv BITS UsoSvc WaaSMedicSvc DoSvc) do sc config %%S start= demand >nul 2>&1
for %%T in ("Scheduled Start" "sih" "sihboot") do (
    schtasks /query /tn "\Microsoft\Windows\WindowsUpdate\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\%%~T" /enable >nul 2>&1
)
call :DetectState
if "%WSTATE%"=="TERBLOKIR" (
    echo  [d] Bersihkan sisa policy...
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /f >nul 2>&1
)
echo.
echo  SELESAI. Windows Update AKTIF lagi.
pause
exit /b 0

:EnableOffice
echo.
echo  --- AKTIFKAN OFFICE UPDATE ---
call :FindLatest
if defined LATEST (
    echo  Backup: %LATEST%
    echo  [a] Import registry Office dari backup...
    for %%F in ("%LATEST%\Office-*.reg") do (
        if exist "%%F" (
            reg import "%%F" >nul 2>&1
            echo      + %%~nxF
        )
    )
    set "MAN=%LATEST%\manifest.txt"
    if exist "%MAN%" (
        echo  [b] Hapus key/value yang dibuat saat blokir...
        for /f "tokens=1* delims=:" %%A in ('findstr /b "created-key:" "%MAN%" 2^>nul ^| findstr /i "office"') do (
            echo %%B | findstr /i "windowsupdate" >nul
            if errorlevel 1 (
                reg delete "%%B" /f >nul 2>&1
                echo      - key: %%B
            )
        )
        for /f "tokens=1* delims=:" %%A in ('findstr /b "created-val:" "%MAN%" 2^>nul ^| findstr /i "office"') do (
            for /f "tokens=1,2 delims=|" %%K in ("%%B") do (
                echo %%K | findstr /i "windowsupdate" >nul
                if errorlevel 1 (
                    reg delete "%%K" /v "%%L" /f >nul 2>&1
                    echo      - value: %%L
                )
            )
        )
    )
) else (
    echo  (tidak ada backup - pakai cara langsung)
)
echo  [c] Kembalikan value + task diaktifkan...
reg query "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" >nul 2>&1
if not errorlevel 1 (
    reg add "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" /v UpdatesEnabled /t REG_SZ /d True /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" /v enableautomaticupdates /f >nul 2>&1
)
for %%T in ("Office Automatic Updates 2.0" "Office ClickToRun Service Monitor") do (
    schtasks /query /tn "\Microsoft\Office\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Office\%%~T" /enable >nul 2>&1
)
echo.
echo  SELESAI. Office Update AKTIF lagi.
pause
exit /b 0

:: ================== [4] RESTORE SEMUA ==================
:RestoreAll
echo.
echo  --- AKTIFKAN KEDUANYA (RESTORE PENUH) ---
call :FindLatest
if not defined LATEST (
    echo  TIDAK ADA BACKUP di %SystemDrive%\Backup-Blokir-Update\
    pause
    exit /b 0
)
echo  Backup terakhir: %LATEST%
call :Confirm "Mengembalikan SEMUA registry + service dari backup." "Windows dan Office Update akan AKTIF lagi."
if errorlevel 1 (
    pause
    exit /b 0
)
echo  [a] Import semua .reg...
for %%F in ("%LATEST%\*.reg") do (
    reg import "%%F" >nul 2>&1
    echo      + %%~nxF
)
set "MAN=%LATEST%\manifest.txt"
if exist "%MAN%" (
    echo  [b] Hapus key/value yang dibuat saat blokir...
    for /f "tokens=1* delims=:" %%A in ('findstr /b "created-key:" "%MAN%" 2^>nul') do (
        reg delete "%%B" /f >nul 2>&1
        echo      - key: %%B
    )
    for /f "tokens=1* delims=:" %%A in ('findstr /b "created-val:" "%MAN%" 2^>nul') do (
        for /f "tokens=1,2 delims=|" %%K in ("%%B") do (
            reg delete "%%K" /v "%%L" /f >nul 2>&1
            echo      - value: %%L
        )
    )
)
echo  [c] Task diaktifkan lagi...
for %%T in ("Scheduled Start" "sih" "sihboot") do (
    schtasks /query /tn "\Microsoft\Windows\WindowsUpdate\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\%%~T" /enable >nul 2>&1
)
for %%T in ("Office Automatic Updates 2.0" "Office ClickToRun Service Monitor") do (
    schtasks /query /tn "\Microsoft\Office\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Office\%%~T" /enable >nul 2>&1
)
echo.
echo  SELESAI. Semua update AKTIF lagi. Restart PC disarankan.
pause
exit /b 0

:: ================== KONFIRMASI ==================
:Confirm
echo.
echo  +++++ PERINGATAN +++++
echo  %~1
if not "%~2"=="" echo  %~2
echo.
set "CF="
set /p "CF=Ketik YA (huruf besar) untuk lanjut, Enter untuk batal: "
if /i "%CF%"=="YA" exit /b 0
echo  Dibatalkan - tidak ada yang diubah.
exit /b 1
