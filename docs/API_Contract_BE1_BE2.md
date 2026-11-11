# KONTRAK REST API & SPESIFIKASI ENDPOINT
# Ekosistem Wisata Pintar Sumatera Barat (Rancak.in)

Dokumen ini menjadi acuan sinkronisasi antara Backend (BE-1 & BE-2), Mobile (FE-1 & FE-2), dan Web Admin (FS-1).
Prefix URL: `/api/v1`

---

## BE-1: Core & Spasial (Total ~24 Endpoint)

### 1. Destinasi & Kesiapan Medan (Pilar 1 & 3)
- `GET /api/v1/destinations` — Daftar destinasi (filter kategori, search, sort).
- `GET /api/v1/destinations/:id` — Detail destinasi lengkap (4 Statistik, 5 Indikator Medan, Tips).
- `POST /api/v1/destinations` — Buat destinasi baru (Admin/FS-1).
- `PUT /api/v1/destinations/:id` — Perbarui data destinasi & tarif Perda (Admin/FS-1).
- `DELETE /api/v1/destinations/:id` — Hapus destinasi (Admin/FS-1).
- `GET /api/v1/destinations/:id/offline-bundle` — Paket data offline (JSON info + manifest aset mikro).

### 2. Panorama 360° & Hotspot 4 Pin (Pilar 1)
- `GET /api/v1/destinations/:id/scenes-360` — Ambil scene udara & darat (Multi-Spot).
- `POST /api/v1/scenes-360` — Unggah scene 360° baru (Admin/FS-1).
- `GET /api/v1/scenes-360/:scene_id/hotspots` — Ambil pin 4 jenis (Navigasi, Audio, Fasilitas, Mitra).
- `POST /api/v1/scenes-360/:scene_id/hotspots` — Simpan koordinat pin (pitch & yaw) via CMS (FS-1).
- `DELETE /api/v1/scenes-360/hotspots/:id` — Hapus pin hotspot.

### 3. Navigasi Spasial, Shunlu & Peta Mikro (Pilar 2)
- `GET /api/v1/spatial/nearby` — Query lokasi terdekat (ST_DWithin).
- `POST /api/v1/spatial/shunlu` — Search sepanjang koridor rute aktif (ST_Buffer) + kalkulasi detour `+X mnt (Y m)`.
- `GET /api/v1/destinations/:id/micro-map` — Data GeoJSON peta mikro kawasan pejalan kaki.
- `POST /api/v1/routes/optimize-tsp` — Menyusun 3–10 titik destinasi paling efisien (TSP tanjakan & jam).
- `GET /api/v1/rankings/gaode` — Behavior-based ranking (dwell time + navigasi aktif).

### 4. Tarif Perda, Lapor Pungli & Jalur Ekstrem (Pilar 3 & 7)
- `GET /api/v1/destinations/:id/tariffs` — Tabel tarif resmi Perda/Nagari (Fair-Price Barometer).
- `POST /api/v1/pungli/report` — Lapor pungli anonim (multipart: foto karcis/oknum, GPS, keterangan).
- `GET /api/v1/pungli/reports` — Daftar tiket aduan pungli (Satgas FS-1).
- `PATCH /api/v1/pungli/reports/:id/status` — Ubah status aduan (Masuk → Diverifikasi → Ditindaklanjuti → Selesai).
- `GET /api/v1/hazards/active` — Alert peringatan dini jalur rawan (Sitinjau Lauik, Lembah Anai, Kelok 9).
- `POST /api/v1/hazards/sos` — Kirim sinyal darurat SOS GPS ke SAR/Pokdarwis.
- `GET /api/v1/culture/audio-phrases` — Kamus saku frasa audio Minang & kalender budaya.

---

## BE-2: Grup, Mitra, Escrow & Komunitas (Total ~24 Endpoint)

### 1. Autentikasi & Profil Pengguna (FE-2)
- `POST /api/v1/auth/request-otp` — Kirim kode OTP 4 digit via SMS/WA.
- `POST /api/v1/auth/verify-otp` — Verifikasi OTP & cetak token JWT.
- `GET /api/v1/users/saved` — Daftar tempat tersimpan/favorit wisatawan.
- `POST /api/v1/users/saved/:destination_id` — Tambah/hapus tempat dari koleksi.

### 2. Trip Planner & Private Group Room (Pilar 4)
- `GET /api/v1/itineraries` — Riwayat rencana perjalanan 7 hari.
- `POST /api/v1/itineraries` — Buat itinerary manual.
- `POST /api/v1/itineraries/auto-generate` — Auto-generate jadwal harian berdasarkan profil rombongan.
- `POST /api/v1/groups` — Buat Private Group Room (hasilkan kode/link WA unik).
- `GET /api/v1/groups/:code` — Info ruang grup & daftar anggota.
- `POST /api/v1/groups/:code/vote` — Submit voting destinasi/homestay secara live.
- `GET /api/v1/groups/:code/results` — Rekap voting live.
- `POST /api/v1/groups/:code/split-bill` — Kalkulator pembagian tagihan per anggota.
- `POST /api/v1/groups/:code/radar-ping` — Ping lokasi anggota (opt-in Group Live Radar).

### 3. Mitra Nagari, Quick Booking & Escrow (Pilar 5)
- `GET /api/v1/partners` — Katalog mitra nagari (5 kategori + level pedas).
- `GET /api/v1/partners/:id` — Detail profil mitra & paket harga resmi.
- `POST /api/v1/bookings/create` — Pesan via Quick Drawer 360° (Dana masuk Escrow).
- `POST /api/v1/bookings/wa-webhook` — Webhook respon Bot WA mitra (`1` Terima, `0` Tolak).
- `GET /api/v1/bookings/:id/ticket-qr` — Terbitkan QR E-Ticket setelah dikonfirmasi.
- `POST /api/v1/escrow/scan-redeem` — Scan QR oleh mitra saat tamu tiba untuk mencairkan dana.
- `GET /api/v1/escrow/currency/myr-rate` — Kurs konversi MYR/IDR untuk wisatawan Malaysia.

### 4. Komunitas, Gamifikasi & Analitik Dispar (Pilar 6 & 8)
- `POST /api/v1/community/places` — Ajukan tempat baru (wajib tips jaga tempat & sakelar sensitif).
- `GET /api/v1/community/shared-trips` — Board "Cari Barengan" & rute komunitas.
- `POST /api/v1/gamification/checkin` — Check-in validasi Anti-Fake GPS (radius ≤ 200m).
- `GET /api/v1/gamification/passport` — Rekap stempel Paspor Digital Minang (10 titik).
- `POST /api/v1/gamification/certificate` — Generate Sertifikat Digital resmi Gubernur.
- `GET /api/v1/analytics/dispar/summary` — Agregasi tren scan QR, heatmap kepadatan, & perputaran uang UMKM.

