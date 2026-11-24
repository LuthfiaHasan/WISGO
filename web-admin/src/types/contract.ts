// ============================================================================
// SKEMA DATABASE RESMI WISGO — 26 TABEL POSTGRESQL 16 + POSTGIS 3.4
// Dinas Pariwisata Provinsi Sumatera Barat • Ekosistem Wisata Pintar Sumbar
// ============================================================================

import { parsePointGeog, formatPointGeog } from '../utils/geoUtils';
export { parsePointGeog, formatPointGeog };

// ============================================================================
// 1. MASTER KATEGORI (categories)
// ============================================================================
export interface Category {
  id: string; // varchar pk
  name: string; // varchar not null
  module_type:
    | 'destination'
    | 'tariff'
    | 'rule'
    | 'new_tour'
    | 'visit_point'
    | 'minang_phrase'
    | string; // varchar not null
  description?: string | null; // text null
  created_at?: string | null; // timestamptz null
}

export type TariffCategoryType = string;
export type CultureEventCategory = string;
export type CultureEventStatus = string;
export type EmergencyCategoryType = string;
export type ModerationStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'pending' | 'approved' | 'rejected' | string;
export type OpenTripStatus = 'Terverifikasi' | 'Menunggu' | 'Ditangguhkan' | string;
export type SosEmergencyStatus = 'SIAGA_DARURAT' | 'TIM_DIKERAHKAN' | 'BERHASIL_DIEVAKUASI' | 'DIBATALKAN' | string;
export type EscrowTransaction = any;
export type PartnerCategoryType = string;
export type MinangPhraseCategory = string;
export type PungliCategoryType = string;
export type ChallengeCategoryType = string;
export type ChallengeRewardType = string;
export type UGCSubmissionStatus = string;
export type ChecklistClaimStatus = string;

// ============================================================================
// 2. KESIAPAN MEDAN 5 INDIKATOR (indikator_medan)
// ============================================================================
export interface IndikatorMedan {
  id: string; // varchar pk
  destination_id: string; // varchar unique not null
  vehicle_access: string; // varchar not null (e.g. 'Mobil OK', 'Hanya Motor', 'Jalan Kaki')
  trekking_level: string; // varchar not null (e.g. 'Datar / Mudah', 'Sedang', 'Curam / Ekstrem')
  cellular_signal: string; // varchar not null (e.g. '4G Lancar', 'Blank Spot', 'Sinyal Lemah')
  facilities: string; // varchar not null (e.g. 'Toilet & Musala Lengkap', 'Terbatas')
  guide_need: string; // varchar not null (e.g. 'Mandiri', 'Wajib Pemandu', 'Disarankan')

  // UI convenience aliases:
  readiness_notes?: string;
  vehicle_score?: number;
  trekking_score?: number;
  signal_score?: number;
  facilities_score?: number;
  guide_score?: number;
}
export type MedanIndicator = IndikatorMedan;

// ============================================================================
// 3. ATURAN DESTINASI & ETIKA (aturan_destinasi)
// ============================================================================
export interface AturanDestinasi {
  id: string; // varchar pk
  destination_id: string; // varchar not null
  category_id?: string; // varchar not null (Ref: categories.id)
  title?: string; // varchar not null
  content: string; // text not null

  // UI alias:
  is_important?: boolean;
}
export type DestinationTip = AturanDestinasi;
export type LocalTip = AturanDestinasi;

// ============================================================================
// 4. TARIF RESMI PERDA (official_tariffs)
// ============================================================================
export interface OfficialTariff {
  id: string; // varchar pk
  destination_id: string; // varchar not null
  category_id?: string; // varchar not null (Ref: categories.id)
  item_name: string; // varchar not null
  price: number; // numeric not null
  unit: string; // varchar not null (e.g. 'per orang', 'per mobil', 'per kapal')
  regulation_ref: string; // varchar not null (e.g. 'Perda Prov Sumbar No 4/2024')

  // UI convenience aliases:
  category?: string;
  fair_price_min?: number;
  fair_price_max?: number;
}

// ============================================================================
// 5. SCENE PANORAMA 360° (panorama_scenes)
// ============================================================================
export interface PanoramaScene {
  id: string; // varchar pk
  destination_id: string; // varchar not null
  title: string; // varchar not null
  scene_type?: 'aerial' | 'ground' | string; // varchar not null
  panorama_url: string; // text not null
  upload_format?: 'equirectangular' | 'cube' | string; // varchar not null
  spatial_audio_url?: string; // text not null (fallback "" jika kosong)
  initial_pitch: number; // float8 not null
  initial_yaw: number; // float8 not null
  is_default_scene?: boolean; // bool not null
  created_at?: string; // timestamptz not null

  // UI aliases:
  type?: 'aerial' | 'ground';
  ambient_audio_url?: string;
  hotspots?: PanoramaHotspot[];
}
export type Scene360 = PanoramaScene;

// ============================================================================
// 6. HOTSPOT PIN 360° (panorama_hotspots)
// ============================================================================
export type HotspotPinCategory =
  | 'fasilitas_umum'
  | 'mitra_umkm'
  | 'loket_info'
  | 'navigasi_arah'
  | string;

export interface PanoramaHotspot {
  id: string; // varchar pk
  scene_id: string; // varchar not null
  pin_type?: HotspotPinCategory; // varchar not null
  color_token?: string; // varchar not null (teal, coral, amber, blue)
  pitch: number; // float8 not null
  yaw: number; // float8 not null
  title: string; // varchar not null
  target_ref?: string; // varchar not null (WA link/no atau target scene_id, fallback "")
  voice_text?: string; // text not null (fallback "")
  description: string; // text not null
  created_at?: string; // timestamptz not null

  // UI convenience aliases:
  category?: HotspotPinCategory;
  whatsapp_number?: string;
  target_scene_id?: string;
  audio_url?: string;
  partner_name?: string;
  partner_fee?: number;
  facility_subtype?: string;
  operating_hours?: string;
  type?: string;
}
export type HotspotPin = PanoramaHotspot;
export type Hotspot360 = PanoramaHotspot;

// ============================================================================
// 7. BUNDEL POCKET OFFLINE (offline_bundles)
// ============================================================================
export interface OfflineBundle {
  id: string; // varchar pk
  destination_id: string; // varchar unique not null
  bundle_version: string; // varchar not null
  file_size_kb: number; // int4 not null
  map_tiles_url: string; // text not null
  compressed_payload: Record<string, unknown>; // jsonb not null
  updated_at: string; // timestamptz not null
}

// ============================================================================
// CHECK POINT LOKASI & KONTAK DARURAT OFFLINE (Destinasi)
// ============================================================================
export interface DestinationCheckpoint {
  id: string;
  destination_id: string;
  name: string;
  latitude?: number;
  longitude?: number;
  is_mandatory_challenge?: boolean;
  notes?: string;
}

export interface OfflineEmergencyContact {
  id: string;
  destination_id: string;
  unit_name: string;
  phone_number: string;
  service_type: 'SAR' | 'Puskesmas' | 'Polsek' | 'Pos Pengelola' | string;
  notes?: string;
}

// ============================================================================
// 8. DESTINASI UTAMA (destinations)
// ============================================================================
export type CrowdLevel = 'Sepi' | 'Sedang' | 'Ramai' | string;

export interface Destination {
  id: string; // varchar pk
  slug: string | null; // varchar unique null
  name: string; // varchar not null
  category_id?: string; // varchar not null (Ref: categories.id)
  city_regency: string; // varchar not null
  description: string; // text not null
  latitude: number; // float8 not null
  longitude: number; // float8 not null
  geog?: string | null; // geography null
  elevation_m?: number; // int4 not null
  cover_image: string; // text not null
  crowd_level: CrowdLevel; // varchar not null
  distance_km?: number; // numeric not null
  travel_time_min?: number; // int4 not null
  estimated_cost?: number; // numeric not null
  is_hidden_gem?: boolean; // bool not null
  qr_placard_code?: string | null; // varchar unique null
  opening_hours?: string; // varchar not null
  created_at?: string; // timestamptz not null
  updated_at?: string; // timestamptz not null

  // Relasi & UI convenience aliases:
  category?: string;
  estimated_distance_km?: number;
  estimated_duration_min?: number;
  ticket_price_summary?: string;
  is_blank_spot?: boolean;
  medan_indicator?: IndikatorMedan;
  indikator_medan?: IndikatorMedan;
  aturan_destinasi?: AturanDestinasi[];
  tips?: AturanDestinasi[];
  tariffs?: OfficialTariff[];
  official_tariffs?: OfficialTariff[];
  scenes_360?: PanoramaScene[];
  panorama_scenes?: PanoramaScene[];
  offline_bundle?: OfflineBundle;
  checkpoints?: DestinationCheckpoint[];
  offline_emergency_contacts?: OfflineEmergencyContact[];
}

// ============================================================================
// 9. GAODE BEHAVIOR RANKINGS (gaode_behavior_rankings)
// ============================================================================
export interface GaodeBehaviorRanking {
  id: string; // varchar pk
  destination_id: string; // varchar unique not null
  category_id: string; // varchar not null (Ref: categories.id)
  rank_position: number; // int4 not null
  gaode_authenticity_score: number; // numeric not null
  active_nav_count_30d: number; // int4 not null
  avg_dwell_time_min: number; // int4 not null
  return_visit_rate_pct: number; // numeric not null
  anti_fake_review_verified: boolean; // bool not null
  trending_badge: string; // varchar not null
  updated_at: string; // timestamptz not null

  // UI convenience joins:
  name?: string;
  destination_name?: string;
  city_regency?: string;
  category?: string;
  calculated_gaode_score?: number;
  current_rank?: number;
  previous_rank?: number;
  avg_dwell_hours?: number;
  pungli_free_index?: number;
  satisfaction_rate?: number;
  weekly_visits?: number;
  medan_score?: number;
  trend?: 'up' | 'down' | 'same';
}
export type GaodeRankingItem = GaodeBehaviorRanking;

// ============================================================================
// 10. LAPORAN PUNGLI & SATGAS (pungli_reports)
// ============================================================================
export type PungliStatus =
  | 'Masuk'
  | 'Diverifikasi'
  | 'Ditindaklanjuti'
  | 'Selesai'
  | 'Ditolak'
  | string;

export interface PungliReport {
  id: string; // varchar pk
  ticket_code?: string; // varchar unique not null
  user_id?: string; // varchar not null (Ref: users.id)
  destination_id: string; // varchar not null (Ref: destinations.id)
  tariff_id?: string | null; // varchar null (Ref: official_tariffs.id)
  incident_category?: string; // varchar not null
  charged_amount_idr?: number; // numeric not null
  official_perda_price_idr?: number; // numeric not null
  overcharge_amount_idr?: number; // numeric not null
  photo_evidence?: string; // text not null
  incident_geog?: string | null; // geography null
  status: PungliStatus; // varchar not null
  verified_by_admin_id?: string | null; // varchar null (Ref: users.id)
  admin_action_notes?: string | null; // text null
  created_at?: string; // timestamptz not null
  updated_at?: string; // timestamptz not null

  // UI convenience joins:
  destination_name?: string;
  kab_kota?: string;
  reporter_name?: string;
  reporter_phone?: string;
  category?: string;
  reported_amount?: number;
  official_amount?: number;
  description?: string;
  photo_url?: string;
  lat?: number;
  lng?: number;
  bap_notes?: string;
  admin_notes?: string;
}

// ============================================================================
// 11. ULASAN DESTINASI & MODERASI (destination_reviews)
// ============================================================================
export interface DestinationReview {
  id: string; // varchar pk
  destination_id: string; // varchar not null (Ref: destinations.id)
  user_id?: string; // varchar not null (Ref: users.id)
  stemp_visit_id?: string | null; // varchar unique null (Ref: stemp_visit.id)
  rating: number; // int4 not null (1-5)
  review_comment?: string; // text not null
  photo_url?: string | null; // text null
  is_gps_verified?: boolean; // bool not null
  created_at?: string; // timestamptz not null

  // UI convenience joins:
  user_name?: string;
  destination_name?: string;
  comment?: string;
  tourist_name?: string;
  author_badge?: string;
  tags?: string[];
  helpful_count?: number;
  is_hidden?: boolean;
  admin_moderation_reason?: string;
  raw_text?: string;
  is_important?: boolean;
  character_count?: number;
  visited_at?: string;
}
export type TouristReview = DestinationReview;

// ============================================================================
// 12. TELEMETRI LATENSI & SLA (api_telemetry_logs)
// ============================================================================
export interface ApiTelemetryLog {
  id: string; // varchar pk
  endpoint_path: string; // varchar not null
  http_method: string; // varchar not null
  status_code: number; // int4 not null
  latency_ms: number; // numeric not null
  cache_hit: boolean; // bool not null
  recorded_at: string; // timestamptz not null
}

// ============================================================================
// 13. TITIK SINGGAH SEARAH / SHUNLU (visit_point)
// ============================================================================
export interface VisitPoint {
  id: string; // varchar pk
  name: string; // varchar not null
  category_id: string; // varchar not null (Ref: categories.id)
  corridor_road: string; // varchar not null
  city_regency: string; // varchar not null
  latitude: number; // float8 not null
  longitude: number; // float8 not null
  geog?: string | null; // geography null
  detour_minutes: number; // int4 not null
  detour_distance_meter: number; // int4 not null
  highlight_note: string; // text not null
  opening_hours: string; // varchar not null
  is_recommended: boolean; // bool not null

  // UI joins:
  category_name?: string;
}

// ============================================================================
// 14. ALERT JALUR EKSTREM & BENCANA (hazard_alerts)
// ============================================================================
export type HazardSeverity =
  | 'Aman'
  | 'Waspada'
  | 'Buka-Tutup'
  | 'Tutup Total'
  | string;

export interface HazardAlert {
  id: string; // varchar pk
  corridor_code: string; // varchar unique not null (e.g. 'CORR-SITINJAU', 'CORR-ANAI')
  location: string; // varchar not null
  road_segment: string; // varchar not null
  city_regency: string; // varchar not null
  latitude: number; // float8 not null
  longitude: number; // float8 not null
  geog?: string | null; // geography null
  radius_meter: number; // int4 not null
  severity: HazardSeverity; // varchar not null
  hazard_type: string; // varchar not null
  weather_status: string; // varchar not null
  slope_gradient_deg: number; // int4 not null
  message: string; // text not null
  detour_route: string; // text not null
  detour_route_geojson: Record<string, unknown> | null; // jsonb not null
  nearest_rescue_post: string; // varchar not null
  emergency_contact: string; // varchar not null
  triggered_by_admin: string | null; // varchar null (Ref: users.id)
  updated_at: string; // timestamptz not null
}
export type HazardZoneAlert = HazardAlert;

// ============================================================================
// 15. SINYAL DARURAT SOS GPS (sos_signals)
// ============================================================================
export type SosStatus =
  | 'SIAGA_DARURAT'
  | 'TIM_DIKERAHKAN'
  | 'BERHASIL_DIEVAKUASI'
  | 'DIBATALKAN'
  | string;

export interface SosSignal {
  id: string; // varchar pk
  sos_code?: string; // varchar unique not null (e.g. 'SOS-2026-081')
  tourist_name: string; // varchar not null
  phone_number?: string; // varchar not null
  emergency_type?: string; // varchar not null
  latitude: number; // float8 not null
  longitude: number; // float8 not null
  geog?: string | null; // geography null
  battery_percent?: number; // int4 not null
  passengers_count?: number; // int4 not null
  nearest_corridor?: string; // varchar not null (Ref: hazard_alerts.corridor_code)
  nearest_rescue_post?: string; // varchar not null
  distance_to_rescue_km?: number; // numeric not null
  eta_rescue_minutes?: number; // int4 not null
  status: SosStatus; // varchar not null
  notes?: string | null; // text null
  created_at?: string; // timestamptz not null

  // UI convenience aliases:
  tourist_phone?: string;
  destination_name?: string;
  kab_kota?: string;
  lat?: number;
  lng?: number;
  battery_level?: number;
  signal_status?: string;
  medical_notes?: string;
  sar_unit_assigned?: string;
  delivery_method?: 'online' | 'offline_fallback';
  last_signal_at?: string;
  last_known_coords?: string;
  sms_gateway_ref?: string;
}
export type SosEmergencyTicket = SosSignal;

// ============================================================================
// MONITORING CUACA REAL-TIME KAWASAN WISATA
// ============================================================================
export interface WeatherHourlyForecast {
  hour: string;
  temp_c: number;
  condition: string;
}

export interface WeatherMonitoringItem {
  id: string;
  city_regency: string;
  destination_name: string;
  current_temp_c: number;
  condition: 'Cerah' | 'Cerah Berawan' | 'Hujan Ringan' | 'Hujan Lebat & Angin' | 'Kabut Tebal' | string;
  humidity_pct: number;
  wind_speed_kmh: number;
  hourly_forecast: WeatherHourlyForecast[];
  is_extreme_weather: boolean;
  extreme_warning_text?: string;
  updated_at: string;
}

// ============================================================================
// 16. KAMUS SAKU MINANG (minang_phrases)
// ============================================================================
export interface MinangPhrase {
  id: string; // varchar pk
  category_id: string; // varchar not null (Ref: categories.id)
  indonesian_text: string; // text not null
  minang_text: string; // text not null
  phonetic_guide: string; // text not null
  voice_text: string; // text not null
  dialect_note: string; // varchar not null
  usage_context_tip: string; // text not null
  politeness_level: 'Biasa' | 'Sopan' | 'Halus / Adat' | string; // varchar not null

  // UI convenience aliases:
  phrase?: string;
  pronunciation?: string;
  meaning_id?: string;
  meaning_en?: string;
  audio_url?: string;
  notes?: string;
  category?: string;
  updated_at?: string;
}
export type MinangAudioPhrase = MinangPhrase;

// ============================================================================
// 17. KONTAK DARURAT (emergency_contacts)
// ============================================================================
export interface EmergencyContact {
  id: string; // varchar pk
  agency_name: string; // varchar not null
  agency_type: 'Polres' | 'BPBD' | 'SAR' | 'Rumah Sakit' | 'Dishub' | string; // varchar not null
  phone_number: string; // varchar not null
  whatsapp_number?: string | null; // varchar null
  city_regency: string; // varchar not null
  geog: string; // geography not null (e.g. "SRID=4326;POINT(100.354270 -0.949240)")
  created_by_admin_id?: string; // varchar not null (Ref: users.id)
  is_active?: boolean; // bool not null

  // UI convenience:
  latitude?: number;
  longitude?: number;
  call_number?: string;
  description?: string;
  category?: string;
  address?: string;
  is_24_hours?: boolean;
  updated_at?: string;
}
export type EmergencyContactNumber = EmergencyContact;

// ============================================================================
// 18. EVENT BUDAYA (cultural_events)
// ============================================================================
export interface CulturalEvent {
  id: string; // varchar pk
  user_id?: string; // varchar not null (Ref: users.id)
  title: string; // varchar not null
  event_type?: string; // varchar not null
  nagari_location?: string; // varchar not null
  city_regency: string; // varchar not null
  schedule_rule?: string; // varchar not null
  next_event_date?: string; // varchar not null
  latitude?: number; // float8 not null
  longitude?: number; // float8 not null
  geog?: string | null; // geography null
  highlight_item?: string; // text not null
  cultural_etiquette?: string; // text not null

  // UI convenience aliases:
  location?: string;
  start_date?: string;
  end_date?: string;
  description?: string;
  poster_url?: string;
  organizer?: string;
  status?: string;
  category?: string;
  updated_at?: string;
}
export type CultureCalendarEvent = CulturalEvent;

// ============================================================================
// 19. TEMPAT TERSIMPAN (saved_places)
// ============================================================================
export interface SavedPlace {
  id: string; // varchar pk
  user_id: string; // varchar not null (Ref: users.id)
  destination_id: string; // varchar not null (Ref: destinations.id)
  created_at: string | null; // timestamptz null
}

// ============================================================================
// 20. VALIDASI CHECK-IN STEMP VISIT (stemp_visit)
// ============================================================================
export interface StempVisit {
  id: string; // varchar pk
  user_id: string; // varchar not null (Ref: users.id)
  destination_id: string; // varchar not null (Ref: destinations.id)
  checked_in_at: string | null; // timestamptz null
  is_gps_valid: boolean; // bool not null
}

// ============================================================================
// 21. USULAN DESTINASI BARU (new_tour)
// ============================================================================
export interface NewTour {
  id: string; // varchar pk
  user_id?: string; // varchar not null (Ref: users.id)
  name?: string; // varchar not null
  category_id?: string; // varchar not null (Ref: categories.id)
  city_regency: string; // varchar not null
  description: string | null; // text null
  latitude?: number; // float8 not null
  longitude?: number; // float8 not null
  tips_menjaga?: string; // text not null (WAJIB!)
  is_sensitive?: boolean | null; // bool null
  status: 'pending' | 'approved' | 'rejected' | string; // varchar not null
  created_at?: string | null; // timestamptz null

  // UI convenience joins:
  submitter_name?: string;
  submitter_phone?: string;
  title?: string;
  category?: string;
  admin_notes?: string;
  submitted_at?: string;
  pokdarwis_name?: string;
  reviewer_notes?: string;
  is_masked?: boolean;
  photo_url?: string;
  estimated_price?: string;
}
export type TouristDestinationSubmission = NewTour;
export type CommunityHiddenGemSubmission = NewTour;

// ============================================================================
// 22. TANTANGAN CEKLIS WISATA (challenges)
// ============================================================================
export interface Challenge {
  id: string; // varchar pk
  created_by_admin_id?: string; // varchar not null (Ref: users.id)
  title: string; // varchar not null
  description: string; // text not null
  target_destination_count?: number; // int4 not null
  reward_title?: string; // varchar not null
  reward_type?: string; // varchar not null (e.g. 'Uang Tunai', 'Sertifikat', 'Voucher')
  reward_points?: number; // int4 not null (default 0 untuk pure ceklis)
  is_active: boolean; // bool not null
  created_at: string; // timestamptz not null
  updated_at?: string; // timestamptz

  // UI convenience:
  target_count?: number;
  reward_description?: string;
  duration_days?: number;
  target_destinations?: string[];
  target_checkpoints?: string[];
  checkin_tagline?: string;
  participant_count?: number;
  completed_count?: number;
  category?: string;
}
export type ChecklistChallenge = Challenge;
export type TouristChallenge = Challenge;

// ============================================================================
// 23. KLAIM REWARD TANTANGAN (user_challenge_rewards)
// ============================================================================
export interface UserChallengeReward {
  id: string; // varchar pk
  challenge_id: string; // varchar not null (Ref: challenges.id)
  user_id?: string; // varchar not null (Ref: users.id)
  progress_count?: number; // int4 not null
  status: 'DALAM_PROGRES' | 'SIAP_KLAIM' | 'HADIAH_TERKIRIM' | string; // varchar not null
  jenis_reward?: string; // varchar not null (salinan dari challenges.reward_type)
  reward?: string; // varchar not null (salinan dari challenges.reward_title)
  certificate_code?: string | null; // varchar unique null
  certificate_url?: string | null; // text null
  completed_at?: string | null; // timestamptz null

  // UI convenience joins:
  challenge_title?: string;
  tourist_name?: string;
  tourist_phone?: string;
  target_count?: number;
  target_destination_count?: number;
  completed_count?: number;
  reward_description?: string;
  completed_destinations?: string[];
  reward_sent_at?: string;
  reward_notes?: string;
}
export type TouristChecklistClaim = UserChallengeReward;

// ============================================================================
// 24. PENGGUNA SISTEM (users)
// ============================================================================
export interface User {
  id: string; // varchar pk
  phone_number: string; // varchar unique not null
  full_name: string; // varchar not null
  role: 'admin' | 'admin_utama' | 'wisatawan' | 'mitra' | 'pokdarwis' | string; // varchar not null
  jenis_input?: string | null; // varchar null ('web_admin', 'mobile_app', 'qr_kiosk', etc.)
  created_at?: string | null; // timestamptz null

  // Optional session additions:
  email?: string;
  agency?: string;
}

// ============================================================================
// 25. OPEN TRIPS / CARI BARENGAN (open_trips)
// ============================================================================
export interface OpenTrip {
  id: string; // varchar pk (Dipakai sebagai kode grup / invitation code)
  user_id: string; // varchar not null (Ref: users.id)
  title: string; // varchar not null
  destination_route: string; // varchar not null (Format delimiter: "H1: BIM | H2: Harau | H3: Bukittinggi")
  departure_date: string; // timestamptz not null
  available_seats: number; // int4 not null
  cost_per_person: number; // numeric not null (IDR)
  contact_wa: string; // varchar not null
  created_at?: string | null; // timestamptz null

  // UI convenience:
  trip_code?: string;
  leader_name?: string;
  trip_leader_name?: string;
  leader_phone?: string;
  pokdarwis_partner?: string;
  city_regency?: string;
  destination_routes?: string[];
  destinations?: string[];
  total_quota?: number;
  filled_quota?: number;
  quota_filled?: number;
  quota_max?: number;
  duration_days?: number;
  estimated_split_bill_idr?: number;
  estimated_split_bill_myr?: number;
  split_bill_idr?: number;
  split_bill_myr?: number;
  notes?: string;
  status?: 'Terverifikasi' | 'Menunggu' | 'Ditangguhkan' | string;
  pokdarwis_verified?: boolean;

  // Single Destination & Auto-Category Constraint
  destination_id?: string;
  destination_name?: string;
  travel_category?: string;
  meeting_point_name?: string;
  meeting_point_gmaps_url?: string;
  meeting_point_coords?: string;
  external_activity_terms?: string;

  // Trip Planner Detail
  trip_planner?: {
    checklist: string[];
    jobdesk_assignments: { role: string; person_name: string }[];
    packing_checklist: string[];
    itinerary: { day: number; time: string; activity: string }[];
  };
}
export type OpenTripItem = OpenTrip;

// ============================================================================
// VERIFIKASI PENYELENGGARA OPEN TRIP (Kredibilitas Komunitas/Pemandu)
// ============================================================================
export interface OpenTripOrganizer {
  id: string;
  name: string;
  agency_name: string;
  phone_number: string;
  doc_ktp_url?: string;
  doc_sk_pokdarwis_url?: string;
  doc_guide_cert_url?: string;
  status: 'Menunggu' | 'Terverifikasi' | 'Ditolak';
  submitted_at: string;
  verified_at?: string;
  notes?: string;
}

// ============================================================================
// TRANSAKSI SISTEM KHUSUS OPEN TRIP (Sistem Transaksi HANYA untuk Open Trip)
// ============================================================================
export interface OpenTripTransaction {
  id: string;
  transaction_code: string;
  trip_id: string;
  trip_title: string;
  participant_name: string;
  participant_phone: string;
  seats_booked: number;
  amount_idr: number;
  payment_channel: string;
  status: 'BERHASIL' | 'MENUNGGU' | 'REFUND';
  paid_at: string;
}

// ============================================================================
// TEMPLATE BARANG BAWAAN BERDASARKAN KATEGORI PERJALANAN
// ============================================================================
export interface PackingTemplate {
  id: string;
  category_name: string; // 'Wisata Alam & Pegunungan' | 'Wisata Bahari & Pesisir' | 'Sejarah & Warisan Minangkabau' | 'Nagari Adat & Edukasi Budaya' | 'Kuliner Otentik & Agrowisata'
  item_name: string;
  is_mandatory: boolean;
  notes?: string;
}

// ============================================================================
// 5 LEVEL PETUALANG RESMI WISGO (Leveling & Lencana)
// ============================================================================
export interface AdventurerLevelConfig {
  level: 1 | 2 | 3 | 4 | 5;
  name: string; // 'Beginner' | 'Explorer' | 'Adventurer' | 'Trailblazer' | 'Wanderer'
  title: string;
  min_trips: number;
  min_checkpoints: number;
  min_xp: number;
  badge_icon: string;
  badge_color: string;
  perk_description: string;
}

// ============================================================================
// PROFIL & EXPERIENCE PENGGUNA (Statistik Strava-style & Verifikasi Klaim)
// ============================================================================
export interface UserProfileExperience {
  id: string;
  user_id: string;
  full_name: string;
  email: string;
  phone_number: string;
  google_avatar?: string;
  is_google_auth: boolean;
  current_level: 1 | 2 | 3 | 4 | 5;
  level_name: string;
  total_trips: number;
  total_checkpoints: number;
  total_distance_km: number;
  total_xp: number;
  last_active_at: string;
  experience_history: {
    date: string;
    destination_name: string;
    checkpoint_name?: string;
    xp_earned: number;
    notes?: string;
    status?: 'verified' | 'pending';
  }[];
}

// ============================================================================
// TEMPLATE POSTING SHARE & QR UNDUH
// ============================================================================
export interface PostingShareTemplate {
  id: string;
  template_name: string;
  watermark_text: string;
  qr_download_url: string;
  qr_image_url: string;
  background_banner_url: string;
  badge_placeholder_text: string;
  preview_strava_style: boolean;
}

// ============================================================================
// 26. NOTIFIKASI PENGGUNA (notifikasi)
// ============================================================================
export interface Notifikasi {
  id: string; // varchar pk
  user_id?: string; // varchar not null (Ref: users.id)
  notification_type?:
    | 'review_moderation'
    | 'new_tour_rejected'
    | 'pungli_action'
    | 'system'
    | string; // varchar not null
  title: string; // varchar not null
  message: string; // text not null
  reference_id?: string | null; // varchar null (e.g. new_tour.id atau destination_reviews.id)
  is_read?: boolean; // bool not null
  created_at?: string; // timestamptz not null

  // UI aliases:
  type?: string;
  broadcasted_at?: string;
  is_delivered?: boolean;
  target?: string;
  ref_id?: string;
}
export type SystemNotification = Notifikasi;

// ============================================================================
// KOMPATIBILITAS AUTH, SIMULATOR & ANALITIK
// ============================================================================
export interface AdminAuthCredentials {
  email: string;
  password: string;
  role?: string;
}

export interface AdminAuthResponse {
  token: string;
  expires_at: string;
  user: User & {
    email: string;
    agency: string;
  };
}

export interface WAWebhookResponse {
  action: '1' | '0';
  status: 'CONFIRMED' | 'REJECTED';
  ticket_qr?: string;
  escrow_info: string;
}

export interface WhatsAppSimulationMessage {
  id: string;
  sender: 'system' | 'tourist' | 'mitra';
  message: string;
  timestamp: string;
  booking_code?: string;
  qr_code_ticket?: string;
  amount?: number;
  service_date?: string;
}

export interface RegencyHeatmapData {
  id: string;
  name: string;
  code: string;
  crowd_status: 'Sepi' | 'Sedang' | 'Ramai' | 'Overload';
  visitor_count_week: number;
  domestic_pct: number;
  foreign_myr_pct: number;
  top_destination: string;
  wa_leads_count: number;
  personal_visitors_est?: number;
  group_visitors_est?: number;
}

export interface Partner {
  id: string;
  name: string;
  category: string;
  whatsapp: string;
  spicy_level?: number;
  is_verified: boolean;
  standard_fee: number;
  fee_myr_estimate?: number;
  nagari_name: string;
  city_regency?: string;
  owner_name?: string;
  pokdarwis_sk_number?: string;
  photo_url?: string;
  photo_360_url?: string;
  destination_id?: string;
  destination_name?: string;
  scene_id?: string;
  pin_id?: string;
  pitch?: number;
  yaw?: number;
  has_360_pin?: boolean;
  halal_certified?: boolean;
  created_at?: string;
  wa_click_count?: number;
  direct_payment_methods?: string[];
}
export type PartnerNagari = Partner;

export interface GaodeWeightConfig {
  satisfaction_weight: number;
  pungli_free_weight: number;
  medan_access_weight: number;
  visit_volume_weight: number;
}

export interface SystemBenchmarkMetrics {
  server_uptime_pct: number;
  api_response_time_ms: number;
  database_connection_pool: string;
  offline_cache_hit_rate: number;
  last_stress_test_date: string;
  system_status: 'OPERATIONAL' | 'DEGRADED' | 'MAINTENANCE' | string;
  server_status?: string;
  benchmark_history?: any[];
  postgres_spatial_query_ms?: number;
  go_engine_latency_ms?: number;
  offline_360_bundle_speed_sec?: number;
  backend_version?: string;
  memory_allocated_mb?: number;
  requests_per_second?: number;
}

export interface BenchmarkRunResult {
  run_id: string;
  timestamp: string;
  latency_ms: number;
  memory_usage_mb: number;
  active_sessions: number;
  status: 'OPTIMAL' | 'NORMAL' | 'WARNING' | string;
  total_requests?: number;
}

export interface DigitalPassportMetrics {
  total_gps_checkins_verified: number;
  total_governor_certificates_issued: number;
  total_wa_leads_generated: number;
  top_nagari_leads: { nagari: string; leads_count: number }[];
  leads_by_category: { category: string; total_leads: number; count: number }[];
}

export interface GroupVotingItem {
  id: string;
  title: string;
  category: string;
  votes_count: number;
  is_winner?: boolean;
}

export interface GroupRoomPreview {
  group_code: string;
  group_name: string;
  leader_name: string;
  trip_dates: string;
  member_count: number;
  destinations_summary: string[];
  voting_items: GroupVotingItem[];
}
