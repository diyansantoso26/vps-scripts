#!/usr/bin/env bash
# ==============================================================================
# install-cloudflared.sh — SATU script untuk semuanya:
#   1. Install Cloudflare Tunnel (cloudflared) di VPS
#   2. RESTORE OTOMATIS kredensial tunnel lama dari backup Google Drive
#      (download 251MB -> decrypt -> ambil file tunnel saja -> hapus sisa)
#      ATAU buat tunnel baru dari nol
#   3. Routing DNS: gtg.my.id, www (opsional), panel.gtg.my.id, *.gtg.my.id
#   4. Routing panel.gtg.my.id -> port panel aaPanel (HTTP atau HTTPS)
#   5. Routing WILDCARD *.gtg.my.id -> nginx (subdomain otomatis)
#
# ---- KONSEP DASAR (baca dulu, 1 menit) ---------------------------------------
# Cloudflare Tunnel = koneksi KELUAR (outbound) dari VPS kamu ke Cloudflare.
# Bukan Cloudflare yang "masuk" ke VPS, tapi VPS yang "menelepon" Cloudflare
# dan menjaga sambungannya tetap hidup. Akibatnya:
#   - Tidak perlu buka port 80/443/panel ke internet.
#   - IP asli VPS tidak terekspos langsung.
#   - Kalau VPS di-reinstall / ganti IP, tunnel tetap jalan tanpa ubah DNS.
#
# Alur request setelah script ini selesai:
#   browser -> Cloudflare -> (tunnel) -> cloudflared di VPS -> nginx / panel
#
# Dua file rahasia yang dipakai:
#   - <tunnel-id>.json = KUNCI tunnel. Cuma cocok dengan tunnel ID yang
#     terdaftar di akun Cloudflare kamu. Disimpan di /etc/cloudflared/.
#   - cert.pem = tanda pengenal AKUN Cloudflare. Dengan ini, perintah
#     'tunnel route dns' bisa jalan TANPA login ulang via browser.
#   Keduanya diambil otomatis dari backup Google Drive (mode 1).
#
# Ingress rule di config = daftar "kalau request untuk hostname X,
# teruskan ke alamat lokal Y". Dibaca BERURUTAN dari atas, jadi yang spesifik
# (panel.gtg.my.id) harus di atas wildcard (*.gtg.my.id).
#
# ---- CARA PAKAI ---------------------------------------------------------------
#   1. Di VPS:  nano install-cloudflared.sh   (paste seluruh isi ini,
#               Ctrl+O, Enter, Ctrl+X untuk simpan)
#   2.          chmod +x install-cloudflared.sh
#   3.          sudo ./install-cloudflared.sh
#   4. Jawab pertanyaan yang muncul satu per satu.
#
# ---- PRASYARAT ----------------------------------------------------------------
#   - Ubuntu 24.04, dijalankan sebagai root
#   - Koneksi internet ke drive.google.com (untuk download backup, mode 1)
#   - ~700MB disk kosong sementara (arsip 251MB + hasil decrypt)
#   - Password decrypt arsip backup (diketik saat diminta, tidak disimpan)
#   - Website gtg.my.id sudah ditambahkan di aaPanel (biar nginx jawab port 80)
# ==============================================================================
set -euo pipefail

# ==============================================================================
# STEP 0 — CEK ROOT
# Kenapa: install paket, tulis ke /etc/cloudflared, dan atur systemd service
# semuanya butuh hak akses root.
# ==============================================================================
if [[ $EUID -ne 0 ]]; then
  echo "Harus dijalankan sebagai root. Coba: sudo ./install-cloudflared.sh"
  exit 1
fi

# ==============================================================================
# STEP 1 — INSTALL cloudflared
# Apa: 'cloudflared' adalah program resmi Cloudflare yang membuat tunnel.
# Kenapa dari repo resmi: biar dapat update keamanan otomatis via apt,
# bukan file .deb random dari internet.
# ==============================================================================
echo
echo "=== STEP 1/7 — Install cloudflared ==="
if command -v cloudflared >/dev/null 2>&1; then
  echo "Sudah terinstall, lewati: $(cloudflared --version)"
else
  echo "Menambahkan repository resmi Cloudflare..."
  mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
    | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared noble main' \
    | tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq cloudflared
  echo "Berhasil: $(cloudflared --version)"
fi

mkdir -p /etc/cloudflared
chmod 700 /etc/cloudflared   # hanya root yang boleh intip folder ini

# ==============================================================================
# STEP 2 — SIAPKAN TUNNEL (pilih salah satu)
# Mode 1 = RESTORE OTOMATIS: download arsip backup dari Google Drive, decrypt
#          dengan password kamu, ambil HANYA file tunnel (JSON + cert.pem),
#          lalu hapus semua file sementara (arsip berisi SEMUA rahasia VPS
#          lama, jadi tidak boleh tertinggal di disk).
# Mode 2 = BARU: buat tunnel baru dari nol (butuh login Cloudflare via
#          HP/browser sekali).
# ==============================================================================
echo
echo "=== STEP 2/7 — Siapkan tunnel ==="
echo "1) RESTORE OTOMATIS dari backup Google Drive (disarankan)"
echo "2) BARU: buat tunnel baru (login Cloudflare via HP/browser)"
read -rp "Pilih [1/2]: " MODE

TUNNEL_ID=""
TUNNEL_NAME=""

# --- kalau kredensial sudah ada dari run sebelumnya, pakai lagi ---------------
EXISTING_JSON="$(ls /etc/cloudflared/*.json 2>/dev/null | head -1 || true)"
if [[ -n "$EXISTING_JSON" && "$MODE" == "1" ]]; then
  echo "Kredensial tunnel sudah ada: $EXISTING_JSON — dipakai lagi (tanpa download ulang)."
  TUNNEL_ID="$(basename "$EXISTING_JSON" .json)"
fi

if [[ "$MODE" == "1" && -z "$TUNNEL_ID" ]]; then
  echo "--- Mode RESTORE OTOMATIS ---"
  read -rp "ID file Google Drive [109KuUQd47IVPW5hQkolvporNZDBH-6v6]: " DRIVE_ID
  DRIVE_ID="${DRIVE_ID:-109KuUQd47IVPW5hQkolvporNZDBH-6v6}"

  # Cek ruang disk (butuh ~700MB sementara)
  FREE_KB="$(df --output=avail /root | tail -1)"
  if [[ "$FREE_KB" -lt 700000 ]]; then
    echo "Disk kurang dari 700MB, bersihkan dulu lalu ulangi."
    exit 1
  fi

  # gdown = downloader Google Drive yang handal untuk file besar
  if ! python3 -c "import gdown" 2>/dev/null; then
    echo "Install gdown (sekali saja)..."
    pip install -q --break-system-packages gdown
  fi

  BKDIR="/root/cf-restore-$$"
  mkdir -p "$BKDIR"
  echo "Download arsip backup (251MB)..."
  python3 -m gdown "https://drive.google.com/uc?id=${DRIVE_ID}" -O "$BKDIR/backup.bin"

  # Password tidak ditampilkan saat diketik (read -s) dan tidak disimpan
  read -rsp "Password decrypt arsip: " BKPASS
  echo
  echo "Decrypt..."
  if ! echo "$BKPASS" | openssl enc -d -aes-256-cbc -pbkdf2 \
      -in "$BKDIR/backup.bin" -out "$BKDIR/backup.tar.gz" -pass stdin 2>/dev/null; then
    echo "GAGAL decrypt — password salah atau file rusak."
    rm -rf "$BKDIR"
    unset BKPASS
    exit 1
  fi
  unset BKPASS

  # Ambil HANYA file tunnel dari arsip (bukan seluruh isi backup!)
  echo "Mengambil file tunnel dari arsip..."
  tar xzf "$BKDIR/backup.tar.gz" -C "$BKDIR" ./system/cloudflared-root/
  TUNNEL_JSON="$(ls "$BKDIR"/system/cloudflared-root/*.json 2>/dev/null | head -1 || true)"
  if [[ -z "$TUNNEL_JSON" ]]; then
    echo "GAGAL: file kredensial tunnel tidak ketemu di arsip."
    rm -rf "$BKDIR"
    exit 1
  fi
  TUNNEL_ID="$(basename "$TUNNEL_JSON" .json)"
  echo "Tunnel ID ditemukan: $TUNNEL_ID"

  # Pasang kredensial + cert akun
  cp "$TUNNEL_JSON" "/etc/cloudflared/${TUNNEL_ID}.json"
  chmod 600 "/etc/cloudflared/${TUNNEL_ID}.json"
  mkdir -p /root/.cloudflared
  cp "$BKDIR/system/cloudflared-root/cert.pem" /root/.cloudflared/cert.pem
  chmod 600 /root/.cloudflared/cert.pem
  echo "Kredensial + cert akun dipasang."
  echo "cert.pem = dengan ini 'tunnel route dns' bisa jalan TANPA login browser."

  # Bersih-bersih: arsip berisi semua rahasia VPS lama -> wajib hapus
  rm -rf "$BKDIR"
  echo "File sementara dihapus (keamanan + hemat 500MB disk)."
fi

if [[ "$MODE" == "2" ]]; then
  echo "--- Mode BARU ---"
  echo "Sebentar lagi muncul URL. Buka di HP/browser, login Cloudflare,"
  echo "pilih akun yang punya domain gtg.my.id, lalu klik Authorize."
  cloudflared tunnel login
  read -rp "Beri nama tunnel [gtg-tunnel]: " TUNNEL_NAME
  TUNNEL_NAME="${TUNNEL_NAME:-gtg-tunnel}"
  CREATE_OUT="$(cloudflared tunnel create "$TUNNEL_NAME" 2>&1)"
  echo "$CREATE_OUT"
  TUNNEL_ID="$(echo "$CREATE_OUT" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)"
  if [[ -z "$TUNNEL_ID" ]]; then echo "Gagal membaca Tunnel ID."; exit 1; fi
  echo "Tunnel ID kamu: $TUNNEL_ID  (catat baik-baik)"
  cp "$HOME/.cloudflared/${TUNNEL_ID}.json" "/etc/cloudflared/${TUNNEL_ID}.json"
  chmod 600 "/etc/cloudflared/${TUNNEL_ID}.json"
fi

echo "Tunnel ID aktif: $TUNNEL_ID"

# ==============================================================================
# STEP 3 — ROUTING DNS (menghubungkan nama domain -> tunnel)
# Konsep: 'cloudflared tunnel route dns' membuat record CNAME di Cloudflare:
#     gtg.my.id  ->  <tunnel-id>.cfargotunnel.com
# Artinya: setiap request ke gtg.my.id diteruskan Cloudflare masuk lewat
# tunnel kamu, lalu keluar di VPS. <tunnel-id>.cfargotunnel.com itu "pintu"
# khusus tunnel kamu di jaringan Cloudflare.
# Syarat perintah ini jalan: ada cert.pem (tanda pengenal akun). Mode 1
# mengambilnya dari backup, mode 2 dari 'tunnel login'. Kalau tidak ada,
# script menampilkan daftar CNAME untuk dibuat manual di dashboard.
# ==============================================================================
echo
echo "=== STEP 3/7 — Routing DNS ==="

INGRESS=""        # aturan hostname -> service lokal (ditulis ke config)
MANUAL_DNS=""     # teks CNAME untuk dibuat manual (kalau tanpa cert.pem)

# Fungsi bantu: routing DNS satu hostname (boleh "*.gtg.my.id" untuk wildcard)
route_dns() {
  local host="$1"
  if [[ -f "$HOME/.cloudflared/cert.pem" ]]; then
    echo "  route dns: $host -> ${TUNNEL_ID}.cfargotunnel.com"
    cloudflared tunnel route dns "$TUNNEL_ID" "$host" || true
  else
    MANUAL_DNS+="    CNAME  ${host}  ->  ${TUNNEL_ID}.cfargotunnel.com  (Proxy ON)\n"
  fi
}

# --- 3a. gtg.my.id (wajib) -> nginx aaPanel port 80 ---------------------------
echo "- gtg.my.id -> website (port 80)"
route_dns "gtg.my.id"
INGRESS+="$(printf '  - hostname: %s\n    service: %s\n' "gtg.my.id" "http://127.0.0.1:80")"

# --- 3b. www.gtg.my.id (opsional) ----------------------------------------------
read -rp "Tambahkan www.gtg.my.id juga? [y/N]: " ADD_WWW
if [[ "${ADD_WWW,,}" == "y" ]]; then
  route_dns "www.gtg.my.id"
  INGRESS+="$(printf '  - hostname: %s\n    service: %s\n' "www.gtg.my.id" "http://127.0.0.1:80")"
fi

# --- 3c. panel.gtg.my.id -> panel aaPanel ---------------------------------------
# Tidak perlu setting reverse-proxy di aaPanel: tunnel meneruskan request
# apa adanya ke program panel aaPanel di port panel.
echo
read -rp "Tambahkan panel.gtg.my.id untuk akses aaPanel? [y/N]: " ADD_PANEL
PANEL_PORT_USED=""
if [[ "${ADD_PANEL,,}" == "y" ]]; then
  # Coba baca port panel otomatis dari file data aaPanel
  DETECTED_PORT="$(cat /www/server/panel/data/port.pl 2>/dev/null || true)"
  if [[ -n "$DETECTED_PORT" ]]; then
    read -rp "Port panel terdeteksi ${DETECTED_PORT}. Enter = pakai, atau ketik lain: " PANEL_PORT_USED
    PANEL_PORT_USED="${PANEL_PORT_USED:-$DETECTED_PORT}"
  else
    read -rp "Ketik port panel aaPanel (lihat di pesan hasil install, mis. 7800): " PANEL_PORT_USED
  fi
  [[ -z "$PANEL_PORT_USED" ]] && { echo "Port kosong, dibatalkan."; exit 1; }
  # Panel aaPanel bisa HTTP biasa atau HTTPS (kalau SSL panel diaktifkan).
  # Kalau HTTPS, perlu noTLSVerify karena sertifikatnya self-signed.
  read -rp "Apakah panel aaPanel pakai HTTPS/SSL (gembok di browser)? [y/N]: " PANEL_HTTPS
  route_dns "panel.gtg.my.id"
  if [[ "${PANEL_HTTPS,,}" == "y" ]]; then
    INGRESS+="$(printf '  - hostname: panel.gtg.my.id\n    service: https://127.0.0.1:%s\n    originRequest:\n      noTLSVerify: true\n' "$PANEL_PORT_USED")"
    echo "  panel.gtg.my.id -> https://127.0.0.1:${PANEL_PORT_USED} (noTLSVerify)"
  else
    INGRESS+="$(printf '  - hostname: %s\n    service: %s\n' "panel.gtg.my.id" "http://127.0.0.1:${PANEL_PORT_USED}")"
    echo "  panel.gtg.my.id -> http://127.0.0.1:${PANEL_PORT_USED}"
  fi
fi

# --- 3d. WILDCARD *.gtg.my.id (subdomain otomatis) -------------------------------
# Konsep: satu record DNS "*.gtg.my.id" menangkap SEMUA subdomain yang belum
# ada record khususnya (toko.gtg.my.id, blog.gtg.my.id, coba123.gtg.my.id...).
# Semuanya diteruskan ke nginx aaPanel (port 80). Jadi besok kalau kamu tambah
# website baru di aaPanel (mis. "toko.gtg.my.id"), subdomain itu LANGSUNG bisa
# dibuka tanpa utak-atik tunnel / DNS lagi. aaPanel yang memilih website mana
# yang tampil berdasarkan nama host-nya (virtual host).
echo
read -rp "Tambahkan WILDCARD *.gtg.my.id (subdomain otomatis)? [Y/n]: " ADD_WILD
if [[ "${ADD_WILD,,}" != "n" ]]; then
  route_dns "*.gtg.my.id"
  INGRESS+="$(printf '  - hostname: %s\n    service: %s\n' "*.gtg.my.id" "http://127.0.0.1:80")"
  echo "  *.gtg.my.id -> nginx (port 80). Subdomain baru tinggal tambah di aaPanel."
fi

# ==============================================================================
# STEP 4 — TULIS config.yml
# Apa: file konfigurasi cloudflared. Bagian 'ingress' = daftar aturan tadi.
# Dibaca dari ATAS ke BAWAH, request dipakai aturan pertama yang cocok.
# Makanya urutannya: gtg.my.id, www, panel (spesifik) -> wildcard -> 404.
# Baris terakhir 'http_status:404' = kalau tidak ada yang cocok, tolak.
#
# Catatan: service ditulis 'http://...' (bukan https) karena:
#   - browser -> Cloudflare tetap HTTPS (aman),
#   - Cloudflare -> cloudflared lewat tunnel terenkripsi (aman),
#   - cloudflared -> nginx/panel di MESIN YANG SAMA tidak perlu TLS lagi.
#   (Pengecualian: panel yang SSL-nya aktif -> pakai https + noTLSVerify.)
# ==============================================================================
echo
echo "=== STEP 4/7 — Tulis /etc/cloudflared/config.yml ==="
[[ -f /etc/cloudflared/config.yml ]] && cp /etc/cloudflared/config.yml /etc/cloudflared/config.yml.bak
cat > /etc/cloudflared/config.yml <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: /etc/cloudflared/${TUNNEL_ID}.json
ingress:
${INGRESS}  - service: http_status:404
EOF
chmod 600 /etc/cloudflared/config.yml
echo "--- isi config ---"
cat /etc/cloudflared/config.yml
echo "------------------"

# ==============================================================================
# STEP 5 — JALANKAN SEBAGAI SERVICE (systemd)
# Apa: systemd = "mandor" layanan di Linux.
#   'cloudflared service install' = daftarkan cloudflared sebagai layanan.
#   'enable'  = otomatis jalan setiap VPS dinyalakan ulang.
#   'restart' = jalankan sekarang + pakai config terbaru.
# ==============================================================================
echo
echo "=== STEP 5/7 — Jalankan service cloudflared ==="
cloudflared service install 2>/dev/null || true
systemctl daemon-reload
systemctl enable cloudflared
systemctl restart cloudflared
sleep 3
systemctl --no-pager --lines=10 status cloudflared || true

# ==============================================================================
# STEP 6 — VERIFIKASI (memastikan semuanya benar-benar jalan)
# Tes 1: service cloudflared aktif?
# Tes 2: nginx aaPanel menjawab di port 80? (kalau tidak, website belum
#        ditambahkan di aaPanel -> tunnel jalan tapi halaman tidak muncul)
# ==============================================================================
echo
echo "=== STEP 6/7 — Verifikasi ==="
if systemctl is-active --quiet cloudflared; then
  echo "[OK] service cloudflared AKTIF"
else
  echo "[GAGAL] service cloudflared tidak aktif. Lihat: journalctl -u cloudflared -e"
fi
echo "-- tes nginx lokal --"
if curl -s -o /dev/null -w "HTTP %{http_code} dari http://127.0.0.1/\n" --max-time 10 http://127.0.0.1/; then
  :
else
  echo "[WARNING] nginx tidak menjawab di port 80."
  echo "  Pastikan website gtg.my.id sudah ditambahkan di aaPanel."
fi

# ==============================================================================
# STEP 7 — RINGKASAN AKHIR
# ==============================================================================
echo
echo "=== STEP 7/7 — SELESAI, ringkasan ==="
echo "Tes dari HP/browser:"
echo "  https://gtg.my.id"
[[ "${ADD_PANEL,,}" == "y" ]] && echo "  https://panel.gtg.my.id   (login pakai user/pass hasil install aaPanel)"
[[ "${ADD_WILD,,}" != "n" ]] && echo "  https://coba.gtg.my.id    (wildcard: subdomain apapun -> nginx)"
echo
if [[ -n "$MANUAL_DNS" ]]; then
  echo "Buat manual record berikut di dashboard Cloudflare"
  echo "(domain gtg.my.id > DNS > Add record):"
  echo -e "$MANUAL_DNS"
fi
echo "Catatan:"
echo "- Tunnel = koneksi outbound, TIDAK perlu buka port inbound di firewall."
echo "- Tunnel ID yang dipakai: $TUNNEL_ID (sama seperti tunnel lama)."
echo "- Config lama di backup juga punya: ai.gtg.my.id, wa.gtg.my.id,"
echo "  docker.gtg.my.id (untuk 9router/WAHA/dll). Itu belum diaktifkan karena"
echo "  servicenya belum diinstall di VPS baru — bisa ditambah nanti."
if [[ "${ADD_PANEL,,}" == "y" ]]; then
  echo "- Keamanan: port panel (${PANEL_PORT_USED}) tidak perlu dibuka ke internet"
  echo "  karena diakses lewat tunnel. Opsional, tutup via UFW:"
  echo "      sudo ufw deny ${PANEL_PORT_USED}/tcp"
  echo "  Lakukan HANYA setelah https://panel.gtg.my.id terbukti bisa dibuka,"
  echo "  biar tidak terkunci di luar. (Akses via localhost tetap jalan.)"
fi
echo "- Cek log tunnel kapan saja:  journalctl -u cloudflared -f"
