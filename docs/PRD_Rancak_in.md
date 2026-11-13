# PRODUCT REQUIREMENTS DOCUMENT (PRD) · MASTER SPECIFICATION
# Ekosistem Wisata Pintar Sumatera Barat (Rancak.in / KeRanah)

- **Versi & Status**: v1.0 — Siap Eksekusi
- **Arsitektur Platform**: 100% Web Modern (PWA) + Flutter Mobile App + Web Admin Dashboard
- **Cakupan Wilayah**: 19 Kabupaten/Kota Sumatera Barat
- **Basis Dokumen**: Master Blueprint & `desain.md`

---

## 01. Ringkasan Eksekutif & Masalah yang Diselesaikan

Pengembangan sistem informasi pariwisata Sumatera Barat selama ini terkendala oleh 4 hambatan utama di lapangan:

1. **Hambatan Unduh APK (<100 Unduhan)**
   - *Masalah*: Wisatawan enggan mengunduh aplikasi berukuran 50–100 MB di Play Store hanya untuk liburan singkat 2–3 hari.
   - *Solusi PRD*: 100% Progressive Web App (PWA) & Mobile Flutter ringan yang terbuka dalam <2 detik lewat browser atau scan Plang QR di lokasi wisata tanpa instalasi rumit.

2. **Ketidakpastian Medan & Rawan Pungli**
   - *Masalah*: Peta umum tidak memuat info kontur jalan curam, kesiapan trekking, sinyal seluler, maupun tarif resmi tiket/parkir.
   - *Solusi PRD*: Grid 4 Statistik Keputusan di Depan, Kartu Kesiapan Medan 5 Indikator, tabel Fair-Price Barometer resmi Perda/Nagari, dan tombol Lapor Pungli terhubung Satgas.

3. **Titik Buta Konektivitas (Blank Spot Sinyal)**
   - *Masalah*: Banyak *hidden gem* unggulan (Lembah Harau dalam, Air Terjun Nyarai, Silokek) berada di lembah tanpa sinyal internet.
   - *Solusi PRD*: Mode Zero-Signal (Offline Pocket) yang menyimpan paket peta mikro, panduan suara, tips menjaga tempat, & tiket QR di memori lokal HP (Hive/SQLite/IndexedDB).

4. **Gap Literasi Digital UMKM & Vendor Nagari**
   - *Masalah*: Pemilik homestay Rumah Gadang, perahu pulau, dan pemandu lokal kesulitan mengoperasikan dashboard web rumit.
   - *Solusi PRD*: Bot WhatsApp Mitra Tanpa Login (cukup balas `1` untuk Terima / `0` untuk Tolak di WA) yang terhubung ke rekening bersama (Escrow).

---

## 02. Profil Pengguna & Aktor Sistem (User Personas)

1. **Wisatawan Mandiri & Keluarga (Domestik, Perantau & Turis Malaysia)**
   - *Konteks*: Pakai ponsel satu tangan di perjalanan / di bawah terik matahari.
   - *Kebutuhan*: Pratinjau 360° sebelum berangkat, lihat jarak, waktu tempuh, kepadatan, tarif resmi di paruh atas layar, cari RM Padang / SPBU / Masjid searah rute (*Shunlu*).
   - *Kanal*: Mobile App / PWA (390×844 px) & Scan Plang QR.

2. **Koordinator & Anggota Rombongan (Keluarga / Kantor / Open Trip)**
   - *Konteks*: Kelola jadwal dan biaya 4–15 orang tanpa ribet chat WA berantakan.
   - *Kebutuhan*: Private Group Room via link WA, live voting destinasi/homestay, split-bill otomatis via QRIS/DuitNow, pantau posisi rombongan.
   - *Kanal*: Tautan Web Instan dari Grup WhatsApp.

3. **Mitra Lokal Nagari & Pokdarwis (Homestay, Kapal, Pemandu, Kuliner)**
   - *Konteks*: Sibuk melayani tamu di lapangan, jarang buka laptop.
   - *Kebutuhan*: Terima pesanan via chat WA, scan QR E-Ticket saat tamu tiba untuk pencairan dana Escrow otomatis.
   - *Kanal*: Bot WhatsApp Resmi & Kamera Scan QR.

4. **Eksekutif Dispar & Satgas Saber Pungli (Gubernur, Kadispar 19 Kab/Kota)**
   - *Konteks*: Butuh analitik kunjungan riil harian & respons cepat aduan fasilitas/pungli.
   - *Kebutuhan*: Heatmap kepadatan real-time, perputaran ekonomi UMKM, kelola tiket laporan pungli (Masuk → Diverifikasi → Ditindaklanjuti → Selesai), CMS Studio 360°.
   - *Kanal*: Dashboard Eksekutif & CMS Studio 360°.

---

## 03. Spesifikasi Fitur: 8 Pilar Smart Tourism

### PILAR 1: Eksplorasi Visual Imersif 360° & Storytelling Budaya Minang
- **P1.1 Aerial-to-Ground Multi-Spot 360° (P1 - MVP)**: Panorama drone 360° (100–200m) dengan tombol transisi mulus ke darat (parkir, gerbang, spot utama) tanpa reload halaman. Mendukung sentuhan & gyroscope ponsel (≥30 FPS).
- **P1.2 Sistem 4 Pin Interaktif Terstandarisasi (P1 - MVP)**:
  - (1) Pin Navigasi (Biru)
  - (2) Pin Audio Budaya (Emas)
  - (3) Pin Fasilitas Resmi (Hijau)
  - (4) Pin Mitra Nagari (Oranye)
- **P1.3 Spatial Audio Berbasis Orientasi (P2)**: Suara alam/alat musik Minang berubah keseimbangan kiri/kanan mengikuti orientasi hadap kamera 360°.
- **P1.4 Kamus Saku Audio Minang & Kalender Budaya (P2)**: Frasa praktis Minang audio instan (2–5 dtk) & jadwal event adat (Tabuik, Pacu Jawi, Hari Pakan).
- **P1.5 Mode WebVR & AR Souvenir Try-On (P3)**: Layar belah VR Cardboard & filter kamera coba baju adat (Suntiang, Deta/Saluak).

### PILAR 2: Navigasi Cerdas & Algoritma Lapangan (Adopsi Killer Features Amap)
- **P2.1 Along-the-Route Search ("Shunlu") (P1 - MVP)**: Pencarian titik singgah searah rute aktif (SPBU, RM Padang Otentik, Masjid Bersih, ATM, Bengkel) dengan kalkulasi waktu detour: `Detour: +X menit (Y m dari rute utama)`.
- **P2.2 Peta Mikro Area Wisata (Scenic Micro-Map) (P1 - MVP)**: Peta pejalan kaki area luas (Jam Gadang, Pagaruyung, Lembah Harau) menampilkan gerbang, jalur ramah lansia/anak, toilet, titik foto. Beralih otomatis via geofencing / scan QR gerbang.
- **P2.3 Pemandu Audio GPS Otomatis (P2)**: Audio narasi berputar otomatis saat pengguna berada ≤15 meter dari prasasti/bangunan.
- **P2.4 Behavior-Based Ranking (Gaode Guide) (P2)**: Skor ranking berdasarkan data riil: frekuensi navigasi aktif + dwell time GPS + kunjungan berulang.
- **P2.5 Multi-Stop Route Optimizer (TSP) (P2)**: Menyusun 3–10 destinasi sehari dengan algoritma Traveling Salesperson Problem mempertimbangkan tanjakan & jam buka (<3 detik).
- **P2.6 AR Walking Nav & Landmark Finder (P3)**: Panah 3D lorong padat & label elevasi gunung (Marapi, Singgalang).

### PILAR 3: Kesiapan Medan Lapangan, Smart QR On-Site & Anti-Pungli
- **P3.1 Buka Cepat (<2 Detik) & SEO (P1 - MVP)**: Initial load <2 detik di 4G, Add to Homescreen, SEO friendly.
- **P3.2 Grid 4 Statistik Keputusan & Kartu Medan 5 Indikator (P1 - MVP)**:
  - *Grid 4 Statistik*: Jarak, Waktu Tempuh, Tingkat Keramaian (Sepi / Sedang / Ramai), Biaya Tiket.
  - *5 Indikator Medan*: Akses Kendaraan (Mobil/Motor), Kesulitan Trekking, Sinyal Seluler, Toilet/Musala, Pemandu.
  - *Kartu Edukasi*: Tips Menjaga Tempat Ini (wajib untuk hidden gem).
- **P3.3 Plang QR Fisik Cerdas (Smart QR Placard) (P1 - MVP)**: QR di gerbang membuka peta mikro, audio guide, tarif resmi, dan otomatis mencatat data statistik kunjungan.
- **P3.4 Fair-Price Barometer & Lapor Pungli (P1 - MVP)**: Tabel tarif resmi Perda/Nagari + Tombol merah Lapor Pungli (foto karcis/oknum & GPS anonim ke Satgas Saber Pungli).

### PILAR 4: Smart Trip Planner & Kolaborasi Rombongan (Private Group Room)
- **P4.1 Timeline Rencana Perjalanan & Peringatan Rute (P1 - MVP)**: Strip kalender 7 hari dengan agenda jam & peringatan rute macet (contoh: Pasar Koto Baru).
- **P4.2 Auto-Itinerary Generator (P2)**: Susun jadwal otomatis berdasarkan durasi hari, titik kedatangan (Bandara BIM / darat), dan profil rombongan.
- **P4.3 Private Group Room via Link WA & Live Voting (P2)**: Kolaborasi voting destinasi/homestay secara live tanpa instal aplikasi.
- **P4.4 Shared Cart & Split-Bill Otomatis (P3)**: Bagi rata tagihan sewa armada/homestay/perahu dengan tautan bayar QRIS masing-masing anggota.
- **P4.5 Group Live Radar (P3)**: Radar opt-in lokasi anggota rombongan di peta mikro kawasan wisata.

### PILAR 5: Ekosistem Vendor Lokal Nagari, Escrow & Bot WhatsApp
- **P5.1 Quick Booking Drawer di Atas Kanvas 360° (P1 UI / P3 Live)**: Laci setengah layar (radius 28px) saat pin mitra diketuk tanpa menutup kanvas 360°.
- **P5.2 Bot WhatsApp Mitra Nagari Tanpa Login (P1 Sim / P3 Live)**: Notifikasi pesanan ke WhatsApp mitra; konfirmasi via balas `1` (Terima) atau `0` (Tolak).
- **P5.3 5 Kategori Mitra & Indikator Level Pedas (P3)**: Homestay, Kapal, Pemandu Pokdarwis, Kuliner Halal (dengan level pedas), Sewa Baju Adat.
- **P5.4 Rekening Bersama (Escrow) & QRIS Cross-Border (P3)**: Dana tersimpan aman di Escrow; cair saat QR E-Ticket dipindai di lokasi. Dukung QRIS & DuitNow Malaysia (MYR).

### PILAR 6, 7 & 8: Komunitas, Jalur Ekstrem & Dashboard Dispar
- **P6.1 Tambah Tempat Komunitas & Proteksi Lokasi Sensitif (P1 - MVP)**: Form kontribusi tempat dengan input wajib "Tips menjaga tempat ini" dan sakelar proteksi radius perkiraan hingga dikurasi Pokdarwis.
- **P6.2 Board "Cari Barengan" & Salin Rute 1-Klik (P2/P3)**: Patungan sewa mobil/perahu aman via escrow & salin jadwal trip pengguna lain.
- **P6.3 Paspor Digital Minang & Sertifikat Gubernur (P3)**: Check-in GPS valid (radius ≤200m) anti-fake GPS, gamifikasi ukiran 360°, Sertifikat Digital Gubernur setelah 10 titik ikonik.
- **P7.1 Mode Zero-Signal / Offline Pocket (P1 - MVP)**: Simpan paket destinasi lokal (info, peta mikro, audio, tiket QR) dengan banner notifikasi offline otomatis.
- **P7.2 Live Hazard Alert Jalur Ekstrem & SOS GPS (P2)**: Peringatan bencana jalur Sitinjau Lauik, Lembah Anai, Kelok 9 terintegrasi BMKG/PVMBG + tombol darurat SOS GPS.
- **P8.1 Dashboard Analitik Real-Time & Komando Anti-Pungli (P1 - MVP)**: Dashboard pimpinan daerah (tren kunjungan QR, heatmap kepadatan 19 Kab/Kota, perputaran ekonomi UMKM, antrean aduan pungli status: Masuk → Diverifikasi → Ditindaklanjuti → Selesai).

