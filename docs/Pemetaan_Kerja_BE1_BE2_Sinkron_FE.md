# 🗺️ PEMETAAN KERJA & KONTRAK SINERGI BE-1 & BE-2
## Ekosistem Wisata Pintar Sumatera Barat (WISGO / Rancak.in)
### Sinkronisasi 13 Catatan Revisi dengan Arsitektur Frontend Mobile Terbaru

> **Status Dokumen**: *Authoritative Living Map & Technical Contract*  
> **Terakhir Diperbarui**: 23 November 2026  
> **Prinsip Utama**: *Zero Merge Conflict, One Canonical Owner per Fact, & Intent-Driven Verification*  
> **Rujukan Arsitektur**:
> - Frontend Mobile: [`mobile/lib/features/saved/presentation/screens/saved_places_screen.dart`](file:///D:/WISGO/mobile/lib/features/saved/presentation/screens/saved_places_screen.dart) (4 Tab Utama: Beranda, Open Trip, Peta, Profil)
> - Service Bridge: [`mobile/lib/core/services/api_service.dart`](file:///D:/WISGO/mobile/lib/core/services/api_service.dart)
> - Backend BE-1: [`backend/internal/modules/`](file:///D:/WISGO/backend/internal/modules/) (`destination`, `spatial`, `scenes360`, `hazard_alerts`, `categories`)
> - Backend BE-2: [`backend/internal/modules/`](file:///D:/WISGO/backend/internal/modules/) (`auth`, `group`, `itinerary`, `booking_escrow`, `community`, `gamification`, `analytics`)

---

## 01. Batasan Wilayah Kerja (Zero Merge Conflict Guardrails)

Untuk memastikan kelancaran pengerjaan paralel tanpa tumpang tindih file (*git merge conflict*), batasan direktori dan kepemilikan tabel dipatok secara ketat:

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                 WISGO ARCHITECTURE MAP                  │
                  └─────────────────────────────────────────────────────────┘
                                               │
             ┌─────────────────────────────────┴─────────────────────────────────┐
             ▼                                                                   ▼
┌─────────────────────────────┐                                     ┌─────────────────────────────┐
│       DOMAIN BE-1           │                                     │       DOMAIN BE-2           │
│  (Core, Spasial & Aset)     │                                     │  (Sosial, Escrow & Game)    │
├─────────────────────────────┤                                     ├─────────────────────────────┤
│ • modules/destination/      │                                     │ • modules/auth/             │
│ • modules/spatial/          │           KONTRAK SINERGI           │ • modules/group/            │
│ • modules/scenes360/        │ ◄─────────────────────────────────► │ • modules/itinerary/        │
│ • modules/categories/       │       (Data Provider ➔ Consumer)     │ • modules/booking_escrow/   │
│ • 11 Tabel Spasial/Katalog  │                                     │ • modules/gamification/     │
│                             │                                     │ • modules/community/        │
│ Tanggung Jawab:             │                                     │ • 12 Tabel Sosial/Escrow    │
│ Master Destinasi, Cuaca,    │                                     │                             │
│ Titik PostGIS, SOS Offline, │                                     │ Tanggung Jawab:             │
│ & Kanvas Panorama 360°      │                                     │ WhatsApp OTP, Google OAuth, │
└─────────────────────────────┘                                     │ Open Trip, Escrow DP,       │
                                                                    │ Paspor Minang, & Strava Log │
                                                                    └─────────────────────────────┘
```

### Matriks Kepemilikan Tabel Database Supabase (Skema DBML v2 Terpusat)

| Domain | Pemilik | Tabel-Tabel Database Terdaftar (DBML v2) | Tanggung Jawab Utama |
| :--- | :---: | :--- | :--- |
| **Katalog & Spasial** | **BE-1** | `categories`, `destinations`, `indikator_medan`, `aturan_destinasi`, `panorama_scenes`, `panorama_hotspots`, `hazard_alerts`, `sos_signals`, `emergency_contacts`, `offline_bundles`, `visit_point`, `notifikasi`, `api_telemetry_logs` | Validasi spasial PostGIS, koordinat GPS destinasi, master kategori, aturan/larangan destinasi, indikator medan, peringatan cuaca, dan bundel kontak darurat offline. |
| **Pengguna & Gamifikasi** | **BE-2** | `users`, `saved_places`, `open_trips`, `new_tour`, `stemp_visit`, `destination_reviews`, `challenges`, `challenge_destinations`, `user_challenge_rewards`, `group_rooms`, `booking_escrows` | Autentikasi sesi JWT/OAuth, bookmark cloud, kartu Open Trip, usulan tempat baru, stempel stiker Minang, ulasan komunitas, misi gamifikasi, dan ledger DP escrow. |

---

## 02. Pemetaan 13 Catatan Revisi & Sinkronisasi Layar FE Mobile Terbaru

Antarmuka Flutter (`mobile/`) saat ini telah berpusat pada **4 Tab Terpadu** di [`SavedPlacesScreen`](file:///D:/WISGO/mobile/lib/features/saved/presentation/screens/saved_places_screen.dart):
* **Tab 0: Beranda (Explore)** — Visualisasi kartu destinasi real-time, filter daerah & alam, pencarian, dan modal detail destinasi.
* **Tab 1: Open Trip** — Board "Cari Barengan", Smart Trip Planner Card, dan Ruang Rombongan & Kolaborasi Voting Card.
* **Tab 2: Peta (Visual Rute)** — Peta interaktif live pins, radar cuaca jalur ekstrem, dan status jalur lintas Sumbar.
* **Tab 3: Profil** — Reaktif sesi akun (Guest vs Terverifikasi), Paspor Digital Minang, Geode Ranking, dan pengaturan sesi.

Berikut adalah pemetaan operasional 13 poin revisi ke dalam arsitektur FE dan Backend:

| Poin | Topik Revisi | Pemilik Utama | Layar / Widget FE Terkait | Endpoint REST Terkait | Ringkasan Pekerjaan & Acceptance Criteria (AC) |
| :---: | :--- | :---: | :--- | :--- | :--- |
| **1** | **Login Google** | **BE-2** | `LoginScreen`, `_buildProfileView()` | `POST /api/v1/auth/google` | Mengintegrasikan OAuth Google Sign-In melengkapi WhatsApp OTP yang sudah live. Akun dipetakan ke tabel `users`. **AC-01**: Token Google diverifikasi, mengembalikan token JWT WISGO dan `UserProfile`. |
| **2** | **Fitur SOS (Kondisi Offline)** | **BE-1** | `hazard_sos_screen.dart`, `OfflineBanner` | `GET /api/v1/spatial/emergency-contacts`, `POST /api/v1/spatial/sos` | Menyediakan data kontak darurat pos SAR/BPBD 4 koridor ekstrem dalam paket offline bundle dan format SMS darurat teks ringkas `LAT, LNG`. **AC-02**: Kontak darurat dapat dibuka tanpa koneksi internet. |
| **3** | **Open Trip (1 Destinasi & Kategori Otomatis)** | **BE-2** *(Konsumsi BE-1)* | `_buildOpenTripView()`, `open_trips` | `GET /api/v1/community/shared-trips` (query ke `open_trips`), `POST /api/v1/community/shared-trips` | Membatasi 1 Open Trip fokus pada 1 destinasi utama. Kategori otomatis ditarik dari relasi `destinations.category_id` milik BE-1. **AC-03**: Form buat Open Trip otomatis mengunci kategori berdasarkan destinasi terpilih. |
| **4** | **Trip Planner (Checklist, Jobdesk, Barang)** | **BE-2** | `trip_planner_sheet.dart`, `group_room_sheet.dart` | `POST /api/v1/itineraries/auto-generate`, `POST /api/v1/groups/:code/checklist` | Menambahkan sub-item checklist barang bawaan (tenda, obat, logistik) dan jobdesk peserta rombongan (koordinator, bendahara, driver). **AC-04**: Anggota rombongan dapat centang checklist secara kolaboratif. |
| **5** | **Experience & Riwayat Perjalanan (Konsep Strava)** | **BE-2** *(Konsumsi BE-1)* | `_buildProfileView()`, `digital_passport_sheet.dart` | `GET /api/v1/gamification/trips`, `POST /api/v1/gamification/share-card` | Menampilkan linimasa perjalanan yang telah diselesaikan wisatawan dengan statistik jarak tempuh, stempel terkumpul, dan generator share-card media sosial. **AC-05**: Kartu riwayat perjalanan dapat diekspor menjadi gambar/link share. |
| **6** | **Kategori Perjalanan (Master & Kategori Otomatis)** | **BE-1** | `_buildExploreView()`, Filter Chip Kategori | `GET /api/v1/categories`, `GET /api/v1/destinations?category_id=...` | Mengelola tabel master `categories` (Alam & Geopark, Budaya & Nagari, Hidden Gem, Religi, Kuliner) dan menghubungkannya secara presisi ke tabel `destinations`. **AC-06**: Query filter kategori FE terhubung langsung ke ID kategori BE-1. |
| **7** | **Informasi Cuaca Real-Time per Destinasi** | **BE-1** | `_buildPetaView()`, Modal Detail Destinasi | `GET /api/v1/destinations/:id` (`weather_status`), `GET /api/v1/spatial/hazards` | Menyajikan data cuaca live (suhu, cuaca, peringatan hujan) per kota/kabupaten di modal detail dan status radar cuaca di Tab 2 Peta. **AC-07**: Perubahan cuaca buruk otomatis memicu badge alert di jalur terkait. |
| **8** | **Kondisi Nyata Lapangan (Medan & Ulasan)** | **Sinergi** *(BE-1 Medan, BE-2 Ulasan)* | Modal Detail Destinasi, Tab Kondisi Lapangan | `GET /api/v1/destinations/:id` (BE-1), `GET /api/v1/destinations/:id/reviews` (BE-2) | BE-1 menyajikan 5 indikator medan resmi (jalan beraspal, kecuraman, sinyal HP, parkir, fasilitas). BE-2 menyajikan ulasan teks/rating real-time dari wisatawan. **AC-08**: Layar detail menggabungkan indikator resmi dan ulasan komunitas. |
| **9** | **Fitur 360° (Penyederhanaan Panorama View)** | **BE-1** | `virtual_tour_360_screen.dart`, Panorama Viewer | `GET /api/v1/destinations/:id/scenes-360` | Menyederhanakan 360° menjadi foto panorama resolusi tajam yang ringan dibuka di HP, membuang kompleksitas video VR berat, tetap menyertakan hotspot deskripsi. **AC-09**: Kanvas panorama termuat < 1.5 detik di koneksi 3G/4G. |
| **10** | **Transaksi Khusus Open Trip (Escrow DP)** | **BE-2** | `_buildOpenTripView()`, Bottom Sheet Booking | `POST /api/v1/bookings/create`, `POST /api/v1/bookings/wa-webhook` | Mengunci pembayaran DP peserta Open Trip di ledger `booking_escrows` hingga kuota terpenuhi atau trip terlaksana. Dilengkapi simulator konfirmasi WhatsApp mitra/host (`1` Terima, `0` Tolak). **AC-10**: Dana tertahan di escrow dan hanya cair saat QR check-in tervalidasi. |
| **11** | **Profil Terpadu Pengguna** | **BE-2** | `_buildProfileView()` (Tab 3) | `GET /api/v1/users/profile`, `GET /api/v1/users/saved` | Mengagregasikan seluruh identitas wisatawan: nomor WhatsApp terverifikasi, inisial avatar dinamis, daftar destinasi tersimpan di cloud, progres Paspor Minang, dan tombol logout aman. **AC-11**: Tab Profil reaktif 100% tanpa reload via `authNotifier`. |
| **12** | **5 Level & Lencana Petualang** | **BE-2** | `_buildProfileView()`, Modal Geode Ranking | `GET /api/v1/gamification/levels`, `GET /api/v1/gamification/leaderboard` | Menghitung kenaikan grade petualang berdasarkan akumulasi stempel nagari: *1. Panjajah Mudo (Beginner) ➔ 2. Panjelajah Nagari (Explorer) ➔ 3. Pengelana Bukik (Wanderer) ➔ 4. Pendekar Minang (Adventurer) ➔ 5. Legenda Ranah Minang (Master)*. **AC-12**: Level naik otomatis saat check-in stempel bertambah. |
| **13** | **Check-In & Challenge Berhadiah** | **BE-2** *(Konsumsi BE-1)* | `digital_passport_sheet.dart`, QR Scanner Plang | `POST /api/v1/gamification/checkin`, `GET /api/v1/gamification/passport` | Validasi kunjungan fisik berbasis formula Haversine $\le 200\text{ meter}$ terhadap koordinat BE-1 atau scan QR plang fisik. Menyediakan kuota challenge tematik dan hadiah e-sertifikat Gubernur. **AC-13**: Check-in ditolak jika jarak GPS perangkat > 200m dari koordinat resmi. |

---

## 03. Spesifikasi Detail Kontrak Sinergi (BE-1 ➔ BE-2)

Pada 3 titik temu utama, BE-1 menjadi penyedia data (*data provider*) dan BE-2 menjadi pemroses logika bisnis (*logic consumer*):

```
┌────────────────────────────────────────────────────────────────────────┐
│                      KONTRAK SINERGI DATA (BE-1 ➔ BE-2)                 │
└────────────────────────────────────────────────────────────────────────┘

  [BE-1] PostgreSQL Cloud                     [BE-2] Go Gin Business Logic
  ┌───────────────────────────┐               ┌───────────────────────────┐
  │ TABLE: destinations       │               │ MODULE: open_trips        │
  │ • id (UUID / Slug)        │ ────────────► │ • destination_id (FK)     │
  │ • name, cover_image       │  Validasi ID  │ • auto_category (Read)    │
  │ • category_id, category   │               │ • host_user_id (Users FK) │
  └───────────────────────────┘               └───────────────────────────┘
  ┌───────────────────────────┐               ┌───────────────────────────┐
  │ TABLE: destinations       │               │ MODULE: gamification      │
  │ • latitude, longitude     │ ────────────► │ • haversine_calc(lat,lng) │
  │ • qr_placard_code         │  Acuan Geofis │ • radius <= 200m check    │
  │ • nagari_id, regency      │               │ • unlock_stamp(user_id)   │
  └───────────────────────────┘               └───────────────────────────┘
  ┌───────────────────────────┐               ┌───────────────────────────┐
  │ TABLE: medan_indicators   │               │ MODULE: reviews           │
  │ • road_condition (1-5)    │ ────────────► │ • user_text_review        │
  │ • cellular_signal (1-5)   │  Gabung di UI │ • user_star_rating        │
  │ • slope_steepness (1-5)   │               │ • photos_proof_urls       │
  └───────────────────────────┘               └───────────────────────────┘
```

### 1. Sinergi Open Trip (Poin 3 & Poin 6)
* **Kebutuhan BE-2**: Saat wisatawan membuka Tab 1 (Open Trip) dan menekan *"+ Buat Jadwal Open Trip Baru"*, form membutuhkan dropdown destinasi yang valid.
* **Payload BE-1 (`GET /api/v1/destinations`)**:
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": "dst-harau-01",
        "name": "Lembah Harau",
        "city_regency": "Lima Puluh Kota",
        "category_id": "cat-alam-01",
        "category_name": "Alam & Geopark",
        "cover_image": "https://supabase.../harau.jpg"
      }
    ]
  }
  ```
* **Konsumsi BE-2 (`POST /api/v1/community/shared-trips`)**:
  BE-2 mengambil `destination_id: "dst-harau-01"` dan otomatis mengunci `category: "Alam & Geopark"` tanpa perlu diisi manual oleh pengguna.

### 2. Sinergi Check-In Challenge & Gamifikasi (Poin 5 & Poin 13)
* **Kebutuhan BE-2**: Algoritma `gamification/checkin` wajib memvalidasi apakah wisatawan benar-benar berada di lokasi fisik sebelum memberikan stempel stiker Minang.
* **Data Acuan BE-1 (`destinations`)**:
  - `latitude`: `double precision` (contoh: `-0.093124`)
  - `longitude`: `double precision` (contoh: `100.672314`)
  - `qr_placard_code`: `string` unik plang fisik nagari (contoh: `WISGO-QR-HARAU-01`)
* **Logika Verifikasi BE-2**:
  BE-2 menghitung jarak lengkung bumi menggunakan formula Haversine:
  $$d = 2R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)}\right)$$
  Jika $d \le 200\text{ meter}$ ATAU kode QR plang cocok $\to$ Stempel berhasil terbuka di tabel `stemp_visit`.

### 3. Sinergi Kondisi Nyata Lapangan (Poin 8)
* **BE-1** menyuplai data kuantitatif resmi Pemprov/Dispar via `indikator_medan` (kondisi aspal, persentase tanjakan, sinyal Telkomsel/Indosat).
* **BE-2** menyuplai data kualitatif real-time via `destination_reviews` (komentar terkini wisatawan: *"Parkir motor resmi Rp 5.000, jalan licin sehabis hujan lebat"*).

---

## 04. Spesifikasi Kerja Eksklusif BE-1 (Core, Spasial, 360° & SOS)

| Modul | Endpoint | Method | Keterangan & Aturan Respons |
| :--- | :--- | :---: | :--- |
| **Categories** | `/api/v1/categories` | `GET` | Mengembalikan 5 kategori induk revisi: *Alam & Geopark, Budaya & Nagari, Hidden Gem, Religi, Kuliner*. |
| **Destinations** | `/api/v1/destinations` | `GET` | Daftar 20 destinasi prioritas Sumbar dengan filter spasial, kategori, dan cuaca. |
| **Destinations** | `/api/v1/destinations/:id` | `GET` | Detail destinasi, 5 indikator medan, tarif Perda resmi, dan field `weather_status`. |
| **Scenes 360°** | `/api/v1/destinations/:id/scenes-360` | `GET` | Aset foto panorama ekuirektangular view resolusi tajam + titik koordinat pitch/yaw 4 pin interaktif. |
| **Spatial Shunlu**| `/api/v1/spatial/along-route` | `POST` | Engine pencarian tempat searah rute (*Shunlu*) dengan toleransi deviasi waktu $+X$ menit. |
| **Hazard Alert** | `/api/v1/spatial/hazards` | `GET` | Status kondisi 4 jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9, Malalak). |
| **SOS & Darurat**| `/api/v1/spatial/emergency-contacts` | `GET` | Daftar kontak pos SAR, BPBD, ambulans, dan kepolisian untuk paket offline bundle. |
| **SOS Signal** | `/api/v1/spatial/sos` | `POST` | Penerima sinkronisasi sinyal darurat saat perangkat kembali mendapat koneksi internet. |

---

## 05. Spesifikasi Kerja Eksklusif BE-2 (Auth, Group, Escrow & Gamifikasi)

| Modul | Endpoint | Method | Keterangan & Sinkronisasi Layar FE |
| :--- | :--- | :---: | :--- |
| **Auth (OTP)** | `/api/v1/auth/request-otp` | `POST` | Kirim kode OTP 4 digit WhatsApp simulasi (berlaku 300s, dual bypass dev `1234`/`2486`). *(Sudah Live)* |
| **Auth (OTP)** | `/api/v1/auth/verify-otp` | `POST` | Verifikasi OTP WhatsApp, cetak JWT, kembalikan data `UserProfile`. *(Sudah Live)* |
| **Auth (OAuth)** | `/api/v1/auth/google` | `POST` | Opsi autentikasi Google Sign-In alternatif yang menyimpan identitas ke tabel `users`. *(Baru)* |
| **Saved Places**| `/api/v1/users/saved` | `GET` | Ambil daftar bookmark tempat tersimpan wisatawan dari database cloud Supabase. |
| **Saved Places**| `/api/v1/users/saved/:destination_id` | `POST` | Toggle simpan/hapus destinasi dari akun wisatawan secara real-time. |
| **Open Trips** | `/api/v1/community/shared-trips` | `GET` | Daftar kartu Open Trip terbuka untuk Tab 1 Mobile (Cari Barengan / Patungan). |
| **Open Trips** | `/api/v1/community/shared-trips` | `POST` | Buat jadwal Open Trip baru (mengunci 1 destinasi dan kategori otomatis BE-1). |
| **Group Rooms** | `/api/v1/groups` | `POST` | Buat ruang koordinasi rombongan baru, terbitkan `room_code` unik tautan WhatsApp (misal: `MINANG-88`). |
| **Group Rooms** | `/api/v1/groups/:code` | `GET` | Detail rombongan, leader, daftar anggota, dan status checklist barang/jobdesk. |
| **Group Rooms** | `/api/v1/groups/:code/join` | `POST` | Anggota bergabung ke ruang rombongan via tautan link WhatsApp. |
| **Group Rooms** | `/api/v1/groups/:code/vote` | `POST` | Submit voting destinasi/homestay secara live antar anggota rombongan. |
| **Group Rooms** | `/api/v1/groups/:code/results` | `GET` | Rekapitulasi hasil voting destinasi persentase real-time. |
| **Group Rooms** | `/api/v1/groups/:code/split-bill` | `POST` | Kalkulator bagi rata tagihan rombongan (sewa mobil, homestay). |
| **Group Radar** | `/api/v1/groups/:code/radar` | `POST` | Menerima ping lokasi koordinat GPS anggota rombongan di lapangan. |
| **Group Radar** | `/api/v1/groups/:code/radar` | `GET` | Feed live radar lokasi seluruh anggota rombongan di peta. |
| **Escrow Booking**| `/api/v1/bookings/create` | `POST` | Transaksi DP/Booking Open Trip atau Mitra Nagari (Dana terkunci di status `ESCROW_LOCKED`). |
| **Escrow Bot WA**| `/api/v1/bookings/wa-webhook` | `POST` | Simulator respon bot WhatsApp Mitra/Host (`1` Terima ➔ E-Ticket QR terbit; `0` Tolak ➔ Refund). |
| **Escrow E-Ticket**| `/api/v1/bookings/:id/ticket-qr` | `GET` | Ambil QR Code E-Ticket digital resmi setelah booking dikonfirmasi host. |
| **Escrow Redeem**| `/api/v1/escrow/scan-redeem` | `POST` | Scan QR tiket saat hari-H di lokasi untuk pencairan dana escrow ke rekening host/mitra. |
| **Gamifikasi** | `/api/v1/gamification/checkin` | `POST` | Validasi check-in GPS $\le 200\text{ m}$ (Anti-Fake GPS) atau scan plang QR untuk cetak stempel. |
| **Gamifikasi** | `/api/v1/gamification/passport` | `GET` | Rekap 10 stempel Paspor Digital Minang, lencana yang terkumpul, dan progres menuju sertifikat. |
| **Gamifikasi** | `/api/v1/gamification/levels` | `GET` | Status 5 level petualang pengguna (*Panjajah Mudo* hingga *Legenda Ranah Minang*). |
| **Gamifikasi** | `/api/v1/gamification/certificate`| `POST` | Penerbitan E-Sertifikat resmi Gubernur Sumatera Barat jika 10 stempel telah lengkap. |
| **Dispar Admin** | `/api/v1/analytics/dispar/summary` | `GET` | Agregasi statistik kunjungan, transaksi UMKM nagari, dan heatmap kepadatan untuk FS-1. |

---

## 06. Rencana Alur Eksekusi & Pengujian (Verification Loop)

Sesuai pedoman Karpathy dan *Intent-Driven Development*, integrasi dilakukan secara bertahap dan terukur:

### Tahap 1: Sinkronisasi Kontrak API di Frontend (`api_service.dart`)
1. Pastikan seluruh method di [`mobile/lib/core/services/api_service.dart`](file:///D:/WISGO/mobile/lib/core/services/api_service.dart) memiliki nama route yang identik 1:1 dengan route Go Gin BE-1 dan BE-2.
2. Tambahkan handler Google OAuth `ApiService.loginWithGoogle(idToken)` melengkapi `requestOtp` dan `verifyOtp`.

### Tahap 2: Pengujian Integrasi Lokal & Cloud Database
1. **Verifikasi Backend Go**:
   ```bash
   cd backend
   go test -v ./internal/modules/...
   go build ./...
   ```
   *Kriteria Sukses*: Seluruh unit test modul BE-1 dan BE-2 lulus 100% dan kompilasi exit code 0.
2. **Verifikasi Frontend Flutter**:
   ```bash
   cd mobile
   flutter analyze
   flutter test
   ```
   *Kriteria Sukses*: Bebas warning/eror kompilasi, seluruh 15 test suite widget dan flow lolos 100%.

---

## 07. Kesimpulan & Rekomendasi Kerja

1. **Bebas Bentrok**: Tidak ada konflik arsitektur antara pembagian tugas BE-1 dengan pekerjaan BE-2.
2. **Ketergantungan Data Jelas**: BE-2 membutuhkan data destinasi dan koordinat PostGIS dari BE-1 hanya sebagai *query filter/FK validator*, yang mana datanya sudah live di Supabase.
3. **Langkah Berikutnya**: BE-2 dapat langsung melanjutkan pengaktifan **Tab 1: Open Trip & Ruang Rombongan** pada aplikasi mobile dengan memanfaatkan akun wisatawan yang sudah terautentikasi.
