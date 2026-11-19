// ============================================================================
// MOCK DESTINATIONS & DATA SEED (COMPATIBILITY LAYER)
// Menjembatani komponen lama ke Master Mock Database V2 (26 Tabel Final)
// ============================================================================

import {
  Destination,
  Partner,
  PungliReport,
  SosEmergencyTicket,
  HazardZoneAlert,
  GroupRoomPreview,
  RegencyHeatmapData,
  CommunityHiddenGemSubmission,
  DigitalPassportMetrics,
  MinangAudioPhrase,
  CultureCalendarEvent,
  GaodeRankingItem,
  OpenTripItem,
  SystemBenchmarkMetrics,
  EmergencyContactNumber,
  TouristChallenge,
  SystemNotification,
} from '../types/contract';

import {
  SEED_CATEGORIES,
  SEED_DESTINATIONS,
  SEED_INDIKATOR_MEDAN,
  SEED_ATURAN_DESTINASI,
  SEED_OFFICIAL_TARIFFS,
  SEED_PANORAMA_SCENES,
  SEED_PANORAMA_HOTSPOTS,
  SEED_GAODE_RANKINGS,
  SEED_PUNGLI_REPORTS,
  SEED_SOS_SIGNALS,
  SEED_HAZARD_ALERTS,
  SEED_MINANG_PHRASES,
  SEED_EMERGENCY_CONTACTS,
  SEED_CULTURAL_EVENTS,
  SEED_NEW_TOURS,
  SEED_CHALLENGES,
  SEED_OPEN_TRIPS,
  SEED_NOTIFIKASI,
  SEED_REGENCY_HEATMAP,
} from './mockDatabaseV2';

import { DestinationsRepo } from '../services/dbRepository';

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

export const DESTINATION_CATEGORIES = [
  'Wisata Alam & Geopark',
  'Warisan Budaya & Adat',
  'Pusat Kuliner Tradisional',
  'Bahari & Kepulauan',
  'Situs Bersejarah & Tambang',
] as const;

export const TARIFF_CATEGORIES = [
  'Tiket Retribusi Masuk',
  'Karcis Parkir Kendaraan',
  'Jasa Pemandu & Perahu',
  'Sewa Fasilitas & Adat',
] as const;

export function toDestinationSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-');
}

// 20 Destinasi Prioritas Sumbar dengan Relasi Lengkap
export const MOCK_20_DESTINATIONS: Destination[] = DestinationsRepo.getAll();

export const INITIAL_PARTNERS: Partner[] = [
  {
    id: 'prt-001',
    name: 'Pondok Kawa Daun & Goreng Pisang Mak Etek',
    category: 'Kuliner Halal',
    whatsapp: '6281363456789',
    spicy_level: 0,
    is_verified: true,
    standard_fee: 15000,
    fee_myr_estimate: 4.5,
    nagari_name: 'Nagari Harau',
    city_regency: 'Kab. Lima Puluh Kota',
    owner_name: 'Mak Etek Syafei',
    pokdarwis_sk_number: 'SK-POKDARWIS/HRU/2024-08',
    photo_url: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
    destination_id: 'dest-001',
    destination_name: 'Lembah Harau & Sarasah',
    has_360_pin: true,
    halal_certified: true,
    wa_click_count: 245,
    direct_payment_methods: ['QRIS Nagari Harau', 'Tunai di Tempat', 'Transfer Bank Nagari'],
  },
  {
    id: 'prt-002',
    name: 'Sewa Baju Adat Bundo Kanduang Rang Kayo',
    category: 'Sewa Baju Adat',
    whatsapp: '6281267889900',
    spicy_level: 0,
    is_verified: true,
    standard_fee: 50000,
    fee_myr_estimate: 15.0,
    nagari_name: 'Nagari Pagaruyung',
    city_regency: 'Kab. Tanah Datar',
    owner_name: 'Ibu Hj. Rosmawati',
    pokdarwis_sk_number: 'SK-POKDARWIS/PGR/2023-11',
    photo_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80',
    destination_id: 'dest-002',
    destination_name: 'Istano Basa Pagaruyung',
    has_360_pin: true,
    halal_certified: true,
    wa_click_count: 180,
    direct_payment_methods: ['QRIS Nagari Pagaruyung', 'Tunai di Tempat'],
  },
  {
    id: 'prt-003',
    name: 'Jasa Pemandu Geopark Harau Uda Hendra',
    category: 'Pemandu Pokdarwis',
    whatsapp: '6285263112233',
    spicy_level: 0,
    is_verified: true,
    standard_fee: 150000,
    fee_myr_estimate: 45.0,
    nagari_name: 'Nagari Harau',
    city_regency: 'Kab. Lima Puluh Kota',
    owner_name: 'Hendra Saputra',
    pokdarwis_sk_number: 'SK-POKDARWIS/HRU/2024-01',
    destination_id: 'dest-001',
    destination_name: 'Lembah Harau & Sarasah',
    has_360_pin: true,
    halal_certified: true,
    wa_click_count: 310,
    direct_payment_methods: ['Transfer Bank Nagari', 'QRIS Mandiri', 'Tunai'],
  },
  {
    id: 'prt-004',
    name: 'Boat Wisata Mandeh Bahari Express',
    category: 'Kapal & Transportasi',
    whatsapp: '6281299887711',
    spicy_level: 0,
    is_verified: true,
    standard_fee: 350000,
    fee_myr_estimate: 105.0,
    nagari_name: 'Carocok Tarusan',
    city_regency: 'Kab. Pesisir Selatan',
    owner_name: 'Kapten Rizal Mandeh',
    pokdarwis_sk_number: 'SK-POKDARWIS/MND/2024-03',
    destination_id: 'dest-005',
    destination_name: 'Kawasan Wisata Bahari Mandeh',
    has_360_pin: true,
    halal_certified: true,
    wa_click_count: 420,
    direct_payment_methods: ['QRIS Bank Nagari', 'Transfer BRI', 'Tunai'],
  },
  {
    id: 'prt-005',
    name: 'Homestay Rumah Gadang Tuo Silinduang',
    category: 'Homestay Rumah Gadang',
    whatsapp: '6281363221100',
    spicy_level: 0,
    is_verified: true,
    standard_fee: 250000,
    fee_myr_estimate: 75.0,
    nagari_name: 'Nagari Pariangan',
    city_regency: 'Kab. Tanah Datar',
    owner_name: 'Datuak Bandaro Kayo',
    pokdarwis_sk_number: 'SK-POKDARWIS/PRG/2023-09',
    destination_id: 'dest-008',
    destination_name: 'Nagari Tuo Pariangan',
    has_360_pin: false,
    halal_certified: true,
    wa_click_count: 145,
    direct_payment_methods: ['Transfer BNI', 'QRIS Nagari Pariangan'],
  },
];

export const INITIAL_PUNGLI_REPORTS: PungliReport[] = SEED_PUNGLI_REPORTS;
export const INITIAL_SOS_TICKETS: SosEmergencyTicket[] = SEED_SOS_SIGNALS;
export const INITIAL_HAZARD_ALERTS: HazardZoneAlert[] = SEED_HAZARD_ALERTS;

export const INITIAL_GROUP_ROOMS: Record<string, GroupRoomPreview> = {
  'GRP-HARAU-01': {
    group_code: 'GRP-HARAU-01',
    group_name: 'Trip Geopark Harau & Kelok 9',
    leader_name: 'Uda Hendra (Pokdarwis Harau)',
    trip_dates: '28 - 30 November 2026',
    member_count: 8,
    destinations_summary: ['Lembah Harau', 'Kelok 9', 'Bukittinggi'],
    voting_items: [
      { id: 'v-1', title: 'Trekking Sarasah Murai Pagi Hari', category: 'Aktivitas', votes_count: 6, is_winner: true },
      { id: 'v-2', title: 'Makan Siang Gulai Itiak Lado Mudo', category: 'Kuliner', votes_count: 7, is_winner: true },
    ],
  },
};

export const INITIAL_REGENCY_HEATMAP: RegencyHeatmapData[] = SEED_REGENCY_HEATMAP as unknown as RegencyHeatmapData[];
export const INITIAL_COMMUNITY_SUBMISSIONS: CommunityHiddenGemSubmission[] = SEED_NEW_TOURS as unknown as CommunityHiddenGemSubmission[];

export const INITIAL_DIGITAL_PASSPORT_METRICS: DigitalPassportMetrics = {
  total_gps_checkins_verified: 1525,
  total_governor_certificates_issued: 480,
  total_wa_leads_generated: 12580,
  top_nagari_leads: [
    { nagari: 'Nagari Harau', leads_count: 3820 },
    { nagari: 'Nagari Pagaruyung', leads_count: 2450 },
    { nagari: 'Carocok Tarusan (Mandeh)', leads_count: 2190 },
    { nagari: 'Nagari Pariangan', leads_count: 1420 },
  ],
  leads_by_category: [
    { category: 'Pemandu Pokdarwis', total_leads: 4200, count: 42 },
    { category: 'Kuliner Halal', total_leads: 3600, count: 68 },
    { category: 'Kapal & Transportasi', total_leads: 2800, count: 25 },
    { category: 'Sewa Baju Adat', total_leads: 1100, count: 18 },
    { category: 'Homestay Rumah Gadang', total_leads: 880, count: 14 },
  ],
};

export const INITIAL_MINANG_PHRASES: MinangAudioPhrase[] = SEED_MINANG_PHRASES as unknown as MinangAudioPhrase[];
export const INITIAL_CULTURE_EVENTS: CultureCalendarEvent[] = SEED_CULTURAL_EVENTS as unknown as CultureCalendarEvent[];
export const INITIAL_GAODE_RANKINGS: GaodeRankingItem[] = SEED_GAODE_RANKINGS as unknown as GaodeRankingItem[];
export const INITIAL_OPEN_TRIPS: OpenTripItem[] = SEED_OPEN_TRIPS as unknown as OpenTripItem[];

export const INITIAL_SYSTEM_BENCHMARK: SystemBenchmarkMetrics = {
  server_uptime_pct: 99.98,
  api_response_time_ms: 24.5,
  database_connection_pool: 'Supabase PostgreSQL 16 (Pool Active: 15 Conn)',
  offline_cache_hit_rate: 94.2,
  last_stress_test_date: '18 Nov 2026, 23:00 WIB',
  system_status: 'OPERATIONAL',
};

export const INITIAL_EMERGENCY_CONTACTS: EmergencyContactNumber[] = SEED_EMERGENCY_CONTACTS as unknown as EmergencyContactNumber[];
export const INITIAL_TOURIST_CHALLENGES: TouristChallenge[] = SEED_CHALLENGES as unknown as TouristChallenge[];
export const INITIAL_SYSTEM_NOTIFICATIONS: SystemNotification[] = SEED_NOTIFIKASI as unknown as SystemNotification[];
