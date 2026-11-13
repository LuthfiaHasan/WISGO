export interface DailyTaskStep {
  id: string;
  day: string;
  title: string;
  focus: string;
  deliverable: string;
  sqlOrGoFiles: string[];
  syncWithRole: string;
  verificationCommand: string;
}

export interface RoleBoundaryItem {
  roleCode: 'BE-1' | 'BE-2' | 'FE-1' | 'FE-2' | 'FS-1';
  roleName: string;
  stack: string;
  sprint1Focus: string;
  ownedTablesOrModules: string[];
  routePrefixOrBoundary: string;
  interactionRuleForBE1: string;
}

export interface TableSchemaSpec {
  tableNumber: number;
  tableName: string;
  sprint: 'Sprint 1 (Aktif)' | 'Sprint 2 (Aktif)' | 'Sprint 3 (Aktif)' | 'Sprint 2 (Roadmap)' | 'Sprint 3 (Roadmap)';
  pilar: string;
  description: string;
  primaryKey: string;
  foreignKeys: string;
  spatialIndex: string;
  columns: { name: string; type: string; nullable: boolean; desc: string }[];
}

export const SPRINT_1_DAILY_STEPS: DailyTaskStep[] = [
  {
    id: 's1-day1',
    day: 'Hari 1 (Senin)',
    title: 'Setup Kerangka Server WISGO (Go 1.22 ServeMux), PostGIS & Stateless JWT Middleware',
    focus: 'Sinkronisasi modul Go (`github.com/LuthfiaHasan/WISGO/backend`), koneksi database `internal/database/db.go`, serta pembuatan middleware Stateless JWT Auth & RBAC (`tourist`, `pokdarwis`, `admin_dispar`) di `internal/be1_core/middleware_jwt.go`.',
    deliverable: 'Endpoint `/api/v1/health` aktif merespons status PostGIS <15ms & middleware RBAC siap dipakai bersama BE-2 tanpa menyentuh `internal/be2_group/handlers.go`.',
    sqlOrGoFiles: ['backend/go.mod', 'backend/cmd/api/main.go', 'backend/internal/be1_core/middleware_jwt.go'],
    syncWithRole: 'BE-2 (Kesepakatan struktur JWT Claim: `sub`, `role`, `exp` & `JWT_SECRET` bersama)',
    verificationCommand: 'curl -i http://localhost:3000/api/v1/health'
  },
  {
    id: 's1-day2',
    day: 'Hari 2 (Selasa)',
    title: 'Migrasi 4 Tabel Inti Sprint 1 (Destinations, Medan, Local Tips, Official Tariffs)',
    focus: 'Menjalankan DDL migrasi terisolasi milik BE-1 (`backend/internal/be1_core/migrations_sprint1.sql`) dengan tipe geometri `GEOGRAPHY(Point, 4326)` dan indeks spasial `GIST` serta penyelarasan struct `backend/internal/models/models.go` tanpa mengganggu struct BE-2.',
    deliverable: '4 tabel inti Sprint 1 (`destinations`, `medan_indicators`, `local_tips`, `official_tariffs`) terbentuk di PostgreSQL lengkap dengan constraint enum dan indeks spasial GIST.',
    sqlOrGoFiles: ['backend/internal/be1_core/migrations_sprint1.sql', 'backend/internal/models/models.go'],
    syncWithRole: 'Mandiri BE-1 (Zero Merge Conflict — file SQL berada di dalam `internal/be1_core/`)',
    verificationCommand: 'psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint1.sql'
  },
  {
    id: 's1-day3',
    day: 'Hari 3 (Rabu)',
    title: 'Seeder 20 Destinasi Prioritas Sumatera Barat (Data Riil & Perda)',
    focus: 'Mengisi 20 destinasi unggulan lintas 19 Kabupaten/Kota Sumbar (`backend/internal/be1_core/seeder_20_sumbar.go`) lengkap dengan koordinat GPS presisi, 4 Statistik Keputusan, 5 Indikator Medan, Tips Menjaga Tempat (`--sage-100`), dan Tarif Resmi Perda/Nagari.',
    deliverable: '20 destinasi prioritas Sumatera Barat siap diakses beserta relasi 1:1 `medan_indicators` dan 1:N `local_tips` & `official_tariffs`.',
    sqlOrGoFiles: ['backend/internal/be1_core/seeder_20_sumbar.go'],
    syncWithRole: 'FE-1 & FE-2 (Memastikan kategori dan format harga Perda sesuai komponen UI)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/destinations" | jq ".meta.total"'
  },
  {
    id: 's1-day4',
    day: 'Hari 4 (Kamis)',
    title: 'API Direktori, Kalkulasi Jarak Spasial PostGIS & Aggregate Detail Destinasi',
    focus: 'Membangun `RepositoryBE1` (`backend/internal/be1_core/repository_postgis.go`) dan handler (`backend/internal/be1_core/handlers.go`) untuk `GET /api/v1/destinations` (filter kategori, kab/kota, keramaian, sinyal blank spot, & kalkulasi jarak `ST_DistanceSphere` / Haversine dari GPS pengguna) serta `GET /api/v1/destinations/{id}`, `GET /api/v1/destinations/{id}/tariffs`, dan `GET /api/v1/destinations/{id}/offline-bundle`.',
    deliverable: 'FE-1 (Layar Beranda, Detail Tempat, & Offline Bundle) serta FE-2 (Tabel Fair-Price Barometer) dapat merender data nyata <100ms dalam 1 kali panggil.',
    sqlOrGoFiles: ['backend/internal/be1_core/repository_postgis.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'FE-1 (Layar 01 & 02 + Offline Pocket) dan FE-2 (Komponen Tabel Fair-Price Barometer)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/destinations/lembah-harau-limapuluh-kota?lat=-0.9471&lng=100.4172"'
  },
  {
    id: 's1-day5',
    day: 'Hari 5 (Jumat — Target Rilis Sprint 1)',
    title: 'API Admin CMS (Sinkronisasi FS-1) & Automated Test Suite 8 Skenario Sprint 1',
    focus: 'Membuka endpoint mutasi CMS berproteksi RBAC `admin_dispar` / `pokdarwis` (`POST /api/v1/destinations`, `PUT /api/v1/destinations/{id}`, `PUT /api/v1/destinations/{id}/tariffs`, `DELETE /api/v1/destinations/{id}` beserta alias `/api/v1/admin/destinations/*`) di `cms_admin_day5.go` untuk Web Admin milik FS-1, lalu menjalankan 8 skenario `go test` (`TC-01` s/d `TC-08`).',
    deliverable: 'Output Wajib Jumat Minggu 1 tercapai 100%: Server Go aktif, 20 destinasi lengkap siap diakses, CMS FS-1 sinkron untuk CRUD destinasi & tarif Perda, dan 8 unit test otomatis lulus 100%.',
    sqlOrGoFiles: ['backend/internal/be1_core/cms_admin_day5.go', 'backend/internal/be1_core/be1_sprint1_test.go'],
    syncWithRole: 'FS-1 (Sinkronisasi kontrak JSON CMS Manajemen Destinasi, Indikator Medan & Tarif Perda)',
    verificationCommand: 'cd backend && go test -v ./internal/be1_core/... -run TestSprint1'
  }
];

export const ROLE_BOUNDARY_MATRIX: RoleBoundaryItem[] = [
  {
    roleCode: 'BE-1',
    roleName: 'Backend 1 — Core & Spasial (ANDA)',
    stack: 'Go (Gin) + PostgreSQL/PostGIS',
    sprint1Focus: 'Server Go Gin, Stateless JWT/RBAC Middleware, Migrasi 4 Tabel Inti (`destinations`, `medan_indicators`, `tips`, `official_tariffs`), Seeder 20 Destinasi Sumbar, API Detail & CMS Destinasi.',
    ownedTablesOrModules: [
      'destinations (Sprint 1)',
      'medan_indicators (Sprint 1)',
      'tips (Sprint 1)',
      'official_tariffs (Sprint 1)',
      'panorama_scenes (Sprint 2)',
      'panorama_hotspots (Sprint 2)',
      'shunlu_pois (Sprint 2)',
      'scenic_micro_maps (Sprint 2)',
      'pungli_reports (Sprint 2)',
      'hazard_alerts & sos_signals (Sprint 3)',
      'minang_phrases_events & behavior_rankings (Sprint 3)'
    ],
    routePrefixOrBoundary: '/api/v1/health, /api/v1/destinations/*, /api/v1/admin/destinations/*, /api/v1/spatial/*, /api/v1/pungli/*',
    interactionRuleForBE1: 'Area kerja penuh Anda. Seluruh file migrasi SQL wajib diawali `00X_be1_*.sql` dan kode berada di package `internal/be1_*` atau modul `destination` & `spatial`.'
  },
  {
    roleCode: 'BE-2',
    roleName: 'Backend 2 — Grup, Auth OTP & Escrow (REKAN BACKEND)',
    stack: 'Go (Gin) + PostgreSQL',
    sprint1Focus: 'Migrasi tabel `users`, `saved_places`, `itineraries`, `partners`; seeder 5 kategori mitra nagari; API Login/OTP, API Tersimpan, & API Katalog Mitra.',
    ownedTablesOrModules: [
      'users & otp_sessions (DILARANG DISENTUH BE-1)',
      'saved_places (DILARANG DISENTUH BE-1)',
      'itineraries & itinerary_items (DILARANG DISENTUH BE-1)',
      'partners & partner_packages (DILARANG DISENTUH BE-1)',
      'group_rooms & group_votes (Sprint 2)',
      'community_submissions (Sprint 2)',
      'escrow_bookings & wa_bot_logs (Sprint 3)',
      'split_bills & group_radar_pings (Sprint 3)',
      'digital_passport_checkins & certificates (Sprint 4)'
    ],
    routePrefixOrBoundary: '/api/v1/auth/*, /api/v1/saved-places/*, /api/v1/itineraries/*, /api/v1/partners/*, /api/v1/groups/*, /api/v1/escrow/*',
    interactionRuleForBE1: 'JANGAN membuat atau mengubah tabel `users` atau `saved_places`. Untuk menyimpan ID destinasi pada `saved_places`, BE-2 cukup merujuk ke UUID `destinations.id` milik Anda. Untuk autentikasi, BE-1 cukup memverifikasi signature JWT dari header Authorization.'
  },
  {
    roleCode: 'FE-1',
    roleName: 'Frontend 1 — Visual 360°, Peta, Medan & Offline',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Setup tema Flutter `desain.md`, komponen PillButton & CrowdBadge, Layar 01. Beranda, & Layar 02. Detail Tempat (4 Statistik + 5 Indikator Medan + Tips).',
    ownedTablesOrModules: ['Layar 01. Beranda', 'Layar 02. Detail Tempat', 'Kartu Medan 5 Indikator', 'Kartu Tips Menjaga Tempat (--sage-100)'],
    routePrefixOrBoundary: 'Konsumsi GET /api/v1/destinations & GET /api/v1/destinations/:idOrSlug',
    interactionRuleForBE1: 'Pastikan objek `decision_stats` (4 statistik) dan `medan_indicator` (5 indikator) serta array `tips` selalu kembali dalam 1 respons di endpoint Detail Destinasi agar FE-1 tidak perlu melakukan multiple request.'
  },
  {
    roleCode: 'FE-2',
    roleName: 'Frontend 2 — Planner, Grup, Escrow & Anti-Pungli',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Layar 05. Splash, Onboarding Lokasi, Login/OTP 4 Kotak, Layar 04. Tersimpan, & komponen Tabel Fair-Price Barometer.',
    ownedTablesOrModules: ['Komponen Tabel Fair-Price Barometer (Tarif Resmi Perda)', 'Layar Auth & Tersimpan (Ke BE-2)'],
    routePrefixOrBoundary: 'Konsumsi array `official_tariffs` dari GET /api/v1/destinations/:idOrSlug',
    interactionRuleForBE1: 'Pastikan setiap item pada `official_tariffs` memuat `item_name`, `price_idr`, `unit`, dan `perda_reference` agar FE-2 dapat langsung merender Tabel Fair-Price Barometer.'
  },
  {
    roleCode: 'FS-1',
    roleName: 'Fullstack — Web Admin Dispar, CMS 360° & Simulator',
    stack: 'TypeScript (Web) + Go Gin Bridge',
    sprint1Focus: 'Setup Web Admin TypeScript, autentikasi admin, CMS Manajemen Destinasi, Indikator Medan & Tarif Resmi Perda, sinkronisasi kontrak JSON dengan BE-1.',
    ownedTablesOrModules: ['CMS Manajemen Destinasi', 'Form Editor 5 Indikator Medan', 'Form Editor Tarif Resmi Perda'],
    routePrefixOrBoundary: 'Konsumsi POST/PUT /api/v1/admin/destinations/* dengan Bearer Token role `admin_dispar`',
    interactionRuleForBE1: 'Sediakan token JWT preset khusus `admin_dispar` dan dokumentasi payload JSON `POST`/`PUT` agar FS-1 dapat menguji form tambah/edit destinasi dari Web Admin TS tanpa hambatan.'
  }
];

export const BE1_11_TABLES_SCHEMA: TableSchemaSpec[] = [
  {
    tableNumber: 1,
    tableName: 'destinasi_wisata',
    sprint: 'Sprint 1 (Aktif)',
    pilar: 'Pilar 1 & 3 (Direktori & Statistik Keputusan)',
    description: 'Tabel induk 20 destinasi prioritas Sumatera Barat dengan titik koordinat PostGIS dan 4 Statistik Keputusan di bagian atas layar.',
    primaryKey: 'id_destinasi (UUID / VARCHAR(36))',
    foreignKeys: 'Tidak ada (Tabel Induk Mandiri BE-1)',
    spatialIndex: 'indeks_lokasi_gps_wisata USING GIST (titik_koordinat_gps)',
    columns: [
      { name: 'id_destinasi', type: 'VARCHAR(36)', nullable: false, desc: 'Primary key unik destinasi (contoh: dest-001)' },
      { name: 'kode_url_slug', type: 'VARCHAR(120) UNIQUE', nullable: false, desc: 'Slug ramah SEO & Smart QR URL' },
      { name: 'nama_wisata', type: 'VARCHAR(180)', nullable: false, desc: 'Nama lengkap kawasan wisata' },
      { name: 'kabupaten_kota', type: 'VARCHAR(80)', nullable: false, desc: 'Satu dari 19 Kabupaten/Kota di Sumatera Barat' },
      { name: 'kategori_wisata', type: 'VARCHAR(32)', nullable: false, desc: 'alam | budaya | bahari | nagari | geopark' },
      { name: 'lintang_latitude', type: 'DOUBLE PRECISION', nullable: false, desc: 'Koordinat Lintang (WGS84)' },
      { name: 'bujur_longitude', type: 'DOUBLE PRECISION', nullable: false, desc: 'Koordinat Bujur (WGS84)' },
      { name: 'titik_koordinat_gps', type: 'GEOGRAPHY(Point, 4326)', nullable: false, desc: 'Kolom spasial PostGIS untuk hitung jarak & radius' },
      { name: 'ketinggian_mdpl', type: 'INTEGER', nullable: false, desc: 'Ketinggian lokasi di atas permukaan laut (mdpl)' },
      { name: 'tingkat_keramaian', type: 'VARCHAR(16)', nullable: false, desc: 'Statistik Keputusan #3: sepi | sedang | ramai' },
      { name: 'estimasi_biaya_rupiah', type: 'INTEGER', nullable: false, desc: 'Statistik Keputusan #4: Estimasi biaya tiket dasar (Rp)' },
      { name: 'jarak_dari_padang_km', type: 'NUMERIC(6,1)', nullable: false, desc: 'Statistik Keputusan #1: Jarak acuan default dari Kota Padang (km)' },
      { name: 'waktu_tempuh_menit', type: 'INTEGER', nullable: false, desc: 'Statistik Keputusan #2: Waktu tempuh acuan (menit)' },
      { name: 'apakah_hidden_gem', type: 'BOOLEAN', nullable: false, desc: 'Penanda wajib tampil kartu Tips Menjaga Tempat (--sage-100)' },
      { name: 'kode_plang_qr', type: 'VARCHAR(64) UNIQUE', nullable: false, desc: 'Kode unik Plang QR Fisik di pintu gerbang wisata' }
    ]
  },
  {
    tableNumber: 2,
    tableName: 'indikator_medan',
    sprint: 'Sprint 1 (Aktif)',
    pilar: 'Pilar 3 (P3.2 — Kartu Kesiapan Medan 5 Indikator)',
    description: 'Menyimpan 5 Indikator Kesiapan Medan geografis Ranah Minang (Akses Kendaraan, Kesulitan Trekking, Sinyal Seluler, Fasilitas Toilet/Musala, dan Status Pemandu).',
    primaryKey: 'id_indikator_medan (VARCHAR(36))',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi) ON DELETE CASCADE (1:1)',
    spatialIndex: 'indeks_medan_id_destinasi (B-Tree UNIQUE)',
    columns: [
      { name: 'id_indikator_medan', type: 'VARCHAR(36)', nullable: false, desc: 'Primary key indikator medan' },
      { name: 'id_destinasi', type: 'VARCHAR(36) UNIQUE', nullable: false, desc: 'Relasi 1:1 ke tabel destinasi_wisata' },
      { name: 'kondisi_jalan_akses', type: 'TEXT', nullable: false, desc: 'Indikator #1: Deskripsi akses mobil/motor/bus & kontur jalan' },
      { name: 'bisa_masuk_mobil', type: 'BOOLEAN', nullable: false, desc: 'Apakah mobil roda empat dapat mencapai titik parkir utama' },
      { name: 'kemiringan_tanjakan_derajat', type: 'INTEGER', nullable: false, desc: 'Kemiringan tanjakan maksimum dalam derajat' },
      { name: 'tingkat_kesulitan_jalan_kaki', type: 'VARCHAR(16)', nullable: false, desc: 'Indikator #2: mudah | sedang | ekstrem' },
      { name: 'jarak_jalan_kaki_meter', type: 'INTEGER', nullable: false, desc: 'Jarak jalan kaki dari parkir ke spot utama (meter)' },
      { name: 'kualitas_sinyal_hp', type: 'VARCHAR(24)', nullable: false, desc: 'Indikator #3: 4g_stabil | sinyal_lemah | susah_sinyal' },
      { name: 'operator_sinyal_terbaik', type: 'VARCHAR(160)', nullable: false, desc: 'Detail operator seluler yang masih memiliki sinyal di lokasi' },
      { name: 'kelengkapan_fasilitas', type: 'TEXT', nullable: false, desc: 'Indikator #4: Ringkasan ketersediaan toilet, musala, & rest area' },
      { name: 'status_pemandu_lokal', type: 'VARCHAR(32)', nullable: false, desc: 'Indikator #5: mandiri | tersedia_opsional | wajib_pokdarwis' },
      { name: 'nama_pengelola_pokdarwis', type: 'VARCHAR(160)', nullable: false, desc: 'Nama Pokdarwis / pengelola resmi nagari setempat' }
    ]
  },
  {
    tableNumber: 3,
    tableName: 'tips_lokal_adat',
    sprint: 'Sprint 1 (Aktif)',
    pilar: 'Pilar 3 & 6 (Tips Menjaga Tempat & Etika Adat)',
    description: 'Menyimpan kartu panduan etika adat Minangkabau, keselamatan medan, dan pelestarian lingkungan (wajib pada destinasi hidden gem).',
    primaryKey: 'id_tips (VARCHAR(36))',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi) ON DELETE CASCADE (1:N)',
    spatialIndex: 'indeks_tips_per_destinasi (B-Tree)',
    columns: [
      { name: 'id_tips', type: 'VARCHAR(36)', nullable: false, desc: 'Primary key item tips' },
      { name: 'id_destinasi', type: 'VARCHAR(36)', nullable: false, desc: 'Relasi ke tabel destinasi_wisata' },
      { name: 'jenis_tips', type: 'VARCHAR(32)', nullable: false, desc: 'kelestarian_alam | etika_adat | keselamatan_medan | waktu_terbaik' },
      { name: 'judul_tips', type: 'VARCHAR(160)', nullable: false, desc: 'Judul singkat panduan (ditampilkan di kartu --sage-100)' },
      { name: 'isi_penjelasan_tips', type: 'TEXT', nullable: false, desc: 'Penjelasan praktis bagi wisatawan di lapangan' },
      { name: 'wajib_dibaca', type: 'BOOLEAN', nullable: false, desc: 'True jika wajib tampil di paruh atas halaman detail' }
    ]
  },
  {
    tableNumber: 4,
    tableName: 'tarif_resmi_perda',
    sprint: 'Sprint 1 (Aktif)',
    pilar: 'Pilar 3 (P3.4 — Fair-Price Barometer & Anti-Pungli)',
    description: 'Menyimpan daftar harga resmi sesuai Perda Kab/Kota atau Peraturan Nagari (Tiket, Parkir Motor Rp3rb, Parkir Mobil Rp5rb, Sewa Bendi/Perahu) untuk mencegah pungli.',
    primaryKey: 'id_tarif (VARCHAR(36))',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi) ON DELETE CASCADE (1:N)',
    spatialIndex: 'indeks_tarif_per_destinasi (B-Tree)',
    columns: [
      { name: 'id_tarif', type: 'VARCHAR(36)', nullable: false, desc: 'Primary key item tarif resmi' },
      { name: 'id_destinasi', type: 'VARCHAR(36)', nullable: false, desc: 'Relasi ke tabel destinasi_wisata' },
      { name: 'nama_komponen_biaya', type: 'VARCHAR(160)', nullable: false, desc: 'Nama komponen biaya (contoh: Parkir Resmi Motor)' },
      { name: 'kategori_biaya', type: 'VARCHAR(32)', nullable: false, desc: 'tiket | parkir | transport_lokal | pemandu | fasilitas' },
      { name: 'harga_resmi_rupiah', type: 'INTEGER', nullable: false, desc: 'Nominal harga resmi dalam Rupiah (tabular-nums)' },
      { name: 'satuan_tarif', type: 'VARCHAR(48)', nullable: false, desc: 'Satuan tarif (per_orang, per_kendaraan, per_kapal_10_orang)' },
      { name: 'nomor_aturan_perda', type: 'VARCHAR(160)', nullable: false, desc: 'Dasar hukum Perda atau SK Nagari yang mengikat' }
    ]
  },
  {
    tableNumber: 5,
    tableName: 'adegan_panorama_360',
    sprint: 'Sprint 2 (Aktif)',
    pilar: 'Pilar 1 (P1.1 — Aerial-to-Ground Multi-Spot 360°)',
    description: 'Menyimpan aset equirectangular 360° udara (drone 150m) dan darat beserta orientasi kamera awal dan file suara suasana alam.',
    primaryKey: 'id_adegan_360 (UUID)',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi)',
    spatialIndex: 'indeks_foto_360_utama',
    columns: [
      { name: 'id_adegan_360', type: 'UUID', nullable: false, desc: 'ID foto panorama 360°' },
      { name: 'judul_sudut_pandang', type: 'VARCHAR(140)', nullable: false, desc: 'Nama titik sudut pandang kamera 360°' },
      { name: 'url_gambar_360', type: 'TEXT', nullable: false, desc: 'URL gambar panorama 360° resolusi tinggi' }
    ]
  },
  {
    tableNumber: 6,
    tableName: 'titik_pin_360',
    sprint: 'Sprint 2 (Aktif)',
    pilar: 'Pilar 1 (P1.2 — Sistem 4 Pin Interaktif Terstandarisasi)',
    description: 'Menyimpan posisi titik pin di atas kanvas 360° untuk 4 jenis pin: Info, Navigasi (Pindah Titik), Budaya, dan Peringatan.',
    primaryKey: 'id_pin_360 (UUID)',
    foreignKeys: 'id_adegan_360 -> adegan_panorama_360(id_adegan_360)',
    spatialIndex: 'indeks_pin_per_adegan_360',
    columns: [
      { name: 'id_pin_360', type: 'UUID', nullable: false, desc: 'ID titik pin hotspot 360°' },
      { name: 'jenis_pin', type: 'VARCHAR(24)', nullable: false, desc: 'info | navigasi | budaya | peringatan' },
      { name: 'posisi_atas_bawah_dan_kiri_kanan', type: 'NUMERIC(6,2)', nullable: false, desc: 'Posisi titik pin di dalam layar bola 360°' }
    ]
  },
  {
    tableNumber: 7,
    tableName: 'tempat_mampir_searah',
    sprint: 'Sprint 2 (Aktif)',
    pilar: 'Pilar 2 (P2.1 — Along-the-Route Search "Shunlu")',
    description: 'Titik singgah searah rute aktif (RM Padang Otentik, SPBU, Masjid Bersih, Oleh-oleh, Bengkel) dengan perhitungan waktu belok +X menit.',
    primaryKey: 'id_tempat_mampir (UUID)',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi)',
    spatialIndex: 'indeks_gps_tempat_mampir USING GIST (titik_koordinat_gps)',
    columns: [
      { name: 'id_tempat_mampir', type: 'UUID', nullable: false, desc: 'ID tempat mampir searah rute' },
      { name: 'kategori_tempat_mampir', type: 'VARCHAR(32)', nullable: false, desc: 'masjid_musala | kuliner_pakem | spbu_rest | oleh_oleh' },
      { name: 'titik_koordinat_gps', type: 'GEOGRAPHY(Point, 4326)', nullable: false, desc: 'Titik koordinat lokasi tempat mampir' }
    ]
  },
  {
    tableNumber: 8,
    tableName: 'peta_mikro_kawasan',
    sprint: 'Sprint 2 (Aktif)',
    pilar: 'Pilar 2 (P2.2 & P2.3 — Peta Mikro Kawasan & Audio GPS ≤15m)',
    description: 'Jalur pejalan kaki di dalam kompleks wisata luas beserta poligon batas kawasan dan titik pemicu cerita suara otomatis.',
    primaryKey: 'id_peta_mikro (UUID)',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi)',
    spatialIndex: 'indeks_peta_mikro_destinasi USING GIST (poligon_batas_kawasan)',
    columns: [
      { name: 'id_peta_mikro', type: 'UUID', nullable: false, desc: 'ID peta jalan kaki dalam kawasan' },
      { name: 'garis_rute_jalan_kaki', type: 'JSONB', nullable: false, desc: 'Jalur ramah anak/lansia, gerbang, spot foto, dan toilet' },
      { name: 'daftar_titik_pemicu_audio', type: 'JSONB', nullable: false, desc: 'Titik GPS radius ≤15m pemutar cerita suara otomatis' }
    ]
  },
  {
    tableNumber: 9,
    tableName: 'laporan_pungli',
    sprint: 'Sprint 2 (Aktif)',
    pilar: 'Pilar 3 & 8 (P3.4 & P8.1 — Laporan Satgas Saber Pungli Anonim)',
    description: 'Menyimpan tiket laporan pungutan liar secara anonim beserta foto bukti karcis/oknum, koordinat GPS, dan status tindak lanjut Satgas.',
    primaryKey: 'id_laporan_pungli (UUID)',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi)',
    spatialIndex: 'indeks_gps_kejadian_pungli USING GIST (titik_gps_kejadian)',
    columns: [
      { name: 'id_laporan_pungli', type: 'VARCHAR(32) UNIQUE', nullable: false, desc: 'Kode unik laporan pungli anonim' },
      { name: 'nominal_diminta_oknum_rupiah', type: 'INTEGER', nullable: false, desc: 'Nominal uang yang diminta paksa oleh oknum' },
      { name: 'status_tindak_lanjut', type: 'VARCHAR(24)', nullable: false, desc: 'baru_masuk | peringatan_aktif | selesai_ditindak_satgas' }
    ]
  },
  {
    tableNumber: 10,
    tableName: 'peringatan_bahaya_dan_sos',
    sprint: 'Sprint 3 (Aktif)',
    pilar: 'Pilar 7 (P7.2 — Live Hazard Alert Jalur Ekstrem & SOS GPS)',
    description: 'Data peringatan dini jalur rawan longsor/kabut (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44) serta pancaran koordinat darurat SOS wisatawan.',
    primaryKey: 'id_bahaya_atau_sos (UUID)',
    foreignKeys: 'Mandiri Spasial',
    spatialIndex: 'indeks_gps_pusat_bahaya USING GIST (titik_gps_pusat_kejadian)',
    columns: [
      { name: 'kode_koridor_ekstrem', type: 'VARCHAR(80)', nullable: false, desc: 'sitinjau_lauik | lembah_anai | kelok_9 | kelok_44' },
      { name: 'tingkat_kewaspadaan', type: 'VARCHAR(24)', nullable: false, desc: 'waspada | siaga | awas_tutup' },
      { name: 'saran_jalur_alternatif', type: 'TEXT', nullable: true, desc: 'Saran jalan memutar yang aman dilewati' }
    ]
  },
  {
    tableNumber: 11,
    tableName: 'peringkat_kunjungan_gps & kamus_minang',
    sprint: 'Sprint 3 (Aktif)',
    pilar: 'Pilar 1 & 2 (P1.4 Kamus/Kalender Budaya & P2.4 Gaode Ranking)',
    description: 'Kamus saku suara bahasa Minang, jadwal Hari Pakan/Acara Budaya, serta peringkat wisata jujur dari jumlah kedatangan dan lama betah GPS.',
    primaryKey: 'id_peringkat / id_kamus_atau_agenda (UUID)',
    foreignKeys: 'id_destinasi -> destinasi_wisata(id_destinasi)',
    spatialIndex: 'indeks_skor_peringkat_tertinggi (B-Tree DESC)',
    columns: [
      { name: 'jumlah_kedatangan_navigasi_30h', type: 'INTEGER', nullable: false, desc: 'Jumlah orang yang benar-benar sampai ke lokasi' },
      { name: 'rata_rata_lama_betah_menit', type: 'INTEGER', nullable: false, desc: 'Rata-rata lama pengunjung betah di lokasi (menit)' },
      { name: 'skor_total_perilaku', type: 'NUMERIC(5,2)', nullable: false, desc: 'Nilai peringkat otomatis bebas ulasan bintang palsu' }
    ]
  }
];
