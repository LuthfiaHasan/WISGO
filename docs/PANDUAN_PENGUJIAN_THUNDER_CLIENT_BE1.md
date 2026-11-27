# ⚡ Panduan Lengkap Pengujian Thunder Client — Backend 1 (BE-1) & Sinergi WISGO

> **Base URL Server Lokal**: `http://localhost:8080`  
> **Cara Import Cepat (1 Klik)**:
> 1. Buka ekstensi **Thunder Client** di VS Code.
> 2. Klik tab **Collections** ➔ klik ikon garis tiga (**Menu**) ➔ pilih **Import**.
> 3. Pilih file [`docs/thunder-collection_WISGO.json`](file:///f:/WISGO/docs/thunder-collection_WISGO.json).
> 4. Seluruh **38 Request** sudah terisi URL `http://localhost:8080` dan Bearer Token langsung (tanpa perlu setting Environment `{{...}}`), sehingga Anda cukup klik **Send**!

---

## 🔑 Daftar Token JWT Siap Pakai (Header `Authorization: Bearer <TOKEN>`)

Jika Anda ingin menguji manual, gunakan salah satu token berikut pada tab **Auth ➔ Bearer Token**:

* **Token Admin Dispar (`admin_dispar`)**:
  ```text
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLWFkbWluLWRpc3Bhci0wMSIsIm5hbWUiOiJBZG1pbiBEaXNwYXIgU3VtYmFyIChGUy0xKSIsInJvbGUiOiJhZG1pbl9kaXNwYXIifQ.rancakin_sig_admin
  ```
* **Token Wisatawan (`tourist`)**:
  ```text
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXRvdXJpc3QtMDEiLCJuYW1lIjoiUml6a3kgUHJhdGFtYSAoV2lzYXRhd2FuKSIsInJvbGUiOiJ0b3VyaXN0In0.rancakin_sig_tourist
  ```
* **Token Vendor Event (`vendor`)**:
  ```text
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXZlbmRvci0wMSIsIm5hbWUiOiJTYW5nZ2FyIEJ1ZGF5YSBNaW5hbmcgKFZlbmRvcikiLCJyb2xlIjoidmVuZG9yIn0.rancakin_sig_vendor
  ```
* **Token Dinamis Login OTP**: Anda juga bisa langsung menyalin field `"token": "jwt-wisgo-..."` dari hasil respons endpoint `POST /api/v1/auth/verify-otp`.

---

## 📂 KELOMPOK 1: Health Check & Autentikasi Sinergi

### 1.1 Cek Status Server & Koneksi Supabase
* **Method & URL**: `GET http://localhost:8080/health`
* **Expected (`200 OK`)**: `"status": "ok"`, `"database": "connected"`

### 1.2 Request OTP WhatsApp
* **Method & URL**: `POST http://localhost:8080/api/v1/auth/request-otp`
* **Body (JSON)**:
  ```json
  {
    "phone_number": "628127578953"
  }
  ```
* **Expected (`200 OK`)**: Kode OTP 4 digit tercetak di terminal server Go (atau gunakan kode bypass `1234`).

### 1.3 Verifikasi OTP & Ambil Token Dinamis
* **Method & URL**: `POST http://localhost:8080/api/v1/auth/verify-otp`
* **Body (JSON)**:
  ```json
  {
    "phone_number": "628127578953",
    "otp_code": "1234",
    "full_name": "Rizky Pratama",
    "login_choice": "wisata"
  }
  ```
* **Expected (`200 OK`)**: Mengembalikan `token` (`jwt-wisgo-usr-...`) dan profil user.

---

## 📂 KELOMPOK 2: Katalog 20 Destinasi, 5 Kategori Induk & Cuaca Live WeatherAPI (Poin 6, 7, 8)

### 2.1 Ambil 5 Master Categories & Jumlah Destinasi (Poin 6)
* **Method & URL**: `GET http://localhost:8080/api/v1/categories`
* **Expected (`200 OK`)**: Mengembalikan 5 kategori induk resmi (`cat-alam-geopark`, `cat-budaya-nagari`, `cat-hidden-gem`, `cat-religi`, `cat-kuliner`) beserta `destination_count`.

### 2.2 Direktori 20 Destinasi + Kalkulasi Jarak Spasial GPS
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations?lat=-0.3051&lng=100.3692`
* **Expected (`200 OK`)**: Mengembalikan 20 destinasi yang diurutkan otomatis dari jarak terdekat dengan titik koordinat Bukittinggi (`Jam Gadang` berada di urutan pertama).

### 2.3 Filter Destinasi Berdasarkan `category_id`
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations?category_id=cat-religi`
* **Expected (`200 OK`)**: Hanya menampilkan destinasi dengan `category_id: "cat-religi"` (Masjid Raya Syekh Ahmad Khatib Al-Minangkabawi).

### 2.4 Detail Destinasi + Cuaca Real-Time WeatherAPI + 5 Indikator Medan + Tarif Perda (Poin 7 & 8)
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations/dest-001`
* **Expected (`200 OK`)**:
  - Memuat objek `"weather"` dengan `"source": "WeatherAPI Live API"` (atau fallback jika offline), suhu `temperature_c`, `weather_status`, `wind_speed_kmh`, `rain_probability`.
  - Memuat `"medan_indicator"` (5 indikator medan), `"tips"` (aturan menjaga tempat), dan `"tariffs"` (tarif resmi Perda).

### 2.5 Tabel Fair-Price Barometer (Tarif Resmi Perda)
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations/dest-001/tariffs`
* **Expected (`200 OK`)**: Daftar tarif tiket masuk & parkir resmi sesuai Perda.

### 2.6 Unduh Paket Mode Offline Bundle + Kontak Darurat (Poin 2)
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations/dest-001/offline-bundle`
* **Expected (`200 OK`)**: Mengembalikan bundel JSON lengkap (`destination`, `scenes_360`, `micro_map`, `audio_triggers`, `emergency_contacts`) sekaligus menyimpannya ke tabel `offline_bundles` di PostgreSQL.

### 2.7 Wisatawan: Input Usulan Tempat Wisata Baru / Hidden Gem
* **Method & URL**: `POST http://localhost:8080/api/v1/destinations/hidden-gem`
* **Auth**: Bearer Token Wisatawan (atau sertakan `user_id` di body)
* **Body (JSON)**:
  ```json
  {
    "user_id": "usr-001",
    "name": "Air Terjun Sarasah Barasok Harau",
    "city_regency": "Kab. Lima Puluh Kota",
    "description": "Air terjun alami tersembunyi di balik tebing granit Lembah Harau.",
    "latitude": -0.1085,
    "longitude": 100.6742,
    "vehicle_access": "Hanya Motor / Jalan Kaki",
    "trekking_level": "Sedang",
    "cellular_signal": "Blank Spot",
    "facilities": "Belum Ada",
    "guide_need": "Disarankan",
    "tips_menjaga": "Bawa kembali seluruh sampah plastik dan jangan merusak lumut tebing."
  }
  ```
* **Expected (`201 Created`)**: Destinasi tersimpan dengan `"verification_status": "pending"` dan `"category_id": "cat-hidden-gem"`.

### 2.8 Admin Dispar: Lihat Daftar Usulan Hidden Gem Pending
* **Method & URL**: `GET http://localhost:8080/api/v1/admin/destinations/pending`
* **Auth**: Bearer Token Admin Dispar
* **Expected (`200 OK`)**: Menampilkan daftar usulan destinasi yang berstatus `pending`.

### 2.9 Admin Dispar: Setujui / Verifikasi Usulan Hidden Gem
* **Method & URL**: `PATCH http://localhost:8080/api/v1/admin/destinations/dest-021/verify`
* **Auth**: Bearer Token Admin Dispar
* **Body (JSON)**:
  ```json
  {
    "status": "verified"
  }
  ```
* **Expected (`200 OK`)**: Status berubah menjadi `"verified"` dan langsung tayang di direktori publik.

---

## 📂 KELOMPOK 3: Panorama 360° View & CMS Studio 4-Pin (Poin 9)

### 3.1 Ambil Kanvas Foto Panorama 360° & 4 Pin Hotspot
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations/dest-001/scenes-360`
* **Expected (`200 OK`)**: Mengembalikan aset foto panorama (`panorama_url`), `initial_pitch`, `initial_yaw`, dan array `hotspots` lengkap dengan `voice_text`.

### 3.2 Admin CMS Studio 360°: Tempel Pin Hotspot Baru
* **Method & URL**: `POST http://localhost:8080/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots`
* **Auth**: Bearer Token Admin Dispar
* **Body (JSON)**:
  ```json
  {
    "type": "fasilitas",
    "title": "Musala & Toilet Bersih Sarasah Bunta",
    "pitch": -12.5,
    "yaw": 210.0,
    "voice_text": "Di sebelah kanan terdapat fasilitas musala dan toilet bersih yang dikelola Pokdarwis Nagari.",
    "description": "Fasilitas ibadah dan sanitasi resmi kawasan Lembah Harau."
  }
  ```
* **Expected (`201 Created`)**: `"status": "pin_attached"`, tersimpan ke tabel `panorama_hotspots`.

---

## 📂 KELOMPOK 4: Spasial PostGIS — Shunlu, Peta Mikro, Audio GPS & TSP

### 4.1 Engine Pencarian Searah Rute ("Shunlu")
* **Method & URL**: `POST http://localhost:8080/api/v1/spatial/along-route` *(atau `/api/v1/spatial/shunlu`)*
* **Body (JSON)**:
  ```json
  {
    "origin_lat": -0.9471,
    "origin_lng": 100.4172,
    "destination_lat": -0.3051,
    "destination_lng": 100.3692,
    "category": "rm_padang",
    "max_detour_min": 15
  }
  ```
* **Expected (`200 OK`)**: Daftar titik singgah searah rute (`visit_point`) dengan `detour_minutes <= 15`.

### 4.2 Query Spasial PostGIS Destinasi Terdekat (`ST_DWithin`)
* **Method & URL**: `GET http://localhost:8080/api/v1/spatial/nearby?lat=-0.3051&lng=100.3692&radius=40`
* **Expected (`200 OK`)**: Daftar destinasi dalam radius 40 km dari titik koordinat.

### 4.3 Peta Mikro Pejalan Kaki Kawasan
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations/dest-001/micro-map`
* **Expected (`200 OK`)**: GeoJSON jalur jalan kaki ramah anak/lansia, POI internal, dan titik pemicu audio.

### 4.4 Pemicu Audio Narasi Otomatis Berbasis Radius GPS ($\le 15\text{ meter}$)
* **Method & URL**: `POST http://localhost:8080/api/v1/spatial/audio-trigger-check`
* **Body (JSON)**:
  ```json
  {
    "destination_id": "dest-001",
    "user_lat": -0.1023,
    "user_lng": 100.6728
  }
  ```
* **Expected (`200 OK`)**: `"trigger_status": "AUTO_PLAY_ACTIVE"` karena jarak $\le 15\text{ m}$.

### 4.5 Multi-Stop TSP Route Optimizer
* **Method & URL**: `POST http://localhost:8080/api/v1/routes/optimize-tsp`
* **Body (JSON)**:
  ```json
  {
    "start_lat": -0.9471,
    "start_lng": 100.4172,
    "destination_ids": ["dest-001", "dest-002", "dest-004", "dest-006"]
  }
  ```
* **Expected (`200 OK`)**: Urutan kunjungan paling hemat jarak dan waktu tempuh.

---

## 📂 KELOMPOK 5: Mitigasi Bencana — 4 Radar Jalur Ekstrem, 6 Kontak Darurat & SOS (Poin 2 & 7)

### 5.1 Radar 4 Koridor Jalur Ekstrem + Cuaca Live WeatherAPI (AC-07)
* **Method & URL**: `GET http://localhost:8080/api/v1/spatial/hazards`
* **Expected (`200 OK`)**: Menampilkan status 4 koridor (*Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44*) dengan `weather_status` yang diperbarui otomatis dari **WeatherAPI.com**.

### 5.2 Daftar 6 Nomor Darurat Bencana Resmi Sumbar (AC-02)
* **Method & URL**: `GET http://localhost:8080/api/v1/spatial/emergency-contacts`
* **Expected (`200 OK`)**: Mengembalikan 6 kontak darurat resmi (BPBD, Damkar, PMI, Basarnas) dari tabel `emergency_contacts`.

### 5.3 Admin Dispar: Tambah / Update Kontak Darurat Resmi
* **Method & URL**: `POST http://localhost:8080/api/v1/spatial/emergency-contacts`
* **Auth**: Bearer Token Admin Dispar
* **Body (JSON)**:
  ```json
  {
    "corridor_code": "SITINJAU-LAUIK",
    "agency_type": "SAR",
    "agency_name": "Posko Siaga Basarnas Panorama 2 Sitinjau",
    "phone_number": "(0751) 7051115",
    "whatsapp_number": "62811660115",
    "city": "Kota Padang"
  }
  ```
* **Expected (`200 OK`)**: Kontak darurat baru tersimpan ke tabel `emergency_contacts`.

### 5.4 Sinkronisasi Sinyal Darurat SOS GPS
* **Method & URL**: `POST http://localhost:8080/api/v1/spatial/sos`
* **Body (JSON)**:
  ```json
  {
    "sos_code": "SOS-SUMBAR-901",
    "tourist_name": "Budi Santoso",
    "phone_number": "628127578953",
    "emergency_type": "Kendaraan Mogok di Tanjakan Ekstrem",
    "latitude": -0.9468,
    "longitude": 100.5182,
    "battery_percent": 42,
    "passengers_count": 3,
    "is_offline_sync": true,
    "notes": "Butuh ganjal ban dan derek di dekat Panorama 1 Sitinjau Lauik."
  }
  ```
* **Expected (`201 Created`)**: Sinyal SOS tercatat di `sos_signals`, mengembalikan pos penyelamat terdekat & estimasi waktu tiba (ETA).

### 5.5 Admin Dispar: Trigger Peringatan Bencana Jalur Ekstrem
* **Method & URL**: `POST http://localhost:8080/api/v1/admin/hazards/trigger`
* **Auth**: Bearer Token Admin Dispar
* **Body (JSON)**:
  ```json
  {
    "corridor_code": "SITINJAU-LAUIK",
    "severity": "Siaga",
    "hazard_type": "Hujan Lebat & Kabut Tebal",
    "weather_status": "Hujan Lebat (19°C)",
    "message": "Jarak pandang di bawah 15 meter di Panorama 1, sistem buka-tutup aktif.",
    "detour_route": "Gunakan jalur alternatif Padang - Padang Panjang - Solok."
  }
  ```
* **Expected (`200 OK`)**: Status koridor `SITINJAU-LAUIK` berubah menjadi `"Siaga"` di database.

---

## 📂 KELOMPOK 6: Plang Smart QR Fisik & Satgas Saber Pungli

### 6.1 Resolusi Scanner Plang Smart QR Fisik
* **Method & URL**: `GET http://localhost:8080/api/v1/qr/QR-SMBR-LPK-001`
* **Expected (`200 OK`)**: Mengembalikan data destinasi Lembah Harau, status `"fair_price_verified": true`, tarif resmi Perda, dan kanvas 360°.

### 6.2 Wisatawan: Lapor Pungli Anonim
* **Method & URL**: `POST http://localhost:8080/api/v1/pungli/report`
* **Body (JSON)**:
  ```json
  {
    "destination_id": "dest-001",
    "reporter_name": "Wisatawan Anonim",
    "incident_category": "parkir_liar",
    "charged_amount_idr": 25000,
    "photo_evidence": "https://cdn.rancak.in/evidence/karcis-parkir-liar.jpg",
    "latitude": -0.1025,
    "longitude": 100.6725,
    "description": "Diminta tarif parkir mobil Rp 25.000 tanpa karcis resmi Perda (tarif resmi Rp 5.000)."
  }
  ```
* **Expected (`201 Created`)**: Otomatis menghitung `overcharge_amount_idr` (selisih terhadap tarif Perda) dan menerbitkan nomor tiket `PGL-202611-...`.

### 6.3 Admin Satgas Saber Pungli: Update Status Laporan Pungli
* **Method & URL**: `PATCH http://localhost:8080/api/v1/admin/pungli/pungli-001/status`
* **Auth**: Bearer Token Admin Dispar
* **Body (JSON)**:
  ```json
  {
    "status": "Ditindaklanjuti",
    "satgas_notes": "Tim Satgas Saber Pungli dan Dishub telah menertibkan oknum juru parkir liar di lokasi."
  }
  ```
* **Expected (`200 OK`)**: Status tiket berubah di tabel `pungli_reports`.

---

## 📂 KELOMPOK 7: Kamus Audio Minang, Kalender Budaya & Gaode Ranking

### 7.1 Ambil Kamus Saku Audio Bahasa Minang
* **Method & URL**: `GET http://localhost:8080/api/v1/culture/minang-phrases`
* **Expected (`200 OK`)**: Daftar frasa Minang lengkap dengan panduan pelafalan, audio, dan tingkat kesopanan *Kato Nan Ampek*.

### 7.2 Ambil Kalender Budaya & Hari Pakan Nagari
* **Method & URL**: `GET http://localhost:8080/api/v1/culture/events`
* **Expected (`200 OK`)**: Daftar festival budaya dan pasar tradisional nagari.

### 7.3 Vendor / Admin: Input Event Budaya Baru
* **Method & URL**: `POST http://localhost:8080/api/v1/culture/events`
* **Auth**: Bearer Token Vendor (atau Token Dinamis hasil login OTP Vendor)
* **Body (JSON)**:
  ```json
  {
    "title": "Festival Hoyak Tabuik Pariaman 2026",
    "event_type": "Festival Budaya",
    "nagari_location": "Pantai Gandoriah",
    "city_regency": "Kota Pariaman",
    "schedule_rule": "Puncak 10 Muharram",
    "next_event_date": "2026-07-26",
    "latitude": -0.6264,
    "longitude": 100.1190,
    "highlight_item": "Prosesi arak-arakan Tabuik Pasa dan Tabuik Subarang menuju Pantai Gandoriah.",
    "cultural_etiquette": "Berpakaian sopan dan ikuti arahan ninik mamak serta panitia nagari."
  }
  ```
* **Expected (`201 Created`)**: Event budaya baru tersimpan ke tabel `cultural_events`.

### 7.4 Leaderboard & Rekalkulasi Gaode Behavior Ranking
* **Method & URL**: `POST http://localhost:8080/api/v1/rankings/gaode/recalculate`
* **Expected (`200 OK`)**: Menghitung ulang skor keaslian perilaku GPS (`gaode_authenticity_score`) dan mengurutkan peringkat destinasi.

---

## 📂 KELOMPOK 8: Notifikasi, SLA Benchmark `<100ms` & Uji Keamanan RBAC

### 8.1 Broadcast Notifikasi In-App (`notifikasi` BE-1)
* **Method & URL**: `POST http://localhost:8080/api/v1/notifications/broadcast`
* **Body (JSON)**:
  ```json
  {
    "user_id": "usr-001",
    "notification_type": "HAZARD_ALERT",
    "title": "Siaga Cuaca Jalur Sitinjau Lauik",
    "message": "Hujan lebat terdeteksi via WeatherAPI di Panorama 1. Gunakan gigi rendah dan jaga jarak aman.",
    "reference_id": "SITINJAU-LAUIK"
  }
  ```
* **Expected (`201 Created`)**: Notifikasi tersimpan ke tabel `notifikasi` dan dapat diambil lewat `GET http://localhost:8080/api/v1/notifications`.

### 8.2 Admin Dispar: Live SLA Benchmark (`<100ms`) & Catat `api_telemetry_logs`
* **Method & URL**: `GET http://localhost:8080/api/v1/admin/system/benchmark`
* **Auth**: Bearer Token Admin Dispar
* **Expected (`200 OK`)**: Menampilkan latensi `p50`, `p95`, `p99` di bawah `100ms` (`"sla_passed": true`) dan mencatat log performa ke tabel `api_telemetry_logs`.

### 8.3 Uji Keamanan RBAC (Negative Test: Wisatawan Mencoba Hapus Destinasi Admin)
* **Method & URL**: `DELETE http://localhost:8080/api/v1/admin/destinations/dest-001`
* **Auth**: Bearer Token Wisatawan (`TokenTourist`)
* **Expected (`403 Forbidden`)**: `"code": "FORBIDDEN_INSUFFICIENT_ROLE"`, membuktikan proteksi RBAC berjalan ketat.

---

## Modul 8: Meja Kurasi Usulan Destinasi Wisatawan (Tabel `new_tour`) & Berita Bencana Sumbar (`sumbarkita.id` & `sumbar.antaranews.com`)

### 39. [GET] Ambil Antrean Meja Kurasi Usulan Destinasi (`new_tour`)
* **Method & URL**: `GET http://localhost:8080/api/v1/destinations/new-tours`
* **Expected (`200 OK`)**: Mengembalikan daftar usulan destinasi wisatawan dari tabel `new_tour` beserta `pending_count`, `approved_count`, dan `rejected_count`.

### 40. [POST] Kirim Usulan Destinasi Baru ke Tabel `new_tour`
* **Method & URL**: `POST http://localhost:8080/api/v1/destinations/new-tours`
* **Body JSON**:
  ```json
  {
    "name": "Air Terjun Sarasah Barasok",
    "category": "Hidden Gem",
    "city_regency": "Kab. Lima Puluh Kota",
    "description": "Air terjun bertingkat dengan kabut embun pagi di lembah Harau.",
    "latitude": -0.1012,
    "longitude": 100.6731,
    "tips_menjaga": "Bawa kembali sampah plastik dan tetap di jalur setapak Pokdarwis.",
    "submitter_name": "Ilham Fathoni",
    "submitter_phone": "6281234567890",
    "facilities": ["Jalur Trekking", "Spot Foto Alami"],
    "is_sensitive": true
  }
  ```
* **Expected (`201 Created`)**: Data tersimpan ke tabel `new_tour` dengan `status: "pending"`.

### 41. [PUT] Setujui Usulan `new_tour` & Promosikan ke Direktori `destinations` (Admin)
* **Method & URL**: `PUT http://localhost:8080/api/v1/admin/new-tours/nt-002/approve`
* **Auth**: Bearer Token `jwt-wisgo-admin-dispar-sumbar-2026`
* **Expected (`200 OK`)**: Status `new_tour` berubah menjadi `"approved"` dan otomatis membuat destinasi terverifikasi baru di tabel `destinations`, `indikator_medan`, dan `aturan_destinasi`.

### 42. [POST] Gabungkan Usulan Duplikat `new_tour` + Kredit Kontributor (Admin)
* **Method & URL**: `POST http://localhost:8080/api/v1/admin/new-tours/merge`
* **Auth**: Bearer Token `jwt-wisgo-admin-dispar-sumbar-2026`
* **Body JSON**:
  ```json
  {
    "submission_ids": ["nt-001", "nt-003"],
    "primary_data_submission_id": "nt-001",
    "cover_photo_submission_id": "nt-003",
    "custom_name": "Air Terjun Sarasah Murai Harau"
  }
  ```
* **Expected (`200 OK`)**: Menggabungkan data terbaik & foto cover terbaik menjadi 1 destinasi resmi di `destinations`.

### 43. [GET] Ambil Berita Wisata & Bencana Sumatera Barat (`sumbarkita.id` & `sumbar.antaranews.com`)
* **Method & URL**: `GET http://localhost:8080/api/v1/spatial/news`
* **Query Opsional**: `?portal=sumbarkita.id` atau `?portal=sumbar.antaranews.com`
* **Expected (`200 OK`)**: Mengembalikan daftar berita wisata & kebencanaan Sumatera Barat lengkap dengan `portal_domain` (`sumbarkita.id` / `sumbar.antaranews.com`), `source_url`, `severity`, `region`, `summary`, dan `advice`.

### 44. [POST] Tarik Berita Live RSS `sumbarkita.id` & `sumbar.antaranews.com`
* **Method & URL**: `POST http://localhost:8080/api/v1/spatial/news/sync-portals`
* **Expected (`200 OK`)**: Menarik RSS terbaru dari portal `sumbarkita.id` dan `sumbar.antaranews.com` serta menyinkronkannya ke feed berita aplikasi Mobile & Web Admin.

