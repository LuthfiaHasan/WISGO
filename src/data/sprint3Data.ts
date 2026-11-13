import type { DailyTaskStep, RoleBoundaryItem } from './sprint1ArchitectureData';

export interface GaodeRankingRecord {
  id: string;
  destination_id: string;
  destination_name: string;
  category: 'Alam & Geopark' | 'Budaya & Nagari' | 'Hidden Gem' | 'Kuliner Legendaris';
  city_regency: string;
  rank_position: number;
  gaode_authenticity_score: number;
  active_nav_count_30d: number;
  avg_dwell_time_min: number;
  return_visit_rate_pct: number;
  anti_fake_review_verified: boolean;
  trending_badge: string;
  updated_at: string;
}

export interface HazardAlertRecord {
  id: string;
  corridor_code: 'SITINJAU-LAUIK' | 'LEMBAH-ANAI' | 'KELOK-9' | 'KELOK-44';
  location: string;
  road_segment: string;
  city_regency: string;
  latitude: number;
  longitude: number;
  radius_meter: number;
  severity: 'Normal' | 'Waspada' | 'Siaga' | 'Awas Tutup Total';
  hazard_type: string;
  weather_status: string;
  slope_gradient_deg: number;
  message: string;
  detour_route: string;
  detour_route_geojson: string;
  nearest_rescue_post: string;
  emergency_contact: string;
  triggered_by_admin: string;
  updated_at: string;
}

export interface SOSSignalRecord {
  id: string;
  sos_code: string;
  tourist_name: string;
  phone_number: string;
  emergency_type: string;
  latitude: number;
  longitude: number;
  battery_percent: number;
  passengers_count: number;
  nearest_corridor: string;
  nearest_rescue_post: string;
  distance_to_rescue_km: number;
  eta_rescue_minutes: number;
  status: 'Dipancarkan' | 'Tim SAR Meluncur' | 'Evakuasi Selesai';
  notes: string;
  created_at: string;
}

export interface MinangPhraseRecord {
  id: string;
  category: 'sapaan_adat' | 'tawar_pasar' | 'kuliner_rm' | 'navigasi_darurat';
  indonesian_text: string;
  minang_text: string;
  phonetic_guide: string;
  audio_url: string;
  dialect_note: string;
  usage_context_tip: string;
  politeness_level: string;
}

export interface CulturalEventRecord {
  id: string;
  title: string;
  event_type: 'Hari Pakan Nagari' | 'Festival Budaya' | 'Tradisi Adat';
  nagari_location: string;
  city_regency: string;
  schedule_rule: string;
  next_event_date: string;
  latitude: number;
  longitude: number;
  distance_km?: number;
  highlight_item: string;
  cultural_etiquette: string;
}

export const SPRINT_3_DAILY_STEPS: DailyTaskStep[] = [
  {
    id: 's3-day11',
    day: 'Hari 11 (Senin — Minggu 3)',
    title: 'Penyelesaian Kuota 11/11 Tabel BE-1 (Migrasi & Seeder Gaode, Hazard, SOS, & Budaya Minang)',
    focus: 'Menjalankan DDL `backend/internal/be1_core/migrations_sprint3.sql` untuk menuntaskan seluruh 11 kuota tabel BE-1 (`gaode_behavior_rankings`, `hazard_alerts`, `sos_signals`, `minang_phrases`, `cultural_events`) dan mengisi seeder data nyata Sumatera Barat di `seeder_sprint3_hazard_culture.go`.',
    deliverable: 'Genap 11/11 tabel PostgreSQL + PostGIS milik BE-1 aktif dengan indeks GIST pada 4 koridor jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44).',
    sqlOrGoFiles: ['backend/internal/be1_core/migrations_sprint3.sql', 'backend/internal/be1_core/seeder_sprint3_hazard_culture.go', 'backend/internal/models/models.go'],
    syncWithRole: 'Mandiri BE-1 (Zero Merge Conflict — tidak menyentuh tabel Escrow/Split-Bill/Radar milik BE-2)',
    verificationCommand: 'psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint3.sql'
  },
  {
    id: 's3-day12',
    day: 'Hari 12 (Selasa — Minggu 3)',
    title: 'Algoritma Behavior-Based Ranking (Gaode Guide) & Telemetri Dwell Time GPS',
    focus: 'Membangun `GET /api/v1/destinations/rankings/gaode` dan `POST /api/v1/spatial/navigation-telemetry` yang menghitung skor keaslian (`0.45 * Nav + 0.40 * DwellTime + 0.15 * ReturnRate`) serta menolak otomatis ping GPS kendaraan yang hanya melintas (<10 menit dwell time).',
    deliverable: 'FE-1 dapat merender Peringkat Gaode Guide bebas manipulasi bintang palsu dan mengirim log penyelesaian navigasi + waktu singgah GPS nyata.',
    sqlOrGoFiles: ['backend/internal/be1_core/gaode_ranking_day12.go', 'backend/internal/be1_core/repository_postgis.go'],
    syncWithRole: 'FE-1 (Layar Peringkat Gaode Guide & Tracker Navigasi Selesai)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/destinations/rankings/gaode" | jq ".rankings[0]"'
  },
  {
    id: 's3-day13',
    day: 'Hari 13 (Rabu — Minggu 3)',
    title: 'API Live Hazard Alert Jalur Ekstrem, Trigger Bencana FS-1 & Pancaran SOS GPS FE-1',
    focus: 'Membangun `GET /api/v1/spatial/hazards` (deteksi radius zona rawan Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44 + `detour_route_geojson`), `POST /api/v1/admin/hazards/trigger` untuk Panel Trigger Bencana FS-1, serta `POST /api/v1/spatial/sos` & `GET /api/v1/admin/sos` untuk pancaran sinyal darurat SOS GPS ke Posko SAR/PKJR terdekat.',
    deliverable: 'FE-1 menerima Banner Peringatan Jalur Rawan otomatis + tombol Pancaran SOS GPS; FS-1 dapat menyimulasikan Trigger Bencana dari Command Center.',
    sqlOrGoFiles: ['backend/internal/be1_core/hazard_sos_day13.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'FE-1 (Banner Peringatan Jalur Rawan & Tombol SOS GPS) dan FS-1 (Panel Trigger Bencana)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/spatial/hazards?lat=-0.9465&lng=100.5180" | jq ".user_in_hazard_zone"'
  },
  {
    id: 's3-day14',
    day: 'Hari 14 (Kamis — Minggu 3)',
    title: 'API Kamus Saku Audio Minang & Kalender Budaya / Hari Pakan Nagari',
    focus: 'Membangun `GET /api/v1/culture/minang-phrases` (frasa praktis bahasa Minang + audio penutur asli + adab *Kato Nan Ampek*) dan `GET /api/v1/culture/events` (jadwal Hari Pakan Pasar Tradisional Nagari, Pacu Jawi, & Tabuik dengan kalkulasi jarak spasial).',
    deliverable: 'FE-1 dapat merender kartu Kamus Saku Audio Minang & Kalender Budaya beraksen Indigo (`--indigo-500` `#5B6AE8`).',
    sqlOrGoFiles: ['backend/internal/be1_core/minang_culture_day14.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'FE-1 (Komponen Kamus Saku Audio Minang & Kalender Budaya Hari Pakan)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/culture/minang-phrases?category=tawar_pasar" | jq ".phrases | length"'
  },
  {
    id: 's3-day15',
    day: 'Hari 15 (Jumat — Target Rilis Sprint 3)',
    title: 'Automated Integration Test Suite Minggu 3 (8 Skenario TC-S3-01 s/d TC-S3-08)',
    focus: 'Menjalankan suite pengujian otomatis Minggu 3 di `backend/internal/be1_core/be1_sprint3_test.go` untuk memverifikasi Output Wajib Jumat Minggu 3: *"API ranking perilaku, hazard alert jalur ekstrem, & SOS siap."*',
    deliverable: 'Output Wajib Jumat Minggu 3 tercapai 100%: 8/8 skenario test Sprint 3 PASS dan seluruh 11/11 tabel BE-1 siap menuju Minggu 4.',
    sqlOrGoFiles: ['backend/internal/be1_core/be1_sprint3_test.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'Sinkronisasi Rilis Jumat Minggu 3 bersama FE-1, FE-2, FS-1, dan BE-2',
    verificationCommand: 'go test -v ./internal/be1_core/... -run TestSprint3IntegrationSuite'
  }
];

export const SPRINT_3_ROLE_BOUNDARY_MATRIX: RoleBoundaryItem[] = [
  {
    roleCode: 'BE-1',
    roleName: 'Backend 1 — Gaode Ranking, Hazard Alert, SOS GPS & Budaya Minang (ANDA)',
    stack: 'Go (1.22 ServeMux) + PostgreSQL/PostGIS',
    sprint1Focus: 'Minggu 3: Menuntaskan 11/11 tabel BE-1 (`gaode_behavior_rankings`, `hazard_alerts`, `sos_signals`, `minang_phrases`, `cultural_events`), Algoritma Gaode Ranking + Telemetri Dwell Time GPS, Live Hazard Alert 4 Koridor Ekstrem + Trigger Bencana FS-1 + SOS GPS FE-1, serta Kamus Audio Minang & Kalender Hari Pakan.',
    ownedTablesOrModules: [
      'gaode_behavior_rankings — Peringkat Perilaku Nyata Anti-Bintang Palsu (Hari 11–12)',
      'hazard_alerts — 4 Koridor Jalur Ekstrem Sumbar + Rute Detour GeoJSON (Hari 11 & 13)',
      'sos_signals — Pancaran Sinyal Darurat SOS GPS Wisatawan (Hari 11 & 13)',
      'minang_phrases & cultural_events — Kamus Audio Minang & Hari Pakan (Hari 11 & 14)'
    ],
    routePrefixOrBoundary: '/api/v1/destinations/rankings/gaode, /api/v1/spatial/navigation-telemetry, /api/v1/spatial/hazards, /api/v1/admin/hazards/trigger, /api/v1/spatial/sos, /api/v1/admin/sos, /api/v1/culture/*',
    interactionRuleForBE1: 'Tetap 100% di dalam `backend/internal/be1_core/`. Jangan menyentuh modul transaksi Escrow, Bot WA Mitra 1/0, Split-Bill, atau Group Live Radar milik BE-2.'
  },
  {
    roleCode: 'BE-2',
    roleName: 'Backend 2 — Quick Booking Escrow, Bot WA 1/0, Split-Bill & Group Radar',
    stack: 'Go + PostgreSQL + WebSocket/SSE',
    sprint1Focus: 'Minggu 3: Bangun API Quick Booking & Ledger Escrow (tahan dana & rilis via scan QR), Simulator Bot WA Mitra (balas 1=Terima / 0=Penuh), Kalkulator Split-Bill Rombongan, Group Live Radar, & Cari Barengan.',
    ownedTablesOrModules: [
      'booking_escrows & ledger_transactions (DILARANG DISENTUH BE-1)',
      'wa_bot_simulations (DILARANG DISENTUH BE-1)',
      'split_bills & split_bill_shares (DILARANG DISENTUH BE-1)',
      'group_live_radar & ride_sharings (DILARANG DISENTUH BE-1)'
    ],
    routePrefixOrBoundary: '/api/v1/bookings/*, /api/v1/escrow/*, /api/v1/wa-webhook/*, /api/v1/groups/*/split-bill, /api/v1/groups/*/radar',
    interactionRuleForBE1: 'JANGAN menyentuh `internal/be2_group/handlers.go`. Seluruh fitur pembayaran escrow, bot WA, split-bill, dan radar rombongan dikerjakan penuh oleh BE-2.'
  },
  {
    roleCode: 'FE-1',
    roleName: 'Frontend 1 — Banner Jalur Rawan, SOS GPS, Gaode Ranking & Kamus Minang',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Minggu 3: Bangun Banner Peringatan Jalur Rawan (otomatis muncul jika rute melewati Sitinjau Lauik/Lembah Anai saat hujan), Tombol Pancaran Darurat SOS GPS, UI Daftar Peringkat Gaode Guide, serta UI Kamus Saku Audio Minang & Kalender Budaya.',
    ownedTablesOrModules: [
      'Banner Peringatan Jalur Rawan & Rute Alternatif (`--Status-Danger` / `--Amber-500`)',
      'Tombol Darurat SOS GPS (Kirim Koordinat + Persentase Baterai)',
      'Leaderboard Peringkat Gaode Guide (Filter Kategori)',
      'Kamus Saku Audio Minang & Kalender Hari Pakan (`--Indigo-500` `#5B6AE8`)'
    ],
    routePrefixOrBoundary: 'Konsumsi GET /api/v1/spatial/hazards, POST /api/v1/spatial/sos, GET .../rankings/gaode, POST .../navigation-telemetry, & GET /api/v1/culture/*',
    interactionRuleForBE1: 'Pastikan `GET /api/v1/spatial/hazards?lat=...&lng=...` mengembalikan objek `fe1_active_warning_banner` siap pakai ketika posisi GPS pengguna berpotongan dengan koridor bahaya.'
  },
  {
    roleCode: 'FE-2',
    roleName: 'Frontend 2 — Quick Booking Drawer, Tiket QR Escrow, Split-Bill & Radar UI',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Minggu 3: Bangun Laci Quick Booking Mitra Nagari, Tiket QR Pembayaran Escrow, Layar 05. Peta Radar Rombongan & Split-Bill, serta UI Cari Barengan.',
    ownedTablesOrModules: ['Laci Quick Booking & Tiket QR Escrow', 'Layar 05. Peta Radar Rombongan & Split-Bill', 'UI Cari Barengan (Share Cost)'],
    routePrefixOrBoundary: 'Full sinkronisasi ke endpoint milik BE-2 (`/api/v1/bookings/*`, `/api/v1/groups/*`)',
    interactionRuleForBE1: 'Pada Minggu 3, FE-2 fokus mengintegrasikan transaksi dan rombongan ke BE-2, sambil tetap memakai endpoint Tarif Perda & Lapor Pungli BE-1 dari Minggu 1–2.'
  },
  {
    roleCode: 'FS-1',
    roleName: 'Fullstack — Panel Trigger Bencana, Monitor SOS, Bot WA & Ledger Escrow',
    stack: 'TypeScript (Web) + Go Bridge',
    sprint1Focus: 'Minggu 3: Bangun Panel Simulasi Trigger Bencana (Sitinjau Lauik / Lembah Anai / Kelok 9) & Monitor Sinyal SOS GPS (ke BE-1), serta Simulator Bot WA Mitra 1/0 & Monitor Ledger Escrow (ke BE-2).',
    ownedTablesOrModules: ['Panel Trigger Bencana Jalur Ekstrem (Ke BE-1)', 'Monitor Antrean Sinyal Darurat SOS GPS (Ke BE-1)', 'Simulator Bot WA Mitra & Monitor Escrow (Ke BE-2)'],
    routePrefixOrBoundary: 'Konsumsi POST /api/v1/admin/hazards/trigger & GET /api/v1/admin/sos pada BE-1',
    interactionRuleForBE1: 'Sediakan endpoint `POST /api/v1/admin/hazards/trigger` berproteksi RBAC (`admin_dispar` / `pokdarwis`) agar tombol simulasi bencana di Command Center FS-1 langsung mengubah status koridor secara live.'
  }
];

export const INITIAL_GAODE_RANKINGS: GaodeRankingRecord[] = [
  {
    id: 'gaode-001',
    destination_id: 'dest-001',
    destination_name: 'Lembah Harau (Aka Barayun & Sarasah Bunta)',
    category: 'Alam & Geopark',
    city_regency: 'Kab. Lima Puluh Kota',
    rank_position: 1,
    gaode_authenticity_score: 98.4,
    active_nav_count_30d: 4820,
    avg_dwell_time_min: 145,
    return_visit_rate_pct: 34.2,
    anti_fake_review_verified: true,
    trending_badge: 'Top #1 Dwell Time Terlama di Sumbar (2,4 Jam Singgah Nyata)',
    updated_at: '2026-11-11T09:00:00Z'
  },
  {
    id: 'gaode-002',
    destination_id: 'dest-002',
    destination_name: 'Jam Gadang & Pasar Atas Bukittinggi',
    category: 'Budaya & Nagari',
    city_regency: 'Kota Bukittinggi',
    rank_position: 2,
    gaode_authenticity_score: 97.1,
    active_nav_count_30d: 6390,
    avg_dwell_time_min: 118,
    return_visit_rate_pct: 41.5,
    anti_fake_review_verified: true,
    trending_badge: 'Top #1 Navigasi Aktif Tertinggi (6.390 Trip Selesai/Bulan)',
    updated_at: '2026-11-11T09:00:00Z'
  },
  {
    id: 'gaode-003',
    destination_id: 'dest-004',
    destination_name: 'Istano Basa Pagaruyung',
    category: 'Budaya & Nagari',
    city_regency: 'Kab. Tanah Datar',
    rank_position: 3,
    gaode_authenticity_score: 95.6,
    active_nav_count_30d: 3910,
    avg_dwell_time_min: 95,
    return_visit_rate_pct: 28.8,
    anti_fake_review_verified: true,
    trending_badge: 'Destinasi Pusako Minangkabau Paling Konsisten',
    updated_at: '2026-11-11T09:00:00Z'
  },
  {
    id: 'gaode-004',
    destination_id: 'dest-005',
    destination_name: 'Kawasan Bahari Mandeh (Puncak Paku)',
    category: 'Alam & Geopark',
    city_regency: 'Kab. Pesisir Selatan',
    rank_position: 4,
    gaode_authenticity_score: 94.8,
    active_nav_count_30d: 2740,
    avg_dwell_time_min: 185,
    return_visit_rate_pct: 31.0,
    anti_fake_review_verified: true,
    trending_badge: 'Dwell Time Bahari Tertinggi (3,1 Jam Island Hopping)',
    updated_at: '2026-11-11T09:00:00Z'
  },
  {
    id: 'gaode-005',
    destination_id: 'dest-008',
    destination_name: 'Nagari Tuo Pariangan (Desa Terindah)',
    category: 'Hidden Gem',
    city_regency: 'Kab. Tanah Datar',
    rank_position: 5,
    gaode_authenticity_score: 93.9,
    active_nav_count_30d: 2180,
    avg_dwell_time_min: 110,
    return_visit_rate_pct: 29.4,
    anti_fake_review_verified: true,
    trending_badge: 'Hidden Gem Nagari Terindah — 99% Selesai Navigasi',
    updated_at: '2026-11-11T09:00:00Z'
  },
  {
    id: 'gaode-006',
    destination_id: 'dest-015',
    destination_name: 'Ngarai Sianok & Janjang Koto Gadang',
    category: 'Alam & Geopark',
    city_regency: 'Kota Bukittinggi',
    rank_position: 6,
    gaode_authenticity_score: 92.7,
    active_nav_count_30d: 3120,
    avg_dwell_time_min: 105,
    return_visit_rate_pct: 26.5,
    anti_fake_review_verified: true,
    trending_badge: 'Favorit Trekking Pagi & Geopark',
    updated_at: '2026-11-11T09:00:00Z'
  },
  {
    id: 'gaode-007',
    destination_id: 'dest-011',
    destination_name: 'Desa Wisata Kubu Gadang (Silek Lanyah)',
    category: 'Hidden Gem',
    city_regency: 'Kota Padang Panjang',
    rank_position: 7,
    gaode_authenticity_score: 91.5,
    active_nav_count_30d: 1640,
    avg_dwell_time_min: 130,
    return_visit_rate_pct: 33.0,
    anti_fake_review_verified: true,
    trending_badge: 'Atraksi Silek Lanyah & Makan Bajamba Terbaik',
    updated_at: '2026-11-11T09:00:00Z'
  },
  {
    id: 'gaode-008',
    destination_id: 'dest-007',
    destination_name: 'Danau Kembar & Kebun Teh Alahan Panjang',
    category: 'Hidden Gem',
    city_regency: 'Kab. Solok',
    rank_position: 8,
    gaode_authenticity_score: 90.8,
    active_nav_count_30d: 2450,
    avg_dwell_time_min: 125,
    return_visit_rate_pct: 27.9,
    anti_fake_review_verified: true,
    trending_badge: 'Rute Dingin Highland Favorit Akhir Pekan',
    updated_at: '2026-11-11T09:00:00Z'
  }
];

export const INITIAL_HAZARD_ALERTS: HazardAlertRecord[] = [
  {
    id: 'haz-001',
    corridor_code: 'SITINJAU-LAUIK',
    location: 'Panorama 1 & Panorama 2 Sitinjau Lauik',
    road_segment: 'Jalan Lintas Padang – Solok KM 18 s/d KM 25 (Kec. Lubuk Kilangan)',
    city_regency: 'Kota Padang – Kab. Solok',
    latitude: -0.9468,
    longitude: 100.5182,
    radius_meter: 3500,
    severity: 'Siaga',
    hazard_type: 'Tanjakan Ekstrem 24° + Kabut Tebal & Risiko Truk Rem Blong',
    weather_status: 'Hujan Lebat & Jarak Pandang 25 Meter',
    slope_gradient_deg: 24,
    message:
      'PERINGATAN JALUR EKSTREM: Curah hujan tinggi di tikungan Panorama 1 Sitinjau Lauik. Sistem buka-tutup aktif oleh relawan PKJR. Gunakan gigi rendah (L/Gigi 1) dan jaga jarak 30 meter dari kendaraan berat.',
    detour_route:
      'Gunakan jalur alternatif via Padang Panjang – Danau Singkarak – Solok (+45 menit lebih aman untuk kendaraan keluarga).',
    detour_route_geojson:
      '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"corridor":"Detour Padang-Panjang-Singkarak-Solok","safety_level":"Aman"},"geometry":{"type":"LineString","coordinates":[[100.3543,-0.8871],[100.3982,-0.4661],[100.5401,-0.6124],[100.6552,-0.7911]]}}]}',
    nearest_rescue_post: 'Posko Terpadu PKJR & BPBD Panorama 1 Sitinjau Lauik',
    emergency_contact: '+62-811-660-112',
    triggered_by_admin: 'Pusdalops BPBD Sumbar / Admin Dispar',
    updated_at: '2026-11-11T09:15:00Z'
  },
  {
    id: 'haz-002',
    corridor_code: 'LEMBAH-ANAI',
    location: 'Kawasan Cagar Alam & Air Terjun Lembah Anai',
    road_segment: 'Jalan Lintas Padang – Bukittinggi KM 62 s/d KM 67',
    city_regency: 'Kab. Tanah Datar – Padang Panjang',
    latitude: -0.4832,
    longitude: 100.3385,
    radius_meter: 3000,
    severity: 'Waspada',
    hazard_type: 'Rawan Luapan Sungai Batang Anai & Tebing Longsor saat Hujan Hulu',
    weather_status: 'Mendung Tebal di Hulu Gunung Singgalang',
    slope_gradient_deg: 14,
    message:
      'WASPADA KORIDOR LEMBAH ANAI: Pantauan debit air Batang Anai meningkat sedang. Dilarang berhenti atau parkir di bahu jalan tepat di bawah tebing curam.',
    detour_route:
      'Rute pengalihan darurat via Malalak (Sicincin – Malalak – Bukittinggi) khusus kendaraan roda 4 sehat.',
    detour_route_geojson:
      '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"corridor":"Detour Via Jalur Malalak","safety_level":"Alternatif"},"geometry":{"type":"LineString","coordinates":[[100.2711,-0.6122],[100.2945,-0.4150],[100.3692,-0.3051]]}}]}',
    nearest_rescue_post: 'Posko Siaga SAR & Satlantas Padang Panjang (Rest Area Anai)',
    emergency_contact: '+62-811-664-911',
    triggered_by_admin: 'Sistem Sensor Cuaca Otomatis BE-1',
    updated_at: '2026-11-11T09:15:00Z'
  },
  {
    id: 'haz-003',
    corridor_code: 'KELOK-9',
    location: 'Flyover & Lembah Kelok 9 Hulu Air Putih',
    road_segment: 'Jalan Lintas Sumatera Barat – Riau KM 24 Lubuk Bangku',
    city_regency: 'Kab. Lima Puluh Kota',
    latitude: -0.0706,
    longitude: 100.6975,
    radius_meter: 2500,
    severity: 'Normal',
    hazard_type: 'Tikungan Tajam Berjenjang & Area Larangan Parkir di Atas Jembatan',
    weather_status: 'Cerah Berawan',
    slope_gradient_deg: 16,
    message:
      'Jalur Flyover Kelok 9 lancar dan aman. Wisatawan yang ingin menikmati kuliner jagung bakar & panorama wajib parkir di kantong parkir resmi bawah jembatan.',
    detour_route: 'Tidak diperlukan pengalihan arus (Jalur Utama Normal).',
    detour_route_geojson:
      '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"corridor":"Jalur Normal Flyover Kelok 9","safety_level":"Normal"},"geometry":{"type":"LineString","coordinates":[[100.6940,-0.0725],[100.6975,-0.0706],[100.7010,-0.0680]]}}]}',
    nearest_rescue_post: 'Pos Pengamanan Terpadu Flyover Kelok 9 & Pokdarwis Air Putih',
    emergency_contact: '+62-812-6700-990',
    triggered_by_admin: 'Sistem Sensor Cuaca Otomatis BE-1',
    updated_at: '2026-11-11T09:15:00Z'
  },
  {
    id: 'haz-004',
    corridor_code: 'KELOK-44',
    location: 'Jalur Kelok 44 (Ambun Pagi – Danau Maninjau)',
    road_segment: 'Jalan Raya Bukittinggi – Lubuk Basung via Matur',
    city_regency: 'Kab. Agam',
    latitude: -0.3125,
    longitude: 100.2145,
    radius_meter: 4000,
    severity: 'Waspada',
    hazard_type: '44 Tikungan Hairpin 180° + Kabut Sore & Kawanan Kera Liar',
    weather_status: 'Kabut Sore (Jarak Pandang 40m di Kelok 35–44)',
    slope_gradient_deg: 22,
    message:
      'WASPADA KELOK 44: Bunyikan klakson singkat sebelum masuk tikungan patah (Kelok 1 s/d 44). Pastikan suhu rem normal dan beri jalan bagi kendaraan yang menanjak dari arah Maninjau.',
    detour_route:
      'Untuk bus besar atau pengemudi pemula, gunakan rute memutar via Pariaman – Tiku – Lubuk Basung.',
    detour_route_geojson:
      '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"corridor":"Detour Pesisir Pariaman-Tiku-Maninjau","safety_level":"Aman Bus/Pemula"},"geometry":{"type":"LineString","coordinates":[[100.1205,-0.6250],[99.9240,-0.3980],[100.1650,-0.3280]]}}]}',
    nearest_rescue_post: 'Posko Pokdarwis Ambun Pagi & Polsek Matur',
    emergency_contact: '+62-813-7400-440',
    triggered_by_admin: 'Sistem Sensor Cuaca Otomatis BE-1',
    updated_at: '2026-11-11T09:15:00Z'
  }
];

export const INITIAL_SOS_SIGNALS: SOSSignalRecord[] = [
  {
    id: 'sos-001',
    sos_code: 'SOS-SUMBAR-202611-001',
    tourist_name: 'Rombongan Keluarga Hendra Wijaya',
    phone_number: '+6281299887711',
    emergency_type: 'Kendaraan Mogok / Kampas Kopling Panas di Tanjakan',
    latitude: -0.9455,
    longitude: 100.5169,
    battery_percent: 28,
    passengers_count: 5,
    nearest_corridor: 'Panorama 1 Sitinjau Lauik (KM 19)',
    nearest_rescue_post: 'Posko Terpadu PKJR & BPBD Panorama 1 Sitinjau Lauik',
    distance_to_rescue_km: 0.8,
    eta_rescue_minutes: 5,
    status: 'Tim SAR Meluncur',
    notes: 'Relawan pengganjal ban PKJR sudah berada 300 meter dari titik koordinat.',
    created_at: '2026-11-11T08:50:00Z'
  }
];

export const INITIAL_MINANG_PHRASES: MinangPhraseRecord[] = [
  {
    id: 'minang-001',
    category: 'tawar_pasar',
    indonesian_text: 'Berapa harga pasnya ini, Uni / Uda? Boleh kurang sedikit?',
    minang_text: 'Bara harago pasnyo ko, Ni / Da? Buliah kurang saketek?',
    phonetic_guide: 'Ba-ra ha-ra-go pas-nyo ko, Ni / Da? Bu-liah ku-rang sa-ke-tek?',
    audio_url: 'https://cdn.rancak.in/audio/minang/bara-harago-pasnyo.mp3',
    dialect_note: 'Dialek Umum Sumatera Barat (Bukittinggi & Padang)',
    usage_context_tip: 'Gunakan dengan senyum ramah saat berbelanja kerupuk sanjai atau sulaman di Pasar Atas Bukittinggi.',
    politeness_level: 'Kato Malereang / Sopan Akrab'
  },
  {
    id: 'minang-002',
    category: 'sapaan_adat',
    indonesian_text: 'Permisi Ibu / Bapak, saya wisatawan ingin numpang bertanya jalan.',
    minang_text: 'Maaf Bundo / Apak, ambo tamu nak numpang batanyo jalan.',
    phonetic_guide: 'Ma-af Bun-do / A-pak, am-bo ta-mu nak num-pang ba-ta-nyo ja-lan.',
    audio_url: 'https://cdn.rancak.in/audio/minang/maaf-bundo-batanyo-jalan.mp3',
    dialect_note: 'Dialek Darek (Tanah Datar, Agam, Lima Puluh Kota)',
    usage_context_tip: 'Sangat dihormati saat memasuki kawasan Nagari Tuo Pariangan atau desa adat.',
    politeness_level: 'Kato Mandaki (Sangat Sopan kepada yang lebih tua)'
  },
  {
    id: 'minang-003',
    category: 'kuliner_rm',
    indonesian_text: 'Makanannya enak sekali! Tolong kuah gulai/sambalnya dipisah ya, jangan terlalu pedas.',
    minang_text: 'Lamak bana makanannyo! Tolong kuah jo ladonyo dipisah yo, jan talampau padeh.',
    phonetic_guide: 'La-mak ba-na ma-ka-nan-nyo! To-long ku-ah jo la-do-nyo di-pi-sah yo, jan ta-lam-pau pa-deh.',
    audio_url: 'https://cdn.rancak.in/audio/minang/lamak-bana-jan-padeh.mp3',
    dialect_note: 'Dialek Umum Rumah Makan Minang',
    usage_context_tip: "Ucapkan 'Lamak bana' sebagai pujian tulus kepada pemilik warung/kafe nagari.",
    politeness_level: 'Kato Mendatar (Sopan Sehari-hari)'
  },
  {
    id: 'minang-004',
    category: 'navigasi_darurat',
    indonesian_text: 'Tolong bantu kami, mobil kami tidak kuat menanjak / ban kempes di sini.',
    minang_text: 'Tolong bantu kami Da, oto kami ndak kuek mandaki / ban kampeh di siko.',
    phonetic_guide: 'To-long ban-tu ka-mi Da, o-to ka-mi ndak ku-ek man-da-ki / ban kam-peh di si-ko.',
    audio_url: 'https://cdn.rancak.in/audio/minang/tolong-oto-ndak-kuek-mandaki.mp3',
    dialect_note: 'Dialek Lintas Jalur Sitinjau Lauik & Kelok 44',
    usage_context_tip: 'Sangat berguna saat meminta bantuan warga lokal atau relawan PKJR di jalur tanjakan.',
    politeness_level: 'Darurat & Respek Lokal'
  },
  {
    id: 'minang-005',
    category: 'sapaan_adat',
    indonesian_text: 'Terima kasih banyak atas bantuannya, semoga berkah selalu.',
    minang_text: 'Tarimo kasih banyak Da / Ni, mudah-mudahan barakah salamo-lamonyo.',
    phonetic_guide: 'Ta-ri-mo ka-sih ba-nyak Da / Ni, mu-dah mu-da-han ba-ra-kah sa-la-mo la-mo-nyo.',
    audio_url: 'https://cdn.rancak.in/audio/minang/tarimo-kasih-banyak.mp3',
    dialect_note: 'Dialek Umum Sumatera Barat',
    usage_context_tip: 'Penutup percakapan yang hangat dengan pemandu Pokdarwis atau pedagang nagari.',
    politeness_level: 'Kato Mandaki & Mendatar'
  }
];

export const INITIAL_CULTURAL_EVENTS: CulturalEventRecord[] = [
  {
    id: 'cult-001',
    title: 'Aleknagari Pacu Jawi (Balap Sapi Sawah Berlumpur)',
    event_type: 'Tradisi Adat',
    nagari_location: 'Nagari Tuo Pariangan & Kecamatan Rambatan',
    city_regency: 'Kab. Tanah Datar',
    schedule_rule: 'Setiap Sabtu Sore (Bergilir antar 4 Kecamatan usai panen padi)',
    next_event_date: '2026-11-14',
    latitude: -0.4612,
    longitude: 100.5105,
    highlight_item: 'Atraksi joki memacu sepasang sapi di sawah berlumpur berlatar Gunung Marapi + Pasar Kuliner Kawa Daun.',
    cultural_etiquette: 'Berdiri di atas pematang yang ditentukan Pokdarwis, jangan menggunakan payung warna merah mencolok di tepi lintasan sawah.'
  },
  {
    id: 'cult-002',
    title: 'Hari Pakan Kamih (Pasar Tradisional Kamis Batusangkar)',
    event_type: 'Hari Pakan Nagari',
    nagari_location: 'Pasar Serikat C Batusangkar & Balai Selasa',
    city_regency: 'Kab. Tanah Datar',
    schedule_rule: 'Setiap Hari Kamis Pagi (06.00 – 13.00 WIB)',
    next_event_date: '2026-11-12',
    latitude: -0.4561,
    longitude: 100.5912,
    highlight_item: 'Sentra kuliner langka Lamang Tapai, Dakak-Dakak Simabua, Kopi Kawa Daun, dan tenun Silungkang/Pandai Sikek.',
    cultural_etiquette: 'Datang sebelum pukul 10.00 pagi untuk mendapatkan kuliner tradisional hangat langsung dari dapur induak-induak nagari.'
  },
  {
    id: 'cult-003',
    title: 'Hari Pakan Sabtu & Pasar Kaget Koto Baru (Sentra Bika & Sayur Segar)',
    event_type: 'Hari Pakan Nagari',
    nagari_location: 'Nagari Koto Baru (Kaki Gunung Marapi & Singgalang)',
    city_regency: 'Kab. Tanah Datar – Padang Panjang',
    schedule_rule: 'Setiap Hari Selasa & Sabtu Pagi',
    next_event_date: '2026-11-14',
    latitude: -0.4125,
    longitude: 100.3910,
    highlight_item: 'Pasar agrikultur dataran tinggi terbesar beserta deretan tungku Bika Talago & Bika Mariana tradisional.',
    cultural_etiquette: 'Gunakan kantong parkir resmi agar tidak menghambat arus utama Padang Panjang – Bukittinggi.'
  },
  {
    id: 'cult-004',
    title: 'Pesta Budaya Hoyak Tabuik Piaman',
    event_type: 'Festival Budaya',
    nagari_location: 'Pantai Gandoriah & Simpang Tabuik',
    city_regency: 'Kota Pariaman',
    schedule_rule: 'Agenda Tahunan Akbar (1–10 Muharram) & Pameran Miniatur Setiap Akhir Pekan',
    next_event_date: '2026-11-21',
    latitude: -0.6267,
    longitude: 100.1179,
    highlight_item: 'Prosesi arak-arakan menara Tabuik Pasa & Tabuik Subarang setinggi 12 meter diiringi tabuhan Gendang Tasa.',
    cultural_etiquette: 'Kenakan pakaian sopan dan ikuti arahan koridor penonton saat prosesi pelarungan ke laut menjelang magrib.'
  },
  {
    id: 'cult-005',
    title: 'Pakan Rabaa & Pameran Kerajinan Perak Koto Gadang',
    event_type: 'Hari Pakan Nagari',
    nagari_location: 'Nagari Koto Gadang (Seberang Ngarai Sianok)',
    city_regency: 'Kab. Agam',
    schedule_rule: 'Setiap Hari Rabu & Sabtu (08.00 – 16.00 WIB)',
    next_event_date: '2026-11-18',
    latitude: -0.3131,
    longitude: 100.3547,
    highlight_item: 'Demo langsung pengrajin filigri perak Koto Gadang, sulaman Selendang Koto Gadang, dan sajian Gulai Itiak Lado Mudo.',
    cultural_etiquette: 'Mintalah izin terlebih dahulu sebelum memotret jarak dekat wajah pengrajin lansia di rumah gadang.'
  }
];
