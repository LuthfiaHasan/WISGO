# PANDUAN KERJA TIM ENGINEERING · SPRINT 4 MINGGU (1 BULAN)
# Pembagian Tugas Merata 5 Developer (Rancak.in)

> **Prinsip Utama:** Alokasi Beban Kerja Seimbang (Zero Merge Conflict). Setiap developer memiliki modul dan lapisan tanggung jawab mandiri.

---

## 01. Peta Kepemilikan Modul & Keseimbangan Beban Kerja

| Kode Peran | Posisi & Stack | Modul, Layar & Pilar yang Menjadi Tanggung Jawab Penuh | Kuota Beban Kerja |
| :--- | :--- | :--- | :--- |
| **FE-1** *(Frontend 1)* | **Flutter Mobile** (Visual 360°, Peta, Medan & Offline) | • **Fondasi UI (`desain.md`)**: Token warna (#F6F3EC, #234B24, #F26B4B), komponen Pill 52px, Bottom Navigation.<br>• **Pilar 1**: Beranda (Layar 01), Detail Tempat (Layar 02), Kanvas 360° Aerial-to-Ground, 4 Pin Interaktif, Spatial Audio, Kamus Minang & Kalender Budaya.<br>• **Pilar 2**: Jelajah Peta (Layar 03), Filter Kategori, Cari Searah Rute (*Shunlu* +X mnt detour), Peta Mikro Kawasan, Audio GPS, & Kompas Gunung.<br>• **Pilar 3 & 7**: Grid 4 Statistik Keputusan, Kartu Medan 5 Indikator, Tips Menjaga Tempat, Mode Offline Lokal (Hive/Sqflite), Banner Jalur Rawan, & SOS GPS. | 14 Modul UI Mobile (50% Flutter) |
| **FE-2** *(Frontend 2)* | **Flutter Mobile** (Planner, Grup, Escrow & Gamifikasi) | • **Auth & Saved**: Splash (Layar 05), Onboarding Lokasi, Login/OTP 4 Kotak, Layar Tersimpan (Layar 04: skeleton, empty state, offline banner).<br>• **Pilar 3**: Pemindai Plang Smart QR (Kamera), Tabel Fair-Price Barometer, Form Lapor Pungli / Fasilitas Rusak (Foto + GPS).<br>• **Pilar 4**: Smart Trip Planner 7 Hari (Layar 06), Auto-Itinerary UI, Private Group Room, Live Voting, Split-Bill, Group Live Radar.<br>• **Pilar 5 & 6**: Quick Booking Drawer 360°, Katalog 5 Mitra (+ Level Pedas), Checkout Simulasi QRIS/MYR, QR E-Ticket, Tambah Tempat (FAB +), Board "Cari Barengan", Radar Lapangan, Salin Rute, Paspor Digital & Sertifikat Gubernur. | 14 Modul UI Mobile (50% Flutter) |
| **FS-1** *(Fullstack)* | **TypeScript (Web Admin) + Go Gin Bridge** | • **Pilar 8 (Dashboard Dispar)**: Analitik kunjungan real-time, Heatmap kepadatan 19 Kab/Kota, grafik perputaran ekonomi UMKM.<br>• **Pusat Komando Satgas Saber Pungli**: Verifikasi & ubah status tiket aduan pungli/fasilitas.<br>• **CMS Studio 360° Visual Editor**: Unggah foto 360°, klik-tempel koordinat 4 Pin (pitch/yaw), kelola tarif Perda, kurasi lokasi sensitif.<br>• **Panel Simulator Pengujian**: Simulator Chat Bot WA Mitra (klik balas 1 Terima / 0 Tolak, scan QR pencairan Escrow) + Web Instant Smart QR & Group Invite. | 100% Web Admin TS, CMS Studio & Simulator |
| **BE-1** *(Backend 1)* | **Go (Gin) + PostgreSQL / PostGIS** (Core & Spasial) | • **Fondasi Backend**: Server Go Gin, JWT Auth / RBAC, migrasi 11 tabel inti & spasial, seeder 20 destinasi prioritas Sumbar.<br>• **API Pilar 1 & 3**: CRUD Destinasi, 360° Scenes & 4 Pin Hotspots, 5 Indikator Medan, Tarif Perda, Lapor Pungli, Bundel Offline.<br>• **API Pilar 2 & 7**: Query Spasial Terdekat, Engine Along-the-Route (*Shunlu* +X mnt detour via ST_Buffer / ST_DWithin), Peta Mikro, Multi-Stop TSP Optimizer, Gaode Ranking, Alert Jalur Ekstrem, & SOS GPS. | 24 Endpoint Go Gin + 11 Tabel PostgreSQL |
| **BE-2** *(Backend 2)* | **Go (Gin) + PostgreSQL** (Grup, Mitra & Escrow) | • **API Pilar 4**: Auto-Itinerary Generator, CRUD Rencana Perjalanan, Private Group Room (kode/link), Live Voting, Kalkulator Split-Bill, Group Live Radar.<br>• **API Pilar 5**: CRUD 5 Kategori Mitra, Engine Quick Booking, Ledger Escrow, Kurs MYR, Scan QR Cair, Engine Simulator Bot WA (1=Terima / 0=Tolak).<br>• **API Pilar 6 & 8**: Tambah Tempat Komunitas (masking lokasi sensitif), Cari Barengan, Radar Feed, Validasi Check-in GPS ≤200m (Anti-Fake GPS), Generator Sertifikat Gubernur, Agregasi Analitik Dispar. | 24 Endpoint Go Gin + 12 Tabel PostgreSQL |

---

## 02. Rincian Tugas Mingguan (Roadmap 4 Minggu)

### MINGGU 1 (Hari 1–5): Fondasi Database, Design System Flutter (`desain.md`), Direktori, Kesiapan Medan & CMS Dasar
- **BE-1**: Setup Go Gin + PostgreSQL, JWT Auth, migrasi tabel `destinations`, `medan_indicators`, `tips`, `official_tariffs`, seeder 20 destinasi Sumbar, & API Detail Destinasi. (*Output: Server aktif & 20 destinasi siap diakses*).
- **BE-2**: Migrasi tabel `users`, `saved_places`, `itineraries`, `partners`; seeder 5 kategori mitra; API Login/OTP, API Tersimpan, API Katalog Mitra. (*Output: API Auth OTP, Tersimpan & Katalog Mitra siap*).
- **FE-1**: Setup tema Flutter `desain.md` (#F6F3EC, #234B24, #F26B4B), komponen `PillButton` & `CrowdBadge`, Layar 01 Beranda, & Layar 02 Detail Tempat (4 Statistik + 5 Indikator + Tips). (*Output: Beranda & Detail Tempat identik desain dengan data API*).
- **FE-2**: Bangun Layar 05 Splash, Onboarding Lokasi, Login/OTP 4 Kotak, Layar 04 Tersimpan (skeleton, empty state, offline banner), komponen Tabel Fair-Price Barometer. (*Output: Alur Auth OTP, Tersimpan & tabel tarif resmi tuntas*).
- **FS-1**: Setup Web Admin TypeScript, autentikasi admin, CMS Manajemen Destinasi, Indikator Medan & Tarif Resmi Perda, sinkronisasi kontrak JSON dengan BE-1/BE-2. (*Output: Admin dapat menambah & mengedit data destinasi via Web TS*).

### MINGGU 2 (Hari 6–10): Tur Virtual 360° 4-Pin, Peta & Rute Shunlu, Mode Offline, Lapor Pungli & Private Group Room
- **BE-1**: API `panorama_scenes` & 4 Pin Hotspots, Engine Along-the-Route (*Shunlu* +X mnt detour), API Peta Mikro Kawasan, API Lapor Pungli (upload bukti foto), API Bundel Offline. (*Output: API 360°, rute Shunlu, Peta Mikro & Lapor Pungli siap*).
- **BE-2**: Engine Auto-Itinerary Generator & TSP Optimizer, API Private Group Room (buat grup, gabung via link/kode, Live Voting), API Tambah Tempat Baru (masking radius lokasi sensitif). (*Output: API grup rombongan, voting & tambah tempat aktif*).
- **FE-1**: Bangun Layar 07 Tur Virtual 360° (Aerial-to-Ground + 4 Pin), Layar 03 Jelajah Peta & Kartu Mengambang, filter Cari Searah Rute (*Shunlu*), Peta Mikro, simpan lokal Mode Offline. (*Output: Tur 360° 4-Pin, Peta Shunlu & Mode Offline jalan di HP*).
- **FE-2**: Bangun Scanner Plang Smart QR, Form Lapor Pungli, Layar 06 Itinerary 7 Hari & Auto-Itinerary, Private Group Room & Voting UI, Bottom Sheet Tambah Tempat (FAB +). (*Output: Scan QR, lapor pungli, jadwal grup & tambah tempat selesai*).
- **FS-1**: Bangun CMS Studio 360° (Visual Pin Editor untuk 4 pin di atas kanvas 360°), Pusat Komando Satgas Saber Pungli, Halaman Web Instan Smart QR & Group Invite. (*Output: Editor visual pin 360° & dashboard tindak lanjut pungli aktif*).

### MINGGU 3 (Hari 11–15): Quick Booking Escrow, Simulator Bot WA Mitra, Split-Bill, Cari Barengan & Jalur Rawan
- **BE-1**: Algoritma Behavior-Based Ranking (Gaode Guide), API Live Hazard Alert Jalur Ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9) + API SOS GPS, API Kamus Audio Minang & Kalender Budaya. (*Output: API ranking perilaku, hazard alert jalur ekstrem & SOS siap*).
- **BE-2**: Engine Quick Booking & Ledger Escrow (simulasi QRIS & DuitNow MYR), Simulator Bot WA Mitra (balas 1 terbitkan QR E-Ticket; scan QR cairkan Escrow), Split-Bill, Group Live Radar, Cari Barengan. (*Output: Mesin Escrow, Bot WA 1/0, scan QR cair & Split-Bill tuntas*).
- **FE-1**: Integrasi Spatial Audio 360° & Audio GPS di Peta Mikro, halaman Kamus Saku Audio Minang & Kalender Budaya, Banner Peringatan Jalur Rawan, Tombol Darurat SOS GPS. (*Output: Fitur audio budaya, peringatan jalur ekstrem & SOS aktif*).
- **FE-2**: Bangun Quick Booking Drawer 360°, Katalog 5 Mitra (+ Level Pedas), Checkout QRIS/MYR & QR E-Ticket, Split-Bill UI, Group Live Radar, Board "Cari Barengan", Radar Lapangan + Salin Rute. (*Output: Transaksi booking 360°, patungan grup & Cari Barengan selesai*).
- **FS-1**: Bangun Panel Simulator Chat Bot WA Mitra (tombol Balas 1 Terima, Balas 0 Tolak, Scan QR E-Ticket Cairkan Escrow), Dashboard Kunjungan & Heatmap 19 Kab/Kota, Panel Trigger Bencana. (*Output: Demo interaktif Booking Flutter ↔ Simulator WA Mitra live*).

### MINGGU 4 (Hari 16–20): Paspor Digital GPS ≤200m, Sertifikat Gubernur, Analitik Ekonomi Nagari & Rilis Akhir
- **BE-1**: Optimasi indeks spasial PostgreSQL (<100ms), caching rute & 360°, pengamanan rate-limiting, pengujian beban & stabilitas seluruh endpoint Go Gin. (*Output: Backend cepat, stabil, siap produksi/demo*).
- **BE-2**: Endpoint Validasi Check-in GPS ≤200m (Anti-Fake GPS), Generator Sertifikat Digital Gubernur (PDF/PNG), API Analitik Perputaran Ekonomi UMKM per Nagari. (*Output: Validasi GPS Paspor Digital & Sertifikat Gubernur aktif*).
- **FE-1**: Bangun Kompas Visual Landmark Gunung, Mode VR & Katalog Baju Adat, audit 12 poin Daftar Periksa `desain.md`, pengujian menyeluruh Mode Offline tanpa internet. (*Output: Aplikasi Flutter lulus 100% checklist desain.md & Offline*).
- **FE-2**: Bangun halaman Paspor Digital Minang, tantangan cari ukiran di 360°, unduh Sertifikat Digital Gubernur, fitur Tanyo Urang Awak, pengujian penuh transaksi Escrow. (*Output: Paspor Digital, Sertifikat Gubernur & seluruh alur sosial tuntas*).
- **FS-1**: Bangun Grafik Perputaran Ekonomi UMKM Nagari, Kurasi Tempat Sensitif Komunitas, fitur Ekspor Laporan PDF/CSV Dispar, penyiapan skenario Demo Terpadu 1 Layar. (*Output: Web Admin Dispar, CMS 360° & Panel Simulator siap demo akhir*).

