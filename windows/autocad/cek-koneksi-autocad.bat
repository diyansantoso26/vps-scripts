@echo off
rem ============================================================
rem  CEK-KONEKSI-AUTOCAD.BAT
rem  Monitor live: ke mana saja acad.exe konek saat berjalan.
rem  Jalankan script ini, LALU buka AutoCAD.
rem  Kalau muncul koneksi ESTABLISHED ke IP Autodesk,
rem  berarti blokir internetnya belum jalan.
rem ============================================================
title Monitor Koneksi AutoCAD
echo  ===============================================
echo   MONITOR KONEKSI AUTOCAD (acad.exe)
echo   Refresh tiap 5 detik. Tekan Ctrl+C berhenti.
echo  ===============================================
echo.
:loop
set "ACADPID="
for /f "tokens=2" %%P in ('tasklist /fi "imagename eq acad.exe" /fo table /nh 2^>nul') do set "ACADPID=%%P"
if not defined ACADPID (
    echo [%time%] acad.exe TIDAK berjalan. Menunggu AutoCAD dibuka...
) else (
    echo.
    echo [%time%] acad.exe jalan (PID %ACADPID%). Koneksi aktif:
    netstat -ano | findstr " %ACADPID% " | findstr /v /i "LISTENING"
    echo   ---(tidak ada baris = tidak ada koneksi keluar)---
)
timeout /t 5 /nobreak >nul
goto loop
