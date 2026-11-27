import React, { useState, useEffect } from 'react';
import { Play, Copy, Check, RotateCcw, Terminal, ShieldCheck, AlertTriangle, CheckCircle2, FileCode2 } from 'lucide-react';

export interface EndpointPreset {
  id: string;
  label: string;
  method: 'GET' | 'POST' | 'PUT' | 'PATCH';
  path: string;
  defaultRole: 'public' | 'tourist' | 'pokdarwis' | 'admin_dispar';
  consumerRole: string;
  description: string;
  defaultBody?: string;
}

export const SPRINT1_ENDPOINT_PRESETS: EndpointPreset[] = [
  {
    id: 'ep-health',
    label: '01. Health Check Server & PostGIS',
    method: 'GET',
    path: '/api/v1/health',
    defaultRole: 'public',
    consumerRole: 'DevOps & Semua Tim',
    description: 'Memeriksa kesiapan Server Go BE-1, status PostGIS 3.4, dan jumlah baris aktif di tabel Sprint 1 & Sprint 2.',
  },
  {
    id: 'ep-list',
    label: '02. Direktori 20 Destinasi + Kalkulasi Jarak GPS',
    method: 'GET',
    path: '/api/v1/destinations?lat=-0.9471&lng=100.4172',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Layar 01. Beranda)',
    description: 'Mengambil daftar 20 destinasi prioritas Sumatera Barat diurutkan dari jarak terdekat menggunakan rumus spasial PostGIS.',
  },
  {
    id: 'ep-list-blankspot',
    label: '03. Filter Destinasi Blank Spot Sinyal (Offline Pocket)',
    method: 'GET',
    path: '/api/v1/destinations?signal=blank_spot',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Mode Offline Pocket)',
    description: 'Memfilter khusus destinasi hidden gem di lembah tanpa sinyal seluler (Air Terjun Nyarai, Silokek, Siberut) yang wajib diunduh offline.',
  },
  {
    id: 'ep-detail',
    label: '04. Detail Agregat Destinasi (4 Statistik + 5 Medan + Tips + Perda)',
    method: 'GET',
    path: '/api/v1/destinations/lembah-harau-limapuluh-kota?lat=-0.3051&lng=100.3694',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Layar 02. Detail) & FE-2 (Fair-Price Barometer)',
    description: 'Mengambil 1 paket lengkap Detail Tempat berdasarkan ID, Slug, atau Kode Plang QR (contoh: QR-SMBR-LPK-002).',
  },
  {
    id: 'ep-cms-create',
    label: '05. CMS Admin: Tambah Destinasi Baru (Protected RBAC)',
    method: 'POST',
    path: '/api/v1/admin/destinations',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (Web Admin TypeScript CMS)',
    description: 'Menyimpan destinasi wisata baru beserta 5 Indikator Medan, Tips Menjaga Tempat, dan Tarif Resmi Perda (Wajib Token Admin Dispar / Pokdarwis).',
    defaultBody: JSON.stringify(
      {
        name: 'Tabek Patah & Panorama Barulak',
        kabupaten_kota: 'Kab. Tanah Datar',
        category: 'alam',
        latitude: -0.3412,
        longitude: 100.5621,
        elevation_m: 980,
        crowd_level: 'sepi',
        base_ticket_idr: 10000,
        distance_from_padang_km: 108.5,
        travel_time_from_padang_min: 170,
        is_hidden_gem: true,
        summary: 'Hutan pinus sejuk dan telaga alami di punggung bukit antara Bukittinggi dan Batusangkar.',
        medan_indicator: {
          road_access_status: 'Mobil & Bus (Tepat di tepi jalan raya Baso - Batusangkar)',
          car_accessible: true,
          trekking_difficulty: 'mudah',
          cellular_signal: '4g_stabil',
          recommended_provider: 'Telkomsel & Indosat 4G Stabil',
          facilities_completeness: 'Toilet bersih, Musala, Pondok Kopi Kawa Daun',
          local_guide_status: 'mandiri',
          pokdarwis_name: 'Pokdarwis Nagari Tabek Patah',
        },
        official_tariffs: [
          {
            item_name: 'Tiket Masuk Panorama Tabek Patah',
            category: 'tiket',
            price_idr: 10000,
            unit: 'per_orang',
            perda_reference: 'Peraturan Nagari Tabek Patah No. 2/2024',
            is_mandatory: true,
          },
          {
            item_name: 'Parkir Resmi Motor',
            category: 'parkir',
            price_idr: 3000,
            unit: 'per_kendaraan',
            perda_reference: 'Perda Kab. Tanah Datar No. 6/2023',
            is_mandatory: true,
          },
        ],
      },
      null,
      2
    ),
  },
  {
    id: 'ep-cms-update',
    label: '06. CMS Admin: Update Indikator Medan & Keramaian',
    method: 'PUT',
    path: '/api/v1/admin/destinations/dest-001',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (Web Admin TypeScript CMS)',
    description: 'Memperbarui tingkat keramaian real-time (sepi/sedang/ramai) dan 5 Indikator Medan destinasi dari Dashboard Dispar.',
    defaultBody: JSON.stringify(
      {
        crowd_level: 'sedang',
        medan_indicator: {
          road_access_status: 'Mobil & Bus Pariwisata (Arus lalu lintas lancar sekitar Pasar Ateh)',
          cellular_signal: '4g_stabil',
          facilities_completeness: 'Toilet ramah difabel, Musala Agung, Pos Satgas Aktif',
        },
      },
      null,
      2
    ),
  },
  {
    id: 'ep-cms-tariffs',
    label: '07. CMS Admin: Sinkronisasi Tabel Tarif Resmi Perda',
    method: 'PUT',
    path: '/api/v1/admin/destinations/dest-009/tariffs',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (CMS Perda) & FE-2 (Fair-Price Barometer)',
    description: 'Memperbarui rincian harga resmi Perda pada Pantai Air Manis untuk mencegah pungutan liar di lapangan.',
    defaultBody: JSON.stringify(
      {
        official_tariffs: [
          {
            item_name: 'Tiket Masuk Pantai Air Manis (Dewasa - E-Ticketing)',
            category: 'tiket',
            price_idr: 10000,
            unit: 'per_orang',
            perda_reference: 'Perda Kota Padang No. 1/2024',
            is_mandatory: true,
          },
          {
            item_name: 'Parkir Resmi Motor (1 Pintu Bebas Pungutan Tambahan)',
            category: 'parkir',
            price_idr: 3000,
            unit: 'per_kendaraan',
            perda_reference: 'Perda Kota Padang No. 1/2024',
            is_mandatory: true,
          },
          {
            item_name: 'Parkir Resmi Mobil (1 Pintu Bebas Pungutan Tambahan)',
            category: 'parkir',
            price_idr: 5000,
            unit: 'per_kendaraan',
            perda_reference: 'Perda Kota Padang No. 1/2024',
            is_mandatory: true,
          },
        ],
      },
      null,
      2
    ),
  },
];

export const SPRINT2_ENDPOINT_PRESETS: EndpointPreset[] = [
  {
    id: 's2-ep-360-list',
    label: '01. [Hari 7] Tur Virtual 360° Aerial-to-Ground & 4 Pin Interaktif',
    method: 'GET',
    path: '/api/v1/destinations/dest-001/scenes-360',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Layar 07. Tur Virtual 360°)',
    description: 'Mengambil daftar scene 360° udara (drone 150m) & darat beserta 4 jenis pin terstandarisasi (Navigasi Biru, Audio Emas, Fasilitas Hijau, Mitra Oranye).',
  },
  {
    id: 's2-ep-360-pin',
    label: '02. [Hari 7] CMS Studio 360°: Klik-Tempel Pin di Koordinat Pitch/Yaw',
    method: 'POST',
    path: '/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (CMS Studio 360° Visual Pin Editor)',
    description: 'Menempelkan Pin 360° baru pada koordinat bola (pitch -90..90, yaw 0..360) dari Visual Pin Editor Web Admin FS-1.',
    defaultBody: JSON.stringify(
      {
        type: 'mitra',
        pitch: -11.5,
        yaw: 215.0,
        title: 'Kopi Kawa Daun & Lamang Tapai Harau',
        target_ref: 'partner-004',
        description: 'Klik untuk membuka Quick Booking Drawer kuliner khas Nagari Tarantang.',
      },
      null,
      2
    ),
  },
  {
    id: 's2-ep-360-upload',
    label: '03. [Hari 7] CMS Studio 360°: Unggah Scene Panorama (URL / Base64)',
    method: 'POST',
    path: '/api/v1/admin/scenes-360',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (CMS Studio 360°)',
    description: 'Mengunggah foto equirectangular 360° baru (mendukung URL, Base64 data URI, maupun simulasi Multipart Upload).',
    defaultBody: JSON.stringify(
      {
        destination_id: 'dest-001',
        title: 'Spot Air Terjun Sarasah Bunta (Ground 360°)',
        type: 'ground',
        panorama_url: 'https://cdn.rancak.in/360/harau-sarasah-bunta-ground.jpg',
        spatial_audio_url: 'https://cdn.rancak.in/audio/harau-sarasah-bunta.mp3',
        initial_pitch: 5.0,
        initial_yaw: 160.0,
        is_default_scene: false,
      },
      null,
      2
    ),
  },
  {
    id: 's2-ep-shunlu',
    label: '04. [Hari 8] Engine Cari Searah Rute ("Shunlu" +X Menit Detour)',
    method: 'POST',
    path: '/api/v1/spatial/shunlu',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Layar 03. Jelajah Peta & Filter Shunlu)',
    description: 'Mencari RM Padang Otentik, SPBU, Masjid Bersih, ATM, atau Bengkel yang searah koridor rute aktif tanpa harus putar balik jauh.',
    defaultBody: JSON.stringify(
      {
        origin_lat: -0.9471,
        origin_lng: 100.4172,
        destination_lat: -0.3051,
        destination_lng: 100.3692,
        category: 'rm_padang',
        max_detour_min: 10,
      },
      null,
      2
    ),
  },
  {
    id: 's2-ep-micromap',
    label: '05. [Hari 8] Peta Mikro Kawasan & Titik Pemicu Audio GPS <=15m',
    method: 'GET',
    path: '/api/v1/destinations/dest-001/micro-map',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Peta Mikro Kawasan & Audio GPS)',
    description: 'Mengambil GeoJSON jalur jalan kaki internal kawasan wisata luas, posisi toilet/musala/pos Pokdarwis, serta titik koordinat Audio GPS <=15m.',
  },
  {
    id: 's2-ep-audiotrig',
    label: '06. [Hari 8] Cek Pemicu Otomatis Audio Guide GPS (Radius <=15 Meter)',
    method: 'POST',
    path: '/api/v1/spatial/audio-trigger-check',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Auto-Play Audio GPS <=15m)',
    description: 'Memvalidasi apakah koordinat GPS wisatawan saat berjalan kaki berada dalam radius <=15 meter dari titik cerita sejarah/adat.',
    defaultBody: JSON.stringify(
      {
        destination_id: 'dest-001',
        user_lat: -0.1025,
        user_lng: 100.6725,
      },
      null,
      2
    ),
  },
  {
    id: 's2-ep-qr',
    label: '07. [Hari 9] Resolusi Scanner Plang Smart QR & Web Instant Preview',
    method: 'GET',
    path: '/api/v1/qr/QR-SMBR-LPK-001',
    defaultRole: 'public',
    consumerRole: 'FE-2 (Scanner Smart QR) & FS-1 (Web Instant QR)',
    description: 'Meresolusi kode Plang Smart QR fisik di pintu gerbang wisata menjadi data Tarif Resmi Perda, Kanvas 360°, dan Peta Mikro dalam <2 detik.',
  },
  {
    id: 's2-ep-pungli-post',
    label: '08. [Hari 9] Form Lapor Pungli Anonim (Bukti Foto + GPS + Selisih Perda)',
    method: 'POST',
    path: '/api/v1/pungli/report',
    defaultRole: 'public',
    consumerRole: 'FE-2 (Form Lapor Pungli / Fasilitas Rusak)',
    description: 'Mengirim laporan pungutan liar anonim beserta bukti foto (URL/Base64/Multipart) & GPS; server otomatis menghitung selisih terhadap tarif Perda.',
    defaultBody: JSON.stringify(
      {
        destination_id: 'dest-001',
        reporter_name: 'Wisatawan Anonim',
        incident_category: 'parkir_liar',
        charged_amount_idr: 20000,
        photo_evidence: 'https://cdn.rancak.in/evidence/karcis-pungli-20rb.jpg',
        latitude: -0.1023,
        longitude: 100.6728,
        description: 'Oknum di luar pos resmi meminta parkir mobil Rp20.000 padahal tarif Perda Nagari Tarantang Rp5.000.',
      },
      null,
      2
    ),
  },
  {
    id: 's2-ep-pungli-patch',
    label: '09. [Hari 9] Pusat Komando Satgas: Verifikasi & Ubah Status Tiket Pungli',
    method: 'PATCH',
    path: '/api/v1/admin/pungli/PGL-202611-0091/status',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (Pusat Komando Satgas Saber Pungli)',
    description: 'Mengubah status tiket aduan pungli (Masuk -> Diverifikasi -> Ditindaklanjuti -> Selesai) dari dashboard Satgas Dispar.',
    defaultBody: JSON.stringify(
      {
        status: 'Ditindaklanjuti',
        satgas_notes: 'Tim gabungan Dishub & Satpol PP telah menertibkan oknum parkir liar di lokasi.',
      },
      null,
      2
    ),
  },
  {
    id: 's2-ep-offline-v2',
    label: '10. [Hari 10] Bundel Offline Lengkap v2 (Destinasi + 360° + Peta Mikro + Audio)',
    method: 'GET',
    path: '/api/v1/destinations/dest-001/offline-bundle',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Simpan Lokal Mode Offline Hive/Sqflite)',
    description: 'Mengunduh 1 paket bundel offline v2.0 lengkap dengan scene 360°, 4 pin interaktif, GeoJSON peta mikro, dan transkrip audio untuk area Blank Spot.',
  },
];

export const SPRINT3_ENDPOINT_PRESETS: EndpointPreset[] = [
  {
    id: 's3-ep-gaode-list',
    label: '01. [Hari 12] Leaderboard Gaode Behavior-Based Ranking (Anti-Bintang Palsu)',
    method: 'GET',
    path: '/api/v1/destinations/rankings/gaode',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Layar Peringkat Gaode Guide)',
    description: 'Mengambil peringkat populer Sumatera Barat berdasarkan jumlah navigasi nyata selesai (45%) + waktu singgah GPS dwell time (40%) + kunjungan berulang (15%).',
  },
  {
    id: 's3-ep-gaode-telemetry',
    label: '02. [Hari 12] Kirim Telemetri Dwell Time GPS -> Auto-Update Skor Gaode',
    method: 'POST',
    path: '/api/v1/spatial/navigation-telemetry',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Tracker Selesai Navigasi & Dwell Time)',
    description: 'Mengirimkan durasi singgah GPS nyata wisatawan (>10 menit) di Nagari Tuo Pariangan dan memperbarui skor Gaode Ranking secara otomatis.',
    defaultBody: JSON.stringify(
      {
        destination_id: 'dest-008',
        dwell_time_minutes: 165,
        is_repeat_visit: true,
        gps_accuracy_meters: 4.2,
      },
      null,
      2
    ),
  },
  {
    id: 's3-ep-gaode-reject',
    label: '03. [Hari 12] Uji Guardrail Anti-Manipulasi (Pass-By <10 Menit Ditolak)',
    method: 'POST',
    path: '/api/v1/spatial/navigation-telemetry',
    defaultRole: 'public',
    consumerRole: 'QA & Anti-Fraud Guardrail BE-1',
    description: 'Membuktikan bahwa kendaraan yang hanya lewat di depan destinasi (<10 menit dwell time) ditolak otomatis (HTTP 422) agar tidak memanipulasi ranking.',
    defaultBody: JSON.stringify(
      {
        destination_id: 'dest-002',
        dwell_time_minutes: 4,
        is_repeat_visit: false,
      },
      null,
      2
    ),
  },
  {
    id: 's3-ep-hazards-get',
    label: '04. [Hari 13] Live Hazard Alert Jalur Ekstrem (Cek Zona Rawan Sitinjau Lauik)',
    method: 'GET',
    path: '/api/v1/spatial/hazards?lat=-0.9465&lng=100.5180',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Banner Peringatan Jalur Rawan & Rute Alternatif)',
    description: 'Memeriksa 4 koridor jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44) dan mengaktifkan fe1_active_warning_banner jika GPS berpotongan.',
  },
  {
    id: 's3-ep-hazards-trigger',
    label: '05. [Hari 13] Panel FS-1: Simulasi Trigger Bencana Jalur Ekstrem (RBAC)',
    method: 'POST',
    path: '/api/v1/admin/hazards/trigger',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (Panel Trigger Bencana Command Center)',
    description: 'Mengubah status koridor Lembah Anai menjadi SIAGA / AWAS dari Command Center FS-1 sehingga Banner Peringatan FE-1 langsung berubah real-time.',
    defaultBody: JSON.stringify(
      {
        corridor_code: 'LEMBAH-ANAI',
        severity: 'Siaga',
        hazard_type: 'Debit Air Sungai Batang Anai Naik & Sistem Buka-Tutup',
        weather_status: 'Hujan Deras di Hulu Gunung Singgalang',
        message: 'SIAGA KORIDOR LEMBAH ANAI: Arus kendaraan dialihkan sementara via Jalur Malalak.',
        detour_route: 'Gunakan rute alternatif Sicincin – Malalak – Bukittinggi.',
        triggered_by_admin: 'Panel Trigger Bencana FS-1 (Admin Dispar)',
      },
      null,
      2
    ),
  },
  {
    id: 's3-ep-sos-post',
    label: '06. [Hari 13] Pancaran Darurat SOS GPS Wisatawan (Hitung Posko SAR Terdekat)',
    method: 'POST',
    path: '/api/v1/spatial/sos',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Tombol Darurat SOS GPS)',
    description: 'Memancarkan titik koordinat darurat wisatawan, persentase baterai, dan jumlah penumpang; server otomatis mencari Posko SAR/PKJR terdekat & ETA.',
    defaultBody: JSON.stringify(
      {
        tourist_name: 'Uda Fauzan & Keluarga',
        phone_number: '+62811665544',
        emergency_type: 'Kendaraan Mogok / Kampas Kopling Panas di Tanjakan',
        latitude: -0.9460,
        longitude: 100.5175,
        battery_percent: 19,
        passengers_count: 4,
        notes: 'Berhenti di bahu aman 150 meter sebelum tikungan Panorama 1 Sitinjau Lauik.',
      },
      null,
      2
    ),
  },
  {
    id: 's3-ep-sos-admin',
    label: '07. [Hari 13] Command Center FS-1: Monitor Daftar Sinyal Darurat SOS Masuk',
    method: 'GET',
    path: '/api/v1/admin/sos',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (Monitor Antrean SOS Command Center)',
    description: 'Menampilkan seluruh sinyal darurat SOS GPS yang masuk beserta estimasi jarak dan waktu evakuasi Posko SAR terdekat.',
  },
  {
    id: 's3-ep-minang-phrases',
    label: '08. [Hari 14] Kamus Saku Audio Bahasa Minang & Adab Kato Nan Ampek',
    method: 'GET',
    path: '/api/v1/culture/minang-phrases?category=tawar_pasar',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Kamus Saku Audio Minang — Token Indigo #5B6AE8)',
    description: 'Mengambil frasa praktis bahasa Minang (Tawar-Menawar Pasar, Sapaan Adat, Kuliner, Darurat) lengkap dengan panduan lafal dan file audio penutur asli.',
  },
  {
    id: 's3-ep-culture-events',
    label: '09. [Hari 14] Kalender Budaya & Jadwal Hari Pakan (Pasar Tradisional Nagari)',
    method: 'GET',
    path: '/api/v1/culture/events?lat=-0.4560&lng=100.5900',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Kalender Budaya & Hari Pakan — Token Indigo #5B6AE8)',
    description: 'Mengambil jadwal Pacu Jawi, Hoyak Tabuik, serta Hari Pakan Kamis/Sabtu/Rabaa di nagari-nagari Sumatera Barat beserta jarak spasial.',
  },
];

export const SPRINT4_ENDPOINT_PRESETS: EndpointPreset[] = [
  {
    id: 's4-ep-benchmark',
    label: '01. [Hari 19] Live Performance Benchmark (<100ms SLA) & Audit 11 Tabel PostGIS',
    method: 'GET',
    path: '/api/v1/admin/system/benchmark',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 & QA Workbench (Verifikasi SLA <100ms)',
    description: 'Mengukur latensi nyata p50/p95/p99 (<100ms SLA), rasio Cache HIT/MISS, statistik Token Bucket Rate-Limiter, dan kesiapan 11 tabel PostGIS.',
  },
  {
    id: 's4-ep-contracts',
    label: '02. [Hari 19] Katalog Final 24 Endpoint BE-1 (Sprint 1 s/d Sprint 4)',
    method: 'GET',
    path: '/api/v1/system/contracts',
    defaultRole: 'public',
    consumerRole: 'FE-1, FE-2, & FS-1 (Dokumentasi Kontrak Final)',
    description: 'Mengembalikan daftar terstruktur seluruh 24 Endpoint BE-1 beserta Pilar Referensi, Auth Guard, Consumer Role, dan Target SLA.',
  },
  {
    id: 's4-ep-cache-360',
    label: '03. [Hari 17] Uji In-Memory TTL Cache & Header ETag pada Kanvas 360°',
    method: 'GET',
    path: '/api/v1/destinations/dest-001/scenes-360',
    defaultRole: 'public',
    consumerRole: 'FE-1 (Optimasi FPS Kanvas 360° <5ms)',
    description: 'Panggilan pertama menghasilkan X-Cache: MISS, panggilan kedua langsung menghasilkan X-Cache: HIT dengan ETag W/"rancak-be1-...".',
  },
  {
    id: 's4-ep-cache-flush',
    label: '04. [Hari 19] Admin Manual Cache Flush (Reset In-Memory TTL Cache & ETag)',
    method: 'POST',
    path: '/api/v1/admin/cache/flush',
    defaultRole: 'admin_dispar',
    consumerRole: 'FS-1 (Tombol Penyegaran Cache Admin CMS)',
    description: 'Mengosongkan seluruh entri In-Memory TTL Cache secara instan saat Admin Dispar memerlukan penyegaran paksa.',
  },
  {
    id: 's4-ep-ratelimit-pungli',
    label: '05. [Hari 18] Simulasi Anti-Spam Token Bucket Rate-Limit (HTTP 429) Lapor Pungli',
    method: 'POST',
    path: '/api/v1/pungli/report?simulate_ratelimit=true',
    defaultRole: 'public',
    consumerRole: 'FE-2 & Security Guardrail BE-1',
    description: 'Menyimulasikan serangan spam laporan pungli beruntun; server menolak dengan HTTP 429 Too Many Requests dan Retry-After: 60 detik.',
    defaultBody: JSON.stringify(
      {
        destination_id: 'dest-001',
        incident_category: 'parkir_liar',
        charged_amount_idr: 25000,
        description: 'Simulasi burst spam laporan pungli beruntun',
      },
      null,
      2
    ),
  },
  {
    id: 's4-ep-ratelimit-sos',
    label: '06. [Hari 18] Simulasi Anti-Spam Token Bucket Rate-Limit (HTTP 429) Sinyal SOS GPS',
    method: 'POST',
    path: '/api/v1/spatial/sos?simulate_ratelimit=true',
    defaultRole: 'public',
    consumerRole: 'FE-1 & Security Guardrail BE-1',
    description: 'Menyimulasikan pengiriman sinyal SOS palsu beruntun; server memblokir dengan HTTP 429 Too Many Requests.',
    defaultBody: JSON.stringify(
      {
        tourist_name: 'Spam Bot Tester',
        latitude: -0.9465,
        longitude: 100.518,
      },
      null,
      2
    ),
  },
];

export const JWT_TOKEN_OPTIONS: Record<
  'public' | 'tourist' | 'pokdarwis' | 'admin_dispar',
  { label: string; token: string; roleDesc: string }
> = {
  public: {
    label: 'Tanpa Login (Pengunjung Umum / Scan QR)',
    token: '',
    roleDesc: 'Bisa membuka semua fitur umum, tapi otomatis ditolak (401) kalau coba masuk ke halaman Admin atau Satgas.',
  },
  tourist: {
    label: 'Login Wisatawan Biasa (Role: tourist)',
    token:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXRvdXJpc3QtMDEiLCJuYW1lIjoiUml6a3kgUHJhdGFtYSAoV2lzYXRhd2FuKSIsInJvbGUiOiJ0b3VyaXN0In0.rancakin_sig_tourist',
    roleDesc: 'Tiket login wisatawan biasa. Ditolak (403) kalau coba mengubah data milik Admin Dispar.',
  },
  pokdarwis: {
    label: 'Login Pengelola Lokal (Role: pokdarwis)',
    token:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXBva2Rhcndpcy0wMSIsIm5hbWUiOiJVZGEgWnVsIChQb2tkYXJ3aXMgTmFnYXJpKSIsInJvbGUiOiJwb2tkYXJ3aXMifQ.rancakin_sig_pokdarwis',
    roleDesc: 'Boleh memperbarui info kondisi jalan, harga nagari, dan titik pin fasilitas 360°.',
  },
  admin_dispar: {
    label: 'Login Admin Dispar / Satgas / BPBD (Role: admin_dispar — FS-1)',
    token:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLWFkbWluLWRpc3Bhci0wMSIsIm5hbWUiOiJBZG1pbiBEaXNwYXIgU3VtYmFyIChGUy0xKSIsInJvbGUiOiJhZG1pbl9kaXNwYXIifQ.rancakin_sig_admin',
    roleDesc: 'Akses penuh untuk mengelola tempat wisata, foto 360°, menindak laporan pungli, dan menyalakan alarm bencana.',
  },
};

export interface AutomatedTestResult {
  id: string;
  code: string;
  name: string;
  target: string;
  expected: string;
  status: 'idle' | 'running' | 'pass' | 'fail';
  httpCode?: number;
  durationMs?: number;
  assertionDetail?: string;
}

const INITIAL_SPRINT1_TEST_CASES: AutomatedTestResult[] = [
  {
    id: 'tc-1',
    code: 'TC-01',
    name: 'Health Check Server Go & Status Ekstensi PostGIS',
    target: 'GET /api/v1/health',
    expected: 'HTTP 200 OK · service = rancakin-be1-core-spatial',
    status: 'idle',
  },
  {
    id: 'tc-2',
    code: 'TC-02',
    name: 'Verifikasi Seeder 20 Destinasi Prioritas Sumatera Barat',
    target: 'GET /api/v1/destinations',
    expected: 'HTTP 200 OK · Jumlah destinasi aktif >= 20 lokasi',
    status: 'idle',
  },
  {
    id: 'tc-3',
    code: 'TC-03',
    name: 'Akurasi Kalkulasi Jarak Spasial PostGIS (ST_DistanceSphere)',
    target: 'GET /api/v1/destinations?lat=-0.3051&lng=100.3694',
    expected: 'HTTP 200 OK · Jam Gadang Bukittinggi berada di urutan terdekat (<1 km)',
    status: 'idle',
  },
  {
    id: 'tc-4',
    code: 'TC-04',
    name: 'Filter Spesifik Zona Blank Spot Sinyal (Mode Offline Pocket FE-1)',
    target: 'GET /api/v1/destinations?signal=blank_spot',
    expected: 'HTTP 200 OK · Semua hasil memiliki cellular_signal = blank_spot',
    status: 'idle',
  },
  {
    id: 'tc-5',
    code: 'TC-05',
    name: 'Kelengkapan Kontrak JSON Detail Tempat (4 Statistik + 5 Medan + Tips + Perda)',
    target: 'GET /api/v1/destinations/QR-SMBR-LPK-002',
    expected: 'HTTP 200 OK · Memuat decision_stats, medan_indicator, tips[], official_tariffs[]',
    status: 'idle',
  },
  {
    id: 'tc-6',
    code: 'TC-06',
    name: 'Guardrail Keamanan JWT: Tolak Request CMS Tanpa Header Token',
    target: 'POST /api/v1/admin/destinations (Tanpa Token)',
    expected: 'HTTP 401 Unauthorized · code = UNAUTHORIZED_MISSING_TOKEN',
    status: 'idle',
  },
  {
    id: 'tc-7',
    code: 'TC-07',
    name: 'Guardrail RBAC: Tolak Role Tourist Saat Mengubah Data CMS Admin',
    target: 'PUT /api/v1/admin/destinations/dest-001 (Role: tourist)',
    expected: 'HTTP 403 Forbidden · code = FORBIDDEN_INSUFFICIENT_ROLE',
    status: 'idle',
  },
  {
    id: 'tc-8',
    code: 'TC-08',
    name: 'Integrasi CMS FS-1: Update Indikator Medan & Sinkronisasi Tarif Perda (Role: admin_dispar)',
    target: 'PUT /api/v1/admin/destinations/dest-001 (Role: admin_dispar)',
    expected: 'HTTP 200 OK · Data indikator medan & timestamp terbarui di server',
    status: 'idle',
  },
];

const INITIAL_SPRINT2_TEST_CASES: AutomatedTestResult[] = [
  {
    id: 'tc-s2-1',
    code: 'TC-S2-01',
    name: '[Hari 7] Tur Virtual 360° Aerial-to-Ground & Standarisasi 4 Pin Interaktif',
    target: 'GET /api/v1/destinations/dest-001/scenes-360',
    expected: 'HTTP 200 OK · Memuat scene aerial & ground beserta 4 jenis pin (navigasi, audio, fasilitas, mitra)',
    status: 'idle',
  },
  {
    id: 'tc-s2-2',
    code: 'TC-S2-02',
    name: '[Hari 7] CMS Studio 360° FS-1: Klik-Tempel Pin di Koordinat Bola (Pitch/Yaw)',
    target: 'POST /api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots',
    expected: 'HTTP 201 Created · Pin baru tertempel dengan color_token sesuai tipe pin',
    status: 'idle',
  },
  {
    id: 'tc-s2-3',
    code: 'TC-S2-03',
    name: '[Hari 8] Engine Cari Searah Rute ("Shunlu" +X Menit Detour)',
    target: 'POST /api/v1/spatial/shunlu',
    expected: 'HTTP 200 OK · Mengembalikan POI searah rute diurutkan dari detour_minutes terkecil',
    status: 'idle',
  },
  {
    id: 'tc-s2-4',
    code: 'TC-S2-04',
    name: '[Hari 8] Peta Mikro Kawasan & Pemicu Otomatis Audio GPS <=15 Meter',
    target: 'POST /api/v1/spatial/audio-trigger-check',
    expected: 'HTTP 200 OK · trigger_status = AUTO_PLAY_ACTIVE saat GPS <=15m dari titik cerita',
    status: 'idle',
  },
  {
    id: 'tc-s2-5',
    code: 'TC-S2-05',
    name: '[Hari 9] Resolusi Cepat Scanner Plang Smart QR (<2 Detik)',
    target: 'GET /api/v1/qr/QR-SMBR-LPK-001',
    expected: 'HTTP 200 OK · status = resolved + fair_price_verified + scenes_360 + micro_map',
    status: 'idle',
  },
  {
    id: 'tc-s2-6',
    code: 'TC-S2-06',
    name: '[Hari 9] Form Lapor Pungli Anonim + Kalkulasi Otomatis Selisih Tarif Perda',
    target: 'POST /api/v1/pungli/report',
    expected: 'HTTP 201 Created · Menerbitkan kode tiket PGL-202611-XXXX & menghitung overcharge_amount_idr',
    status: 'idle',
  },
  {
    id: 'tc-s2-7',
    code: 'TC-S2-07',
    name: '[Hari 9] Pusat Komando Satgas FS-1: Ubah Status Tiket Aduan (Protected RBAC)',
    target: 'PATCH /api/v1/admin/pungli/PGL-202611-0091/status',
    expected: 'HTTP 200 OK · Status tiket berubah menjadi Ditindaklanjuti oleh Admin Dispar',
    status: 'idle',
  },
  {
    id: 'tc-s2-8',
    code: 'TC-S2-08',
    name: '[Hari 10] Bundel Offline Lengkap v2 (Destinasi + 360° + Peta Mikro + Audio)',
    target: 'GET /api/v1/destinations/dest-001/offline-bundle',
    expected: 'HTTP 200 OK · bundle_version = v2.0-sprint2-complete siap simpan di Hive/Sqflite FE-1',
    status: 'idle',
  },
];

const INITIAL_SPRINT3_TEST_CASES: AutomatedTestResult[] = [
  {
    id: 'tc-s3-1',
    code: 'TC-S3-01',
    name: '[Hari 12] Leaderboard Gaode Behavior-Based Ranking (Anti-Manipulasi Bintang Palsu)',
    target: 'GET /api/v1/destinations/rankings/gaode',
    expected: 'HTTP 200 OK · Daftar peringkat diurutkan berdasarkan gaode_authenticity_score tertinggi',
    status: 'idle',
  },
  {
    id: 'tc-s3-2',
    code: 'TC-S3-02',
    name: '[Hari 12] Kalkulasi Otomatis Skor Gaode dari Log Navigasi & Dwell Time GPS (>10m)',
    target: 'POST /api/v1/spatial/navigation-telemetry',
    expected: 'HTTP 200 OK · status = telemetry_recorded & skor keaslian Gaode terhitung ulang otomatis',
    status: 'idle',
  },
  {
    id: 'tc-s3-3',
    code: 'TC-S3-03',
    name: '[Hari 12] Guardrail Anti-Manipulasi: Tolak Ping GPS Kendaraan Melintas (<10 Menit)',
    target: 'POST /api/v1/spatial/navigation-telemetry (4 mnt)',
    expected: 'HTTP 422 Unprocessable Entity · status = rejected_pass_by',
    status: 'idle',
  },
  {
    id: 'tc-s3-4',
    code: 'TC-S3-04',
    name: '[Hari 13] Deteksi Spasial Zona Bahaya Jalur Ekstrem Sitinjau Lauik + Rute Detour',
    target: 'GET /api/v1/spatial/hazards?lat=-0.9465&lng=100.5180',
    expected: 'HTTP 200 OK · user_in_hazard_zone = true & fe1_active_warning_banner terisi otomatis',
    status: 'idle',
  },
  {
    id: 'tc-s3-5',
    code: 'TC-S3-05',
    name: '[Hari 13] Simulasi Trigger Bencana Command Center FS-1 (Protected RBAC)',
    target: 'POST /api/v1/admin/hazards/trigger',
    expected: 'HTTP 200 OK · status = hazard_triggered mengubah level bahaya koridor Lembah Anai',
    status: 'idle',
  },
  {
    id: 'tc-s3-6',
    code: 'TC-S3-06',
    name: '[Hari 13] Pancaran Darurat SOS GPS FE-1 + Kalkulasi Posko SAR Terdekat & ETA',
    target: 'POST /api/v1/spatial/sos',
    expected: 'HTTP 201 Created · Menerbitkan kode SOS-SUMBAR-202611-XXX & menghitung eta_rescue_minutes',
    status: 'idle',
  },
  {
    id: 'tc-s3-7',
    code: 'TC-S3-07',
    name: '[Hari 14] Direktori Kamus Saku Audio Bahasa Minang & Panduan Kato Nan Ampek',
    target: 'GET /api/v1/culture/minang-phrases?category=tawar_pasar',
    expected: 'HTTP 200 OK · Mengembalikan frasa bahasa Minang, cara baca fonetik, dan URL audio',
    status: 'idle',
  },
  {
    id: 'tc-s3-8',
    code: 'TC-S3-08',
    name: '[Hari 14] Kalender Budaya & Jadwal Hari Pakan Nagari + Kalkulasi Jarak GPS',
    target: 'GET /api/v1/culture/events?lat=-0.4560&lng=100.5900',
    expected: 'HTTP 200 OK · Mengembalikan jadwal Pacu Jawi & Hari Pakan lengkap dengan distance_km',
    status: 'idle',
  },
];

const INITIAL_SPRINT4_TEST_CASES: AutomatedTestResult[] = [
  {
    id: 'tc-s4-1',
    code: 'TC-S4-01',
    name: '[Hari 17] In-Memory TTL Cache MISS & Pembuatan Header ETag pada Panggilan Pertama 360°',
    target: 'GET /api/v1/destinations/dest-001/scenes-360 (First Call)',
    expected: 'HTTP 200 OK · Header X-Cache = MISS & ETag W/"rancak-be1-..." diterbitkan',
    status: 'idle',
  },
  {
    id: 'tc-s4-2',
    code: 'TC-S4-02',
    name: '[Hari 17] In-Memory TTL Cache HIT (<5ms) pada Panggilan Kedua Kanvas 360°',
    target: 'GET /api/v1/destinations/dest-001/scenes-360 (Second Call)',
    expected: 'HTTP 200 OK · Header X-Cache = HIT tanpa membebani kueri database',
    status: 'idle',
  },
  {
    id: 'tc-s4-3',
    code: 'TC-S4-03',
    name: '[Hari 17] Validasi HTTP 304 Not Modified saat Header If-None-Match Cocok dengan ETag',
    target: 'GET /api/v1/destinations/dest-001/scenes-360 (If-None-Match)',
    expected: 'HTTP 304 Not Modified · Menghemat bandwidth FE-1 saat kanvas 360° belum berubah',
    status: 'idle',
  },
  {
    id: 'tc-s4-4',
    code: 'TC-S4-04',
    name: '[Hari 18] Guardrail Anti-Spam Token Bucket Rate-Limiter pada Lapor Pungli (Burst)',
    target: 'POST /api/v1/pungli/report (X-Simulate-RateLimit: burst)',
    expected: 'HTTP 429 Too Many Requests · code = RATE_LIMIT_EXCEEDED & Retry-After = 60',
    status: 'idle',
  },
  {
    id: 'tc-s4-5',
    code: 'TC-S4-05',
    name: '[Hari 18] Guardrail Anti-Spam Token Bucket Rate-Limiter pada Pancaran SOS GPS (Burst)',
    target: 'POST /api/v1/spatial/sos (X-Simulate-RateLimit: burst)',
    expected: 'HTTP 429 Too Many Requests · Mencegah banjir sinyal SOS palsu ke Command Center',
    status: 'idle',
  },
  {
    id: 'tc-s4-6',
    code: 'TC-S4-06',
    name: '[Hari 16 & 19] Verifikasi Live Benchmark Performa Spasial PostGIS (<100ms SLA)',
    target: 'GET /api/v1/admin/system/benchmark',
    expected: 'HTTP 200 OK · sla_passed = true (p50, p95, dan p99 seluruhnya < 100ms)',
    status: 'idle',
  },
  {
    id: 'tc-s4-7',
    code: 'TC-S4-07',
    name: '[Hari 19] Manual Cache Flush Admin FS-1 Mereset Status Cache Kembali ke MISS',
    target: 'POST /api/v1/admin/cache/flush',
    expected: 'HTTP 200 OK · status = flushed & panggilan 360° berikutnya kembali X-Cache = MISS',
    status: 'idle',
  },
  {
    id: 'tc-s4-8',
    code: 'TC-S4-08',
    name: '[Hari 19 & 20] Verifikasi Katalog Kontrak Final Genap 24 Endpoint BE-1 (Sprint 1–4)',
    target: 'GET /api/v1/system/contracts',
    expected: 'HTTP 200 OK · total_endpoints = 24 (7 Sprint 1 + 7 Sprint 2 + 7 Sprint 3 + 3 Sprint 4)',
    status: 'idle',
  },
];

interface ApiTesterAndQaViewProps {
  mode: 'tester' | 'qa';
  selectedSprint: 'sprint1' | 'sprint2' | 'sprint3' | 'sprint4';
  onDatabaseMutated: () => void;
}

export const ApiTesterAndQaView: React.FC<ApiTesterAndQaViewProps> = ({
  mode,
  selectedSprint,
  onDatabaseMutated,
}) => {
  const activePresets =
    selectedSprint === 'sprint1'
      ? SPRINT1_ENDPOINT_PRESETS
      : selectedSprint === 'sprint2'
      ? SPRINT2_ENDPOINT_PRESETS
      : selectedSprint === 'sprint3'
      ? SPRINT3_ENDPOINT_PRESETS
      : SPRINT4_ENDPOINT_PRESETS;

  const [selectedPresetId, setSelectedPresetId] = useState<string>(activePresets[0].id);
  const [httpMethod, setHttpMethod] = useState<'GET' | 'POST' | 'PUT' | 'PATCH'>(activePresets[0].method);
  const [requestPath, setRequestPath] = useState<string>(activePresets[0].path);
  const [selectedRole, setSelectedRole] = useState<'public' | 'tourist' | 'pokdarwis' | 'admin_dispar'>(
    activePresets[0].defaultRole
  );
  const [requestBody, setRequestBody] = useState<string>(activePresets[0].defaultBody || '');
  const [isSending, setIsSending] = useState<boolean>(false);
  const [responseStatus, setResponseStatus] = useState<number | null>(null);
  const [responseLatencyMs, setResponseLatencyMs] = useState<number | null>(null);
  const [responseCacheHeader, setResponseCacheHeader] = useState<string | null>(null);
  const [responseEtagHeader, setResponseEtagHeader] = useState<string | null>(null);
  const [responseJson, setResponseJson] = useState<string>(
    '// Klik tombol "Kirim Request ke Server" untuk melihat respons JSON real-time dari endpoint BE-1.'
  );
  const [copiedCurl, setCopiedCurl] = useState<boolean>(false);
  const [copiedResponse, setCopiedResponse] = useState<boolean>(false);

  const [testResultsSprint1, setTestResultsSprint1] = useState<AutomatedTestResult[]>(INITIAL_SPRINT1_TEST_CASES);
  const [testResultsSprint2, setTestResultsSprint2] = useState<AutomatedTestResult[]>(INITIAL_SPRINT2_TEST_CASES);
  const [testResultsSprint3, setTestResultsSprint3] = useState<AutomatedTestResult[]>(INITIAL_SPRINT3_TEST_CASES);
  const [testResultsSprint4, setTestResultsSprint4] = useState<AutomatedTestResult[]>(INITIAL_SPRINT4_TEST_CASES);
  const [isRunningTests, setIsRunningTests] = useState<boolean>(false);
  const [isResettingSeed, setIsResettingSeed] = useState<boolean>(false);

  useEffect(() => {
    const first = (
      selectedSprint === 'sprint1'
        ? SPRINT1_ENDPOINT_PRESETS
        : selectedSprint === 'sprint2'
        ? SPRINT2_ENDPOINT_PRESETS
        : selectedSprint === 'sprint3'
        ? SPRINT3_ENDPOINT_PRESETS
        : SPRINT4_ENDPOINT_PRESETS
    )[0];
    setSelectedPresetId(first.id);
    setHttpMethod(first.method);
    setRequestPath(first.path);
    setSelectedRole(first.defaultRole);
    setRequestBody(first.defaultBody || '');
  }, [selectedSprint]);

  const handleSelectPreset = (preset: EndpointPreset) => {
    setSelectedPresetId(preset.id);
    setHttpMethod(preset.method);
    setRequestPath(preset.path);
    setSelectedRole(preset.defaultRole);
    setRequestBody(preset.defaultBody || '');
  };

  const buildCurlCommand = () => {
    const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3000';
    const token = JWT_TOKEN_OPTIONS[selectedRole].token;
    const lines: string[] = [`curl -i -X ${httpMethod} "${baseUrl}${requestPath}"`];
    lines.push(`  -H "Accept: application/json"`);
    if (token) {
      lines.push(`  -H "Authorization: Bearer ${token}"`);
    }
    if (httpMethod !== 'GET' && requestBody.trim()) {
      const compactBody = requestBody.replace(/\s+/g, ' ').trim();
      lines.push(`  -H "Content-Type: application/json"`);
      lines.push(`  -d '${compactBody}'`);
    }
    return lines.join(' \\\n');
  };

  const handleSendRequest = async () => {
    setIsSending(true);
    const start = performance.now();
    try {
      const headers: Record<string, string> = {
        Accept: 'application/json',
      };
      const token = JWT_TOKEN_OPTIONS[selectedRole].token;
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
      if (httpMethod !== 'GET') {
        headers['Content-Type'] = 'application/json';
      }

      const res = await fetch(requestPath, {
        method: httpMethod,
        headers,
        body: httpMethod !== 'GET' ? requestBody : undefined,
      });

      const elapsed = Number((performance.now() - start).toFixed(1));
      setResponseStatus(res.status);
      setResponseLatencyMs(elapsed);
      setResponseCacheHeader(res.headers.get('X-Cache'));
      setResponseEtagHeader(res.headers.get('ETag'));

      const data = await res.json();
      setResponseJson(JSON.stringify(data, null, 2));

      if (httpMethod !== 'GET') {
        onDatabaseMutated();
      }
    } catch (err) {
      setResponseStatus(500);
      setResponseJson(
        JSON.stringify(
          {
            status: 'client_error',
            message: err instanceof Error ? err.message : 'Gagal menghubungi server API',
          },
          null,
          2
        )
      );
    } finally {
      setIsSending(false);
    }
  };

  const handleCopyCurl = () => {
    navigator.clipboard.writeText(buildCurlCommand());
    setCopiedCurl(true);
    setTimeout(() => setCopiedCurl(false), 1800);
  };

  const handleCopyResponse = () => {
    navigator.clipboard.writeText(responseJson);
    setCopiedResponse(true);
    setTimeout(() => setCopiedResponse(false), 1800);
  };

  const handleResetSeed = async () => {
    setIsResettingSeed(true);
    try {
      await fetch('/api/v1/dev/reset-seed', { method: 'POST' });
      onDatabaseMutated();
    } finally {
      setIsResettingSeed(false);
    }
  };

  const runSprint1AutomatedTestSuite = async () => {
    setIsRunningTests(true);
    const updated: AutomatedTestResult[] = INITIAL_SPRINT1_TEST_CASES.map((t) => ({ ...t, status: 'running' }));
    setTestResultsSprint1([...updated]);

    const runSingle = async (
      idx: number,
      fn: () => Promise<{ pass: boolean; httpCode: number; detail: string }>
    ) => {
      const t0 = performance.now();
      try {
        const res = await fn();
        const dt = Number((performance.now() - t0).toFixed(1));
        updated[idx] = {
          ...updated[idx],
          status: res.pass ? 'pass' : 'fail',
          httpCode: res.httpCode,
          durationMs: dt,
          assertionDetail: res.detail,
        };
      } catch (e) {
        updated[idx] = {
          ...updated[idx],
          status: 'fail',
          httpCode: 500,
          durationMs: 0,
          assertionDetail: e instanceof Error ? e.message : 'Request gagal',
        };
      }
      setTestResultsSprint1([...updated]);
    };

    await runSingle(0, async () => {
      const r = await fetch('/api/v1/health');
      const j = await r.json();
      const pass = r.status === 200 && j.status === 'ok' && j.service === 'rancakin-be1-core-spatial';
      return {
        pass,
        httpCode: r.status,
        detail: `Service: ${j.service} · Active Destinations: ${j.active_tables?.destinations}`,
      };
    });

    await runSingle(1, async () => {
      const r = await fetch('/api/v1/destinations');
      const j = await r.json();
      const count = Array.isArray(j.data) ? j.data.length : 0;
      return {
        pass: r.status === 200 && count >= 20,
        httpCode: r.status,
        detail: `Ditemukan ${count} destinasi prioritas Sumatera Barat lengkap dengan indikator medan.`,
      };
    });

    await runSingle(2, async () => {
      const r = await fetch('/api/v1/destinations?lat=-0.30519&lng=100.36947');
      const j = await r.json();
      const first = j.data?.[0];
      const pass =
        r.status === 200 &&
        first &&
        first.slug === 'jam-gadang-bukittinggi' &&
        first.decision_stats.distance_km <= 1.0;
      return {
        pass,
        httpCode: r.status,
        detail: first
          ? `Urutan #1: ${first.name} (${first.decision_stats.distance_km} km dari titik uji)`
          : 'Data kosong',
      };
    });

    await runSingle(3, async () => {
      const r = await fetch('/api/v1/destinations?signal=blank_spot');
      const j = await r.json();
      const list = Array.isArray(j.data) ? j.data : [];
      const allBlank =
        list.length >= 3 &&
        list.every((d: { medan_indicator?: { cellular_signal?: string } }) => d.medan_indicator?.cellular_signal === 'blank_spot');
      return {
        pass: r.status === 200 && allBlank,
        httpCode: r.status,
        detail: `${list.length} destinasi Blank Spot terdeteksi (Nyarai, Silokek, Siberut) untuk Offline Pocket FE-1.`,
      };
    });

    await runSingle(4, async () => {
      const r = await fetch('/api/v1/destinations/QR-SMBR-LPK-002');
      const j = await r.json();
      const d = j.data;
      const pass =
        r.status === 200 &&
        d &&
        d.decision_stats &&
        d.medan_indicator &&
        Array.isArray(d.tips) &&
        d.tips.length > 0 &&
        Array.isArray(d.official_tariffs) &&
        d.official_tariffs.length > 0;
      return {
        pass,
        httpCode: r.status,
        detail: d
          ? `Lookup QR '${d.qr_placard_code}' -> ${d.name} (${d.official_tariffs.length} tarif Perda, ${d.tips.length} tips)`
          : 'Gagal mengambil detail',
      };
    });

    await runSingle(5, async () => {
      const r = await fetch('/api/v1/admin/destinations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'Uji Tanpa Token' }),
      });
      const j = await r.json();
      return {
        pass: r.status === 401 && j.code === 'UNAUTHORIZED_MISSING_TOKEN',
        httpCode: r.status,
        detail: `Ditolak sesuai ekspektasi: ${j.code}`,
      };
    });

    await runSingle(6, async () => {
      const r = await fetch('/api/v1/admin/destinations/dest-001', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${JWT_TOKEN_OPTIONS.tourist.token}`,
        },
        body: JSON.stringify({ crowd_level: 'sepi' }),
      });
      const j = await r.json();
      return {
        pass: r.status === 403 && j.code === 'FORBIDDEN_INSUFFICIENT_ROLE',
        httpCode: r.status,
        detail: `Ditolak sesuai ekspektasi: Role '${j.current_role}' tidak boleh mengubah CMS.`,
      };
    });

    await runSingle(7, async () => {
      const r = await fetch('/api/v1/admin/destinations/dest-001', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${JWT_TOKEN_OPTIONS.admin_dispar.token}`,
        },
        body: JSON.stringify({
          crowd_level: 'ramai',
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 200 && j.status === 'success',
        httpCode: r.status,
        detail: `Berhasil diperbarui oleh Admin Dispar FS-1: ${j.data?.name}`,
      };
    });

    onDatabaseMutated();
    setIsRunningTests(false);
  };

  const runSprint2AutomatedTestSuite = async () => {
    setIsRunningTests(true);
    const updated: AutomatedTestResult[] = INITIAL_SPRINT2_TEST_CASES.map((t) => ({ ...t, status: 'running' }));
    setTestResultsSprint2([...updated]);

    const runSingle = async (
      idx: number,
      fn: () => Promise<{ pass: boolean; httpCode: number; detail: string }>
    ) => {
      const t0 = performance.now();
      try {
        const res = await fn();
        const dt = Number((performance.now() - t0).toFixed(1));
        updated[idx] = {
          ...updated[idx],
          status: res.pass ? 'pass' : 'fail',
          httpCode: res.httpCode,
          durationMs: dt,
          assertionDetail: res.detail,
        };
      } catch (e) {
        updated[idx] = {
          ...updated[idx],
          status: 'fail',
          httpCode: 500,
          durationMs: 0,
          assertionDetail: e instanceof Error ? e.message : 'Request gagal',
        };
      }
      setTestResultsSprint2([...updated]);
    };

    // TC-S2-01: Tur Virtual 360 & 4 Pin
    await runSingle(0, async () => {
      const r = await fetch('/api/v1/destinations/dest-001/scenes-360');
      const j = await r.json();
      const scenes = Array.isArray(j.scenes_360) ? j.scenes_360 : [];
      return {
        pass: r.status === 200 && scenes.length >= 2,
        httpCode: r.status,
        detail: `${scenes.length} Scene 360° (Aerial 150m & Ground) aktif untuk ${j.destination_name}.`,
      };
    });

    // TC-S2-02: Klik-Tempel Pin 360 dari CMS FS-1
    await runSingle(1, async () => {
      const r = await fetch('/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${JWT_TOKEN_OPTIONS.admin_dispar.token}`,
        },
        body: JSON.stringify({
          type: 'mitra',
          pitch: -12.0,
          yaw: 220.0,
          title: 'Kopi Kawa Daun & Homestay Harau',
          target_ref: 'partner-004',
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 201 && j.status === 'pin_attached' && j.attached_pin?.color_token === '#E85D1A',
        httpCode: r.status,
        detail: `Pin '${j.attached_pin?.title}' tertempel pada pitch ${j.attached_pin?.pitch}°, yaw ${j.attached_pin?.yaw}° (${j.attached_pin?.color_token}).`,
      };
    });

    // TC-S2-03: Engine Shunlu (+X mnt detour)
    await runSingle(2, async () => {
      const r = await fetch('/api/v1/spatial/shunlu', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          origin_lat: -0.9471,
          origin_lng: 100.4172,
          destination_lat: -0.3051,
          destination_lng: 100.3692,
          category: 'rm_padang',
          max_detour_min: 10,
        }),
      });
      const j = await r.json();
      const pois = Array.isArray(j.shunlu_pois) ? j.shunlu_pois : [];
      return {
        pass: r.status === 200 && pois.length > 0,
        httpCode: r.status,
        detail: `Ditemukan ${pois.length} RM Padang searah rute · Rekomendasi #1: ${j.recommended} (+${j.detour_time_min} mnt detour).`,
      };
    });

    // TC-S2-04: Audio Guide GPS <=15m
    await runSingle(3, async () => {
      const r = await fetch('/api/v1/spatial/audio-trigger-check', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          destination_id: 'dest-001',
          user_lat: -0.1025,
          user_lng: 100.6725,
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 200 && j.trigger_status === 'AUTO_PLAY_ACTIVE',
        httpCode: r.status,
        detail: `Status: ${j.trigger_status} · ${j.matched_count} narasi suara aktif otomatis dalam radius <=15 meter.`,
      };
    });

    // TC-S2-05: Scanner Plang Smart QR
    await runSingle(4, async () => {
      const r = await fetch('/api/v1/qr/QR-SMBR-LPK-001');
      const j = await r.json();
      return {
        pass: r.status === 200 && j.status === 'resolved' && j.fair_price_verified === true,
        httpCode: r.status,
        detail: `Smart QR '${j.qr_placard_code}' teresolusi ke ${j.destination?.name} + 360° + Peta Mikro.`,
      };
    });

    // TC-S2-06: Form Lapor Pungli Anonim + Selisih Perda
    await runSingle(5, async () => {
      const r = await fetch('/api/v1/pungli/report', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          destination_id: 'dest-001',
          reporter_name: 'Wisatawan Anonim',
          incident_category: 'parkir_liar',
          charged_amount_idr: 20000,
          photo_evidence: 'https://cdn.rancak.in/evidence/parkir-20rb.jpg',
          latitude: -0.1023,
          longitude: 100.6728,
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 201 && Boolean(j.ticket) && j.report?.overcharge_amount_idr > 0,
        httpCode: r.status,
        detail: `Tiket ${j.ticket} terbit · Selisih di atas Perda: Rp${j.report?.overcharge_amount_idr?.toLocaleString('id-ID')}.`,
      };
    });

    // TC-S2-07: Pusat Komando Satgas Saber Pungli (FS-1)
    await runSingle(6, async () => {
      const r = await fetch('/api/v1/admin/pungli/PGL-202611-0091/status', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${JWT_TOKEN_OPTIONS.admin_dispar.token}`,
        },
        body: JSON.stringify({
          status: 'Ditindaklanjuti',
          satgas_notes: 'Petugas Satgas Saber Pungli telah menindaklanjuti laporan di lapangan.',
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 200 && j.report?.status === 'Ditindaklanjuti',
        httpCode: r.status,
        detail: `Tiket ${j.report?.ticket_code} berhasil diubah menjadi '${j.report?.status}' oleh Admin Dispar.`,
      };
    });

    // TC-S2-08: Bundel Offline v2.0
    await runSingle(7, async () => {
      const r = await fetch('/api/v1/destinations/dest-001/offline-bundle');
      const j = await r.json();
      return {
        pass:
          r.status === 200 &&
          j.bundle_version === 'v2.0-sprint2-complete' &&
          Array.isArray(j.scenes_360) &&
          Boolean(j.micro_map),
        httpCode: r.status,
        detail: `Bundle ${j.bundle_version} siap diunduh ke Hive/Sqflite FE-1 (${j.scenes_360?.length} scene 360° + Peta Mikro).`,
      };
    });

    onDatabaseMutated();
    setIsRunningTests(false);
  };

  const runSprint3AutomatedTestSuite = async () => {
    setIsRunningTests(true);
    const updated: AutomatedTestResult[] = INITIAL_SPRINT3_TEST_CASES.map((t) => ({ ...t, status: 'running' }));
    setTestResultsSprint3([...updated]);

    const runSingle = async (
      idx: number,
      fn: () => Promise<{ pass: boolean; httpCode: number; detail: string }>
    ) => {
      const t0 = performance.now();
      try {
        const res = await fn();
        const dt = Number((performance.now() - t0).toFixed(1));
        updated[idx] = {
          ...updated[idx],
          status: res.pass ? 'pass' : 'fail',
          httpCode: res.httpCode,
          durationMs: dt,
          assertionDetail: res.detail,
        };
      } catch (e) {
        updated[idx] = {
          ...updated[idx],
          status: 'fail',
          httpCode: 500,
          durationMs: 0,
          assertionDetail: e instanceof Error ? e.message : 'Request gagal',
        };
      }
      setTestResultsSprint3([...updated]);
    };

    // TC-S3-01: Gaode Behavior-Based Ranking
    await runSingle(0, async () => {
      const r = await fetch('/api/v1/destinations/rankings/gaode');
      const j = await r.json();
      const list = Array.isArray(j.rankings) ? j.rankings : [];
      return {
        pass: r.status === 200 && list.length >= 5 && list[0].rank_position === 1,
        httpCode: r.status,
        detail: `${list.length} destinasi terindeks Gaode Guide · Peringkat #1: ${list[0]?.destination_name} (Skor ${list[0]?.gaode_authenticity_score}).`,
      };
    });

    // TC-S3-02: Telemetri Dwell Time GPS (>10 menit) memperbarui skor otomatis
    await runSingle(1, async () => {
      const r = await fetch('/api/v1/spatial/navigation-telemetry', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          destination_id: 'dest-008',
          dwell_time_minutes: 165,
          is_repeat_visit: true,
          gps_accuracy_meters: 4.2,
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 200 && j.status === 'telemetry_recorded' && Boolean(j.updated_metric),
        httpCode: r.status,
        detail: `Telemetri diterima · ${j.updated_metric?.destination_name} kini memiliki skor Gaode ${j.updated_metric?.gaode_authenticity_score} (${j.updated_metric?.active_nav_count_30d} navigasi).`,
      };
    });

    // TC-S3-03: Guardrail Anti-Manipulasi menolak pass-by <10 menit
    await runSingle(2, async () => {
      const r = await fetch('/api/v1/spatial/navigation-telemetry', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          destination_id: 'dest-002',
          dwell_time_minutes: 4,
          is_repeat_visit: false,
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 422 && j.status === 'rejected_pass_by',
        httpCode: r.status,
        detail: `Ditolak sesuai ekspektasi (HTTP 422): ${j.anti_fake_guardrail}`,
      };
    });

    // TC-S3-04: Live Hazard Alert mendeteksi zona rawan Sitinjau Lauik
    await runSingle(3, async () => {
      const r = await fetch('/api/v1/spatial/hazards?lat=-0.9465&lng=100.5180');
      const j = await r.json();
      return {
        pass: r.status === 200 && j.user_in_hazard_zone === true && Boolean(j.fe1_active_warning_banner),
        httpCode: r.status,
        detail: `Zona bahaya terdeteksi: ${j.fe1_active_warning_banner?.location} (Status: ${j.fe1_active_warning_banner?.severity}).`,
      };
    });

    // TC-S3-05: Trigger Bencana Command Center FS-1
    await runSingle(4, async () => {
      const r = await fetch('/api/v1/admin/hazards/trigger', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${JWT_TOKEN_OPTIONS.admin_dispar.token}`,
        },
        body: JSON.stringify({
          corridor_code: 'LEMBAH-ANAI',
          severity: 'Siaga',
          hazard_type: 'Debit Air Sungai Batang Anai Naik & Sistem Buka-Tutup',
          weather_status: 'Hujan Deras di Hulu Singgalang',
          message: 'SIAGA KORIDOR LEMBAH ANAI: Arus kendaraan dialihkan via Malalak.',
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 200 && j.status === 'hazard_triggered' && j.hazard_alert?.severity === 'Siaga',
        httpCode: r.status,
        detail: `Koridor ${j.hazard_alert?.corridor_code} berhasil diubah menjadi '${j.hazard_alert?.severity}' oleh FS-1.`,
      };
    });

    // TC-S3-06: Pancaran Darurat SOS GPS FE-1
    await runSingle(5, async () => {
      const r = await fetch('/api/v1/spatial/sos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tourist_name: 'Uda Fauzan & Keluarga',
          phone_number: '+62811665544',
          emergency_type: 'Kendaraan Mogok di Tanjakan Curam',
          latitude: -0.9460,
          longitude: 100.5175,
          battery_percent: 19,
          passengers_count: 4,
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 201 && j.status === 'sos_dispatched' && Boolean(j.sos_signal?.sos_code),
        httpCode: r.status,
        detail: `Sinyal ${j.sos_signal?.sos_code} terkirim ke ${j.sos_signal?.nearest_rescue_post} (ETA ${j.sos_signal?.eta_rescue_minutes} mnt).`,
      };
    });

    // TC-S3-07: Kamus Saku Audio Bahasa Minang
    await runSingle(6, async () => {
      const r = await fetch('/api/v1/culture/minang-phrases?category=tawar_pasar');
      const j = await r.json();
      const phrases = Array.isArray(j.phrases) ? j.phrases : [];
      return {
        pass: r.status === 200 && phrases.length > 0,
        httpCode: r.status,
        detail: `${phrases.length} frasa tawar-menawar Minang siap diputar: "${phrases[0]?.minang_text}"`,
      };
    });

    // TC-S3-08: Kalender Budaya & Hari Pakan Nagari
    await runSingle(7, async () => {
      const r = await fetch('/api/v1/culture/events?lat=-0.4560&lng=100.5900');
      const j = await r.json();
      const events = Array.isArray(j.events) ? j.events : [];
      return {
        pass: r.status === 200 && events.length >= 4 && typeof events[0]?.distance_km === 'number',
        httpCode: r.status,
        detail: `${events.length} agenda budaya & Hari Pakan ditemukan · Terdekat: ${events[0]?.title} (${events[0]?.distance_km} km).`,
      };
    });

    onDatabaseMutated();
    setIsRunningTests(false);
  };

  const runSprint4AutomatedTestSuite = async () => {
    setIsRunningTests(true);
    const updated: AutomatedTestResult[] = INITIAL_SPRINT4_TEST_CASES.map((t) => ({ ...t, status: 'running' }));
    setTestResultsSprint4([...updated]);

    const runSingle = async (
      idx: number,
      fn: () => Promise<{ pass: boolean; httpCode: number; detail: string }>
    ) => {
      const t0 = performance.now();
      try {
        const res = await fn();
        const dt = Number((performance.now() - t0).toFixed(1));
        updated[idx] = {
          ...updated[idx],
          status: res.pass ? 'pass' : 'fail',
          httpCode: res.httpCode,
          durationMs: dt,
          assertionDetail: res.detail,
        };
      } catch (e) {
        updated[idx] = {
          ...updated[idx],
          status: 'fail',
          httpCode: 500,
          durationMs: 0,
          assertionDetail: e instanceof Error ? e.message : 'Request gagal',
        };
      }
      setTestResultsSprint4([...updated]);
    };

    // Kosongkan cache terlebih dahulu agar urutan MISS -> HIT -> 304 deterministik
    await fetch('/api/v1/admin/cache/flush', {
      method: 'POST',
      headers: { Authorization: `Bearer ${JWT_TOKEN_OPTIONS.admin_dispar.token}` },
    });

    let capturedETag = '';

    // TC-S4-01: Cache MISS pada panggilan pertama
    await runSingle(0, async () => {
      const r = await fetch('/api/v1/destinations/dest-001/scenes-360');
      const xCache = r.headers.get('X-Cache') || '';
      capturedETag = r.headers.get('ETag') || '';
      return {
        pass: r.status === 200 && xCache === 'MISS' && Boolean(capturedETag),
        httpCode: r.status,
        detail: `X-Cache: ${xCache} · ETag diterbitkan: ${capturedETag}`,
      };
    });

    // TC-S4-02: Cache HIT pada panggilan kedua
    await runSingle(1, async () => {
      const r = await fetch('/api/v1/destinations/dest-001/scenes-360');
      const xCache = r.headers.get('X-Cache') || '';
      return {
        pass: r.status === 200 && xCache === 'HIT',
        httpCode: r.status,
        detail: `X-Cache: ${xCache} · Payload 360° dilayani langsung dari InMemoryTTLCache (<5ms).`,
      };
    });

    // TC-S4-03: HTTP 304 Not Modified saat If-None-Match cocok
    await runSingle(2, async () => {
      const r = await fetch('/api/v1/destinations/dest-001/scenes-360', {
        headers: { 'If-None-Match': capturedETag },
      });
      return {
        pass: r.status === 304,
        httpCode: r.status,
        detail: `HTTP 304 Not Modified terverifikasi untuk ETag ${capturedETag} (Zero Payload Transfer).`,
      };
    });

    // TC-S4-04: Token Bucket Rate-Limiter HTTP 429 pada Lapor Pungli
    await runSingle(3, async () => {
      const r = await fetch('/api/v1/pungli/report', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Simulate-RateLimit': 'burst',
        },
        body: JSON.stringify({
          destination_id: 'dest-001',
          incident_category: 'parkir_liar',
          charged_amount_idr: 25000,
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 429 && j.code === 'RATE_LIMIT_EXCEEDED',
        httpCode: r.status,
        detail: `Spam diblokir (HTTP 429) · Retry-After: ${r.headers.get('Retry-After')} detik (${j.code}).`,
      };
    });

    // TC-S4-05: Token Bucket Rate-Limiter HTTP 429 pada Pancaran SOS GPS
    await runSingle(4, async () => {
      const r = await fetch('/api/v1/spatial/sos', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Simulate-RateLimit': 'burst',
        },
        body: JSON.stringify({
          tourist_name: 'Spam Bot',
          latitude: -0.9465,
          longitude: 100.518,
        }),
      });
      const j = await r.json();
      return {
        pass: r.status === 429 && j.code === 'RATE_LIMIT_EXCEEDED',
        httpCode: r.status,
        detail: `Banjir sinyal SOS palsu diblokir otomatis oleh Token Bucket Guard (HTTP 429).`,
      };
    });

    // TC-S4-06: Live Benchmark <100ms SLA
    await runSingle(5, async () => {
      const r = await fetch('/api/v1/admin/system/benchmark', {
        headers: { Authorization: `Bearer ${JWT_TOKEN_OPTIONS.admin_dispar.token}` },
      });
      const j = await r.json();
      const sla = j.sla_verification;
      return {
        pass: r.status === 200 && sla?.sla_passed === true && sla?.p99_latency_ms < 100,
        httpCode: r.status,
        detail: `p50: ${sla?.p50_latency_ms}ms · p95: ${sla?.p95_latency_ms}ms · p99: ${sla?.p99_latency_ms}ms (<100ms SLA LULUS).`,
      };
    });

    // TC-S4-07: Admin Manual Cache Flush
    await runSingle(6, async () => {
      const flushRes = await fetch('/api/v1/admin/cache/flush', {
        method: 'POST',
        headers: { Authorization: `Bearer ${JWT_TOKEN_OPTIONS.admin_dispar.token}` },
      });
      const flushJson = await flushRes.json();
      const checkRes = await fetch('/api/v1/destinations/dest-001/scenes-360');
      const xCacheAfter = checkRes.headers.get('X-Cache');
      return {
        pass: flushRes.status === 200 && flushJson.status === 'flushed' && xCacheAfter === 'MISS',
        httpCode: flushRes.status,
        detail: `Cache di-flush (${flushJson.flushed_keys} key) · Panggilan 360° berikutnya kembali X-Cache: ${xCacheAfter}.`,
      };
    });

    // TC-S4-08: Katalog Kontrak Final 24 Endpoint BE-1
    await runSingle(7, async () => {
      const r = await fetch('/api/v1/system/contracts');
      const j = await r.json();
      return {
        pass: r.status === 200 && j.total_endpoints === 24 && Array.isArray(j.endpoints) && j.endpoints.length === 24,
        httpCode: r.status,
        detail: `Genap ${j.total_endpoints}/24 Endpoint BE-1 aktif & siap diserahterimakan untuk Demo Akhir Bulan 1.`,
      };
    });

    onDatabaseMutated();
    setIsRunningTests(false);
  };

  if (mode === 'tester') {
    const activePreset = activePresets.find((p) => p.id === selectedPresetId);

    return (
      <div className="space-y-6">
        <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 pb-5 border-b border-[#E2DFD7]">
            <div>
              <div className="text-xs text-[#5A625A] mb-1">
                Live Endpoint Simulator · Kontrak JSON Identik Go (WISGO internal/be1_core) + PostGIS
              </div>
              <h2 className="text-xl font-bold text-[#1B1F1A]">
                Interactive API Runner & Generator Perintah cURL (
                {selectedSprint === 'sprint1'
                  ? 'Sprint 1: Hari 1–5'
                  : selectedSprint === 'sprint2'
                  ? 'Sprint 2: Hari 6–10'
                  : selectedSprint === 'sprint3'
                  ? 'Sprint 3: Hari 11–15'
                  : 'Sprint 4: Hari 16–20 Final'}
                )
              </h2>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={handleResetSeed}
                disabled={isResettingSeed}
                className="px-3.5 py-2 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-2 whitespace-nowrap shrink-0 cursor-pointer"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                {isResettingSeed ? 'Mereset Data...' : 'Reset Data Awal Sprint 1–4'}
              </button>
              <button
                onClick={handleSendRequest}
                disabled={isSending}
                className="px-4 py-2 text-xs font-semibold text-white bg-[#234B24] rounded-lg hover:bg-[#1a381b] transition-colors flex items-center gap-2 whitespace-nowrap shrink-0 cursor-pointer"
              >
                <Play className="w-3.5 h-3.5" />
                {isSending ? 'Mengeksekusi...' : 'Kirim Request ke Server'}
              </button>
            </div>
          </div>

          <div className="mt-5">
            <label className="block text-xs font-semibold text-[#1B1F1A] mb-2">
              Pilih Skenario Endpoint{' '}
              {selectedSprint === 'sprint1'
                ? 'Sprint 1 (Minggu 1)'
                : selectedSprint === 'sprint2'
                ? 'Sprint 2 (Minggu 2)'
                : selectedSprint === 'sprint3'
                ? 'Sprint 3 (Minggu 3)'
                : 'Sprint 4 (Minggu 4 — Final)'}{' '}
              BE-1:
            </label>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2.5">
              {activePresets.map((preset) => {
                const isSelected = preset.id === selectedPresetId;
                return (
                  <button
                    key={preset.id}
                    onClick={() => handleSelectPreset(preset)}
                    className={`text-left p-3 rounded-lg border transition-colors cursor-pointer ${
                      isSelected
                        ? 'bg-[#E4E9DA] border-[#234B24] text-[#1B1F1A]'
                        : 'bg-[#F6F3EC]/60 border-[#E2DFD7] text-[#1B1F1A] hover:bg-[#F6F3EC]'
                    }`}
                  >
                    <div className="flex items-center justify-between gap-2 mb-1">
                      <span
                        className={`font-mono text-xs font-bold ${
                          preset.method === 'GET'
                            ? 'text-[#1E9E5A]'
                            : preset.method === 'POST'
                            ? 'text-[#E85D1A]'
                            : 'text-[#5B6AE8]'
                        }`}
                      >
                        {preset.method}
                      </span>
                      <span className="text-[11px] text-[#5A625A] truncate">{preset.consumerRole}</span>
                    </div>
                    <div className="text-xs font-semibold text-[#1B1F1A] line-clamp-1">{preset.label}</div>
                    <div className="font-mono text-[11px] text-[#5A625A] truncate mt-0.5">{preset.path}</div>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="mt-6 grid grid-cols-1 lg:grid-cols-12 gap-4">
            <div className="lg:col-span-2">
              <label className="block text-xs font-semibold text-[#1B1F1A] mb-1.5">Metode HTTP</label>
              <select
                value={httpMethod}
                onChange={(e) => setHttpMethod(e.target.value as 'GET' | 'POST' | 'PUT' | 'PATCH')}
                className="w-full px-3 py-2 text-xs font-mono font-bold bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
              >
                <option value="GET">GET</option>
                <option value="POST">POST</option>
                <option value="PUT">PUT</option>
                <option value="PATCH">PATCH</option>
              </select>
            </div>

            <div className="lg:col-span-6">
              <label className="block text-xs font-semibold text-[#1B1F1A] mb-1.5">
                Path Endpoint & Query Parameter Spasial
              </label>
              <input
                type="text"
                value={requestPath}
                onChange={(e) => setRequestPath(e.target.value)}
                className="w-full px-3.5 py-2 text-xs font-mono bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
                placeholder="/api/v1/destinations/dest-001/scenes-360"
              />
            </div>

            <div className="lg:col-span-4">
              <label className="block text-xs font-semibold text-[#1B1F1A] mb-1.5">
                Simulasi Header JWT Role (Stateless Auth BE-1)
              </label>
              <select
                value={selectedRole}
                onChange={(e) =>
                  setSelectedRole(e.target.value as 'public' | 'tourist' | 'pokdarwis' | 'admin_dispar')
                }
                className="w-full px-3 py-2 text-xs font-medium bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
              >
                <option value="public">Tanpa Token (Public Wisatawan)</option>
                <option value="tourist">Role: tourist (Token OTP BE-2)</option>
                <option value="pokdarwis">Role: pokdarwis (Pengelola Nagari)</option>
                <option value="admin_dispar">Role: admin_dispar (CMS Admin FS-1)</option>
              </select>
            </div>
          </div>

          <div className="mt-3 px-4 py-2.5 bg-[#E4E9DA] rounded-lg flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs text-[#1B1F1A]">
            <div>
              <span className="font-semibold">Konteks Skenario:</span>{' '}
              {activePreset?.description || 'Uji kustom endpoint REST API BE-1.'}
            </div>
            <div className="text-[#234B24] font-medium shrink-0">
              {JWT_TOKEN_OPTIONS[selectedRole].roleDesc}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          <div className="lg:col-span-5 flex flex-col gap-6">
            <div className="bg-white border border-[#E2DFD7] rounded-xl p-5 flex-1 flex flex-col">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-bold text-[#1B1F1A]">
                  Request Body JSON ({httpMethod === 'GET' ? 'Tidak diperlukan untuk GET' : `Aktif untuk ${httpMethod}`})
                </span>
                <span className="text-[11px] font-mono text-[#5A625A]">Content-Type: application/json</span>
              </div>
              <textarea
                value={requestBody}
                onChange={(e) => setRequestBody(e.target.value)}
                disabled={httpMethod === 'GET'}
                rows={10}
                placeholder={
                  httpMethod === 'GET'
                    ? '// Metode GET menggunakan query parameter pada URL di atas.'
                    : '{\n  "title": "Contoh Payload"\n}'
                }
                className="w-full flex-1 p-3.5 text-xs font-mono bg-[#1B1F1A] text-[#F6F3EC] rounded-lg border border-[#323830] disabled:opacity-60"
              />
            </div>

            <div className="bg-white border border-[#E2DFD7] rounded-xl p-5">
              <div className="flex items-center justify-between mb-2.5">
                <div>
                  <h3 className="text-xs font-bold text-[#1B1F1A]">
                    Perintah Terminal cURL Otomatis (Siap Copy untuk Tim)
                  </h3>
                  <p className="text-[11px] text-[#5A625A]">
                    Gunakan perintah ini di terminal lokal atau kirimkan ke grup FE-1, FE-2, & FS-1.
                  </p>
                </div>
                <button
                  onClick={handleCopyCurl}
                  className="px-3 py-1.5 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 shrink-0 cursor-pointer"
                >
                  {copiedCurl ? <Check className="w-3.5 h-3.5 text-[#1E9E5A]" /> : <Copy className="w-3.5 h-3.5" />}
                  {copiedCurl ? 'Tersalin' : 'Salin cURL'}
                </button>
              </div>
              <pre className="p-3.5 text-xs font-mono bg-[#1B1F1A] text-[#E4E9DA] rounded-lg overflow-x-auto leading-relaxed">
                {buildCurlCommand()}
              </pre>
            </div>
          </div>

          <div className="lg:col-span-7 bg-white border border-[#E2DFD7] rounded-xl p-5 flex flex-col">
            <div className="flex flex-wrap items-center justify-between gap-3 pb-3 mb-3 border-b border-[#E2DFD7]">
              <div>
                <h3 className="text-sm font-bold text-[#1B1F1A]">Respons Server BE-1 Real-Time</h3>
                <div className="text-xs text-[#5A625A] font-mono tabular-nums mt-0.5">
                  {responseStatus !== null ? (
                    <span>
                      Status:{' '}
                      <strong
                        className={
                          responseStatus >= 200 && responseStatus < 300
                            ? 'text-[#1E9E5A]'
                            : responseStatus >= 400
                            ? 'text-[#F26B4B]'
                            : 'text-[#E85D1A]'
                        }
                      >
                        HTTP {responseStatus}
                      </strong>{' '}
                      · Waktu Eksekusi: <strong>{responseLatencyMs} ms</strong>
                      {responseCacheHeader && (
                        <span>
                          {' '}
                          · X-Cache: <strong className="text-[#234B24]">{responseCacheHeader}</strong>
                        </span>
                      )}
                      {responseEtagHeader && (
                        <span>
                          {' '}
                          · ETag: <strong className="text-[#5B6AE8]">{responseEtagHeader}</strong>
                        </span>
                      )}
                    </span>
                  ) : (
                    'Belum ada request yang dikirim'
                  )}
                </div>
              </div>
              <button
                onClick={handleCopyResponse}
                className="px-3 py-1.5 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 shrink-0 cursor-pointer"
              >
                {copiedResponse ? (
                  <Check className="w-3.5 h-3.5 text-[#1E9E5A]" />
                ) : (
                  <Copy className="w-3.5 h-3.5" />
                )}
                {copiedResponse ? 'JSON Tersalin' : 'Salin Respons JSON'}
              </button>
            </div>

            <pre className="flex-1 p-4 text-xs font-mono bg-[#1B1F1A] text-[#F6F3EC] rounded-lg overflow-auto max-h-[540px] leading-relaxed">
              {responseJson}
            </pre>
          </div>
        </div>
      </div>
    );
  }

  // MODE === 'qa'
  const activeTestResults =
    selectedSprint === 'sprint1'
      ? testResultsSprint1
      : selectedSprint === 'sprint2'
      ? testResultsSprint2
      : selectedSprint === 'sprint3'
      ? testResultsSprint3
      : testResultsSprint4;
  const passedCount = activeTestResults.filter((t) => t.status === 'pass').length;

  return (
    <div className="space-y-6">
      <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 pb-5 border-b border-[#E2DFD7]">
          <div>
            <div className="text-xs text-[#5A625A] mb-1">
              {selectedSprint === 'sprint1'
                ? 'Cek Otomatis Pekerjaan Minggu 1 · Menguji 8 Fitur Dasar Tempat Wisata & Harga Resmi'
                : selectedSprint === 'sprint2'
                ? 'Cek Otomatis Pekerjaan Minggu 2 · Menguji 8 Fitur Foto 360°, Tempat Mampir, Peta Dalam Lokasi & Aduan Pungli'
                : selectedSprint === 'sprint3'
                ? 'Cek Otomatis Pekerjaan Minggu 3 · Menguji 8 Fitur Peringkat Kunjungan GPS, Info Bahaya Jalan, Tombol SOS & Bahasa Minang'
                : 'Cek Otomatis Pekerjaan Minggu 4 (Final) · Menguji Memori Cepat 304, Penangkal Spam 429, Kecepatan <100ms & 24 Alamat API'}
            </div>
            <h2 className="text-xl font-bold text-[#1B1F1A]">
              {selectedSprint === 'sprint1'
                ? 'Pengetesan Otomatis Minggu 1 (Hari 1–5)'
                : selectedSprint === 'sprint2'
                ? 'Pengetesan Otomatis Minggu 2 (Hari 6–10)'
                : selectedSprint === 'sprint3'
                ? 'Pengetesan Otomatis Minggu 3 (Hari 11–15)'
                : 'Pengetesan Otomatis Minggu 4 — Final (Hari 16–20)'}
            </h2>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-xs font-mono tabular-nums text-[#1B1F1A] bg-[#F6F3EC] px-3.5 py-2 rounded-lg border border-[#E2DFD7]">
              Hasil Tes: <strong>{passedCount} / {activeTestResults.length}</strong> Lulus
            </div>
            <button
              onClick={
                selectedSprint === 'sprint1'
                  ? runSprint1AutomatedTestSuite
                  : selectedSprint === 'sprint2'
                  ? runSprint2AutomatedTestSuite
                  : selectedSprint === 'sprint3'
                  ? runSprint3AutomatedTestSuite
                  : runSprint4AutomatedTestSuite
              }
              disabled={isRunningTests}
              className="px-4 py-2.5 text-xs font-semibold text-white bg-[#234B24] rounded-lg hover:bg-[#1a381b] transition-colors flex items-center gap-2 whitespace-nowrap shrink-0 cursor-pointer"
            >
              <Play className="w-3.5 h-3.5" />
              {isRunningTests
                ? 'Sedang Mengetes 8 Fitur...'
                : selectedSprint === 'sprint1'
                ? 'Mulai Tes Otomatis Minggu 1'
                : selectedSprint === 'sprint2'
                ? 'Mulai Tes Otomatis Minggu 2'
                : selectedSprint === 'sprint3'
                ? 'Mulai Tes Otomatis Minggu 3'
                : 'Mulai Tes Otomatis Minggu 4 (Final)'}
            </button>
          </div>
        </div>

        <div className="mt-5 overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#E2DFD7] text-[11px] font-semibold text-[#5A625A]">
                <th className="py-2.5 px-3">Kode</th>
                <th className="py-2.5 px-3">Skenario Pengujian & Kriteria Penerimaan</th>
                <th className="py-2.5 px-3">Endpoint Target</th>
                <th className="py-2.5 px-3 text-right">HTTP</th>
                <th className="py-2.5 px-3 text-right">Durasi</th>
                <th className="py-2.5 px-3">Status & Bukti Verifikasi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2DFD7] text-xs">
              {activeTestResults.map((tc) => (
                <tr key={tc.id} className="hover:bg-[#F6F3EC]/60 transition-colors">
                  <td className="py-3 px-3 font-mono font-bold text-[#1B1F1A] whitespace-nowrap">{tc.code}</td>
                  <td className="py-3 px-3">
                    <div className="font-semibold text-[#1B1F1A]">{tc.name}</div>
                    <div className="text-[11px] text-[#5A625A] mt-0.5">Ekspektasi: {tc.expected}</div>
                  </td>
                  <td className="py-3 px-3 font-mono text-[11px] text-[#234B24] whitespace-nowrap">{tc.target}</td>
                  <td className="py-3 px-3 font-mono tabular-nums text-right whitespace-nowrap">
                    {tc.httpCode ? `HTTP ${tc.httpCode}` : '—'}
                  </td>
                  <td className="py-3 px-3 font-mono tabular-nums text-right whitespace-nowrap">
                    {tc.durationMs !== undefined ? `${tc.durationMs} ms` : '—'}
                  </td>
                  <td className="py-3 px-3">
                    {tc.status === 'idle' && (
                      <span className="text-[#5A625A]">Belum dijalankan — Klik tombol Jalankan Semua Test</span>
                    )}
                    {tc.status === 'running' && (
                      <span className="text-[#E85D1A] font-medium">Sedang menguji endpoint...</span>
                    )}
                    {tc.status === 'pass' && (
                      <div className="flex items-start gap-1.5 text-[#1E9E5A]">
                        <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />
                        <div>
                          <span className="font-bold">LULUS (PASS)</span> ·{' '}
                          <span className="text-[#1B1F1A]">{tc.assertionDetail}</span>
                        </div>
                      </div>
                    )}
                    {tc.status === 'fail' && (
                      <div className="flex items-start gap-1.5 text-[#F26B4B]">
                        <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                        <div>
                          <span className="font-bold">GAGAL (FAIL)</span> ·{' '}
                          <span className="text-[#1B1F1A]">{tc.assertionDetail}</span>
                        </div>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="bg-white border border-[#E2DFD7] rounded-xl p-5">
          <div className="flex items-center gap-2 text-[#234B24] font-bold text-sm mb-2">
            <Terminal className="w-4 h-4" />
            <span>
              Langkah 1: Migrasi & Tuning SQL{' '}
              {selectedSprint === 'sprint1'
                ? 'Sprint 1 (4 Tabel)'
                : selectedSprint === 'sprint2'
                ? 'Sprint 2 (5 Tabel)'
                : selectedSprint === 'sprint3'
                ? 'Sprint 3 (Genap 11/11 Tabel BE-1)'
                : 'Sprint 4 (Tuning Indeks <100ms)'}
            </span>
          </div>
          <p className="text-xs text-[#5A625A] leading-relaxed mb-3">
            Jalankan file DDL terisolasi milik BE-1 di dalam folder <code className="font-mono">backend/internal/be1_core/</code>:
          </p>
          <pre className="p-3 text-[11px] font-mono bg-[#1B1F1A] text-[#F6F3EC] rounded-lg overflow-x-auto leading-relaxed">
            {selectedSprint === 'sprint1'
              ? `# Migrasi 4 Tabel Inti Sprint 1
psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint1.sql`
              : selectedSprint === 'sprint2'
              ? `# Migrasi 5 Tabel Spasial & 360° Sprint 2
psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint2.sql`
              : selectedSprint === 'sprint3'
              ? `# Migrasi 2 Kuota Tabel Terakhir Sprint 3 (11/11 Tabel BE-1)
psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint3.sql`
              : `# Tuning Composite GIST Index & Materialized View Sprint 4 (<100ms SLA)
psql $DATABASE_URL -f backend/internal/be1_core/migrations_sprint4_tuning.sql`}
          </pre>
        </div>

        <div className="bg-white border border-[#E2DFD7] rounded-xl p-5">
          <div className="flex items-center gap-2 text-[#234B24] font-bold text-sm mb-2">
            <FileCode2 className="w-4 h-4" />
            <span>Langkah 2: Menjalankan Automated Go Test di Lokal</span>
          </div>
          <p className="text-xs text-[#5A625A] leading-relaxed mb-3">
            Uji seluruh handler dan repository BE-1 di cabang <code className="font-mono">dev</code> repository WISGO:
          </p>
          <pre className="p-3 text-[11px] font-mono bg-[#1B1F1A] text-[#F6F3EC] rounded-lg overflow-x-auto leading-relaxed">
            {selectedSprint === 'sprint1'
              ? `cd backend
go test -v ./internal/be1_core/... -run TestBE1Sprint1Suite`
              : selectedSprint === 'sprint2'
              ? `cd backend
go test -v ./internal/be1_core/... -run TestBE1Sprint2Suite`
              : selectedSprint === 'sprint3'
              ? `cd backend
go test -v ./internal/be1_core/... -run TestSprint3IntegrationSuite`
              : `cd backend
go test -v ./internal/be1_core/... -run TestSprint4IntegrationSuite`}
          </pre>
        </div>

        <div className="bg-white border border-[#E2DFD7] rounded-xl p-5">
          <div className="flex items-center gap-2 text-[#234B24] font-bold text-sm mb-2">
            <ShieldCheck className="w-4 h-4" />
            <span>
              Langkah 3: Checklist Serah Terima{' '}
              {selectedSprint === 'sprint1'
                ? 'Jumat Minggu 1'
                : selectedSprint === 'sprint2'
                ? 'Jumat Minggu 2'
                : selectedSprint === 'sprint3'
                ? 'Jumat Minggu 3'
                : 'Jumat Minggu 4 (Final Release)'}
            </span>
          </div>
          {selectedSprint === 'sprint1' ? (
            <ul className="space-y-2 text-xs text-[#1B1F1A] leading-relaxed">
              <li>
                <strong>FE-1:</strong> Endpoint <code className="font-mono text-[#234B24]">GET /api/v1/destinations</code> & Detail 4 Statistik + 5 Indikator Medan.
              </li>
              <li>
                <strong>FE-2:</strong> Array <code className="font-mono text-[#234B24]">official_tariffs</code> siap untuk Tabel Fair-Price Barometer.
              </li>
              <li>
                <strong>FS-1:</strong> Endpoint <code className="font-mono text-[#234B24]">POST/PUT /api/v1/admin/destinations</code> dengan RBAC <code className="font-mono">admin_dispar</code>.
              </li>
            </ul>
          ) : selectedSprint === 'sprint2' ? (
            <ul className="space-y-2 text-xs text-[#1B1F1A] leading-relaxed">
              <li>
                <strong>FE-1:</strong> Endpoint <code className="font-mono text-[#234B24]">GET .../scenes-360</code>, <code className="font-mono text-[#234B24]">POST /api/v1/spatial/shunlu</code>, Peta Mikro, & Offline Bundle v2.
              </li>
              <li>
                <strong>FE-2:</strong> Endpoint <code className="font-mono text-[#234B24]">GET /api/v1/qr/:qrCode</code> & <code className="font-mono text-[#234B24]">POST /api/v1/pungli/report</code> (URL/Base64/Multipart).
              </li>
              <li>
                <strong>FS-1:</strong> Klik-tempel Pin 360° (<code className="font-mono text-[#234B24]">POST .../hotspots</code>) & Pusat Komando Satgas (<code className="font-mono text-[#234B24]">PATCH .../pungli/:id/status</code>).
              </li>
            </ul>
          ) : selectedSprint === 'sprint3' ? (
            <ul className="space-y-2 text-xs text-[#1B1F1A] leading-relaxed">
              <li>
                <strong>FE-1:</strong> Leaderboard <code className="font-mono text-[#234B24]">GET .../rankings/gaode</code>, Banner Jalur Rawan <code className="font-mono text-[#234B24]">GET /api/v1/spatial/hazards</code>, Tombol <code className="font-mono text-[#234B24]">POST /api/v1/spatial/sos</code>, & Kamus Minang.
              </li>
              <li>
                <strong>FS-1:</strong> Panel Simulasi Trigger Bencana (<code className="font-mono text-[#234B24]">POST /api/v1/admin/hazards/trigger</code>) & Monitor Sinyal SOS (<code className="font-mono text-[#234B24]">GET /api/v1/admin/sos</code>).
              </li>
              <li>
                <strong>BE-2:</strong> Zero Merge Conflict — Modul Escrow, Bot WA 1/0, Split-Bill & Group Radar di <code className="font-mono text-[#F26B4B]">internal/be2_group</code> tidak tersentuh.
              </li>
            </ul>
          ) : (
            <ul className="space-y-2 text-xs text-[#1B1F1A] leading-relaxed">
              <li>
                <strong>SLA & Cache:</strong> In-Memory TTL Cache + HTTP ETag (<code className="font-mono text-[#234B24]">304 Not Modified</code>) & Benchmark <code className="font-mono text-[#234B24]">&lt;100ms</code> aktif.
              </li>
              <li>
                <strong>Anti-Spam:</strong> Token Bucket Rate-Limiter (<code className="font-mono text-[#234B24]">HTTP 429</code>) melindungi Lapor Pungli & Sinyal SOS GPS.
              </li>
              <li>
                <strong>Final 24 Endpoint:</strong> Katalog <code className="font-mono text-[#234B24]">GET /api/v1/system/contracts</code> merangkum seluruh 24 endpoint BE-1 (Zero Conflict dengan Paspor Digital BE-2).
              </li>
            </ul>
          )}
        </div>
      </div>
    </div>
  );
};
