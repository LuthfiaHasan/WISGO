import type { DailyTaskStep, RoleBoundaryItem } from './sprint1ArchitectureData';

export interface Hotspot360Record {
  id: string;
  scene_id: string;
  type: 'navigasi' | 'audio' | 'fasilitas' | 'mitra';
  color_token: string;
  pitch: number;
  yaw: number;
  title: string;
  target_ref?: string;
  audio_url?: string;
  description: string;
}

export interface Scene360Record {
  id: string;
  destination_id: string;
  destination_name: string;
  title: string;
  type: 'aerial' | 'ground';
  panorama_url: string;
  upload_format: 'url' | 'base64' | 'multipart';
  spatial_audio_url: string;
  initial_pitch: number;
  initial_yaw: number;
  is_default_scene: boolean;
  hotspots: Hotspot360Record[];
}

export interface ShunluPOIRecord {
  id: string;
  name: string;
  category: 'rm_padang' | 'spbu' | 'masjid_bersih' | 'atm' | 'bengkel';
  corridor_road: string;
  city_regency: string;
  latitude: number;
  longitude: number;
  detour_minutes: number;
  detour_distance_meter: number;
  highlight_note: string;
  opening_hours: string;
  is_recommended: boolean;
}

export interface AudioTriggerRecord {
  id: string;
  destination_id: string;
  title: string;
  latitude: number;
  longitude: number;
  trigger_radius_m: number;
  audio_url_id: string;
  audio_url_minang: string;
  transcript_short: string;
}

export interface MicroMapRecord {
  id: string;
  destination_id: string;
  destination_name: string;
  area_size_hectare: number;
  walkway_geojson: string;
  child_friendly_path: boolean;
  elderly_friendly_path: boolean;
  internal_pois: Array<{
    id: string;
    name: string;
    type: 'gerbang' | 'spot_foto' | 'toilet_musala' | 'pos_pokdarwis' | 'gardu_pandang';
    latitude: number;
    longitude: number;
    description: string;
  }>;
  audio_triggers: AudioTriggerRecord[];
}

export interface PungliReportRecord {
  id: string;
  ticket_code: string;
  destination_id: string;
  destination_name: string;
  reporter_name: string;
  incident_category: 'parkir_liar' | 'tiket_di_atas_perda' | 'paksaan_pemandu' | 'fasilitas_rusak';
  charged_amount_idr: number;
  official_perda_price_idr: number;
  overcharge_amount_idr: number;
  photo_evidence: string;
  upload_format: 'url' | 'base64' | 'multipart';
  latitude: number;
  longitude: number;
  description: string;
  status: 'Masuk' | 'Diverifikasi' | 'Ditindaklanjuti' | 'Selesai';
  satgas_notes: string;
  created_at: string;
  updated_at: string;
}

export const SPRINT_2_DAILY_STEPS: DailyTaskStep[] = [
  {
    id: 's2-day6',
    day: 'Hari 6 (Senin — Minggu 2)',
    title: 'Migrasi 5 Tabel Spasial & Visual Sprint 2 + Seeder Data 360° & Shunlu',
    focus: 'Menjalankan DDL `backend/internal/be1_core/migrations_sprint2.sql` untuk 5 tabel baru milik BE-1 (`panorama_scenes`, `panorama_hotspots`, `shunlu_pois`, `scenic_micro_maps`, `pungli_reports`) serta mengisi seeder data nyata Sumatera Barat di `seeder_sprint2_spatial.go`.',
    deliverable: '5 tabel baru Sprint 2 aktif di PostgreSQL + PostGIS lengkap dengan indeks GIST koridor rute & 4 jenis Pin 360°.',
    sqlOrGoFiles: ['backend/internal/be1_core/migrations_sprint2.sql', 'backend/internal/be1_core/seeder_sprint2_spatial.go', 'backend/internal/models/models.go'],
    syncWithRole: 'Mandiri BE-1 (Zero Merge Conflict — tidak menyentuh tabel grup/voting milik BE-2)',
    verificationCommand: 'psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint2.sql'
  },
  {
    id: 's2-day7',
    day: 'Hari 7 (Selasa — Minggu 2)',
    title: 'API Tur Virtual 360° Aerial-to-Ground, 4 Pin Hotspots & CMS Studio 360°',
    focus: 'Membangun `GET /api/v1/destinations/{id}/scenes-360` untuk FE-1 (Layar 07 Tur Virtual 360°), serta `POST /api/v1/admin/scenes-360` (mendukung URL, Base64, & Multipart) dan `POST /api/v1/admin/scenes-360/{sceneId}/hotspots` (klik-tempel koordinat bola `pitch/yaw` 4 Pin: Navigasi Biru, Audio Emas, Fasilitas Hijau, Mitra Oranye) untuk CMS Studio 360° milik FS-1.',
    deliverable: 'FE-1 dapat merender transisi Aerial-to-Ground 360° & 4 Pin Interaktif; FS-1 dapat menempelkan pin baru di koordinat bola (`pitch`, `yaw`).',
    sqlOrGoFiles: ['backend/internal/be1_core/panorama_360_day7.go', 'backend/internal/be1_core/repository_postgis.go'],
    syncWithRole: 'FE-1 (Layar 07 Kanvas 360° 4-Pin) & FS-1 (CMS Studio 360° Visual Pin Editor)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/destinations/dest-001/scenes-360" | jq ".scenes_360 | length"'
  },
  {
    id: 's2-day8',
    day: 'Hari 8 (Rabu — Minggu 2)',
    title: 'Engine Along-the-Route ("Shunlu" +X mnt detour) & Peta Mikro Kawasan + Audio GPS ≤15m',
    focus: 'Membangun `POST /api/v1/spatial/shunlu` yang mencari RM Padang Otentik, SPBU, Masjid Bersih, ATM, & Bengkel searah koridor rute aktif dengan kalkulasi waktu memutar (`+X mnt detour`), serta `GET /api/v1/destinations/{id}/micro-map` dan `POST /api/v1/spatial/audio-trigger-check` (validasi jarak GPS `≤15 meter`).',
    deliverable: 'FE-1 (Layar 03 Jelajah Peta & Kartu Mengambang) dapat memfilter POI searah rute tanpa putar balik dan memutar narasi audio otomatis saat GPS berjarak ≤15m.',
    sqlOrGoFiles: ['backend/internal/be1_core/shunlu_micromap_day8.go'],
    syncWithRole: 'FE-1 (Layar 03 Filter Cari Searah Rute Shunlu, Peta Mikro Kawasan & Audio GPS)',
    verificationCommand: 'curl -s -X POST "http://localhost:3000/api/v1/spatial/shunlu" -H "Content-Type: application/json" -d \'{"category":"rm_padang","max_detour_min":10}\''
  },
  {
    id: 's2-day9',
    day: 'Hari 9 (Kamis — Minggu 2)',
    title: 'API Scanner Plang Smart QR, Form Lapor Pungli (Foto + GPS) & Pusat Komando Satgas',
    focus: 'Membangun `GET /api/v1/qr/{qrCode}` untuk pemindai Plang Smart QR, `POST /api/v1/pungli/report` (unggah bukti foto via URL/Base64/Multipart + koordinat GPS + kalkulasi otomatis selisih harga Perda), serta `GET /api/v1/admin/pungli/reports` dan `PATCH /api/v1/admin/pungli/{id}/status` (`Masuk` → `Diverifikasi` → `Ditindaklanjuti` → `Selesai`).',
    deliverable: 'FE-2 dapat memindai Plang Smart QR & mengirim laporan pungli berfoto; FS-1 dapat memverifikasi dan mengubah status tiket aduan di Pusat Komando Satgas Saber Pungli.',
    sqlOrGoFiles: ['backend/internal/be1_core/pungli_satgas_day9.go'],
    syncWithRole: 'FE-2 (Scanner Plang Smart QR & Form Lapor Pungli) & FS-1 (Pusat Komando Satgas Saber Pungli + Web Instant QR)',
    verificationCommand: 'curl -s "http://localhost:3000/api/v1/qr/QR-SMBR-LPK-001" | jq ".status"'
  },
  {
    id: 's2-day10',
    day: 'Hari 10 (Jumat — Target Rilis Sprint 2)',
    title: 'API Bundel Offline v2 (Hive/Sqflite) & Automated Test Suite 8 Skenario Minggu 2',
    focus: 'Memperbarui `GET /api/v1/destinations/{id}/offline-bundle` ke versi `v2.0-sprint2-complete` (membungkus data destinasi, 5 indikator medan, tarif Perda, `scenes_360` + 4 Pin, `micro_map` GeoJSON, dan `audio_triggers` untuk disimpan di Hive/Sqflite FE-1) serta menjalankan 8 skenario `go test` Minggu 2 (`TC-S2-01` s/d `TC-S2-08`).',
    deliverable: 'Output Wajib Jumat Minggu 2 tercapai 100%: API 360° 4-Pin, rute Shunlu, Peta Mikro, Bundel Offline v2, & Lapor Pungli siap dan lulus 8 unit test otomatis.',
    sqlOrGoFiles: ['backend/internal/be1_core/handlers.go', 'backend/internal/be1_core/be1_sprint2_test.go'],
    syncWithRole: 'FE-1 (Simpan Lokal Mode Offline Hive/Sqflite), FE-2, & FS-1 (Demo Akhir Minggu 2)',
    verificationCommand: 'cd backend && go test -v ./internal/be1_core/... -run TestBE1Sprint2Suite'
  }
];

export const SPRINT_2_ROLE_BOUNDARY_MATRIX: RoleBoundaryItem[] = [
  {
    roleCode: 'BE-1',
    roleName: 'Backend 1 — Core, 360°, Spasial Shunlu & Satgas Pungli (ANDA)',
    stack: 'Go (1.22 ServeMux) + PostgreSQL/PostGIS',
    sprint1Focus: 'Minggu 2: Migrasi 5 tabel (`panorama_scenes`, `panorama_hotspots`, `shunlu_pois`, `scenic_micro_maps`, `pungli_reports`), API 360° 4-Pin + CMS Pin Editor, Engine Shunlu (+X mnt detour), Peta Mikro + Audio GPS ≤15m, Smart QR, Lapor Pungli & Bundel Offline v2.',
    ownedTablesOrModules: [
      'panorama_scenes (Hari 6–7)',
      'panorama_hotspots — 4 Pin Interaktif (Hari 6–7)',
      'shunlu_pois — Koridor Cari Searah Rute (Hari 6 & 8)',
      'scenic_micro_maps — Peta Mikro & Audio GPS ≤15m (Hari 6 & 8)',
      'pungli_reports — Lapor Pungli & Pusat Komando Satgas (Hari 6 & 9)'
    ],
    routePrefixOrBoundary: '/api/v1/destinations/{id}/scenes-360, /api/v1/admin/scenes-360*, /api/v1/spatial/shunlu, /api/v1/destinations/{id}/micro-map, /api/v1/qr/*, /api/v1/pungli/*, /api/v1/admin/pungli/*',
    interactionRuleForBE1: 'Tetap 100% di dalam `backend/internal/be1_core/`. Untuk Pin 360° bertipe `mitra` (Oranye), simpan ID mitra pada kolom `target_ref` sebagai string lepas tanpa Foreign Key ke tabel `partners` milik BE-2.'
  },
  {
    roleCode: 'BE-2',
    roleName: 'Backend 2 — Auto-Itinerary, Private Group Room & Komunitas',
    stack: 'Go + PostgreSQL',
    sprint1Focus: 'Minggu 2: Engine Auto-Itinerary Generator & TSP Optimizer, API Private Group Room (buat grup, gabung via kode/link, & Live Voting), serta API Tambah Tempat Baru Komunitas (masking lokasi sensitif).',
    ownedTablesOrModules: [
      'group_rooms & group_members (DILARANG DISENTUH BE-1)',
      'group_votes (DILARANG DISENTUH BE-1)',
      'community_submissions (DILARANG DISENTUH BE-1)',
      'auto_itinerary_plans (DILARANG DISENTUH BE-1)'
    ],
    routePrefixOrBoundary: '/api/v1/groups/*, /api/v1/itineraries/auto-generate, /api/v1/community/places/*',
    interactionRuleForBE1: 'JANGAN menyentuh file `internal/be2_group/handlers.go` atau membuat endpoint grup/voting. Seluruh fitur rombongan dan tambah tempat komunitas dikerjakan oleh BE-2.'
  },
  {
    roleCode: 'FE-1',
    roleName: 'Frontend 1 — Layar 07 Tur Virtual 360°, Peta Shunlu & Offline',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Minggu 2: Bangun Layar 07. Tur Virtual 360° (Aerial-to-Ground + 4 Pin), Layar 03. Jelajah Peta & Kartu Mengambang, filter Cari Searah Rute (Shunlu), Peta Mikro, & simpan lokal Mode Offline.',
    ownedTablesOrModules: ['Layar 07. Tur Virtual 360° 4-Pin', 'Layar 03. Jelajah Peta & Filter Shunlu', 'Peta Mikro Kawasan & Audio GPS ≤15m', 'Mode Offline Hive/Sqflite'],
    routePrefixOrBoundary: 'Konsumsi GET .../scenes-360, POST /api/v1/spatial/shunlu, GET .../micro-map, & GET .../offline-bundle',
    interactionRuleForBE1: 'Pastikan setiap pin pada `hotspots` menyertakan `type` (`navigasi`, `audio`, `fasilitas`, `mitra`) dan `color_token` resmi agar FE-1 dapat langsung merender ikon pin di atas kanvas 360°.'
  },
  {
    roleCode: 'FE-2',
    roleName: 'Frontend 2 — Scanner Smart QR, Form Lapor Pungli & Grup UI',
    stack: 'Flutter Mobile (Dart)',
    sprint1Focus: 'Minggu 2: Bangun Scanner Plang Smart QR, Form Lapor Pungli (unggah bukti foto + GPS), Layar 06. Itinerary 7 Hari, Private Group Room & Voting UI.',
    ownedTablesOrModules: ['Scanner Plang Smart QR', 'Form Lapor Pungli / Fasilitas Rusak (Foto + GPS)'],
    routePrefixOrBoundary: 'Konsumsi GET /api/v1/qr/{qrCode} & POST /api/v1/pungli/report (ke BE-1); Group Room ke BE-2',
    interactionRuleForBE1: 'Pastikan `POST /api/v1/pungli/report` menerima `photo_evidence` berupa URL, Base64, maupun Multipart dan langsung mengembalikan nomor tiket (`PGL-202611-XXXX`) serta selisih harga terhadap Perda.'
  },
  {
    roleCode: 'FS-1',
    roleName: 'Fullstack — CMS Studio 360° Pin Editor & Pusat Komando Satgas',
    stack: 'TypeScript (Web) + Go Bridge',
    sprint1Focus: 'Minggu 2: Bangun CMS Studio 360° (Visual Pin Editor) untuk klik-tempel 4 pin di atas kanvas 360°, Pusat Komando Satgas Saber Pungli, serta Halaman Web Instan Smart QR.',
    ownedTablesOrModules: ['CMS Studio 360° (Klik-Tempel Pitch/Yaw 4 Pin)', 'Pusat Komando Satgas Saber Pungli', 'Halaman Web Instan Smart QR'],
    routePrefixOrBoundary: 'Konsumsi POST /api/v1/admin/scenes-360/{sceneId}/hotspots & PATCH /api/v1/admin/pungli/{id}/status',
    interactionRuleForBE1: 'Sediakan validasi koordinat bola (`pitch` -90..90, `yaw` 0..360) dan endpoint perubahan status tiket pungli (`Masuk`, `Diverifikasi`, `Ditindaklanjuti`, `Selesai`) dengan RBAC `admin_dispar`.'
  }
];

export const INITIAL_SCENES_360: Scene360Record[] = [
  {
    id: 'scene-harau-aerial-01',
    destination_id: 'dest-001',
    destination_name: 'Lembah Harau (Aka Barayun & Sarasah Bunta)',
    title: 'Panorama Drone 150m Lembah Harau & Tebing Granit',
    type: 'aerial',
    panorama_url: 'https://cdn.rancak.in/360/harau-aerial-150m-equirectangular.jpg',
    upload_format: 'url',
    spatial_audio_url: 'https://cdn.rancak.in/audio/harau-angin-lembah-spatial.mp3',
    initial_pitch: -12.5,
    initial_yaw: 180.0,
    is_default_scene: true,
    hotspots: [
      {
        id: 'pin-harau-01',
        scene_id: 'scene-harau-aerial-01',
        type: 'navigasi',
        color_token: '#2563EB',
        pitch: -28.4,
        yaw: 172.0,
        title: 'Turun ke Kolam Air Terjun Aka Barayun (Ground 360°)',
        target_ref: 'scene-harau-ground-01',
        description: 'Klik untuk transisi mulus (dive-in) dari udara 150m ke tepi kolam air terjun.'
      },
      {
        id: 'pin-harau-02',
        scene_id: 'scene-harau-aerial-01',
        type: 'audio',
        color_token: '#D97706',
        pitch: -8.0,
        yaw: 115.5,
        title: 'Kisah Geologi Patahan Semangko & Tebing Harau Purba',
        audio_url: 'https://cdn.rancak.in/audio/story-geologi-harau-id.mp3',
        description: 'Narasi 45 detik tentang terbentuknya lembah granit purba jutaan tahun lalu.'
      }
    ]
  },
  {
    id: 'scene-harau-ground-01',
    destination_id: 'dest-001',
    destination_name: 'Lembah Harau (Aka Barayun & Sarasah Bunta)',
    title: 'Spot Utama Air Terjun Aka Barayun & Tebing Gema',
    type: 'ground',
    panorama_url: 'https://cdn.rancak.in/360/harau-ground-akabarayun-equirectangular.jpg',
    upload_format: 'url',
    spatial_audio_url: 'https://cdn.rancak.in/audio/harau-gemericik-air-terjun.mp3',
    initial_pitch: 4.0,
    initial_yaw: 90.0,
    is_default_scene: false,
    hotspots: [
      {
        id: 'pin-harau-03',
        scene_id: 'scene-harau-ground-01',
        type: 'navigasi',
        color_token: '#2563EB',
        pitch: 34.0,
        yaw: 10.0,
        title: 'Naik Kembali ke Panorama Udara (Drone 150m)',
        target_ref: 'scene-harau-aerial-01',
        description: 'Kembali melihat bentang kawasan Lembah Harau dari udara.'
      },
      {
        id: 'pin-harau-04',
        scene_id: 'scene-harau-ground-01',
        type: 'fasilitas',
        color_token: '#1E9E5A',
        pitch: -3.5,
        yaw: 210.0,
        title: 'Musala, Toilet Bersih & Pos Pokdarwis Tarantang (80m)',
        description: 'Fasilitas air bersih pegunungan, ruang ganti ramah keluarga, dan loket resmi Perda.'
      },
      {
        id: 'pin-harau-05',
        scene_id: 'scene-harau-ground-01',
        type: 'mitra',
        color_token: '#E85D1A',
        pitch: -6.0,
        yaw: 142.0,
        title: 'Pesan Pemandu Tebing & Homestay Kayu Nagari Tarantang',
        target_ref: 'partner-001',
        description: 'Buka Quick Booking Drawer untuk memesan pemandu lokal terverifikasi via Escrow.'
      }
    ]
  },
  {
    id: 'scene-jamgadang-aerial-01',
    destination_id: 'dest-002',
    destination_name: 'Jam Gadang & Taman Panorama Ngarai Sianok',
    title: 'Panorama Udara Plaza Jam Gadang & Latar Gunung Singgalang',
    type: 'aerial',
    panorama_url: 'https://cdn.rancak.in/360/jamgadang-aerial-120m.jpg',
    upload_format: 'url',
    spatial_audio_url: 'https://cdn.rancak.in/audio/saluang-minang-ambient.mp3',
    initial_pitch: -10.0,
    initial_yaw: 180.0,
    is_default_scene: true,
    hotspots: [
      {
        id: 'pin-jg-01',
        scene_id: 'scene-jamgadang-aerial-01',
        type: 'navigasi',
        color_token: '#2563EB',
        pitch: -25.0,
        yaw: 180.0,
        title: 'Turun ke Pelataran Jam Gadang & Pasar Ateh',
        target_ref: 'scene-jamgadang-ground-01',
        description: 'Transisi ke pelataran pejalan kaki Jam Gadang.'
      },
      {
        id: 'pin-jg-02',
        scene_id: 'scene-jamgadang-aerial-01',
        type: 'audio',
        color_token: '#D97706',
        pitch: 2.0,
        yaw: 185.0,
        title: 'Rahasia Angka Romawi IIII & Mesin Vortmann 1926',
        audio_url: 'https://cdn.rancak.in/audio/sejarah-jam-gadang-1926.mp3',
        description: 'Dengarkan sejarah arsitektur Yazid Rajo Mangkuto & atap Bagonjong.'
      },
      {
        id: 'pin-jg-03',
        scene_id: 'scene-jamgadang-aerial-01',
        type: 'mitra',
        color_token: '#E85D1A',
        pitch: -14.0,
        yaw: 240.0,
        title: 'Sewa Bendi Wisata Resmi & Nasi Kapau Uni Lis',
        target_ref: 'partner-002',
        description: 'Tarif resmi keliling kota Bukittinggi tanpa pungli.'
      }
    ]
  },
  {
    id: 'scene-pagaruyung-ground-01',
    destination_id: 'dest-005',
    destination_name: 'Istano Basa Pagaruyung',
    title: 'Pelataran Utama Istano Basa Pagaruyung (11 Gonjong)',
    type: 'ground',
    panorama_url: 'https://cdn.rancak.in/360/pagaruyung-pelataran-utama.jpg',
    upload_format: 'url',
    spatial_audio_url: 'https://cdn.rancak.in/audio/talempong-pacik-pagaruyung.mp3',
    initial_pitch: 8.0,
    initial_yaw: 180.0,
    is_default_scene: true,
    hotspots: [
      {
        id: 'pin-pg-01',
        scene_id: 'scene-pagaruyung-ground-01',
        type: 'audio',
        color_token: '#D97706',
        pitch: 15.0,
        yaw: 180.0,
        title: 'Filosofi Ukiran Aka Barayun & Rangkiang Patah Sembilan',
        audio_url: 'https://cdn.rancak.in/audio/filosofi-istano-pagaruyung.mp3',
        description: 'Penjelasan makna falsafah Alam Takambang Jadi Guru pada tiap lantai istana.'
      },
      {
        id: 'pin-pg-02',
        scene_id: 'scene-pagaruyung-ground-01',
        type: 'mitra',
        color_token: '#E85D1A',
        pitch: -5.0,
        yaw: 135.0,
        title: 'Sewa Busana Adat Anak Daro & Marapulai + Fotografer',
        target_ref: 'partner-003',
        description: 'Booking langsung paket busana adat Minangkabau resmi di Lantai 1.'
      }
    ]
  }
];

export const INITIAL_SHUNLU_POIS: ShunluPOIRecord[] = [
  {
    id: 'shunlu-001',
    name: 'Sate Mak Syukur Padang Panjang (Pusat)',
    category: 'rm_padang',
    corridor_road: 'Lintas Padang - Bukittinggi',
    city_regency: 'Kota Padang Panjang',
    latitude: -0.4658,
    longitude: 100.4012,
    detour_minutes: 2,
    detour_distance_meter: 180,
    highlight_note: 'Searah jalur utama Lembah Anai - Bukittinggi (+2 mnt detour, parkir luas bus/mobil).',
    opening_hours: '08.00 - 21.30 WIB',
    is_recommended: true
  },
  {
    id: 'shunlu-002',
    name: 'SPBU Pertamina 14.271.522 Sicincin & Rest Area',
    category: 'spbu',
    corridor_road: 'Lintas Padang - Bukittinggi',
    city_regency: 'Kab. Padang Pariaman',
    latitude: -0.5914,
    longitude: 100.2891,
    detour_minutes: 1,
    detour_distance_meter: 60,
    highlight_note: 'Pertamax Turbo & Dex tersedia, toilet bersih, tepat sebelum tanjakan Lembah Anai.',
    opening_hours: '24 Jam',
    is_recommended: true
  },
  {
    id: 'shunlu-003',
    name: 'Masjid Agung Nurul Iman / Islamic Center Padang Panjang',
    category: 'masjid_bersih',
    corridor_road: 'Lintas Padang - Bukittinggi',
    city_regency: 'Kota Padang Panjang',
    latitude: -0.4591,
    longitude: 100.4150,
    detour_minutes: 4,
    detour_distance_meter: 450,
    highlight_note: 'Air wudu pegunungan sejuk, toilet ramah lansia/anak, rest area teduh.',
    opening_hours: '04.30 - 22.30 WIB',
    is_recommended: true
  },
  {
    id: 'shunlu-004',
    name: 'RM Pak Datuk & Galeri Randang Padang Panjang',
    category: 'rm_padang',
    corridor_road: 'Lintas Padang - Bukittinggi',
    city_regency: 'Kota Padang Panjang',
    latitude: -0.4712,
    longitude: 100.3910,
    detour_minutes: 1,
    detour_distance_meter: 90,
    highlight_note: 'Dendeng Batokok & Gulai Tambusu otentik, 90m dari badan jalan lintas.',
    opening_hours: '07.30 - 21.00 WIB',
    is_recommended: true
  },
  {
    id: 'shunlu-005',
    name: 'RM Pongek Situjuah & Kopi Kawa Daun Payakumbuh',
    category: 'rm_padang',
    corridor_road: 'Lintas Bukittinggi - Lembah Harau',
    city_regency: 'Kota Payakumbuh',
    latitude: -0.2245,
    longitude: 100.6318,
    detour_minutes: 3,
    detour_distance_meter: 320,
    highlight_note: 'Kuliner khas gulai nangka muda (Pongek) searah pintu masuk Lembah Harau.',
    opening_hours: '08.30 - 20.30 WIB',
    is_recommended: true
  },
  {
    id: 'shunlu-006',
    name: 'ATM Center Bank Nagari, BRI, Mandiri & BCA Pasar Ibuh',
    category: 'atm',
    corridor_road: 'Lintas Bukittinggi - Lembah Harau',
    city_regency: 'Kota Payakumbuh',
    latitude: -0.2261,
    longitude: 100.6335,
    detour_minutes: 2,
    detour_distance_meter: 150,
    highlight_note: 'Tarik tunai terakhir sebelum masuk zona Blank Spot sebagian lembah dalam Harau.',
    opening_hours: '24 Jam',
    is_recommended: true
  },
  {
    id: 'shunlu-007',
    name: 'Bengkel Siaga Rem & Ban Sitinjau Lauik (Lubuk Kilangan)',
    category: 'bengkel',
    corridor_road: 'Lintas Padang - Solok (Sitinjau Lauik)',
    city_regency: 'Kota Padang',
    latitude: -0.9518,
    longitude: 100.4912,
    detour_minutes: 1,
    detour_distance_meter: 50,
    highlight_note: 'Pengecekan suhu kampas rem & tekanan ban sebelum/sesudah tanjakan ekstrem Sitinjau Lauik.',
    opening_hours: '24 Jam',
    is_recommended: true
  }
];

export const INITIAL_MICRO_MAPS: Record<string, MicroMapRecord> = {
  'dest-001': {
    id: 'micromap-harau-01',
    destination_id: 'dest-001',
    destination_name: 'Lembah Harau (Aka Barayun & Sarasah Bunta)',
    area_size_hectare: 270.5,
    walkway_geojson: '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"Jalur Pedestrian Ramah Keluarga Aka Barayun","surface":"paved_flat"},"geometry":{"type":"LineString","coordinates":[[100.6720,-0.1028],[100.6725,-0.1025],[100.6728,-0.1023],[100.6732,-0.1019]]}}]}',
    child_friendly_path: true,
    elderly_friendly_path: true,
    internal_pois: [
      { id: 'mpoi-01', name: 'Gerbang Utama & Plang Smart QR Harau', type: 'gerbang', latitude: -0.1028, longitude: 100.6720, description: 'Loket tiket resmi Perda Rp15.000 & pemindaian Smart QR.' },
      { id: 'mpoi-02', name: 'Tebing Gema (Echo Cliff) Sarasah Bunta', type: 'spot_foto', latitude: -0.1025, longitude: 100.6725, description: 'Titik akustik alami tebing granit 200m yang memantulkan suara hingga 5 kali.' },
      { id: 'mpoi-03', name: 'Musala & Toilet Bersih Pokdarwis Tarantang', type: 'toilet_musala', latitude: -0.1023, longitude: 100.6728, description: 'Air pegunungan bersih, tempat wudu terpisah, & ruang laktasi.' },
      { id: 'mpoi-04', name: 'Pos Siaga Pokdarwis & P3K Lembah Harau', type: 'pos_pokdarwis', latitude: -0.1019, longitude: 100.6732, description: 'Pos informasi pemandu resmi & bantuan darurat kawasan.' }
    ],
    audio_triggers: [
      {
        id: 'audiotrig-harau-01',
        destination_id: 'dest-001',
        title: 'Fenomena Akustik Tebing Gema Sarasah Bunta',
        latitude: -0.1025,
        longitude: 100.6725,
        trigger_radius_m: 15.0,
        audio_url_id: 'https://cdn.rancak.in/audio/gps-harau-tebing-gema-id.mp3',
        audio_url_minang: 'https://cdn.rancak.in/audio/gps-harau-tebing-gema-minang.mp3',
        transcript_short: 'Anda berada tepat di titik fokus cekungan granit Sarasah Bunta. Cobalah berseru ke arah timur; dinding batu purba ini memantulkan gema secara presisi.'
      },
      {
        id: 'audiotrig-harau-02',
        destination_id: 'dest-001',
        title: 'Prasasti Kunjungan Ratu Belanda 1926 di Air Terjun',
        latitude: -0.1023,
        longitude: 100.6728,
        trigger_radius_m: 15.0,
        audio_url_id: 'https://cdn.rancak.in/audio/gps-harau-prasasti-1926-id.mp3',
        audio_url_minang: 'https://cdn.rancak.in/audio/gps-harau-prasasti-1926-minang.mp3',
        transcript_short: 'Di sebelah kanan kolam ini terdapat prasasti tahun 1926 yang menandai peresmian cagar alam Lembah Harau sebagai kawasan lindung tertua di Sumatera Barat.'
      }
    ]
  },
  'dest-002': {
    id: 'micromap-jamgadang-01',
    destination_id: 'dest-002',
    destination_name: 'Jam Gadang & Taman Panorama Ngarai Sianok',
    area_size_hectare: 4.8,
    walkway_geojson: '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"Koridor Pedestrian Jam Gadang - Janjang 40","surface":"granite_tile"},"geometry":{"type":"LineString","coordinates":[[100.3690,-0.3053],[100.3692,-0.3051],[100.3696,-0.3048]]}}]}',
    child_friendly_path: true,
    elderly_friendly_path: true,
    internal_pois: [
      { id: 'mpoi-jg-01', name: 'Menara Jam Gadang 1926', type: 'spot_foto', latitude: -0.3051, longitude: 100.3692, description: 'Titik nol Kota Bukittinggi dengan mesin jam mekanik kembaran Big Ben London.' },
      { id: 'mpoi-jg-02', name: 'Pangkalan Bendi Wisata Resmi Perda', type: 'pos_pokdarwis', latitude: -0.3053, longitude: 100.3690, description: 'Pangkalan kusir bendi berseragam resmi dengan tabel tarif Perda Bukittinggi.' }
    ],
    audio_triggers: [
      {
        id: 'audiotrig-jg-01',
        destination_id: 'dest-002',
        title: 'Tiga Perubahan Atap Menara Jam Gadang (1926 - Sekarang)',
        latitude: -0.3051,
        longitude: 100.3692,
        trigger_radius_m: 15.0,
        audio_url_id: 'https://cdn.rancak.in/audio/gps-jamgadang-3-atap-id.mp3',
        audio_url_minang: 'https://cdn.rancak.in/audio/gps-jamgadang-3-atap-minang.mp3',
        transcript_short: 'Tahukah Anda? Atap Jam Gadang pernah berganti 3 kali: bulat dengan patung ayam jantan pada masa Belanda, pagoda pada masa Jepang, dan Bagonjong Minangkabau sejak kemerdekaan.'
      }
    ]
  }
};

export const INITIAL_PUNGLI_REPORTS: PungliReportRecord[] = [
  {
    id: 'pungli-001',
    ticket_code: 'PGL-202611-0091',
    destination_id: 'dest-003',
    destination_name: 'Pantai Air Manis & Batu Malin Kundang',
    reporter_name: 'Wisatawan Anonim',
    incident_category: 'parkir_liar',
    charged_amount_idr: 25000,
    official_perda_price_idr: 5000,
    overcharge_amount_idr: 20000,
    photo_evidence: 'https://cdn.rancak.in/evidence/karcis-tanpa-porporasi-airmanis.jpg',
    upload_format: 'url',
    latitude: -0.9841,
    longitude: 100.3612,
    description: 'Oknum di luar pos resmi meminta uang parkir mobil Rp25.000 tanpa karcis porporasi Dishub/Perda Kota Padang.',
    status: 'Diverifikasi',
    satgas_notes: 'Tim Satgas Saber Pungli Kota Padang telah diterjunkan ke titik koordinat pintu selatan.',
    created_at: '2026-11-11T08:15:00Z',
    updated_at: '2026-11-11T09:40:00Z'
  },
  {
    id: 'pungli-002',
    ticket_code: 'PGL-202611-0092',
    destination_id: 'dest-002',
    destination_name: 'Jam Gadang & Taman Panorama Ngarai Sianok',
    reporter_name: 'Rombongan Keluarga Pekanbaru',
    incident_category: 'tiket_di_atas_perda',
    charged_amount_idr: 150000,
    official_perda_price_idr: 75000,
    overcharge_amount_idr: 75000,
    photo_evidence: 'https://cdn.rancak.in/evidence/bukti-tarif-bendi-non-perda.jpg',
    upload_format: 'url',
    latitude: -0.3053,
    longitude: 100.3690,
    description: 'Kusir non-stiker resmi meminta Rp150.000 untuk rute pendek 15 menit yang seharusnya Rp75.000 sesuai tabel Perda.',
    status: 'Masuk',
    satgas_notes: 'Menunggu konfirmasi Koordinator Lapangan Dishub & Dispar Bukittinggi.',
    created_at: '2026-11-11T10:20:00Z',
    updated_at: '2026-11-11T10:20:00Z'
  }
];
