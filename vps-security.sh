#!/usr/bin/env bash
#
# vps-security.sh — Sistem keamanan dasar untuk VPS (Ubuntu 22.04 / 24.04)
#
# Dijalankan SEKALI sebagai root di VPS BARU (bukan VPS yang sudah jalan).
# Idempoten: aman dijalankan ulang.
#
# Yang dilakukan:
#   1. Update sistem
#   2. User non-root + sudo (opsional)
#   3. SSH hardening (hanya matikan password JIKA ssh key sudah terpasang!)
#   4. Firewall UFW (default tolak masuk, izinkan SSH/HTTP/HTTPS + port pilihan)
#   5. fail2ban (blokir brute-force SSH & nginx)
#   6. unattended-upgrades (update keamanan otomatis)
#   7. Sysctl hardening (anti IP-spoofing, SYN-flood, dsb.)
#   8. rkhunter (pemindai rootkit + cron mingguan)
#
# Cara pakai:
#   chmod +x vps-security.sh
#   sudo ./vps-security.sh
#
# CATATAN PENTING:
#   - Jangan jalankan di VPS yang memakai aaPanel tanpa baca penjelasan dulu
#     (aaPanel punya firewall sendiri; lihat dokumen pendamping).
#   - Script TIDAK akan mematikan login password sebelum SSH key terpasang.
#     Kalau kamu skip key, password tetap bisa dipakai (kamu yang putuskan).

set -euo pipefail

# ---------- helper ----------
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok()   { echo -e "\e[1;32m[OK]\e[0m $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
fail() { echo -e "\e[1;31m[FAIL]\e[0m $*"; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "Jalankan sebagai root (sudo ./vps-security.sh)."
command -v lsb_release >/dev/null 2>&1 || apt-get update -qq && apt-get install -y -qq lsb-release
OS_VER="$(lsb_release -rs)"
[[ "$OS_VER" == "22.04" || "$OS_VER" == "24.04" ]] || warn "Belum diuji di Ubuntu $OS_VER, lanjut dengan risiko sendiri."

info "=== 1/8 Update sistem ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
ok "Sistem up-to-date."

# ---------- 2. user non-root (opsional) ----------
info "=== 2/8 User non-root ==="
read -rp "Buat user non-root baru? (nama user / kosongkan = skip): " NEW_USER
if [ -n "$NEW_USER" ]; then
  if id "$NEW_USER" >/dev/null 2>&1; then
    info "User $NEW_USER sudah ada, skip pembuatan."
  else
    adduser --disabled-password --gecos "" "$NEW_USER"
    usermod -aG sudo "$NEW_USER"
    ok "User $NEW_USER dibuat + grup sudo."
  fi
  LOGIN_USER="$NEW_USER"
else
  LOGIN_USER="root"
  warn "Pakai root langsung — pastikan SSH key root terpasang (langkah 3)."
fi
USER_HOME="$(eval echo "~$LOGIN_USER")"

# ---------- 3. SSH hardening ----------
info "=== 3/8 SSH hardening ==="
SSH_PUBKEY=""
if [ -f "$USER_HOME/.ssh/authorized_keys" ] && grep -qE '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+) ' "$USER_HOME/.ssh/authorized_keys" 2>/dev/null; then
  info "SSH key sudah terpasang untuk $LOGIN_USER."
  SSH_PUBKEY="exists"
else
  echo "Tempel SSH PUBLIC KEY (satu baris, diawali ssh-ed25519/ssh-rsa)."
  echo "Kosongkan jika belum punya — login password TIDAK akan dimatikan."
  read -rp "SSH public key: " SSH_PUBKEY
  if [ -n "$SSH_PUBKEY" ]; then
    [[ "$SSH_PUBKEY" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+)[[:space:]][A-Za-z0-9+/=]+$ ]] \
      || fail "Format key tidak valid."
    mkdir -p "$USER_HOME/.ssh"; chmod 700 "$USER_HOME/.ssh"
    echo "$SSH_PUBKEY" >> "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R "$LOGIN_USER:$LOGIN_USER" "$USER_HOME/.ssh"
    ok "SSH key terpasang untuk $LOGIN_USER."
  fi
fi

SSHD_CFG="/etc/ssh/sshd_config"
cp -n "$SSHD_CFG" "${SSHD_CFG}.bak-security-$(date +%F)" 2>/dev/null || true

set_sshd() { # $1=key $2=value
  if grep -qE "^#?${1}\b" "$SSHD_CFG"; then
    sed -i -E "s|^#?${1}\b.*|${1} ${2}|" "$SSHD_CFG"
  else
    echo "${1} ${2}" >> "$SSHD_CFG"
  fi
}

# Opsi aman yang selalu diterapkan:
set_sshd "PermitRootLogin" "prohibit-password"   # root hanya via key, tak bisa password
set_sshd "X11Forwarding" "no"
set_sshd "MaxAuthTries" "3"
set_sshd "LoginGraceTime" "30"
set_sshd "ClientAliveInterval" "300"
set_sshd "ClientAliveCountMax" "2"

if [ -n "$SSH_PUBKEY" ]; then
  set_sshd "PasswordAuthentication" "no"
  set_sshd "ChallengeResponseAuthentication" "no"
  set_sshd "UsePAM" "yes"
  ok "Login password SSH DIMATIKAN (key-only)."
else
  warn "Tidak ada SSH key — login password tetap AKTIF. Pasang key lalu jalankan ulang script."
fi

sshd -t || fail "Konfigurasi sshd tidak valid, dibatalkan."
systemctl restart sshd
ok "SSH diamankan."

# ---------- 4. Firewall UFW ----------
info "=== 4/8 Firewall UFW ==="
apt-get install -y -qq ufw
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
read -rp "Port TCP tambahan yang dibuka (mis. 20156 / kosongkan): " EXTRA_PORTS
for p in $EXTRA_PORTS; do
  [[ "$p" =~ ^[0-9]+$ ]] && ufw allow "$p"/tcp && info "Port $p dibuka."
done
ufw --force enable
ufw status numbered | head -15
ok "Firewall aktif."

# ---------- 5. fail2ban ----------
info "=== 5/8 fail2ban ==="
apt-get install -y -qq fail2ban
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime  = 1h
findtime  = 10m
maxretry  = 5
banaction = ufw

[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port    = http,https
filter  = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
EOF
systemctl enable --now fail2ban
ok "fail2ban aktif (blokir brute-force SSH & login nginx)."

# ---------- 6. unattended-upgrades ----------
info "=== 6/8 Update keamanan otomatis ==="
apt-get install -y -qq unattended-upgrades apt-listchanges
cat > /etc/apt/apt.conf.d/51unattended-upgrades-security <<'EOF'
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
  "${distro_id}ESMApps:${distro_codename}-apps-security";
  "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
cat > /etc/apt/apt.conf.d/52unattended-upgrades-timer <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable --now unattended-upgrades
ok "Update keamanan otomatis aktif (tanpa reboot otomatis)."

# ---------- 7. sysctl hardening ----------
info "=== 7/8 Sysctl hardening ==="
cat > /etc/sysctl.d/99-vps-security.conf <<'EOF'
# Anti IP-spoofing & redirect jahat
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
# Anti SYN-flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
# Abaikan broadcast ping & bogus error
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
sysctl --system >/dev/null
ok "Kernel hardening diterapkan."

# ---------- 8. rkhunter ----------
info "=== 8/8 rkhunter (pemindai rootkit) ==="
apt-get install -y -qq rkhunter
rkhunter --update >/dev/null 2>&1 || warn "rkhunter --update gagal (mungkin offline), lanjut."
rkhunter --propupd >/dev/null 2>&1 || true
# cron mingguan: scan tiap Senin jam 03:30, hasil ke /var/log/rkhunter-weekly.log
cat > /etc/cron.d/rkhunter-weekly <<'EOF'
30 3 * * 1 root /usr/bin/rkhunter --cronjob --report-warnings-only --nocolors >> /var/log/rkhunter-weekly.log 2>&1
EOF
ok "rkhunter terpasang + scan mingguan dijadwalkan."

# ---------- ringkasan ----------
echo ""
echo "=============================================="
echo "  KEAMANAN VPS SELESAI"
echo "=============================================="
echo "- User login      : $LOGIN_USER"
echo "- SSH password    : $([ -n "$SSH_PUBKEY" ] && echo "MATI (key-only)" || echo "MASIH AKTIF (segera pasang key!)")"
echo "- Firewall (UFW)  : aktif, default tolak masuk"
echo "- fail2ban        : aktif (SSH + nginx-auth)"
echo "- Auto-update     : update keamanan otomatis harian"
echo "- Sysctl          : anti-spoofing & SYN-flood aktif"
echo "- rkhunter        : scan rootkit tiap Senin 03:30"
echo ""
echo "UJI SEBELUM TUTUP SESI INI:"
echo "  1. Buka terminal BARU, coba login via SSH key."
echo "  2. Kalau gagal JANGAN tutup sesi ini — perbaiki dulu."
echo "  3. Cek: sudo ufw status | sudo fail2ban-client status sshd"
echo "=============================================="
