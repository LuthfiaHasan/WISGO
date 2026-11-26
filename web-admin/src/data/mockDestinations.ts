// ============================================================================
// KONSTANTA KANONIK, HELPER DOMAIN & DATA SEED WISGO V3
// Sinkron 100% Frontend-1 (73a33bb) & Frontend-2 (6911eaf)
// ============================================================================

import {
  CanonicalPartnerCategory,
  CulturalEvent,
  DenahPointCategory,
  Destination,
  DestinationWeatherSnapshot,
  EmergencyAgencyType,
  EmergencyContact,
  GaodeBehaviorRanking,
  GroupRoomPreview,
  HazardAlert,
  HazardSeverity,
  MasterDestinationCategory,
  MinangPhrase,
  Notifikasi,
  OpenTrip,
  Partner,
  PungliReport,
  PungliStatus,
  RegencyHeatmapData,
  SosSignal,
  SystemBenchmarkMetrics,
  Challenge,
  NewTour,
} from '../types/contract';

import {
  SEED_ATURAN_DESTINASI,
  SEED_CHALLENGES,
  SEED_CULTURAL_EVENTS,
  SEED_DENAH_POINTS,
  SEED_DESTINATIONS,
  SEED_EMERGENCY_CONTACTS,
  SEED_GAODE_RANKINGS,
  SEED_HAZARD_ALERTS,
  SEED_INDIKATOR_MEDAN,
  SEED_MINANG_PHRASES,
  SEED_NEW_TOURS,
  SEED_NOTIFIKASI,
  SEED_OFFICIAL_TARIFFS,
  SEED_OPEN_TRIPS,
  SEED_PANORAMA_SCENES,
  SEED_PARTNERS,
  SEED_PUNGLI_REPORTS,
  SEED_REGENCY_HEATMAP,
  SEED_SOS_SIGNALS,
  SEED_WEATHER_MONITORING,
  categoryNameToId,
  determineCategoryForDestination,
} from './mockDatabaseV2';

export { categoryNameToId, determineCategoryForDestination };

// ============================================================================
// 1. KONSTANTA KANONIK SUMATERA BARAT & 5 MASTER KATEGORI
// ============================================================================
export const SUMBAR_REGENCIES = [
  'Semua Kab/Kota',
  'Kab. Lima Puluh Kota',
  'Kota Bukittinggi',
  'Kab. Tanah Datar',
  'Kab. Agam',
  'Kota Padang',
  'Kota Sawahlunto',
  'Kab. Pesisir Selatan',
  'Kab. Solok',
  'Kota Padang Panjang',
  'Kota Payakumbuh',
  'Kota Pariaman',
  'Kab. Padang Pariaman',
  'Kab. Kepulauan Mentawai',
  'Kab. Sijunjung',
  'Kab. Solok Selatan',
  'Kab. Pasaman',
  'Kab. Pasaman Barat',
  'Kab. Dharmasraya',
  'Kota Solok',
] as const;

export const MASTER_DESTINATION_CATEGORIES: readonly MasterDestinationCategory[] = [
  'Alam & Geopark',
  'Budaya & Nagari',
  'Hidden Gem',
  'Religi',
  'Kuliner',
] as const;

export const DESTINATION_CATEGORIES = MASTER_DESTINATION_CATEGORIES;

export const PARTNER_CATEGORIES: readonly CanonicalPartnerCategory[] = [
  'Penginapan',
  'Transportasi',
  'Atraksi',
  'Pakaian Adat',
  'Kuliner',
] as const;

export const DENAH_POINT_CATEGORIES: readonly DenahPointCategory[] = [
  'PARKIR',
  'UMKM',
  'TOILET',
  'MUSHOLLA',
  'LOKET',
] as const;

export const TARIFF_CATEGORIES = [
  'Tiket Masuk',
  'Parkir Kendaraan',
  'Sewa Perahu & Bendi',
  'Jasa Pemandu Pokdarwis',
] as const;

export const HAZARD_SEVERITIES: readonly HazardSeverity[] = [
  'Normal',
  'Waspada',
  'Siaga',
  'Awas Tutup Total',
] as const;

export const PUNGLI_STATUSES: readonly PungliStatus[] = [
  'Masuk',
  'Diverifikasi',
  'Ditindaklanjuti',
  'Selesai',
] as const;

export const EMERGENCY_AGENCY_TYPES: readonly EmergencyAgencyType[] = [
  'BPBD',
  'PMI',
  'Damkar',
  'Basarnas',
  'Kepolisian',
  'Medis',
] as const;

export const TOLL_FREE_EMERGENCY_NUMBERS = [
  { number: '112', label: 'Darurat Terpadu Nasional', desc: 'Bebas pulsa, lintas operator' },
  { number: '115', label: 'Basarnas / SAR', desc: 'Evakuasi tebing, hutan & laut' },
  { number: '110', label: 'Polri / Kepolisian', desc: 'Keamanan & Saber Pungli' },
  { number: '118', label: 'Ambulans / Medis', desc: 'Gawat darurat kesehatan' },
] as const;

// ============================================================================
// 2. HELPER NORMALISASI, ASSET SVG & KALKULASI LEVEL PETUALANG
// ============================================================================
export function toDestinationSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-');
}

export function normalizeDestinationCategory(raw?: string | null): MasterDestinationCategory {
  if (!raw) return 'Alam & Geopark';
  const trimmed = raw.trim();
  if ((MASTER_DESTINATION_CATEGORIES as readonly string[]).includes(trimmed)) {
    return trimmed as MasterDestinationCategory;
  }
  const lower = trimmed.toLowerCase();
  if (lower.includes('religi') || lower.includes('masjid') || lower.includes('surau')) return 'Religi';
  if (lower.includes('kuliner') || lower.includes('agro') || lower.includes('kapau')) return 'Kuliner';
  if (lower.includes('hidden')) return 'Hidden Gem';
  if (lower.includes('budaya') || lower.includes('nagari') || lower.includes('sejarah') || lower.includes('warisan')) {
    return 'Budaya & Nagari';
  }
  return 'Alam & Geopark';
}

export function normalizePartnerCategory(raw?: string | null): CanonicalPartnerCategory {
  if (!raw) return 'Kuliner';
  const trimmed = raw.trim();
  if ((PARTNER_CATEGORIES as readonly string[]).includes(trimmed)) {
    return trimmed as CanonicalPartnerCategory;
  }
  const lower = trimmed.toLowerCase();
  if (lower.includes('homestay') || lower.includes('penginapan') || lower.includes('hotel') || lower.includes('villa')) {
    return 'Penginapan';
  }
  if (lower.includes('kapal') || lower.includes('boat') || lower.includes('transport') || lower.includes('bendi') || lower.includes('rental')) {
    return 'Transportasi';
  }
  if (lower.includes('baju') || lower.includes('pakaian') || lower.includes('adat') || lower.includes('songket')) {
    return 'Pakaian Adat';
  }
  if (lower.includes('kuliner') || lower.includes('makan') || lower.includes('kawa') || lower.includes('kopi') || lower.includes('sate')) {
    return 'Kuliner';
  }
  if (lower.includes('pemandu') || lower.includes('pokdarwis') || lower.includes('atraksi') || lower.includes('guide') || lower.includes('rafting')) {
    return 'Atraksi';
  }
  return 'Atraksi';
}

export function calculateAdventurerLevel(totalXp: number): {
  level: 1 | 2 | 3 | 4 | 5;
  name: 'Pemula' | 'Penjelajah' | 'Petualang' | 'Perintis' | 'Pengelana';
} {
  if (totalXp >= 2000) return { level: 5, name: 'Pengelana' };
  if (totalXp >= 1200) return { level: 4, name: 'Perintis' };
  if (totalXp >= 700) return { level: 3, name: 'Petualang' };
  if (totalXp >= 300) return { level: 2, name: 'Penjelajah' };
  return { level: 1, name: 'Pemula' };
}

export function getCategorySvgPath(category?: string | null): string {
  const normalized = normalizeDestinationCategory(category);
  switch (normalized) {
    case 'Alam & Geopark':
      return '/assets/synced/cat_alam_geopark.svg';
    case 'Budaya & Nagari':
      return '/assets/synced/cat_budaya_nagari.svg';
    case 'Hidden Gem':
      return '/assets/synced/cat_hidden_gem.svg';
    case 'Religi':
      return '/assets/synced/cat_religi.svg';
    case 'Kuliner':
      return '/assets/synced/cat_kuliner.svg';
  }
}

export function getDenahSvgPath(category: DenahPointCategory | string): string {
  switch (category.toUpperCase()) {
    case 'PARKIR':
      return '/assets/synced/denah_parkir.svg';
    case 'UMKM':
      return '/assets/synced/denah_umkm.svg';
    case 'TOILET':
      return '/assets/synced/denah_toilet.svg';
    case 'MUSHOLLA':
      return '/assets/synced/denah_musholla.svg';
    case 'LOKET':
    default:
      return '/assets/synced/denah_loket.svg';
  }
}

export function normalizePungliStatus(raw?: string | null): PungliStatus {
  if (!raw) return 'Masuk';
  const trimmed = raw.trim();
  if ((PUNGLI_STATUSES as readonly string[]).includes(trimmed)) {
    return trimmed as PungliStatus;
  }
  const lower = trimmed.toLowerCase();
  if (lower.includes('selesai') || lower.includes('tuntas')) return 'Selesai';
  if (lower.includes('tindak')) return 'Ditindaklanjuti';
  if (lower.includes('verif')) return 'Diverifikasi';
  return 'Masuk';
}

export function normalizeHazardSeverity(raw?: string | null): HazardSeverity {
  if (!raw) return 'Normal';
  const trimmed = raw.trim();
  if ((HAZARD_SEVERITIES as readonly string[]).includes(trimmed)) {
    return trimmed as HazardSeverity;
  }
  const lower = trimmed.toLowerCase();
  if (lower.includes('tutup') || lower.includes('awas') || lower.includes('merah')) return 'Awas Tutup Total';
  if (lower.includes('siaga') || lower.includes('ekstrem')) return 'Siaga';
  if (lower.includes('waspada') || lower.includes('kuning')) return 'Waspada';
  return 'Normal';
}

export function normalizeTariffCategory(raw?: string | null): string {
  if (!raw) return 'Tiket Masuk';
  const trimmed = raw.trim();
  if ((TARIFF_CATEGORIES as readonly string[]).includes(trimmed)) return trimmed;
  const lower = trimmed.toLowerCase();
  if (lower.includes('parkir')) return 'Parkir Kendaraan';
  if (lower.includes('perahu') || lower.includes('bendi') || lower.includes('sewa') || lower.includes('adat')) {
    return 'Sewa Perahu & Bendi';
  }
  if (lower.includes('pemandu') || lower.includes('pokdarwis') || lower.includes('guide')) {
    return 'Jasa Pemandu Pokdarwis';
  }
  return 'Tiket Masuk';
}

export function tariffCategoryToId(category: string): string {
  switch (normalizeTariffCategory(category)) {
    case 'Parkir Kendaraan':
      return 'cat-trf-parkir';
    case 'Sewa Perahu & Bendi':
      return 'cat-trf-sewa';
    case 'Jasa Pemandu Pokdarwis':
      return 'cat-trf-pemandu';
    case 'Tiket Masuk':
    default:
      return 'cat-trf-tiket';
  }
}

export function buildWeatherSnapshot(cityRegency: string): DestinationWeatherSnapshot {
  const matched =
    SEED_WEATHER_MONITORING.find(
      (w) => w.city_regency.toLowerCase() === cityRegency.toLowerCase()
    ) || SEED_WEATHER_MONITORING[0];
  return {
    city_regency: matched.city_regency,
    temperature_c: matched.current_temp_c,
    condition: matched.condition,
    weather_status: matched.weather_status,
    humidity_percent: matched.humidity_pct,
    wind_speed_kmh: matched.wind_speed_kmh,
    rain_probability: matched.rain_probability,
    forecast: matched.hourly_forecast?.[0]?.condition || matched.condition,
    alert_note: matched.extreme_warning_text,
    source: matched.source,
    last_updated: matched.updated_at,
  };
}

// ============================================================================
// 3. SEED COMPOSITE DESTINASI & COMPATIBILITY EXPORTS (BEBAS CIRCULAR IMPORT)
// ============================================================================
export const MOCK_20_DESTINATIONS: Destination[] = SEED_DESTINATIONS.map((d) => {
  const rules = SEED_ATURAN_DESTINASI.filter((a) => a.destination_id === d.id);
  const tariffs = SEED_OFFICIAL_TARIFFS.filter((t) => t.destination_id === d.id);
  const weather = buildWeatherSnapshot(d.city_regency);
  return {
    ...d,
    medan_indicator: SEED_INDIKATOR_MEDAN.find((m) => m.destination_id === d.id),
    aturan_destinasi: rules,
    tips: rules,
    tariffs,
    official_tariffs: tariffs,
    scenes_360: SEED_PANORAMA_SCENES.filter((s) => s.destination_id === d.id),
    denah_points: SEED_DENAH_POINTS.filter((p) => p.destination_id === d.id),
    weather,
    weather_status: d.weather_status || weather.weather_status,
  };
});

export const INITIAL_PARTNERS: Partner[] = SEED_PARTNERS;
export const INITIAL_PUNGLI_REPORTS: PungliReport[] = SEED_PUNGLI_REPORTS;
export const INITIAL_SOS_TICKETS: SosSignal[] = SEED_SOS_SIGNALS;
export const INITIAL_HAZARD_ALERTS: HazardAlert[] = SEED_HAZARD_ALERTS;
export const INITIAL_REGENCY_HEATMAP: RegencyHeatmapData[] = SEED_REGENCY_HEATMAP;
export const INITIAL_MINANG_PHRASES: MinangPhrase[] = SEED_MINANG_PHRASES;
export const INITIAL_CULTURE_EVENTS: CulturalEvent[] = SEED_CULTURAL_EVENTS;
export const INITIAL_GAODE_RANKINGS: GaodeBehaviorRanking[] = SEED_GAODE_RANKINGS;
export const INITIAL_OPEN_TRIPS: OpenTrip[] = SEED_OPEN_TRIPS;
export const INITIAL_EMERGENCY_CONTACTS: EmergencyContact[] = SEED_EMERGENCY_CONTACTS;
export const INITIAL_TOURIST_CHALLENGES: Challenge[] = SEED_CHALLENGES;
export const INITIAL_SYSTEM_NOTIFICATIONS: Notifikasi[] = SEED_NOTIFIKASI;
export const INITIAL_NEW_TOURS: NewTour[] = SEED_NEW_TOURS;

// ============================================================================
// 4. GROUP ROOMS PUBLIK (/join — Kode Undangan Baku WISGO)
// ============================================================================
export const INITIAL_GROUP_ROOMS: Record<string, GroupRoomPreview> = {
  'WISGO-MINANG-88': {
    group_code: 'WISGO-MINANG-88',
    group_name: 'Trip Go Keluarga Serumpun Ranah Minang',
    leader_name: 'Azman bin Razak (KL Tour)',
    trip_dates: '28 – 30 November 2026',
    member_count: 10,
    destinations_summary: [
      'Jam Gadang & Ngarai Sianok',
      'Istano Basa Pagaruyung',
      'Lembah Harau & Sarasah Bunta',
    ],
    voting_items: [
      { id: 'v-m1', title: 'Makan Siang Nasi Kapau Los Lambuang', category: 'Kuliner', votes_count: 8, is_winner: true },
      { id: 'v-m2', title: 'Sewa Baju Adat Bundo Kanduang di Istano', category: 'Budaya & Nagari', votes_count: 7, is_winner: true },
      { id: 'v-m3', title: 'Sore Santai Kawa Daun Nagari Harau', category: 'Alam & Geopark', votes_count: 5 },
    ],
  },
  'WISGO-HARAU-07': {
    group_code: 'WISGO-HARAU-07',
    group_name: 'Eksplorasi Geopark Harau & Sarasah Bunta',
    leader_name: 'Uda Hendra (Pokdarwis Harau)',
    trip_dates: '05 – 06 Desember 2026',
    member_count: 8,
    destinations_summary: [
      'Lembah Harau & Sarasah Bunta',
      'Kelok 9 & Echo Point',
      'Nagari Tuo Pariangan',
    ],
    voting_items: [
      { id: 'v-h1', title: 'Trekking Sarasah Murai Pagi Hari', category: 'Hidden Gem', votes_count: 6, is_winner: true },
      { id: 'v-h2', title: 'Makan Siang Gulai Itiak Lado Mudo', category: 'Kuliner', votes_count: 7, is_winner: true },
    ],
  },
  'WISGO-MANDEH-12': {
    group_code: 'WISGO-MANDEH-12',
    group_name: 'Island Hopping & Snorkeling Teluk Mandeh',
    leader_name: 'Kapten Roni (Asosiasi Boat Mandeh)',
    trip_dates: '12 Desember 2026',
    member_count: 12,
    destinations_summary: [
      'Kawasan Wisata Bahari Mandeh',
      'Pulau Sironjong Ketek',
      'Sungai Gemuruh & Pulau Kapo-Kapo',
    ],
    voting_items: [
      { id: 'v-md1', title: 'Snorkeling Terumbu Karang Pulau Sironjong', category: 'Alam & Geopark', votes_count: 10, is_winner: true },
      { id: 'v-md2', title: 'Ikan Bakar Segar di Pulau Kapo-Kapo', category: 'Kuliner', votes_count: 9, is_winner: true },
    ],
  },
};

// ============================================================================
// 5. TELEMETRI BENCHMARK SISTEM (Komplet Nol Undefined)
// ============================================================================
export const INITIAL_SYSTEM_BENCHMARK: SystemBenchmarkMetrics = {
  server_uptime_pct: 99.98,
  api_response_time_ms: 19.4,
  go_engine_latency_ms: 18.2,
  postgres_spatial_query_ms: 34.6,
  panorama_load_speed_sec: 1.15,
  database_connection_pool: 'Supabase PostgreSQL 16 + PostGIS 3.4 (Pool Active: 15 Conn)',
  cache_hit_rate_pct: 94.8,
  backend_version: 'WISGO Go Gin Engine v2.4.0 (FE-1/FE-2 Sync)',
  memory_allocated_mb: 124,
  requests_per_second: 540,
  last_stress_test_date: '24 Nov 2026, 23:00 WIB',
  system_status: 'OPERATIONAL',
  benchmark_history: [
    {
      run_id: 'run-20261124-01',
      timestamp: '2026-11-24T16:00:00Z',
      concurrency: 50,
      total_requests: 500,
      latency_ms: 18,
      latency_p50_ms: 18,
      latency_p95_ms: 42,
      latency_p99_ms: 71,
      throughput_qps: 540,
      error_rate_pct: 0.0,
      memory_usage_mb: 124,
      status: 'OPTIMAL',
    },
    {
      run_id: 'run-20261123-02',
      timestamp: '2026-11-23T14:30:00Z',
      concurrency: 20,
      total_requests: 200,
      latency_ms: 15,
      latency_p50_ms: 15,
      latency_p95_ms: 36,
      latency_p99_ms: 62,
      throughput_qps: 498,
      error_rate_pct: 0.0,
      memory_usage_mb: 118,
      status: 'OPTIMAL',
    },
  ],
};
