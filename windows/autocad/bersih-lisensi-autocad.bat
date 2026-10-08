@echo off
rem ============================================================
rem  BERSIH-LISENSI-AUTOCAD.BAT
rem  Membersihkan data lisensi/konfigurasi AutoCAD TANPA
rem  install ulang Windows.
rem   [1] DATA LISENSI SAJA (disarankan)
rem       Hapus FlexNet trusted storage, data lisensi CLM,
rem       status login Autodesk, registry FLEXlm.
rem       Program AutoCAD TETAP terinstall -> tinggal
rem       aktivasi ulang seperti baru.
rem   [2] BERSIH TOTAL (ala clean-uninstall Autodesk)
rem       Hapus SEMUA folder + registry Autodesk.
rem       Setelah ini install ulang AutoCAD dari installer.
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  ===============================================
echo   BERSIHKAN LISENSI AUTOCAD
echo   (tanpa install ulang Windows)
echo  ===============================================
echo.
echo   [1] Data lisensi SAJA (disarankan)
echo       Program tetap, tinggal aktivasi ulang.
echo.
echo   [2] BERSIH TOTAL
echo       Folder + registry Autodesk dihapus semua,
echo       lanjut install ulang AutoCAD.
echo.
set /p MODE="  Pilih [1/2]: "
if "%MODE%"=="2" goto FULL
if not "%MODE%"=="1" (
    echo Pilihan tidak valid.
    pause
    exit /b 1
)

:LICENSE_ONLY
echo.
echo  --- Mode 1: bersihkan data lisensi ---
call :KillAutodesk
call :WipeLicenseData
goto DONE

:FULL
echo.
echo  --- Mode 2: BERSIH TOTAL ---
echo  SEMUA folder dan registry Autodesk akan dihapus!
set /p YAKIN="  Ketik YA untuk lanjut: "
if /i not "%YAKIN%"=="YA" (
    echo Dibatalkan.
    pause
    exit /b 0
)
call :KillAutodesk
call :WipeLicenseData
call :WipeProgramData
goto DONE

:DONE
echo.
echo  ===============================================
echo   SELESAI. Restart PC dulu, lalu:
if "%MODE%"=="2" (
    echo   - Install ulang AutoCAD 2018 dari installer.
    echo   - SEBELUM aktivasi: jalankan blokir-autocad-2018.bat
    echo     biar langsung buta internet.
) else (
    echo   - Buka AutoCAD dan lakukan aktivasi ulang dari awal.
    echo   - Pastikan blokir-autocad-2018.bat sudah dijalankan
    echo     supaya tidak ada cek lisensi online.
)
echo  ===============================================
echo.
pause
exit /b 0

:: ================= Subrutin =================
:KillAutodesk
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

:WipeLicenseData
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

:WipeProgramData
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
echo      Selesai.
exit /b 0
