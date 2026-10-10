@echo off
rem ============================================================
rem  KILL-NET-AUTOCAD.BAT
rem  Kill-switch darurat: mematikan SEMUA proses Autodesk yang
rem  punya koneksi internet aktif, plus service-nya.
rem.
rem  Ini PEMADAM KEBAKARAN, bukan tembok permanen:
rem  - script ini  = mematikan koneksi yang SEDANG jalan
rem  - toolkit [1] = mencegah koneksi BARU (tembok permanen)
rem  Pakai dua-duanya. Idempotent, aman diulang-ulang.
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  ===============================================
echo   KILL SEMUA KONEKSI INTERNET AUTODESK
echo  ===============================================
echo.
echo [1/3] Kill proses Autodesk yang dikenal...
set KILLED=0
for %%P in (
    acad.exe AcWebBrowser.exe AcCefSubprocess.exe
    AdSSO.exe AutodeskDesktopApp.exe AdAppMgr.exe AdAppMgrSvc.exe AdSync.exe
    AdskLicensingService.exe AdskLicensingAgent.exe GenuineService.exe
    senddmp.exe
) do (
    taskkill /f /im %%P >nul 2>&1
    if not errorlevel 1 (
        echo      x %%P dimatikan
        set /a KILLED+=1
    )
)
if %KILLED%==0 echo      - tidak ada proses dikenal yang jalan.
echo.
echo [2/3] Sapu koneksi aktif: cari proses Autodesk LAIN yang masih nyambung...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$found=$false; foreach ($c in (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue)) { try { $p = Get-Process -Id $c.OwningProcess -ErrorAction Stop } catch { continue }; if ($p.Path -and $p.Path -like '*Autodesk*') { try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-Output ('      x {0} (PID {1}) -> {2} dimatikan' -f $p.ProcessName, $p.Id, $c.RemoteAddress); $found=$true } catch {} } }; if (-not $found) { Write-Output '      - bersih, tidak ada koneksi Autodesk tersisa.' }"
echo.
echo [3/3] Matikan service Autodesk biar tidak hidup lagi...
for %%S in ("AdskGenuineService" "AdskLicensingService" "Autodesk Desktop App Service" "FlexNet Licensing Service") do (
    sc stop %%~S >nul 2>&1
    sc config %%~S start= disabled >nul 2>&1
)
echo      + service dinonaktifkan.
echo.
echo  ===============================================
echo   BERES. Catatan:
echo   - Ini kill-switch darurat (matikan yang SEDANG jalan).
echo   - Tembok permanen tetap toolkit v22/v6 opsi [1] Blokir.
echo   - Cek ulang pakai toolkit opsi [6] Monitor.
echo  ===============================================
echo.
pause
