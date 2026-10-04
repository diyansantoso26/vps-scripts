# Panduan Restore VPS gtg.my.id

Untuk dipakai SETELAH reinstall VPS. Asumsi: Ubuntu 24.04 fresh + aaPanel
terinstal (karena website & database dikelola aaPanel).

File yang dibutuhkan (download SEBELUM reinstall via aaPanel File Manager):
- `/home/gtg/backup/vps-backup-2026-10-05-0003.tar.gz.enc` (256 MB)
- `/home/gtg/backup/PASSWORD.txt` (password dekripsi — JAGA!)

## 0. Buka arsip

```bash
openssl enc -d -aes-256-cbc -pbkdf2 \
  -pass file:PASSWORD.txt \
  -in vps-backup-2026-10-05-0003.tar.gz.enc \
  | tar -xz -C /root/restore
```

## 1. aaPanel: website + database

1. Buat ulang website di aaPanel dengan **nama domain yang sama**
   (gtg.my.id, blog.gtg.my.id, drive.gtg.my.id, dst.).
2. Buat ulang database di aaPanel dengan **nama & username yang sama**
   (lihat `system/aapanel-default.db` tabel `databases` untuk nama/user/password).
   Password DB ada di kolom `password` tabel tersebut.
3. Copy file website: `cp -a /root/restore/wwwroot/wwwroot/* /www/wwwroot/`
4. Import dump: `mysql -u <user> -p'<password>' <db> < /root/restore/dbsql/<db>.sql`
5. `chown -R www:www /www/wwwroot`

## 2. TG Drive

```bash
# install dependensi python + buat user
id tgdrive >/dev/null 2>&1 || useradd -r -m -s /bin/bash tgdrive
apt install -y python3-venv python3-pip
cp -a /root/restore/tgdrive/app /home/tgdrive/
cd /home/tgdrive/app && python3 -m venv venv && venv/bin/pip install -r requirements.txt
chown -R tgdrive:tgdrive /home/tgdrive/app
# service systemd
cp /root/restore/system/tgdrive.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now tgdrive
```
Token bot & config ikut dalam `app/` (file `.env`). SQLite `drive.db` sudah
termasuk — tidak perlu migrasi.

## 3. Hermes (bot Telegram)

```bash
# install hermes-agent versi yang sama dulu (lihat dokumentasi hermes),
# lalu timpa data:
cp -a /root/restore/hermes/.env /root/restore/hermes/config.yaml /root/restore/hermes/state.db /home/gtg/.hermes/
cp -a /root/restore/hermes/sessions /root/restore/hermes/skills /home/gtg/.hermes/
chown -R gtg:gtg /home/gtg/.hermes
cp /root/restore/system/hermes-gateway.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now hermes-gateway
```
Token bot ada di `.env` — tidak perlu buat bot baru / pairing ulang.

## 4. 9router

```bash
# install 9router versi yang sama, lalu:
cp -a /root/restore/ninerouter/. /home/gtg/.9router/
chown -R gtg:gtg /home/gtg/.9router
cp /root/restore/system/9router.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now 9router
```
API keys ikut dalam database 9router — klien lama langsung bisa pakai lagi.

## 5. Cloudflare Tunnel

```bash
mkdir -p /etc/cloudflared /root/.cloudflared
cp -a /root/restore/system/cloudflared-etc/. /etc/cloudflared/
cp -a /root/restore/system/cloudflared-root/. /root/.cloudflared/
chmod 600 /root/.cloudflared/*.json /root/.cloudflared/cert.pem
cp /root/restore/system/cloudflared.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now cloudflared
```
Kredensial tunnel (JSON + cert) ikut ter-backup — **tidak perlu buat tunnel
baru**, ID tunnel tetap sama. Jangan sampai file JSON ini hilang.

## 6. Docker (WAHA, n8n, Uptime Kuma, dsb.)

```bash
apt install -y docker.io docker-compose-plugin
# kembalikan volume
cp -a /root/restore/docker-volumes/. /var/lib/docker/volumes/
# jalankan ulang compose project masing-masing
# (file compose ada di repo masing-masing / dokumentasi)
docker start waha   # session WhatsApp ikut — tanpa scan QR ulang
```
Nama volume: `waha_sessions`, `n8n_n8n_data`, `portainer_data`.

## 7. Panel kontrol (monitor.gtg.my.id)

```bash
cp -a /root/restore/system/svcpanel-app /home/gtg/svcpanel
cp /root/restore/system/.panel_pass /home/gtg/.panel_pass
cp /root/restore/system/svcpanel /etc/sudoers.d/svcpanel && chmod 440 /etc/sudoers.d/svcpanel
cp /root/restore/system/svcpanel.service /etc/systemd/system/
# vhost nginx + buat ulang venv python, lalu:
systemctl daemon-reload && systemctl enable --now svcpanel
# vhost: cp /root/restore/system/nginx-vhosts/*.conf /www/server/panel/vhost/nginx/
# lalu reload nginx via /etc/init.d/nginx reload
```

## 8. Lain-lain

- Crontab: `crontab -u <user> /root/restore/system/cron/<user>.crontab`
- Sertifikat SSL: `/root/restore/system/letsencrypt/` → `/etc/letsencrypt/`
  (atau biarkan aaPanel/ certbot menerbitkan ulang — lebih bersih).
- `tunnel-guard`: copy service-nya seperti di atas bila masih dipakai.

## Urutan yang disarankan

aaPanel dulu → website+DB → Docker → cloudflared → 9router → hermes →
tgdrive → panel → crontab. Tes satu per satu sebelum lanjut.
