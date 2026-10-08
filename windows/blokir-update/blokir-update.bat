@echo off
rem ============================================================
rem  BLOKIR-UPDATE.BAT v1
rem  Blokir permanen Windows Update & Microsoft Office Update.
rem
rem  CARA KERJA: setiap aksi blokir SELALU backup registry dulu
rem  ke %SystemDrive%\Backup-Blokir-Update\<timestamp>\  berupa
rem  file .reg + manifest. Opsi [4] Restore mengembalikan semua
rem  seperti semula dari backup terakhir.
rem  Dibuat oleh GTG COMPUTER
rem ============================================================
set "VER=3"
set "REPO=https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/windows/blokir-update"

:: ---------- cek update otomatis ----------
if /i "%~1"=="--noupdate" goto ADM
echo  Mengecek update...
set "LATEST="
for /f %%V in ('powershell -NoProfile -Command "try { (Invoke-RestMethod '%REPO%/VERSION' -TimeoutSec 10).Trim() } catch { '' }" 2^>nul') do set "LATEST=%%V"
if not defined LATEST goto ADM
if "%LATEST%"=="%VER%" goto ADM
echo  Versi baru v%LATEST% tersedia, mengunduh...
set "TMPBAT=%TEMP%\blokir-update-%LATEST%.bat"
powershell -NoProfile -Command "Invoke-RestMethod '%REPO%/blokir-update.bat' -OutFile '%TMPBAT%'" >nul 2>&1
if not exist "%TMPBAT%" (
    echo  Gagal mengunduh, lanjut versi lokal.
    goto ADM
)
findstr /i /c:"BLOKIR-UPDATE.BAT" "%TMPBAT%" >nul 2>&1
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
cls
echo  ===============================================
echo   BLOKIR UPDATE v%VER% - Windows ^& Office
echo   oleh GTG COMPUTER - WA 085738127969
echo  ===============================================
echo.
echo   [1] Blokir Windows Update saja
echo       - backup registry dulu, lalu disable permanen
echo   [2] Blokir Microsoft Office Update saja
echo       - backup registry dulu, lalu disable permanen
echo   [3] Blokir keduanya (Windows + Office)
echo   [4] Restore - kembalikan seperti semula
echo       - dari backup terakhir, update AKTIF lagi
echo   [5] Cek status update
echo       - lihat service ^& registry saat ini
echo   [0] Keluar
echo.
set "PIL="
set /p "PIL=Pilih [0-5]: "
if "%PIL%"=="1" (call :InitBackup & call :BlockWindows & goto MENU)
if "%PIL%"=="2" (call :InitBackup & call :BlockOffice & goto MENU)
if "%PIL%"=="3" (call :InitBackup & call :BlockWindows & call :BlockOffice & goto MENU)
if "%PIL%"=="4" (call :DoRestore & goto MENU)
if "%PIL%"=="5" (call :DoStatus & goto MENU)
if "%PIL%"=="0" exit /b 0
goto MENU

:: ================== BACKUP ==================
:InitBackup
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss" 2^>nul') do set "TS=%%T"
if not defined TS set "TS=manual"
set "BKDIR=%SystemDrive%\Backup-Blokir-Update\%TS%"
set "MANIFEST=%BKDIR%\manifest.txt"
mkdir "%BKDIR%" 2>nul
(echo # Manifest backup blokir-update %TS%)>"%MANIFEST%"
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

:: ================== [1] BLOKIR WINDOWS ==================
:BlockWindows
echo.
echo  --- [1] BLOKIR WINDOWS UPDATE ---
echo  [a] Backup registry...
call :BackupVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" "WU-Policy-AU"
call :BackupVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" "WU-Policy-AU"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" "Start" "Svc-wuauserv"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\BITS" "Start" "Svc-BITS"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" "Start" "Svc-UsoSvc"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" "Start" "Svc-WaaSMedicSvc"
call :BackupVal "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" "Start" "Svc-DoSvc"
echo  [b] Disable service update...
for %%S in (wuauserv BITS UsoSvc WaaSMedicSvc DoSvc) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
    echo      + %%S disabled
)
echo  [c] Registry policy (NoAutoUpdate)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul
echo      + NoAutoUpdate=1, AUOptions=2
echo  [d] Disable scheduled task...
for %%T in ("Scheduled Start" "sih" "sihboot") do (
    schtasks /query /tn "\Microsoft\Windows\WindowsUpdate\%%~T" >nul 2>&1
    if not errorlevel 1 (
        schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\%%~T" /disable >nul 2>&1
        echo      + %%~T disabled
    )
)
echo.
echo  SELESAI. Windows Update terblokir permanen.
echo  Backup: %BKDIR%
pause
exit /b 0

:: ================== [2] BLOKIR OFFICE ==================
:BlockOffice
echo.
echo  --- [2] BLOKIR MICROSOFT OFFICE UPDATE ---
reg query "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" >nul 2>&1
if errorlevel 1 (
    echo  Office Click-to-Run tidak terdeteksi di PC ini. Dilewati.
    pause
    exit /b 0
)
echo  [a] Backup registry...
call :BackupVal "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" "UpdatesEnabled" "Office-C2R-Config"
call :BackupVal "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" "enableautomaticupdates" "Office-Policy-Update"
echo  [b] Registry (matikan auto-update)...
reg add "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" /v UpdatesEnabled /t REG_SZ /d False /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" /v enableautomaticupdates /t REG_DWORD /d 0 /f >nul
echo      + UpdatesEnabled=False, enableautomaticupdates=0
echo  [c] Disable scheduled task...
for %%T in ("Office Automatic Updates 2.0" "Office ClickToRun Service Monitor") do (
    schtasks /query /tn "\Microsoft\Office\%%~T" >nul 2>&1
    if not errorlevel 1 (
        schtasks /change /tn "\Microsoft\Office\%%~T" /disable >nul 2>&1
        echo      + %%~T disabled
    )
)
echo.
echo  SELESAI. Office Update terblokir permanen.
echo  Backup: %BKDIR%
echo  CATATAN: ClickToRunSvc TIDAK di-disable (dibutuhkan Office untuk jalan).
pause
exit /b 0

:: ================== [4] RESTORE ==================
:DoRestore
echo.
echo  --- [4] RESTORE UPDATE ---
set "LATEST="
for /f "delims=" %%D in ('dir /b /ad /o-n "%SystemDrive%\Backup-Blokir-Update\*" 2^>nul') do (
    if not defined LATEST set "LATEST=%SystemDrive%\Backup-Blokir-Update\%%D"
)
if not defined LATEST (
    echo  TIDAK ADA BACKUP di %SystemDrive%\Backup-Blokir-Update\
    pause
    exit /b 0
)
echo  Backup terakhir: %LATEST%
call :Confirm "Mengembalikan registry + service dari backup di atas." "Windows/Office Update akan AKTIF lagi."
if errorlevel 1 (
    pause
    exit /b 0
)
echo  [a] Import file .reg backup...
for %%F in ("%LATEST%\*.reg") do (
    reg import "%%F" >nul 2>&1
    echo      + %%~nxF
)
set "MAN=%LATEST%\manifest.txt"
if exist "%MAN%" (
    echo  [b] Hapus key yang dibuat saat blokir...
    for /f "tokens=1* delims=:" %%A in ('findstr /b "created-key:" "%MAN%" 2^>nul') do (
        reg delete "%%B" /f >nul 2>&1
        echo      - key: %%B
    )
    echo  [c] Hapus value yang dibuat saat blokir...
    for /f "tokens=1* delims=:" %%A in ('findstr /b "created-val:" "%MAN%" 2^>nul') do (
        for /f "tokens=1,2 delims=|" %%K in ("%%B") do (
            reg delete "%%K" /v "%%L" /f >nul 2>&1
            echo      - value: %%L
        )
    )
)
echo  [d] Scheduled task diaktifkan lagi...
for %%T in ("Scheduled Start" "sih" "sihboot") do (
    schtasks /query /tn "\Microsoft\Windows\WindowsUpdate\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Windows\WindowsUpdate\%%~T" /enable >nul 2>&1
)
for %%T in ("Office Automatic Updates 2.0" "Office ClickToRun Service Monitor") do (
    schtasks /query /tn "\Microsoft\Office\%%~T" >nul 2>&1
    if not errorlevel 1 schtasks /change /tn "\Microsoft\Office\%%~T" /enable >nul 2>&1
)
echo.
echo  SELESAI. Update kembali aktif. Restart PC disarankan.
pause
exit /b 0

:: ================== [5] STATUS ==================
:DoStatus
echo.
echo  --- [5] STATUS UPDATE SAAT INI ---
echo  [Service Windows Update]
sc qc wuauserv 2>nul | findstr /i "START_TYPE"
sc qc BITS 2>nul | findstr /i "START_TYPE"
sc qc UsoSvc 2>nul | findstr /i "START_TYPE"
sc qc WaaSMedicSvc 2>nul | findstr /i "START_TYPE"
echo  [Registry Windows]
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate 2>nul | findstr /i "NoAutoUpdate" || echo      (policy tidak ada = update AKTIF)
echo  [Registry Office]
reg query "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" /v UpdatesEnabled 2>nul | findstr /i "UpdatesEnabled" || echo      (Office tidak terinstall / tidak diblokir)
echo.
echo  START_TYPE 4 = DISABLED (terblokir), 3 = MANUAL (aktif normal).
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
