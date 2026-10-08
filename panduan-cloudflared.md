# Panduan: Cloudflare Tunnel di VPS Fresh (Ubuntu 24.04 + aaPanel)

Ditulis 2026-10-08 setelah instalasi berhasil. Tujuan: lain kali kamu bisa
melakukan sendiri tanpa bantuan.

---

## 1. Kenapa percobaanmu kemarin gagal

Ada 4 masalah, semuanya karena VPS-nya fresh install (kondisinya beda dari VPS lama):

1. **`pip: command not found` (line 125)**
   Penyebab: VPS fresh belum ada `pip`. Script versi pertama langsung
   manggil `pip install gdown` tanpa cek dulu.
   Solusi: install `python3-pip` dulu via apt, baru `python3 -m pip install gdown`.
   (Script di GitHub sudah diperbaiki.)

2. **"Masih sama" padahal script sudah diperbaiki**
   Penyebab: file yang dijalankan masih versi LAMA. Entah karena lupa
   download ulang (cuma jalanin `./install-cloudflared.sh` yang lama),
   atau hasil download ke-cache oleh CDN GitHub.
   Solusi: selalu hapus dulu (`rm -f install-cloudflared.sh`) lalu download
   ulang. Cek versinya dengan:
   `grep -c "python3-pip" install-cloudflared.sh` → harus keluar **3**.
   Kalau keluar 0, tambah `?v=2` di ujung URL biar lolos cache.

3. **`chown: invalid user: 'gtg:gtg'`**
   Penyebab: di VPS lama ada user `gtg`, di VPS baru ini belum dibuat —
   kamu login sebagai `root` semua. Jadi folder `/home/gtg/.ssh` tidak guna.
   Solusi: public key dipasang di `/root/.ssh/authorized_keys`, SSH pakai
   user `root`.

4. **Hal lain yang berubah di VPS fresh** (bukan error, tapi perlu tahu):
   - Port panel aaPanel sekarang **16260** (dulu 14314 — aaPanel generate
     acak tiap install). Cek selalu di `/www/server/panel/data/port.pl`.
   - Web server (nginx/apache) **belum diinstall** — aaPanel yang sekarang
     cuma panelnya saja. Akibatnya `gtg.my.id` masih 502 sampai kamu
     install Nginx/PHP/MySQL dari App Store + tambah website.

---

## 2. Yang aku lakukan di VPS (langkah per langkah)

SSH sebagai root (lewat proxy, port 20156):

**a. Survey kondisi dulu**
```bash
cloudflared --version                          # sudah ada: 2026.10.0
cat /www/server/panel/data/port.pl            # port panel -> 16260
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:16260/   # 302 = panel hidup (HTTP)
curl -sk -o /dev/null -w "%{http_code}\n" https://127.0.0.1:16260/ # 404 = panel TIDAK pakai HTTPS
ls /www/server/                                # tidak ada nginx -> web server belum diinstall
```

**b. Siapkan downloader backup**
```bash
apt-get install -y python3-pip
python3 -m pip install -q --break-system-packages gdown
mkdir -p /root/cf-restore && cd /root/cf-restore
python3 -m gdown 'https://drive.google.com/uc?id=109KuUQd47IVPW5hQkolvporNZDBH-6v6' -O backup.bin
```

**c. Decrypt backup (password diketik manual, TIDAK disimpan di mana pun)**
```bash
export BKPASS='(password decrypt backup)'
openssl enc -d -aes-256-cbc -pbkdf2 -in backup.bin -out backup.tar -pass env:BKPASS
unset BKPASS
```

**d. Ambil HANYA file tunnel dari arsip (tidak perlu extract semuanya)**
```bash
tar -xf backup.tar ./system/cloudflared-root/cert.pem \
  ./system/cloudflared-root/0580b22f-b087-48b5-924c-27dee7f132bb.json
```

**e. Pasang kredensial (permission 600 = hanya root yang bisa baca)**
```bash
TID=0580b22f-b087-48b5-924c-27dee7f132bb
install -m 600 ./system/cloudflared-root/$TID.json /etc/cloudflared/$TID.json
install -m 600 ./system/cloudflared-root/cert.pem /etc/cloudflared/cert.pem
mkdir -p /root/.cloudflared
install -m 600 ./system/cloudflared-root/cert.pem /root/.cloudflared/cert.pem
```

**f. Tulis config `/etc/cloudflared/config.yml`**
```yaml
tunnel: 0580b22f-b087-48b5-924c-27dee7f132bb
credentials-file: /etc/cloudflared/0580b22f-b087-48b5-924c-27dee7f132bb.json

ingress:
  - hostname: gtg.my.id
    service: http://127.0.0.1:80
  - hostname: www.gtg.my.id
    service: http://127.0.0.1:80
  - hostname: panel.gtg.my.id
    service: http://127.0.0.1:16260
  - hostname: "*.gtg.my.id"
    service: http://127.0.0.1:80
  - service: http_status:404
```
Urutan penting: yang spesifik dulu, wildcard belakangan, paling akhir 404.
Lalu validasi: `cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate`
(harus keluar `OK`).

**g. Routing DNS** (pakai cert.pem, jadi TANPA login browser)
```bash
TID=0580b22f-b087-48b5-924c-27dee7f132bb
cloudflared tunnel route dns $TID gtg.my.id
cloudflared tunnel route dns $TID www.gtg.my.id
cloudflared tunnel route dns $TID panel.gtg.my.id
cloudflared tunnel route dns $TID '*.gtg.my.id'
```

**h. Install & jalankan sebagai service**
```bash
cloudflared service install
systemctl enable --now cloudflared
```

**i. Verifikasi**
```bash
systemctl is-active cloudflared                        # harus: active
journalctl -u cloudflared --no-pager | grep "Registered tunnel"
# harus ada 4 baris "Registered tunnel connection" (sin/cgk = Singapore/Jakarta)
```
Dari luar (HP/laptop):
- `https://panel.gtg.my.id` → halaman login aaPanel (tadi dapat HTTP 302)
- `https://gtg.my.id` → 502 itu WAJAR kalau web server belum diinstall

**j. Bersih-bersih (PENTING — jangan sampai ketinggalan)**
```bash
rm -rf /root/cf-restore   # hapus backup.bin + hasil decrypt!
```

**k. Keamanan panel (lanjutan setting VPS lama)**
```bash
ufw limit 16260/tcp   # rate-limit anti brute-force, bukan blokir
```

---

## 3. File-file penting (di VPS)

| File | Isi |
|---|---|
| `/etc/cloudflared/config.yml` | Routing hostname → port lokal |
| `/etc/cloudflared/0580b22f-....json` | Kredensial tunnel (rahasia, 600) |
| `/etc/cloudflared/cert.pem` | Sertifikat akun Cloudflare (untuk `route dns`) |
| `/root/.cloudflared/cert.pem` | Copy untuk perintah manual |
| Service `cloudflared` (systemd) | Jalan otomatis tiap boot |

---

## 4. Cara cepat lain kali (pakai script)

Script sudah diperbaiki dan ada di repo publik:
https://github.com/diyansantoso26/vps-scripts/blob/main/install-cloudflared.sh

Satu baris di VPS sebagai root:
```bash
rm -f install-cloudflared.sh
curl -fsSL "https://raw.githubusercontent.com/diyansantoso26/vps-scripts/main/install-cloudflared.sh" -o install-cloudflared.sh
grep -c "python3-pip" install-cloudflared.sh   # harus 3, kalau 0 tambah ?v=2 di URL
chmod +x install-cloudflared.sh && sudo ./install-cloudflared.sh
```
Pilih mode 1 (restore otomatis), siapkan password decrypt backup.

---

## 5. Yang masih perlu kamu lakukan

1. Buka `https://panel.gtg.my.id` → login aaPanel.
2. App Store → install **Nginx**, **PHP**, **MySQL** (satu-satu, tunggu selesai).
3. Menu Website → Add site → domain `gtg.my.id`.
4. Setelah itu `https://gtg.my.id` akan tampil (bukan 502 lagi).
5. (Opsional) Kalau mau website lama dikembalikan, file + database-nya ada
   di backup — tinggal bilang, nanti direstore sekalian.
