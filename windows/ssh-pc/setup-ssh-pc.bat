@echo off
rem ============================================================
rem  SETUP-SSH-PC.BAT v1
rem  Siapkan PC Windows agar bisa diakses Muse via SSH.
rem  Jalankan SEKALI sebagai Administrator (klik kanan > Run as
rem  administrator). Dibuat oleh GTG COMPUTER - WA 085738127969
rem ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  Klik kanan file ini -^> Run as administrator!
    pause
    exit /b 1
)

echo  [1/4] Install OpenSSH Server...
powershell -NoProfile -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"

echo  [2/4] Jalankan sshd otomatis...
sc config sshd start= auto >nul 2>&1
net start sshd >nul 2>&1
echo       + sshd jalan

echo  [3/4] Pasang key Muse agar bisa masuk...
set "MUSEKEY=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID4UxlDI5Ysk/T95+6s0Bu7cHEEVjO6DzKRMsh1z6h73 muse-vm-ke-pc-diyan"
set "ADMINKEY=C:\ProgramData\ssh\administrators_authorized_keys"
findstr /c:"muse-vm-ke-pc-diyan" "%ADMINKEY%" >nul 2>&1
if errorlevel 1 echo %MUSEKEY%>>"%ADMINKEY%"
icacls "%ADMINKEY%" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" >nul 2>&1
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh" >nul 2>&1
set "USERKEY=%USERPROFILE%\.ssh\authorized_keys"
findstr /c:"muse-vm-ke-pc-diyan" "%USERKEY%" >nul 2>&1
if errorlevel 1 echo %MUSEKEY%>>"%USERKEY%"
echo       + key Muse terpasang

echo  [4/4] Buat key untuk tunnel ke VPS...
if not exist "%USERPROFILE%\.ssh\id_ed25519.pub" (
    ssh-keygen -t ed25519 -f "%USERPROFILE%\.ssh\id_ed25519" -N "" -C "pc-diyan-ke-vps" >nul 2>&1
    echo       + key dibuat
) else (
    echo       + key sudah ada, pakai yang lama
)

echo.
echo  ===============================================
echo   KIRIM public key ini ke Muse (copy semuanya):
echo  ===============================================
type "%USERPROFILE%\.ssh\id_ed25519.pub"
echo  ===============================================
echo.
echo  Setelah key didaftarkan Muse, jalankan tunnel-pc-ke-vps.bat
echo  (biarkan window-nya terbuka selama ingin bisa diakses).
pause
