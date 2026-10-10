@echo off
rem ============================================================
rem  BERSIH-GENUINE-AUTOCAD.BAT
rem  Membersihkan error "You no longer have access to AutoCAD"
rem  dari Autodesk Genuine Service + data lisensi, supaya bisa
rem  aktivasi ulang dari awal seperti baru.
rem.
rem  Urutan pakai: [1] script ini -> restart PC ->
rem  [2] toolkit v21/v5 opsi [1] Blokir -> aktivasi ulang.
rem  Idempotent, aman dijalankan berulang-ulang.
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  ===============================================
echo   BERSIHKAN FLAG GENUINE SERVICE AUTOCAD
echo  ===============================================
echo.
echo [1/4] Menutup proses Autodesk...
for %%P in (GenuineService.exe acad.exe AdSSO.exe AutodeskDesktopApp.exe AdskLicensingService.exe AdskLicensingAgent.exe AcWebBrowser.exe AcCefSubprocess.exe AdAppMgrSvc.exe) do (
    taskkill /f /im %%P >nul 2>&1
)
echo       Selesai.
echo.
echo [2/4] Menonaktifkan service...
for %%S in ("AdskGenuineService" "AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service") do (
    sc stop %%~S >nul 2>&1
    sc config %%~S start= disabled >nul 2>&1
)
echo       + AdskGenuineService dkk dinonaktifkan.
echo.
echo [3/4] Menghapus file + data Genuine Service...
if exist "C:\Program Files\Autodesk\Autodesk Genuine Service" (
    rmdir /s /q "C:\Program Files\Autodesk\Autodesk Genuine Service"
    echo      + folder program dihapus
) else (
    echo      - folder program tidak ada, dilewati
)
if exist "C:\ProgramData\Autodesk\Autodesk Genuine Service" (
    rmdir /s /q "C:\ProgramData\Autodesk\Autodesk Genuine Service"
    echo      + data flag dihapus
) else (
    echo      - data flag tidak ada, dilewati
)
if exist "%LOCALAPPDATA%\Autodesk\Autodesk Genuine Service" (
    rmdir /s /q "%LOCALAPPDATA%\Autodesk\Autodesk Genuine Service"
    echo      + data user dihapus
) else (
    echo      - data user tidak ada, dilewati
)
reg delete "HKLM\SOFTWARE\Autodesk\Autodesk Genuine Service" /f >nul 2>&1
echo      + registry dibersihkan (jika ada).
echo.
echo [4/4] Menghapus data lisensi lama (biar aktivasi fresh)...
if exist "C:\ProgramData\FLEXnet\adskflex_*.data" (
    del /f /q "C:\ProgramData\FLEXnet\adskflex_*.data*"
    echo      + FlexNet trusted storage dihapus
)
if exist "C:\ProgramData\Autodesk\CLM\LGS" (
    del /f /q "C:\ProgramData\Autodesk\CLM\LGS\*"
    echo      + data lisensi CLM dihapus
)
if exist "%LOCALAPPDATA%\Autodesk\Web Services" (
    rmdir /s /q "%LOCALAPPDATA%\Autodesk\Web Services"
    echo      + status login Autodesk dihapus
)
reg delete "HKLM\SOFTWARE\FLEXlm License Manager" /f >nul 2>&1
ipconfig /flushdns >nul 2>&1
echo       Selesai.
echo.
echo  ===============================================
echo   BERES! Lanjut urutan ini:
echo   1. Restart PC dulu.
echo   2. Toolkit v21/v5 -^> opsi [1] Blokir
echo      (Genuine Service sekarang ikut keblokir).
echo   3. Buka AutoCAD -^> aktivasi ulang dari awal.
echo  ===============================================
echo.
pause
