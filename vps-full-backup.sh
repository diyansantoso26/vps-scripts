#!/usr/bin/env bash
# vps-full-backup.sh — Backup penuh VPS sebelum reinstall.
# Dijalankan sebagai root di VPS. Output: /home/gtg/backup/vps-backup-<tanggal>.tar.gz.enc (terenkripsi)
# + /home/gtg/backup/PASSWORD.txt (password arsip — simpan baik-baik!)
set -euo pipefail
info(){ echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok(){ echo -e "\e[1;32m[OK]\e[0m $*"; }
[ "$(id -u)" -eq 0 ] || { echo "Jalankan sebagai root."; exit 1; }

STAGE=/home/gtg/backup-stage
OUT=/home/gtg/backup
DATE=$(date +%F-%H%M)
rm -rf "$STAGE"; mkdir -p "$STAGE" "$OUT"

info "1/7 Database MySQL (dump per database)..."
mkdir -p "$STAGE/dbsql"
python3 - <<'PYEOF'
import sqlite3, subprocess
con = sqlite3.connect("/www/server/panel/data/default.db")
for name, user, pw in con.execute("SELECT name, username, password FROM databases"):
    with open(f"/home/gtg/backup-stage/dbsql/{name}.sql", "w") as f:
        r = subprocess.run(["mysqldump", "-u", user, f"-p{pw}", name],
                           stdout=f, stderr=subprocess.DEVNULL)
        print(("OK " if r.returncode == 0 else "GAGAL ") + name)
PYEOF
[ -n "$(ls -A "$STAGE/dbsql/")" ] || { echo "dump DB gagal!"; exit 1; }

info "2/7 TG Drive (/home/tgdrive/app, tanpa venv/cache/tmp)..."
mkdir -p "$STAGE/tgdrive"
tar -cf - -C /home/tgdrive \
  --exclude='app/venv' --exclude='app/__pycache__' \
  --exclude='app/data/tmp' --exclude='app/data/cache' \
  app | tar -xf - -C "$STAGE/tgdrive"

info "3/7 Hermes (config, .env, state, sessions, skills)..."
mkdir -p "$STAGE/hermes"
for d in .env config.yaml config.yml state.db sessions skills; do
  [ -e "/home/gtg/.hermes/$d" ] && cp -a "/home/gtg/.hermes/$d" "$STAGE/hermes/"
done

info "4/7 9router, websites, docker volumes..."
mkdir -p "$STAGE/ninerouter"
cp -a /home/gtg/.9router/. "$STAGE/ninerouter/" 2>/dev/null || true
mkdir -p "$STAGE/wwwroot"
tar -cf - -C /www --exclude='wwwroot/*/wp-content/cache' wwwroot | tar -xf - -C "$STAGE/wwwroot"
mkdir -p "$STAGE/docker-volumes"
cp -a /var/lib/docker/volumes/. "$STAGE/docker-volumes/" 2>/dev/null || true

info "5/7 Konfigurasi sistem..."
mkdir -p "$STAGE/system"
# service systemd kustom
for s in 9router hermes-gateway tgdrive cloudflared tunnel-guard svcpanel; do
  [ -f "/etc/systemd/system/$s.service" ] && cp -a "/etc/systemd/system/$s.service" "$STAGE/system/"
done
[ -f /etc/sudoers.d/svcpanel ] && cp -a /etc/sudoers.d/svcpanel "$STAGE/system/"
# vhost nginx aaPanel
mkdir -p "$STAGE/system/nginx-vhosts"
cp -a /www/server/panel/vhost/nginx/*.conf "$STAGE/system/nginx-vhosts/" 2>/dev/null || true
# panel kontrol buatan sendiri
[ -d /home/gtg/svcpanel ] && cp -a /home/gtg/svcpanel "$STAGE/system/svcpanel-app"
[ -f /home/gtg/.panel_pass ] && cp -a /home/gtg/.panel_pass "$STAGE/system/"
# cloudflared tunnel (config + kredensial tunnel + cert)
# CATATAN: kredensial tunnel (JSON) ada di /root/.cloudflared, BUKAN /etc/cloudflared!
mkdir -p "$STAGE/system/cloudflared-etc" "$STAGE/system/cloudflared-root"
cp -a /etc/cloudflared/. "$STAGE/system/cloudflared-etc/" 2>/dev/null || true
cp -a /root/.cloudflared/. "$STAGE/system/cloudflared-root/" 2>/dev/null || true
[ -d /home/gtg/.cloudflared ] && cp -a /home/gtg/.cloudflared/. "$STAGE/system/cloudflared-gtg/" 2>/dev/null || true
# sertifikat SSL
mkdir -p "$STAGE/system/letsencrypt"
cp -a /etc/letsencrypt/. "$STAGE/system/letsencrypt/" 2>/dev/null || true
# crontab semua user
mkdir -p "$STAGE/system/cron"
for u in root gtg tgdrive; do
  crontab -u "$u" -l > "$STAGE/system/cron/$u.crontab" 2>/dev/null || true
done
# password DB per situs (dari aaPanel, untuk restore)
cp -a /www/server/panel/data/default.db "$STAGE/system/aapanel-default.db" 2>/dev/null || true

info "6/7 Manifest..."
cat > "$STAGE/MANIFEST.txt" <<EOF
Backup VPS gtg.my.id — $DATE
Isi:
- dbsql/            : dump MySQL (2 database WordPress)
- tgdrive/          : aplikasi TG Drive (source + drive.db + thumbs, tanpa venv/cache/tmp)
- hermes/           : config + .env (token bot!) + state.db + sessions + skills
- ninerouter/       : config + database 9router (API keys)
- wwwroot/          : semua file website
- docker-volumes/   : data WAHA, n8n, uptime-kuma, filebrowser, portainer
- system/           : service systemd, sudoers panel, vhost nginx, aplikasi panel,
                      password panel, config cloudflared (kredensial tunnel!),
                      sertifikat SSL, crontab, db password aaPanel
CATATAN: arsip ini berisi RAHASIA (token bot, password). Jangan disebar.
Lihat panduan-restore-vps.md untuk cara mengembalikan.
EOF

info "7/7 Kompres + enkripsi..."
PASS=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
echo "$PASS" > "$OUT/PASSWORD.txt"; chmod 600 "$OUT/PASSWORD.txt"
tar -czf - -C "$STAGE" . | openssl enc -aes-256-cbc -pbkdf2 -pass "pass:$PASS" -out "$OUT/vps-backup-$DATE.tar.gz.enc"
chmod 600 "$OUT/vps-backup-$DATE.tar.gz.enc"
SIZE=$(du -h "$OUT/vps-backup-$DATE.tar.gz.enc" | cut -f1)
# bersihkan stage (data mentah tidak terenkripsi jangan tertinggal)
rm -rf "$STAGE"

echo ""
ok "SELESAI: $OUT/vps-backup-$DATE.tar.gz.enc ($SIZE, terenkripsi)"
ok "Password: $OUT/PASSWORD.txt"
echo "WAJIB: download KEDUA file via aaPanel File Manager SEBELUM reinstall!"
