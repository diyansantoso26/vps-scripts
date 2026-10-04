# Sistem Keamanan VPS — Penjelasan

Pendamping `vps-security.sh`. Ditulis untuk VPS Ubuntu 22.04/24.04 yang baru.
**Jangan jalankan di VPS yang sudah produksi (mis. yang ada aaPanel-nya) tanpa baca bagian "Kapan JANGAN dipakai" di bawah.**

---

## Cara pakai

1. Upload ke VPS baru sebagai root.
2. `chmod +x vps-security.sh`
3. `sudo ./vps-security.sh`
4. Ikuti prompt (nama user, SSH public key, port tambahan).
5. **PENTING:** setelah selesai, buka terminal **baru** dan coba login SSH dulu.
   Kalau gagal, jangan tutup sesi lama — perbaiki dari sana.

Script ini idempoten: aman dijalankan ulang kalau ada langkah yang ke-skip.

---

## 8 lapisan keamanan (dan kenapa perlu)

### 1. Update sistem
Menutup celah keamanan yang sudah ditambal Ubuntu. Prinsipnya: kebanyakan
server diretas lewat celah *lama* yang belum di-update, bukan teknik canggih.

### 2. User non-root (opsional)
Operasional harian pakai user biasa + `sudo`, bukan root langsung. Kalau
kredensial user bocor, penyerang tetap butuh `sudo` (butuh password lagi)
sebelum bisa merusak sistem.

### 3. SSH hardening — lapisan paling penting
- **Login password dimatikan, hanya SSH key** — tapi *hanya* kalau key sudah
  terpasang. Script tidak akan mengunci kamu keluar: tanpa key, password
  tetap aktif dan kamu dapat peringatan keras.
- `PermitRootLogin prohibit-password` — root tidak bisa login pakai password.
- `MaxAuthTries 3` + `LoginGraceTime 30` — mempersempit jendela brute-force.
- Backup otomatis `sshd_config` sebelum diubah; `sshd -t` memvalidasi
  sebelum restart (konfigurasi rusak = SSH mati total).

### 4. Firewall UFW
Prinsip *default-deny*: semua koneksi masuk **ditolak** kecuali yang
diizinkan eksplisit (SSH, HTTP, HTTPS, + port pilihanmu). Urutan di script
sudah benar: aturan SSH dipasang **sebelum** firewall dinyalakan, jadi tidak
ada momen terkunci di luar.

### 5. fail2ban
Memblokir IP yang gagal login berkali-kali (default: 5x gagal dalam 10 menit
→ diblokir 1 jam). Melindungi SSH dan halaman login nginx (basic auth).
Cek status: `sudo fail2ban-client status sshd`.

### 6. Update keamanan otomatis (unattended-upgrades)
Patch keamanan Ubuntu dipasang otomatis tiap hari, **tanpa reboot otomatis**
(reboot bisa mematikan layanan; kamu yang jadwalkan manual). Membersihkan
dependensi tak terpakai tiap minggu.

### 7. Sysctl hardening (level kernel)
- `rp_filter` — menolak paket dengan alamat sumber palsu (anti IP-spoofing).
- Menolak ICMP redirect — mencegah penyerang membelokkan rute paketmu.
- `tcp_syncookies` — bertahan dari serangan SYN-flood (banjir koneksi
  setengah-jadi yang menghabiskan memory).
- Abaikan ping broadcast — mengurangi visibilitas dari pemindaian massal.

### 8. rkhunter (pemindai rootkit)
Memindai tanda-tanda rootkit/backdoor tiap Senin jam 03:30, hasilnya di
`/var/log/rkhunter-weekly.log`. Ini *deteksi*, bukan *pencegahan* — seperti
CCTV: tidak menghentikan maling, tapi kamu tahu kalau ada yang masuk.

---

## Yang TIDAK dilakukan script ini (sengaja)

- **Tidak mengganti port SSH** — port non-standar hanya mengurangi *noise*,
  bukan menambah keamanan nyata, tapi menambah risiko salah konfigurasi.
  fail2ban sudah cukup.
- **Tidak memasang antivirus real-time** — di server Linux, antivirus
  real-time jarang sepadan dengan beban CPU-nya untuk VPS kecil.
- **Tidak menonaktifkan IPv6** — malah di-hardening (redirect ditolak).
- **Tidak ada backup** — keamanan ≠ backup. Itu pekerjaan terpisah
  (dan tetap wajib).

---

## Kapan JANGAN dipakai / perlu penyesuaian

- **VPS dengan aaPanel** — aaPanel punya firewall dan manajemen port sendiri.
  Menjalankan UFW + `ufw --force reset` di sana bisa menutup port yang
  aaPanel butuhkan. Untuk VPS aaPanel: pakai *hanya* bagian SSH hardening
  dan fail2ban, lewati UFW (atau kelola port lewat panel aaPanel).
- **VPS dengan Docker** — UFW dan Docker terkenal tidak akur: Docker
  mem-bypass UFW via iptables langsung. Kalau VPS-nya menjalankan Docker,
  aturan UFW tidak berlaku untuk port yang di-publish container. Solusinya:
  bind container ke `127.0.0.1` dan expose via reverse proxy, atau atur
  `iptables: false` di `/etc/docker/daemon.json` (tapi itu memutus akses
  container ke internet — pahami dulu sebelum pakai).
- **Cloud firewall** — kalau provider (mis. firewall di panel provider)
  sudah memfilter port, UFW jadi lapisan kedua. Tidak masalah, tapi jangan
  sampai aturan bertentangan dan kamu bingung sendiri.

---

## Setelah script jalan: kebiasaan yang lebih penting dari script

1. **Jangan pakai password yang sama** di banyak tempat; SSH key + passphrase.
2. **Cek log berkala**: `sudo grep "Failed" /var/log/auth.log | tail`.
3. **Reboot terjadwal** tiap 1–2 bulan untuk menerapkan patch kernel
   (unattended-upgrades tidak reboot otomatis — itu tugasmu).
4. **Backup** sebelum upgrade besar. Selalu.
5. Kalau suatu hari butuh buka port baru: `sudo ufw allow <port>/tcp`,
   jangan matikan firewall-nya.
