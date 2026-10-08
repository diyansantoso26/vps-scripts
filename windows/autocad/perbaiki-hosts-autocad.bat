@echo off
rem ============================================================
rem  PERBAIKI-HOSTS-AUTOCAD.BAT
rem  Khusus menulis 9 domain Autodesk ke hosts file, dengan
rem  output verbose supaya kelihatan kalau penulisannya ditolak
rem  (mis. oleh antivirus).
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "HOSTSFILE=%SystemRoot%\System32\drivers\etc\hosts"
echo  Hosts file: %HOSTSFILE%
echo.
echo  --- isi hosts SEBELUM (15 baris terakhir) ---
powershell -NoProfile -Command "Get-Content '%HOSTSFILE%' | Select-Object -Last 15"
echo.
echo  --- menulis entri Autodesk ---
>>"%HOSTSFILE%" echo.
if errorlevel 1 (
    echo  !!! GAGAL: tidak bisa menulis ke hosts file sama sekali.
    echo  !!! Kemungkinan ditahan antivirus. Matikan proteksi
    echo  !!! real-time sementara lalu jalankan ulang script ini.
    pause
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
        if errorlevel 1 (
            echo      !!! GAGAL tulis: %%H
        ) else (
            echo      + %%H ditulis
        )
    ) else (
        echo      = %%H sudah ada, dilewati
    )
)
ipconfig /flushdns >nul 2>&1
echo.
echo  --- isi hosts SESUDAH (15 baris terakhir) ---
powershell -NoProfile -Command "Get-Content '%HOSTSFILE%' | Select-Object -Last 15"
echo.
echo  SELESAI.
pause
exit /b 0
