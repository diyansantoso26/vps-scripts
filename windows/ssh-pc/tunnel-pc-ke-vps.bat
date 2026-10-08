@echo off
rem ============================================================
rem  TUNNEL-PC-KE-VPS.BAT v1
rem  Buka reverse tunnel PC -> VPS agar Muse bisa SSH masuk.
rem  Biarkan window ini TERBUKA selama PC ingin bisa diakses.
rem  Dibuat oleh GTG COMPUTER - WA 085738127969
rem ============================================================

echo  Menghubungkan tunnel ke VPS...
echo  (tutup window ini untuk memutus akses)
echo.
:loop
ssh -N -R 2223:localhost:22 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=accept-new -i "%USERPROFILE%\.ssh\id_ed25519" -p 20156 root@45.66.153.147
echo.
echo  Tunnel putus/gagal. Mencoba lagi dalam 10 detik...
echo  (pastikan public key PC sudah didaftarkan ke VPS oleh Muse)
timeout /t 10 >nul
goto loop
