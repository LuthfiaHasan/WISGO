import type { DailyTaskStep, RoleBoundaryItem } from './sprint1ArchitectureData';

export interface EndpointCatalogRecord {
  number: number;
  sprint: 'Minggu 1 (Sprint 1)' | 'Minggu 2 (Sprint 2)' | 'Minggu 3 (Sprint 3)' | 'Minggu 4 (Sprint 4)';
  day: string;
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  title: string;
  pillar_ref: string;
  auth_guard: string;
  consumer_role: string;
  target_sla_ms: number;
  cache_or_guard: string;
}

export interface BenchmarkProbeRecord {
  probe: string;
  latency_ms: number;
  index_used: string;
}

export const SPRINT_4_DAILY_STEPS: DailyTaskStep[] = [
  {
    id: 's4-day16',
    day: 'Hari 16 (Senin — Minggu 4)',
    title: 'Optimasi Indeks Spasial PostGIS (<100ms SLA), Partial Index & Materialized View',
    focus: 'Menjalankan skrip tuning performa `backend/internal/be1_core/migrations_sprint4_tuning.sql` yang menambahkan Composite Index (`category`, `city_regency`, `crowd_level`), Partial Index khusus `blank_spot` & koridor bencana `Siaga/Awas`, serta Materialized View `mv_gaode_leaderboard`.',
    deliverable: 'Seluruh kueri spasial PostGIS (`ST_DWithin` + `ST_DistanceSphere`) dieksekusi di bawah 15ms–45ms (jauh di bawah batas SLA <100ms).',
    sqlOrGoFiles: ['backend/internal/be1_core/migrations_sprint4_tuning.sql', 'backend/internal/be1_core/repository_postgis.go'],
    syncWithRole: 'Mandiri BE-1 (Zero Merge Conflict — murni tuning 11 tabel milik BE-1)',
    verificationCommand: 'psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint4_tuning.sql'
  },
  {
    id: 's4-day17',
    day: 'Hari 17 (Selasa — Minggu 4)',
    title: 'In-Memory TTL Cache + HTTP ETag (304 Not Modified) untuk Kanvas 360° & Rute',
    focus: 'Membangun lapisan caching Go standar (`InMemoryTTLCache`) di `cache_etag_day17.go` dengan dukungan header `X-Cache: HIT|MISS`, `ETag` (`W/"rancak-be1-..."`), respons `304 Not Modified` saat `If-None-Match` cocok, dan auto-invalidation saat Admin FS-1 mengubah data CMS.',
    deliverable: 'FE-1 membuka ulang Kanvas 360°, Direktori 20 Destinasi, dan Offline Bundle v2 dalam <5ms tanpa membebani PostgreSQL.',
    sqlOrGoFiles: ['backend/internal/be1_core/cache_etag_day17.go', 'backend/internal/be1_core/panorama_360_day7.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'FE-1 (Pemuatan Instan Kanvas 360° & Offline Bundle) dan FS-1 (Auto-Invalidate saat Edit CMS)',
    verificationCommand: 'curl -i "http://localhost:3000/api/v1/destinations/dest-001/scenes-360" | grep -E "X-Cache|ETag"'
  },
  {
    id: 's4-day18',
    day: 'Hari 18 (Rabu — Minggu 4)',
    title: 'Hardening Keamanan & Token Bucket Rate-Limiting Anti-Spam (HTTP 429)',
    focus: 'Membangun middleware `TokenBucketRateLimiter` di `ratelimit_security_day18.go` untuk memproteksi endpoint publik sensitif (`POST /api/v1/pungli/report`, `POST /api/v1/spatial/sos`, `POST /api/v1/spatial/navigation-telemetry`) lengkap dengan header `X-RateLimit-Limit`, `X-RateLimit-Remaining`, dan `Retry-After: 60`.',
    deliverable: 'Serangan spam laporan pungli palsu atau sinyal SOS beruntun langsung ditolak dengan HTTP 429 Too Many Requests.',
    sqlOrGoFiles: ['backend/internal/be1_core/ratelimit_security_day18.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'FE-1 (Proteksi SOS & Telemetri GPS) dan FE-2 (Proteksi Form Lapor Pungli)',
    verificationCommand: 'curl -i -X POST "http://localhost:3000/api/v1/pungli/report" -H "X-Simulate-RateLimit: burst"'
  },
  {
    id: 's4-day19',
    day: 'Hari 19 (Kamis — Minggu 4)',
    title: 'API Live Benchmark (<100ms), Admin Cache Flush, & Katalog Final 24 Endpoint BE-1',
    focus: 'Membuka 3 endpoint penutup kuota 24 Endpoint BE-1: `GET /api/v1/admin/system/benchmark` (mengukur latensi nyata p50/p95/p99 <100ms, rasio Cache HIT, & kesiapan 11 tabel), `POST /api/v1/admin/cache/flush`, dan `GET /api/v1/system/contracts` (daftar lengkap 24 kontrak API BE-1).',
    deliverable: 'Genap 24/24 Endpoint BE-1 terdokumentasi dan dapat diaudit performanya secara live oleh FS-1 maupun tim QA.',
    sqlOrGoFiles: ['backend/internal/be1_core/benchmark_contracts_day19.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'FS-1 (Panel Benchmark & Cache Flush Admin) serta FE-1 & FE-2 (Katalog Kontrak Final)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/system/contracts" | jq ".total_endpoints"'
  },
  {
    id: 's4-day20',
    day: 'Hari 20 (Jumat — Penutupan 1 Bulan Penuh)',
    title: 'Final Automated Integration Test Suite Sprint 4 & Rilis Penuh 24 Endpoint BE-1',
    focus: 'Menjalankan `TestSprint4IntegrationSuite` (`TC-S4-01` s/d `TC-S4-08`) di `be1_sprint4_test.go` untuk memverifikasi Output Wajib Jumat Minggu 4: *"Seluruh 24 endpoint BE-1 stabil, aman, & lolos uji beban (<100ms)."*',
    deliverable: 'Total 32 skenario pengujian otomatis (Sprint 1–4) LULUS 100%, 11/11 tabel PostGIS optimal, dan 24/24 endpoint BE-1 siap demo akhir.',
    sqlOrGoFiles: ['backend/internal/be1_core/be1_sprint4_test.go', 'backend/internal/be1_core/handlers.go'],
    syncWithRole: 'Penutupan Sprint 4 (Full 1 Bulan) bersama FE-1, FE-2, FS-1, dan BE-2',
    verificationCommand: 'go test -v ./internal/be1_core/... -run TestSprint4IntegrationSuite'
  }
];

export const SPRINT_4_ROLE_BOUNDARY_MATRIX: RoleBoundaryItem[] = [
  {
    roleCode: 'BE-1',
    roleName: 'Backend 1 — Optimasi PostGIS <100ms, Cache 360° ETag, Rate-Limiter & 24 Endpoint Final (ANDA)',
    stack: 'Go (1.22 ServeMux) + PostgreSQL/PostGIS + Native TTL Cache',
    sprint1Focus: 'Minggu 4 (Hari 16–20): Optimasi indeks spasial PostGIS (<100ms SLA), In-Memory TTL Cache + HTTP ETag (`304 Not Modified`) untuk Kanvas 360° & Rute, Token Bucket Rate-Limiting (`HTTP 429`) pada Lapor Pungli & SOS GPS, serta pembukaan 3 endpoint penutup sehingga genap 24/24 Endpoint BE-1 selesai.',
    ownedTablesOrModules: [
      'migrations_sprint4_tuning.sql — Composite GIST & B-Tree Index + mv_gaode_leaderboard (Hari 16)',
      'cache_etag_day17.go — In-Memory TTL Cache + HTTP ETag 304 Not Modified (Hari 17)',
      'ratelimit_security_day18.go — Token Bucket Rate-Limiter Anti-Spam HTTP 429 (Hari 18)',
      'benchmark_contracts_day19.go & be1_sprint4_test.go — Benchmark <100ms & Katalog 24 Endpoint (Hari 19–20)'
    ],
    routePrefixOrBoundary: '/api/v1/admin/system/benchmark, /api/v1/admin/cache/flush, /api/v1/system/contracts (+ seluruh 21 endpoint Minggu 1–3)',
    interactionRuleForBE1: 'Tetap 100% di dalam `backend/internal/be1_core/`. Jangan menyentuh modul Paspor Digital Nagari, Check-in GPS 100m, Lencana Sutan Rancak, atau Analitik Pokdarwis milik BE-2.'
  },
  {
    roleCode: 'BE-2',
    roleName: 'Backend 2 — Paspor Digital Nagari (Check-in GPS 100m), Lencana Sutan Rancak & Analitik Pokdarwis',
    stack: 'Go + PostgreSQL',
    sprint1Focus: 'Minggu 4: Bangun API Paspor Digital Nagari (validasi check-in GPS radius 100m), Kalkulasi Lencana "Sutan Rancak", Generator Metadata Story Card 9:16, serta API Rekap Analitik Pokdarwis.',
    ownedTablesOrModules: [
      'digital_passports & gps_checkins_100m (DILARANG DISENTUH BE-1)',
      'sutan_rancak_badges & story_cards (DILARANG DISENTUH BE-1)',
      'pokdarwis_analytics_summary (DILARANG DISENTUH BE-1)'
    ],
    routePrefixOrBoundary: '/api/v1/passport/*, /api/v1/badges/*, /api/v1/story-card/*, /api/v1/admin/pokdarwis-analytics',
    interactionRuleForBE1: 'JANGAN menyentuh `internal/be2_group/handlers.go`. Seluruh fitur gamifikasi Paspor Digital Nagari & analitik transaksi Pokdarwis di Minggu 4 adalah wewenang penuh BE-2.'
  },
  {
    roleCode: 'FE-1',
    roleName: 'Frontend 1 — Optimasi FPS Kanvas 360° (Cache ETag) & Polish Akhir Navigasi',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Minggu 4: Memanfaatkan header `ETag` dan `If-None-Match` dari BE-1 untuk pemuatan instan Kanvas 360° & Offline Bundle, serta melakukan polish akhir transisi antar layar.',
    ownedTablesOrModules: [
      'HTTP Client ETag / 304 Not Modified Handler (Kanvas 360° & Direktori)',
      'Penanganan ramah pesan Rate-Limit (HTTP 429) pada Tombol Darurat SOS GPS'
    ],
    routePrefixOrBoundary: 'Konsumsi 15 Endpoint Spasial, 360°, Shunlu, Gaode, Hazard, SOS, & Budaya milik BE-1',
    interactionRuleForBE1: 'Pastikan header `X-Cache` dan `ETag` selalu dikirim pada `GET /api/v1/destinations/{id}/scenes-360`, `GET /api/v1/destinations`, dan `GET /api/v1/destinations/{id}/offline-bundle`.'
  },
  {
    roleCode: 'FE-2',
    roleName: 'Frontend 2 — Layar 06 Paspor Digital Nagari, Story Card 9:16 & Proteksi Anti-Spam Pungli',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Minggu 4: Bangun Layar 06. Paspor Digital Nagari & Generator Story Card IG/WA 9:16 (ke BE-2), serta integrasi penanganan `HTTP 429 Too Many Requests` pada Form Lapor Pungli (ke BE-1).',
    ownedTablesOrModules: [
      'Layar 06. Paspor Digital Nagari & Lencana Sutan Rancak (Ke BE-2)',
      'Generator Story Card 9:16 (Ke BE-2)',
      'Guard Cooldown 60 Detik pada Form Lapor Pungli saat menerima HTTP 429 (Ke BE-1)'
    ],
    routePrefixOrBoundary: 'Sinkronisasi Paspor Digital ke BE-2 & Proteksi Rate-Limit Lapor Pungli ke BE-1',
    interactionRuleForBE1: 'Pastikan saat `POST /api/v1/pungli/report` terkena batas Token Bucket, BE-1 mengembalikan `retry_after_seconds: 60` agar FE-2 dapat menampilkan hitung mundur di UI.'
  },
  {
    roleCode: 'FS-1',
    roleName: 'Fullstack — Panel Live Benchmark <100ms, Cache Control & Analitik Pokdarwis',
    stack: 'TypeScript (Web) + Go Bridge',
    sprint1Focus: 'Minggu 4: Mengintegrasikan Panel Live Benchmark (<100ms SLA) & tombol Flush Cache ke BE-1 (`GET /api/v1/admin/system/benchmark`, `POST /api/v1/admin/cache/flush`), serta Grafik Analitik Pokdarwis ke BE-2.',
    ownedTablesOrModules: [
      'Panel Verifikasi Performa <100ms & Rasio Cache HIT (Ke BE-1)',
      'Tombol Manual Flush Cache 360° & Rute (Ke BE-1)',
      'Dashboard Analitik Pendapatan Pokdarwis (Ke BE-2)'
    ],
    routePrefixOrBoundary: 'Konsumsi GET /api/v1/admin/system/benchmark, POST /api/v1/admin/cache/flush, & GET /api/v1/system/contracts',
    interactionRuleForBE1: 'Sediakan metrik `p50_latency_ms`, `p95_latency_ms`, `p99_latency_ms`, dan `probe_breakdown_ms` siap tampil untuk panel penutupan Sprint 4.'
  }
];

export const BE1_24_ENDPOINTS_CATALOG: EndpointCatalogRecord[] = [
  // Minggu 1 (Sprint 1) — 7 Endpoint
  { number: 1, sprint: 'Minggu 1 (Sprint 1)', day: 'Hari 1', method: 'GET', path: '/api/v1/health', title: 'Healthcheck Server & Kesiapan 11 Tabel PostGIS BE-1', pillar_ref: 'Infrastruktur', auth_guard: 'Public', consumer_role: 'FE-1, FE-2, FS-1', target_sla_ms: 10, cache_or_guard: 'Zero-Latency Direct' },
  { number: 2, sprint: 'Minggu 1 (Sprint 1)', day: 'Hari 4', method: 'GET', path: '/api/v1/destinations', title: 'Direktori 20 Destinasi Sumbar + Filter Spasial ST_DistanceSphere', pillar_ref: 'Pilar 2 (P2.1)', auth_guard: 'Public', consumer_role: 'FE-1 (Layar 01 Beranda)', target_sla_ms: 45, cache_or_guard: 'InMemoryTTLCache + ETag (304)' },
  { number: 3, sprint: 'Minggu 1 (Sprint 1)', day: 'Hari 4', method: 'GET', path: '/api/v1/destinations/{id}', title: 'Aggregate Detail Destinasi (4 Statistik + 5 Indikator Medan + Tips + Tarif)', pillar_ref: 'Pilar 2 & 3 (P2.2, P3.1)', auth_guard: 'Public', consumer_role: 'FE-1 (Layar 02) & FE-2', target_sla_ms: 50, cache_or_guard: 'Composite Index PostGIS' },
  { number: 4, sprint: 'Minggu 1 (Sprint 1)', day: 'Hari 4', method: 'GET', path: '/api/v1/destinations/{id}/tariffs', title: 'Tabel Fair-Price Barometer Resmi Perda / Nagari', pillar_ref: 'Pilar 3 (P3.1)', auth_guard: 'Public', consumer_role: 'FE-2 (Fair-Price Table)', target_sla_ms: 35, cache_or_guard: 'B-Tree Index Tariffs' },
  { number: 5, sprint: 'Minggu 1 (Sprint 1)', day: 'Hari 4 & 10', method: 'GET', path: '/api/v1/destinations/{id}/offline-bundle', title: 'Bundel JSON Offline v2 (Destinasi + 360° + Peta Mikro + Audio Trigger)', pillar_ref: 'Pilar 7 (P7.1)', auth_guard: 'Public', consumer_role: 'FE-1 (Offline Hive/Sqflite)', target_sla_ms: 65, cache_or_guard: 'InMemoryTTLCache + ETag (304)' },
  { number: 6, sprint: 'Minggu 1 (Sprint 1)', day: 'Hari 5', method: 'POST', path: '/api/v1/admin/destinations', title: 'CMS Tambah Destinasi Baru + 5 Indikator Medan', pillar_ref: 'CMS FS-1', auth_guard: 'JWT RBAC (admin_dispar, pokdarwis)', consumer_role: 'FS-1 (Web Admin CMS)', target_sla_ms: 70, cache_or_guard: 'Auto-Invalidate Cache' },
  { number: 7, sprint: 'Minggu 1 (Sprint 1)', day: 'Hari 5', method: 'PUT', path: '/api/v1/admin/destinations/{id}/tariffs', title: 'CMS Pembaruan Tarif Resmi Perda / Nagari', pillar_ref: 'Pilar 3 (P3.1)', auth_guard: 'JWT RBAC (admin_dispar, pokdarwis)', consumer_role: 'FS-1 (Web Admin CMS)', target_sla_ms: 65, cache_or_guard: 'Auto-Invalidate Cache' },

  // Minggu 2 (Sprint 2) — 7 Endpoint
  { number: 8, sprint: 'Minggu 2 (Sprint 2)', day: 'Hari 7', method: 'GET', path: '/api/v1/destinations/{id}/scenes-360', title: 'Tur Imersif 360° Aerial-to-Ground & 4 Jenis Pin Interaktif', pillar_ref: 'Pilar 1 (P1.1, P1.2)', auth_guard: 'Public', consumer_role: 'FE-1 (Layar 03 Kanvas 360°)', target_sla_ms: 40, cache_or_guard: 'InMemoryTTLCache + ETag (304)' },
  { number: 9, sprint: 'Minggu 2 (Sprint 2)', day: 'Hari 7', method: 'POST', path: '/api/v1/admin/scenes-360/{sceneId}/hotspots', title: 'CMS Studio 360° Visual Editor (Drag & Drop Pitch/Yaw 4 Pin)', pillar_ref: 'Pilar 1 (P1.2)', auth_guard: 'JWT RBAC (admin_dispar, pokdarwis)', consumer_role: 'FS-1 (Studio 360° Editor)', target_sla_ms: 60, cache_or_guard: 'Auto-Invalidate Cache' },
  { number: 10, sprint: 'Minggu 2 (Sprint 2)', day: 'Hari 8', method: 'POST', path: '/api/v1/spatial/shunlu', title: 'Pencarian Searah Rute (Along-the-Route "Shunlu" +X Menit Detour)', pillar_ref: 'Pilar 2 (P2.3)', auth_guard: 'Public', consumer_role: 'FE-1 (Shunlu Filter Chip)', target_sla_ms: 55, cache_or_guard: 'GIST Spatial Buffer Index' },
  { number: 11, sprint: 'Minggu 2 (Sprint 2)', day: 'Hari 8', method: 'GET', path: '/api/v1/destinations/{id}/micro-map', title: 'Peta Mikro Internal Kawasan Wisata + Titik Audio GPS <=15m', pillar_ref: 'Pilar 1 & 2 (P1.3, P2.5)', auth_guard: 'Public', consumer_role: 'FE-1 (Peta Mikro & Audio)', target_sla_ms: 45, cache_or_guard: 'GIST Spatial Index' },
  { number: 12, sprint: 'Minggu 2 (Sprint 2)', day: 'Hari 9', method: 'GET', path: '/api/v1/qr/{qrCode}', title: 'Resolusi Cepat Scanner Plang Smart QR Fisik di Lokasi', pillar_ref: 'Pilar 3 (P3.2)', auth_guard: 'Public', consumer_role: 'FE-2 (Scanner Plang QR)', target_sla_ms: 30, cache_or_guard: 'Unique QR Code Index' },
  { number: 13, sprint: 'Minggu 2 (Sprint 2)', day: 'Hari 9', method: 'POST', path: '/api/v1/pungli/report', title: 'Pengiriman Bukti Lapor Pungli (Foto + Tag GPS + Kalkulasi Selisih Perda)', pillar_ref: 'Pilar 3 (P3.3)', auth_guard: 'Public (Boleh Anonim)', consumer_role: 'FE-2 (Form Lapor Pungli)', target_sla_ms: 75, cache_or_guard: 'Token Bucket Rate-Limit (HTTP 429)' },
  { number: 14, sprint: 'Minggu 2 (Sprint 2)', day: 'Hari 9', method: 'PATCH', path: '/api/v1/admin/pungli/{id}/status', title: 'Pusat Komando Satgas Saber Pungli (Tindak Lanjut Status Laporan)', pillar_ref: 'Pilar 3 (P3.3)', auth_guard: 'JWT RBAC (admin_dispar)', consumer_role: 'FS-1 (Dashboard Satgas)', target_sla_ms: 60, cache_or_guard: 'RBAC Strict Audit' },

  // Minggu 3 (Sprint 3) — 7 Endpoint
  { number: 15, sprint: 'Minggu 3 (Sprint 3)', day: 'Hari 12', method: 'GET', path: '/api/v1/destinations/rankings/gaode', title: 'Leaderboard Behavior-Based Ranking (Gaode Guide Anti-Bintang Palsu)', pillar_ref: 'Pilar 2 (P2.4)', auth_guard: 'Public', consumer_role: 'FE-1 (Leaderboard Gaode)', target_sla_ms: 35, cache_or_guard: 'Materialized View mv_gaode_leaderboard' },
  { number: 16, sprint: 'Minggu 3 (Sprint 3)', day: 'Hari 12', method: 'POST', path: '/api/v1/spatial/navigation-telemetry', title: 'Ingesti Telemetri Navigasi Nyata & Dwell Time GPS (>=20m Valid)', pillar_ref: 'Pilar 2 (P2.4)', auth_guard: 'Public', consumer_role: 'FE-1 (Background GPS Hook)', target_sla_ms: 50, cache_or_guard: 'Token Bucket Rate-Limit (HTTP 429)' },
  { number: 17, sprint: 'Minggu 3 (Sprint 3)', day: 'Hari 13', method: 'GET', path: '/api/v1/spatial/hazards', title: 'Radar Live Hazard Alert 4 Jalur Ekstrem Sumbar + Rute Alternatif', pillar_ref: 'Pilar 7 (P7.2)', auth_guard: 'Public', consumer_role: 'FE-1 (Banner Bahaya & Detour)', target_sla_ms: 35, cache_or_guard: 'Partial GIST Index Active Hazards' },
  { number: 18, sprint: 'Minggu 3 (Sprint 3)', day: 'Hari 13', method: 'POST', path: '/api/v1/admin/hazards/trigger', title: 'Simulasi & Trigger Status Bencana Jalur Ekstrem oleh Admin Dispar/BPBD', pillar_ref: 'Pilar 7 (P7.2)', auth_guard: 'JWT RBAC (admin_dispar, pokdarwis)', consumer_role: 'FS-1 (Panel Kendali Cuaca/Bencana)', target_sla_ms: 60, cache_or_guard: 'Auto-Invalidate Cache' },
  { number: 19, sprint: 'Minggu 3 (Sprint 3)', day: 'Hari 13', method: 'POST', path: '/api/v1/spatial/sos', title: 'Pancaran Sinyal Darurat SOS GPS Wisatawan + Auto-Assign Pos SAR Terdekat', pillar_ref: 'Pilar 7 (P7.2)', auth_guard: 'Public (Darurat)', consumer_role: 'FE-1 (Tombol Darurat SOS)', target_sla_ms: 55, cache_or_guard: 'Token Bucket Rate-Limit (HTTP 429)' },
  { number: 20, sprint: 'Minggu 3 (Sprint 3)', day: 'Hari 14', method: 'GET', path: '/api/v1/culture/minang-phrases', title: 'Kamus Saku Audio Bahasa Minang Sehari-hari (Kato Nan Ampek)', pillar_ref: 'Pilar 1 (P1.4)', auth_guard: 'Public', consumer_role: 'FE-1 (Kamus Saku Audio)', target_sla_ms: 30, cache_or_guard: 'InMemoryTTLCache + ETag (304)' },
  { number: 21, sprint: 'Minggu 3 (Sprint 3)', day: 'Hari 14', method: 'GET', path: '/api/v1/culture/events', title: 'Kalender Budaya & Hari Pakan (Pasar Tradisional Nagari) Terdekat', pillar_ref: 'Pilar 1 (P1.4)', auth_guard: 'Public', consumer_role: 'FE-1 (Kalender Budaya)', target_sla_ms: 40, cache_or_guard: 'Spatial Distance Sort' },

  // Minggu 4 (Sprint 4) — 3 Endpoint Penutup (Total = 24 Endpoint)
  { number: 22, sprint: 'Minggu 4 (Sprint 4)', day: 'Hari 19', method: 'GET', path: '/api/v1/admin/system/benchmark', title: 'Live Performance Benchmark (<100ms SLA), Cache Stats & Audit 11 Tabel PostGIS', pillar_ref: 'Hardening & SLA', auth_guard: 'JWT RBAC (admin_dispar, pokdarwis)', consumer_role: 'FS-1 & QA Workbench', target_sla_ms: 45, cache_or_guard: 'Real-Time Latency Probe' },
  { number: 23, sprint: 'Minggu 4 (Sprint 4)', day: 'Hari 19', method: 'POST', path: '/api/v1/admin/cache/flush', title: 'Manual Flush In-Memory TTL Cache & Reset ETag oleh Admin FS-1', pillar_ref: 'Caching 360° & Rute', auth_guard: 'JWT RBAC (admin_dispar, pokdarwis)', consumer_role: 'FS-1 (Web Admin CMS)', target_sla_ms: 15, cache_or_guard: 'Atomic Cache Reset' },
  { number: 24, sprint: 'Minggu 4 (Sprint 4)', day: 'Hari 19', method: 'GET', path: '/api/v1/system/contracts', title: 'Katalog Kontrak 24 Endpoint BE-1 (Sprint 1-4) & Matriks Sinkronisasi Tim', pillar_ref: 'Dokumentasi Final', auth_guard: 'Public', consumer_role: 'FE-1, FE-2, FS-1', target_sla_ms: 20, cache_or_guard: 'Static Contract Registry' }
];

export const INITIAL_BENCHMARK_PROBES: BenchmarkProbeRecord[] = [
  {
    probe: 'PostGIS Spatial Directory (20 Destinasi + ST_DistanceSphere)',
    latency_ms: 5.2,
    index_used: 'idx_s4_destinations_filter_composite + GIST'
  },
  {
    probe: 'Aggregate Detail (4 Statistik + 5 Indikator Medan + Tarif Perda)',
    latency_ms: 6.4,
    index_used: 'idx_s4_tariffs_dest_category_price'
  },
  {
    probe: 'Kanvas Tur Imersif 360° Aerial-to-Ground + 4 Pin Interaktif',
    latency_ms: 3.1,
    index_used: 'InMemoryTTLCache + idx_s4_scenes360_dest_default'
  },
  {
    probe: 'Gaode Behavior Ranking + Radar Bahaya 4 Koridor Ekstrem',
    latency_ms: 4.9,
    index_used: 'mv_gaode_leaderboard + idx_s4_hazard_active_corridors'
  }
];
