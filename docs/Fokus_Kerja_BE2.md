# 📋 PANDUAN FOKUS KERJA & LIVING CONTRACT — BE-2
# Ekosistem Wisata Pintar Sumatera Barat (Rancak.in)

> **Status Dokumen**: *Living Document* (Dapat diperbarui sewaktu-waktu mengikuti kesepakatan integrasi tim).  
> **Terakhir Diperbarui**: 2026-11-13  
> **Pemegang Peran**: **BE-2 (Backend 2 — Grup, Mitra, Escrow & Gamifikasi)**  
> **Branch Git**: `Backend-2`  
> **Direktori Kerja Utama**: [`backend/internal/be2_group/`](file:///D:/WISGO/backend/internal/be2_group/handlers.go)  
> **Stack Teknologi**: Go 1.22+ (`net/http` / Gin) + PostgreSQL

---

## 01. Batasan Tanggung Jawab (Zero Merge Conflict)

Untuk menjaga prinsip zero merge conflict dengan 4 developer lainnya:
- **Area Eksklusif BE-2**: Folder [`backend/internal/be2_group/`](file:///D:/WISGO/backend/internal/be2_group/) serta migrasi tabel sosial, trip, mitra, dan escrow.
- **Area Bersama (Koordinasi)**: 
  - [`backend/cmd/api/main.go`](file:///D:/WISGO/backend/cmd/api/main.go) (Registrasi route BE-2)
  - [`backend/internal/models/models.go`](file:///D:/WISGO/backend/internal/models/models.go) (Penambahan struct BE-2)
  - [`backend/internal/database/db.go`](file:///D:/WISGO/backend/internal/database/db.go) (Pool koneksi PostgreSQL)
- **Bukan Ranah BE-2 (Milik BE-1)**: Folder `backend/internal/be1_core/`, query spasial PostGIS ST_Buffer (Shunlu), Peta Mikro, CRUD Destinasi dasar, Hotspot 360, dan Tiket Lapor Pungli.

---

## 02. Log Perubahan Fitur & Sinkronisasi Tim (Change Log)

*Tabel ini wajib diperbarui setiap kali ada penyesuaian request endpoint atau payload dari rekan tim (FE-2, FS-1, atau BE-1).*

| Tanggal | Fitur / Endpoint Terdampak | Rekan Terkait | Ringkasan Perubahan & Alasan | Status |
| :--- | :--- | :--- | :--- | :--- |
| 2026-11-13 | Inisialisasi Kontrak 24 Endpoint | Tim 5 Dev | Pemetaan awal sesuai PRD v1.0 & API Contract | **Aktif** |
| 2026-11-13 | Penyelesaian Sprint Minggu 3 (Escrow & WA Bot) | BE-2 | Integrasi Escrow state machine, Bot WA 1/0, Split-bill, & Group Radar (18 Unit Tests PASS) | **Selesai 100%** |
| 2026-11-13 | Penyelesaian Sprint Minggu 4 & Finalisasi Kontrak 24 Endpoint | BE-2 | Integrasi Paspor Digital Minang (Haversine Anti-Fake GPS <= 200m), Sertifikat Gubernur Sumbar & Analitik Dispar 19 Kab/Kota (22 Unit Tests PASS) | **Selesai 100% (Final)** |

---

## 03. Kepemilikan 12 Tabel Database PostgreSQL

| No | Nama Tabel | Deskripsi & Keterangan Kunci | Relasi Luar | Status Migrasi |
| :---: | :--- | :--- | :--- | :---: |
| 1 | `users` | Akun wisatawan & nomor HP untuk OTP | - | ✅ DDL Ready |
| 2 | `saved_places` | Bookmark/favorit destinasi wisatawan | `destinations(id)` [BE-1] | ✅ DDL Ready |
| 3 | `itineraries` | Master rencana perjalanan 7 hari | `users(id)` | ✅ DDL Ready |
| 4 | `itinerary_items` | Rincian per jam, hari ke-N & destinasi | `itineraries(id)`, `destinations(id)` | ✅ DDL Ready |
| 5 | `group_rooms` | Ruang koordinasi rombongan (`room_code` unik) | `users(leader_id)` | ✅ DDL Ready |
| 6 | `group_members` | Daftar anggota dalam group room | `group_rooms(id)`, `users(id)` | ✅ DDL Ready |
| 7 | `group_votes` | Hasil voting live destinasi/homestay | `group_rooms(id)`, `destinations(id)` | ✅ DDL Ready |
| 8 | `partners` | 5 Kategori Mitra Minang (+ `spicy_level` 0-5) | - | ✅ DDL Ready |
| 9 | `booking_escrows` | Ledger rekening bersama & status tiket QR | `partners(id)`, `users(id)` | ✅ DDL Ready |
| 10 | `community_places`| Tempat baru usulan wisatawan (masking radius) | `users(id)` | ✅ DDL Ready |
| 11 | `shared_trips` | Papan cari barengan / patungan sewa mobil | `users(id)` | ✅ DDL Ready |
| 12 | `digital_passports`| Stempel check-in GPS $\le 200\text{ m}$ & sertifikat | `users(id)`, `destinations(id)` | ✅ DDL Ready |

---

## 04. Matriks 24 Endpoint REST API (Kontrak Kerja BE-2)

### A. Klaster Autentikasi & Pengguna (Partner: FE-2)
- [x] `POST /api/v1/auth/request-otp` — Kirim 4 digit OTP via SMS/WA simulasi.
- [x] `POST /api/v1/auth/verify-otp` — Validasi OTP & cetak token JWT.
- [x] `GET /api/v1/users/saved` — Ambil daftar tempat tersimpan wisatawan.
- [x] `POST /api/v1/users/saved` — Toggle simpan/hapus tempat favorit.

### B. Klaster Trip Planner & Private Group Room (Pilar 4 — Partner: FE-2)
- [x] `GET /api/v1/itineraries` — Riwayat rencana trip pengguna.
- [x] `POST /api/v1/itineraries` — Simpan rencana trip 7 hari manual.
- [x] `POST /api/v1/itineraries/auto-generate` — Generator itinerary pintar sesuai preferensi rombongan.
- [x] `POST /api/v1/groups` — Buat Group Room baru & terbitkan `room_code` tautan WhatsApp.
- [x] `GET /api/v1/groups/{code}` — Ambil info rombongan, leader, dan anggota.
- [x] `POST /api/v1/groups/{code}/join` — Gabung ke ruang rombongan via tautan link WA.
- [x] `POST /api/v1/groups/{code}/vote` — Submit voting destinasi/homestay live.
- [x] `GET /api/v1/groups/{code}/results` — Rekapitulasi voting persentase real-time.
- [x] `POST /api/v1/groups/{code}/split-bill` — Kalkulator bagi rata tagihan (homestay/sewa mobil).
- [x] `POST & GET /api/v1/groups/{code}/radar` — Menerima ping lokasi koordinat anggota & monitor Group Radar.

### C. Klaster Mitra Nagari, Quick Booking & Escrow (Pilar 5 — Partner: FE-2 & FS-1)
- [x] `GET /api/v1/partners` — Katalog mitra 5 kategori (+ level pedas kuliner).
- [x] `GET /api/v1/partners/detail` — Detail profil mitra & tarif resmi paket.
- [x] `POST /api/v1/bookings/create` — Booking via Quick Drawer 360° (Dana dikunci di Escrow).
- [x] `POST /api/v1/bookings/wa-webhook` — Simulator respon WhatsApp mitra (`1` Terima, `0` Tolak).
- [x] `GET /api/v1/bookings/{id}/ticket-qr` — Terbitkan QR E-Ticket setelah dikonfirmasi mitra.
- [x] `POST /api/v1/escrow/scan-redeem` — Scan QR oleh mitra saat tamu tiba untuk pencairan dana.
- [x] `GET /api/v1/escrow/currency/myr-rate` — Kurs konversi MYR ke IDR (Wisatawan Malaysia).

### D. Klaster Komunitas, Gamifikasi & Analitik Dispar (Pilar 6 & 8 — Partner: FE-2 & FS-1)
- [x] `POST /api/v1/community/places` — Pengajuan tempat baru (wajib tips & masking koordinat).
- [x] `GET /api/v1/community/places` — Daftar tempat komunitas dalam antrean kurasi Pokdarwis.
- [x] `GET & POST /api/v1/community/shared-trips` — Papan "Cari Barengan" untuk patungan transportasi.
- [x] `POST /api/v1/gamification/checkin` — Validasi check-in GPS $\le 200\text{ m}$ (Anti-Fake GPS).
- [x] `GET /api/v1/gamification/passport` — Rekap stempel Paspor Digital Minang (10 titik ikonik).
- [x] `POST /api/v1/gamification/certificate` — Generator Sertifikat Digital resmi Gubernur Sumbar.
- [x] `GET /api/v1/analytics/dispar/summary` — Agregasi metrik kunjungan & ekonomi UMKM nagari.

---

## 05. Checklist Roadmap Sprint 4 Minggu

### 🚀 MINGGU 1 (Fondasi & Auth) — Target Selesai 100%
- [x] Setup skrip DDL SQL untuk 12 tabel BE-2 (termasuk 4 tabel utama: `users`, `saved_places`, `itineraries`, `partners` di `backend/migrations/000002_be2_schema.sql`).
- [x] Buat data seeder untuk 5 kategori mitra nagari (Homestay, Kuliner, Transport, Baju Adat, Pokdarwis di `backend/migrations/000002_be2_seeders.sql`).
- [x] Implementasi service & handler fungsional `RequestOTP` & `VerifyOTP` (Lolos Unit Test).
- [x] Implementasi endpoint `GET /api/v1/partners` & `GET /api/v1/partners/detail` (Lolos Unit Test).
- [x] Implementasi endpoint `GET & POST /api/v1/users/saved` (Lolos Unit Test).

### 📦 MINGGU 2 (Itinerary & Private Group Room) — Target Selesai 100%
- [x] Implementasi algoritma `POST /api/v1/itineraries/auto-generate` (Lolos Unit Test).
- [x] Implementasi alur Group Room (`POST /api/v1/groups` & `GET /api/v1/groups/detail`) (Lolos Unit Test).
- [x] Implementasi live voting rombongan (`/vote` & `/results`) (Lolos Unit Test).
- [x] Implementasi `POST /api/v1/community/places` dengan algoritma masking koordinat sensitif (Lolos Unit Test).

### 💰 MINGGU 3 (Escrow, Bot WhatsApp 1/0 & Split-Bill) — Target Selesai 100%
- [x] Implementasi state machine Escrow: `PENDING_WA` $\to$ `CONFIRMED` $\to$ `ESCROW_LOCKED` $\to$ `REDEEMED` / `REFUNDED` (Lolos Unit Test).
- [x] Implementasi Webhook Bot WhatsApp (`1` Terima, `0` Tolak) (Lolos Unit Test).
- [x] Integrasi Scan QR E-Ticket untuk pencairan dana escrow (`scan-redeem`) (Lolos Unit Test).
- [x] Implementasi logika Split-Bill rombongan dan feed Group Live Radar (Lolos Unit Test).
- [x] Implementasi Papan Shared Trips & konversi kurs MYR/IDR (Lolos Unit Test).

### 🏆 MINGGU 4 (Paspor Digital $\le 200\text{ m}$, Sertifikat & Analitik Dispar) — Target Selesai 100% (Final)
- [x] Validasi formula Haversine geofence $\le 200\text{ m}$ pada `gamification/checkin` (Anti-Fake GPS) (Lolos Unit Test).
- [x] Logika penentuan kelulusan 10 stempel & penerbitan sertifikat digital resmi Gubernur Sumbar (Lolos Unit Test).
- [x] Agregasi kueri analitik Dispar (total transaksi UMKM, heatmap kepadatan 19 Kab/Kota, scan QR) (Lolos Unit Test).
- [x] Uji performa & penutupan sprint 4 Minggu (22/22 Unit Tests PASS, Go Build Exit Code 0).

---

## 06. Protokol Manajemen Perubahan (Bila Ada Penyesuaian Tim)

Jika rekan tim meminta perubahan:
1. **Perubahan Field/JSON**: Perbarui struct di `models.go`, lalu catat perubahannya di tabel **02. Log Perubahan Fitur**.
2. **Penambahan Endpoint Baru**: Tambahkan ke sub-bab **04. Matriks 24 Endpoint REST API** dengan label `[Baru - Permintaan FE-2/FS-1]`.
3. **Konflik Scope**: Rujuk kembali ke batasan modular di sub-bab **01**. Pastikan tidak menimpa logika BE-1 di `be1_core/`.

