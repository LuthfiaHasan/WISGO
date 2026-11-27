// ============================================================================
// SKEMA DATABASE RESMI WISGO V3 — SINKRON 100% FRONTEND-1 (73a33bb) & FRONTEND-2 (6911eaf)
// Dinas Pariwisata Provinsi Sumatera Barat • Ekosistem Wisata Pintar Sumbar
// ============================================================================

import { parsePointGeog, formatPointGeog } from '../utils/geoUtils';
export { parsePointGeog, formatPointGeog };

// ============================================================================
// 0. KANONIK ENUM & KONSTANTA DOMAIN
// ============================================================================
export type MasterDestinationCategory =
  | 'Alam & Geopark'
  | 'Budaya & Nagari'
  | 'Hidden Gem'
  | 'Religi'
  | 'Kuliner';

export type DenahPointCategory =
  | 'PARKIR'
  | 'TOILET'
  | 'MUSHOLLA'
  | 'LOKET';

export type TariffCategoryType =
  | 'Tiket Masuk'
  | 'Parkir Kendaraan'
  | 'Sewa Perahu & Bendi'
  | 'Jasa Pemandu Pokdarwis'
  | string;

export type PungliStatus =
  | 'Masuk'
  | 'Diverifikasi'
  | 'Ditindaklanjuti'
  | 'Selesai';

export type HazardSeverity =
  | 'Normal'
  | 'Waspada'
  | 'Siaga'
  | 'Awas Tutup Total';

export type EmergencyAgencyType =
  | 'BPBD'
  | 'PMI'
  | 'Damkar'
  | 'Basarnas'
  | 'Kepolisian'
  | 'Medis';

export type SosStatus =
  | 'Dipancarkan'
  | 'Tim SAR Meluncur'
  | 'Evakuasi Selesai'
  | string;

export type JejakWisgoSource = 'GPS_CHECKIN' | 'TRIP_GO' | 'TICKET_SCAN';

export type MinangPolitenessLevel =
  | 'Kato Mandaki'
  | 'Kato Mandata'
  | 'Kato Manurun'
  | 'Kato Malereang';

export type MinangPhraseCategory =
  | 'Kuliner'
  | 'Pasar & Belanja'
  | 'Sapaan Nagari'
  | 'Arah & Navigasi'
  | string;

export type CrowdLevel = 'Sepi' | 'Sedang' | 'Ramai';
export type CultureEventCategory = string;
export type CultureEventStatus = 'Akan Datang' | 'Sedang Berlangsung' | 'Selesai' | string;
export type OpenTripStatus = 'Terverifikasi' | 'Menunggu' | 'Ditangguhkan' | string;
export type ChallengeCategoryType = string;
export type ChallengeRewardType = string;
export type NewTourStatus = 'pending' | 'approved' | 'rejected';

// ============================================================================
// 1. MASTER KATEGORI (categories)
// ============================================================================
export interface Category {
  id: string;
  slug?: string;
  name: string;
  module_type:
    | 'destination'
    | 'tariff'
    | 'rule'
    | 'new_tour'
    | 'visit_point'
    | 'minang_phrase'
    | string;
  description?: string | null;
  created_at?: string | null;
}

// ============================================================================
// 2. KESIAPAN MEDAN 4 INDIKATOR (indikator_medan — Sinkron FE-1 & FE-2)
// ============================================================================
export type VehicleAccessLevel = 'Mobil OK' | 'Hanya Motor' | 'Jalan Kaki' | string;
export type TrekkingLevel = 'Mudah (Datar)' | 'Sedang' | 'Ekstrem (Curam)' | string;
export type FacilitiesLevel = 'Toilet, Musala & Parkir Lengkap' | 'Terbatas' | 'Belum Ada' | string;
export type GuideNeedLevel = 'Mandiri' | 'Disarankan' | 'Wajib Pemandu Lokal' | string;

export interface IndikatorMedan {
  id: string;
  destination_id: string;
  vehicle_access: VehicleAccessLevel;
  trekking_level: TrekkingLevel;
  facilities: FacilitiesLevel;
  guide_need: GuideNeedLevel;
  terrain_note?: string;
  readiness_notes?: string;
}
export type MedanIndicator = IndikatorMedan;

// ============================================================================
// 3. ATURAN DESTINASI & TIPS MENJAGA TEMPAT INI (aturan_destinasi)
// ============================================================================
export interface AturanDestinasi {
  id: string;
  destination_id: string;
  category_id?: string;
  title?: string;
  content: string;
  is_important?: boolean;
}
export type DestinationTip = AturanDestinasi;
export type LocalTip = AturanDestinasi;

// ============================================================================
// 4. TARIF RESMI PERDA (official_tariffs)
// ============================================================================
export interface OfficialTariff {
  id: string;
  destination_id: string;
  category_id?: string;
  category?: TariffCategoryType;
  item_name: string;
  price: number;
  fair_price_min?: number;
  fair_price_max?: number;
  unit: string;
  regulation_ref: string;
}

// ============================================================================
// 5. SCENE PANORAMA 360° BERSIH (panorama_scenes — Pure Panorama View)
// ============================================================================
export interface PanoramaScene {
  id: string;
  destination_id: string;
  title: string;
  scene_type: 'aerial' | 'ground';
  view_mode?: 'photo_panorama' | string;
  image_resolution?: string;
  panorama_url: string;
  upload_format?: 'equirectangular' | string;
  initial_pitch: number;
  initial_yaw: number;
  is_default_scene?: boolean;
  created_at?: string;
}
export type Scene360 = PanoramaScene;

// ============================================================================
// 6. DENAH KAWASAN 2D (denah_points — Parkir, Toilet, Musholla, Loket)
// ============================================================================
export interface DenahPoint {
  id: string;
  destination_id: string;
  category: DenahPointCategory;
  title: string;
  description: string;
  x: number; // 0 - 100 (% horizontal)
  y: number; // 0 - 100 (% vertikal)
}

// ============================================================================
// 7. CHECK POINT LOKASI & CUACA DESTINASI
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

export interface DestinationWeatherSnapshot {
  city_regency: string;
  temperature_c: number;
  condition: string;
  weather_status: 'Aman' | 'Waspada Hujan' | 'Siaga Cuaca Ekstrem' | string;
  humidity_percent: number;
  wind_speed_kmh: number;
  rain_probability: number;
  forecast?: string;
  alert_note?: string;
  source: string;
  last_updated: string;
}

// ============================================================================
// 8. DESTINASI UTAMA (destinations)
// ============================================================================
export interface DestinationContributor {
  name: string;
  phone?: string;
  role:
    | 'Pengusul Utama'
    | 'Kontributor Foto'
    | 'Kontributor Data & Tips'
    | 'Pengusul Bersama';
  submission_id: string;
}

export interface Destination {
  id: string;
  slug: string;
  name: string;
  category_id: string;
  category: MasterDestinationCategory | string;
  city_regency: string;
  description: string;
  latitude: number;
  longitude: number;
  geog?: string | null;
  elevation_m?: number;
  cover_image: string;
  gallery_images?: string[];
  contributors?: DestinationContributor[];
  crowd_level: CrowdLevel;
  distance_km: number;
  travel_time_min: number;
  estimated_cost: number;
  ticket_price_summary?: string;
  is_hidden_gem?: boolean;
  qr_placard_code?: string;
  opening_hours?: string;
  weather_status?: string;
  weather?: DestinationWeatherSnapshot;
  created_at?: string;
  updated_at?: string;

  // Relasi tersinkronisasi:
  medan_indicator?: IndikatorMedan;
  aturan_destinasi?: AturanDestinasi[];
  tips?: AturanDestinasi[];
  tariffs?: OfficialTariff[];
  official_tariffs?: OfficialTariff[];
  scenes_360?: PanoramaScene[];
  denah_points?: DenahPoint[];
  checkpoints?: DestinationCheckpoint[];
}

// ============================================================================
// 9. GAODE BEHAVIOR RANKINGS (gaode_behavior_rankings)
// ============================================================================
export interface GaodeBehaviorRanking {
  id: string;
  destination_id: string;
  category_id: string;
  category: MasterDestinationCategory | string;
  name: string;
  destination_name?: string;
  city_regency: string;
  rank_position: number;
  current_rank: number;
  previous_rank: number;
  gaode_authenticity_score: number;
  calculated_gaode_score: number;
  active_nav_count_30d: number;
  weekly_visits: number;
  avg_dwell_time_min: number;
  avg_dwell_hours: number;
  return_visit_rate_pct: number;
  satisfaction_rate: number;
  pungli_free_index: number;
  medan_score: number;
  anti_fake_review_verified: boolean;
  trending_badge: string;
  trend: 'up' | 'down' | 'same';
  updated_at: string;
}
export type GaodeRankingItem = GaodeBehaviorRanking;

export interface GaodeWeightConfig {
  satisfaction_weight: number;
  pungli_free_weight: number;
  medan_access_weight: number;
  visit_volume_weight: number;
}

// ============================================================================
// 10. LAPORAN PUNGLI & FASILITAS RUSAK (pungli_reports)
// ============================================================================
export interface PungliReport {
  id: string;
  ticket_code: string;
  user_id?: string;
  destination_id: string;
  destination_name: string;
  kab_kota: string;
  tariff_id?: string | null;
  report_type?: 'pungli' | 'fasilitas';
  incident_category: string;
  charged_amount_idr: number;
  official_perda_price_idr: number;
  overcharge_amount_idr: number;
  photo_evidence: string;
  latitude: number;
  longitude: number;
  incident_geog?: string | null;
  reporter_name: string;
  reporter_phone?: string;
  description: string;
  status: PungliStatus;
  verified_by_admin_id?: string | null;
  admin_action_notes?: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// 11. ULASAN DESTINASI & KONDISI LAPANGAN (destination_reviews)
// ============================================================================
export interface DestinationReview {
  id: string;
  destination_id: string;
  destination_name: string;
  user_id?: string;
  user_name: string;
  author_badge?: string;
  stemp_visit_id?: string | null;
  rating: number;
  review_comment: string;
  raw_text?: string;
  photo_url?: string | null;
  tags: string[];
  helpful_count: number;
  is_gps_verified: boolean;
  is_important: boolean;
  is_hidden: boolean;
  admin_moderation_reason?: string;
  character_count: number;
  visited_at: string;
  created_at: string;
}
export type TouristReview = DestinationReview;

// ============================================================================
// 12. TELEMETRI LATENSI & SLA (api_telemetry_logs)
// ============================================================================
export interface ApiTelemetryLog {
  id: string;
  endpoint_path: string;
  http_method: string;
  status_code: number;
  latency_ms: number;
  cache_hit: boolean;
  recorded_at: string;
}

// ============================================================================
// 13. ALERT JALUR EKSTREM & BENCANA (hazard_alerts)
// ============================================================================
export interface HazardAlert {
  id: string;
  corridor_code: string; // SITINJAU-LAUIK | LEMBAH-ANAI | KELOK-9 | KELOK-44
  location: string;
  road_segment: string;
  city_regency: string;
  latitude: number;
  longitude: number;
  geog?: string | null;
  radius_meter: number;
  severity: HazardSeverity;
  hazard_type: string;
  weather_status: string;
  slope_gradient_deg: number;
  message: string;
  detour_route: string;
  detour_route_geojson: Record<string, unknown> | null;
  nearest_rescue_post: string;
  emergency_contact: string;
  triggered_by_admin: string | null;
  updated_at: string;
}
export type HazardZoneAlert = HazardAlert;

// ============================================================================
// 14. LOG SINKRONISASI SOS (sos_signals — Sekunder/Read-Audit Endpoint BE-1)
// ============================================================================
export interface SosSignal {
  id: string;
  sos_code: string;
  tourist_name: string;
  phone_number: string;
  emergency_type: string;
  destination_name?: string;
  city_regency?: string;
  latitude: number;
  longitude: number;
  battery_percent: number;
  passengers_count: number;
  nearest_corridor: string;
  nearest_rescue_post: string;
  distance_to_rescue_km: number;
  eta_rescue_minutes: number;
  status: SosStatus;
  notes: string;
  sar_unit_assigned?: string;
  is_offline_sync?: boolean;
  created_at: string;
}
export type SosEmergencyTicket = SosSignal;

// ============================================================================
// 15. MONITORING CUACA REAL-TIME (Open-Meteo Live)
// ============================================================================
export interface WeatherHourlyForecast {
  hour: string;
  temp_c: number;
  condition: string;
  rain_prob?: number;
}

export interface WeatherMonitoringItem {
  id: string;
  city_regency: string;
  destination_name: string;
  latitude: number;
  longitude: number;
  current_temp_c: number;
  condition: string;
  weather_status: 'Aman' | 'Waspada Hujan' | 'Siaga Cuaca Ekstrem';
  humidity_pct: number;
  wind_speed_kmh: number;
  rain_probability: number;
  hourly_forecast: WeatherHourlyForecast[];
  is_extreme_weather: boolean;
  extreme_warning_text?: string;
  source: 'Open-Meteo Live' | 'Regional Cache';
  updated_at: string;
}

// ============================================================================
// 16. KAMUS SAKU AUDIO MINANG (minang_phrases)
// ============================================================================
export interface MinangPhrase {
  id: string;
  category_id: string;
  category: MinangPhraseCategory;
  indonesian_text: string;
  english_text?: string;
  minang_text: string;
  phonetic_guide: string;
  voice_text: string;
  audio_url?: string;
  dialect_note: string;
  usage_context_tip: string;
  politeness_level: MinangPolitenessLevel | string;
  updated_at?: string;
}
export type MinangAudioPhrase = MinangPhrase;

// ============================================================================
// 17. KONTAK DARURAT RESMI SUMBAR (emergency_contacts — 6 Data Real 000004)
// ============================================================================
export interface EmergencyContact {
  id: string;
  agency_name: string;
  agency_type: EmergencyAgencyType;
  phone_number: string;
  whatsapp_number?: string | null;
  city_regency: string;
  address?: string;
  description?: string;
  is_24_hours: boolean;
  latitude: number;
  longitude: number;
  geog?: string;
  created_by_admin_id?: string;
  is_active: boolean;
  updated_at?: string;
}
export type EmergencyContactNumber = EmergencyContact;

// ============================================================================
// 18. KALENDER EVENT & FESTIVAL BUDAYA MINANG (cultural_events)
// ============================================================================
export interface CulturalEvent {
  id: string;
  user_id?: string;
  title: string;
  event_type: string;
  nagari_location: string;
  city_regency: string;
  schedule_rule: string;
  next_event_date: string;
  end_date?: string;
  time?: string;
  venue?: string;
  latitude: number;
  longitude: number;
  geog?: string | null;
  highlight_item: string;
  cultural_etiquette: string;
  tips?: string;
  rundown?: string[];
  poster_url?: string;
  organizer?: string;
  status: CultureEventStatus;
  updated_at?: string;
}
export type CultureCalendarEvent = CulturalEvent;

// ============================================================================
// 19. TEMPAT TERSIMPAN & CHECK-IN STEMP VISIT
// ============================================================================
export interface SavedPlace {
  id: string;
  user_id: string;
  destination_id: string;
  created_at: string | null;
}

export interface StempVisit {
  id: string;
  user_id: string;
  destination_id: string;
  passport_code?: string; // e.g. CHL-BKT-01
  checked_in_at: string | null;
  is_gps_valid: boolean;
}

export interface DigitalPassportSpot {
  code: string; // CHL-BKT-01 .. CHL-LBH-10
  destination_id: string;
  destination_title: string;
  region: string;
  icon_symbol: string;
  cultural_quote: string;
}

// ============================================================================
// 20. USULAN DESTINASI BARU (new_tour — Sinkron usul_destinasi_sheet.dart)
// ============================================================================
export interface NewTour {
  id: string;
  user_id?: string;
  name: string;
  category_id: string;
  category: MasterDestinationCategory | string;
  city_regency: string;
  description: string;
  latitude: number;
  longitude: number;
  tips_menjaga: string;
  facilities?: string[];
  estimated_price?: string;
  photo_url?: string;
  is_sensitive: boolean;
  status: NewTourStatus;
  submitter_name: string;
  submitter_phone: string;
  admin_notes?: string;
  merged_into_destination_id?: string;
  merged_role?: string;
  created_at: string;
}
export type TouristDestinationSubmission = NewTour;

// ============================================================================
// 21. TANTANGAN & KLAIM REWARD (challenges & user_challenge_rewards)
// ============================================================================
export interface Challenge {
  id: string;
  created_by_admin_id?: string;
  title: string;
  checkin_tagline?: string;
  category?: MasterDestinationCategory | string;
  description: string;
  target_destination_count: number;
  reward_title: string;
  reward_type: string;
  reward_points: number;
  duration_days?: number;
  target_destinations?: string[];
  target_checkpoints?: string[];
  participant_count?: number;
  completed_count?: number;
  is_active: boolean;
  created_at: string;
  updated_at?: string;
}
export type ChecklistChallenge = Challenge;
export type TouristChallenge = Challenge;

export interface UserChallengeReward {
  id: string;
  challenge_id: string;
  challenge_title?: string;
  user_id: string;
  tourist_name: string;
  tourist_phone: string;
  progress_count: number;
  target_destination_count: number;
  status: 'DALAM_PROGRES' | 'SIAP_KLAIM' | 'HADIAH_TERKIRIM';
  jenis_reward: string;
  reward: string;
  certificate_code?: string | null;
  certificate_url?: string | null;
  completed_at?: string | null;
  reward_notes?: string;
}
export type TouristChecklistClaim = UserChallengeReward;

// ============================================================================
// 22. 5 LEVEL PETUALANG & JEJAK WISGO (Paspor & Kunjungan Destinasi)
// ============================================================================
export type AdventurerLevelName =
  | 'Pemula'
  | 'Penjelajah'
  | 'Petualang'
  | 'Perintis'
  | 'Pengelana';

export interface AdventurerLevelConfig {
  level: 1 | 2 | 3 | 4 | 5;
  name: AdventurerLevelName;
  title: string;
  min_trips: number;
  min_checkpoints: number;
  min_xp: number;
  max_xp: number;
  badge_icon: string;
  badge_color: string;
  perk_description: string;
}

export interface JejakHistoryItem {
  id?: string;
  date: string;
  destination_id?: string;
  destination_name: string;
  city_regency?: string;
  checkpoint_name?: string;
  source: JejakWisgoSource;
  stamp_number: number;
  xp_earned: number;
  badge_title?: string;
  notes?: string;
  status: 'verified' | 'pending';
}

export interface UserProfileExperience {
  id: string;
  user_id: string;
  full_name: string;
  email: string;
  phone_number: string;
  google_avatar?: string;
  is_google_auth: boolean;
  current_level: 1 | 2 | 3 | 4 | 5;
  level_name: AdventurerLevelName;
  visited_count: number;
  total_trips: number;
  total_checkpoints: number;
  total_xp: number;
  last_active_at: string;
  experience_history: JejakHistoryItem[];
}

export interface PostingShareTemplate {
  id: string;
  template_name: string;
  watermark_text: string;
  qr_download_url: string;
  qr_image_url: string;
  background_banner_url: string;
  badge_placeholder_text: string;
  preview_mode: 'transparent_sticker' | 'full_card';
}

// ============================================================================
// 23. PENGGUNA, TRIP GO & PENYELENGGARA TERVERIFIKASI
// ============================================================================
export interface User {
  id: string;
  phone_number: string;
  full_name: string;
  role: 'admin' | 'admin_utama' | 'admin_dispar' | 'wisatawan' | 'mitra' | 'pokdarwis' | string;
  jenis_input?: string | null;
  created_at?: string | null;
  email?: string;
  agency?: string;
}

export type EscrowStatus =
  | 'DITAHAN_DI_ESCROW'
  | 'DICAIRKAN_KE_PENYELENGGARA'
  | 'DILAPORKAN_INSIDEN';

export type TripVerificationStatus = 'pending_admin' | 'approved' | 'rejected';

export type TripReadinessStage = 'jadwal' | 'persiapan' | 'barang_bawaan' | 'terfinalisasi';

export interface TripChatMessageItem {
  id: string;
  sender_name: string;
  sender_role: 'Host' | 'Peserta';
  message: string;
  timestamp: string;
  is_pinned_notice?: boolean;
}

export interface OpenTrip {
  id: string;
  user_id: string;
  title: string;
  singleDestination: string;
  destination_id: string;
  destination_name: string;
  destination_route: string;
  travel_category: MasterDestinationCategory;
  departure_date: string;
  available_seats: number;
  quota_filled?: number;
  cost_per_person: number;
  contact_wa: string;
  trip_leader_name: string;
  status: OpenTripStatus;
  meeting_point_name: string;
  meeting_point_address: string;
  meeting_point_lat: number;
  meeting_point_lng: number;
  meeting_point_gmaps_url: string;
  meeting_point_coords?: string;
  external_activity_terms: string;
  includes: string[];
  excludes: string[];
  sop_rules?: string[];
  verification_status?: TripVerificationStatus;
  verification_rejection_reason?: string;
  organizer_instagram?: string;
  is_hard_track?: boolean;
  organizer_ktp_uploaded?: boolean;
  organizer_license_number?: string;
  organizer_experience?: string;
  readiness_stage?: TripReadinessStage;
  is_finalized?: boolean;
  escrow_status: EscrowStatus;
  escrow_amount_idr: number;
  offline_rules: {
    title: string;
    ruleDescription: string;
    iconCode?: string;
  }[];
  organizer?: OpenTripOrganizer;
  trip_planner: {
    checklist: string[];
    jobdesk_assignments: { role: string; person_name: string }[];
    packing_checklist: string[];
    itinerary: { day: number; time: string; activity: string }[];
    messages?: TripChatMessageItem[];
  };
  created_at?: string | null;
}
export type OpenTripItem = OpenTrip;

export interface OpenTripOrganizer {
  id: string;
  name: string;
  agency_name: string;
  phone_number: string;
  phone?: string;
  doc_ktp_url?: string;
  doc_sk_pokdarwis_url?: string;
  doc_guide_cert_url?: string;
  status: 'Menunggu' | 'Terverifikasi' | 'Ditolak';
  submitted_at: string;
  verified_at?: string;
  notes?: string;
  is_verified?: boolean;
  verification_badge?: string;
  ktp_status?: string;
  ktp_upload_status?: string;
  face_verification_status?: string;
  license_number?: string;
  special_competency?: string;
  rating?: number;
  completed_trips?: number;
  social_media?: string;
  experience_years?: string;
  escrow_protection_note?: string;
}

export interface OpenTripTransaction {
  id: string;
  transaction_code: string;
  trip_id: string;
  trip_title: string;
  participant_name: string;
  participant_phone: string;
  seats_booked: number;
  amount_idr: number;
  payment_channel: 'QRIS' | 'WISGO_PAY' | 'VIRTUAL_ACCOUNT' | string;
  status: 'BERHASIL' | 'MENUNGGU' | 'REFUND';
  eticket_code?: string;
  eticket_issued_at?: string;
  paid_at: string;
}

export interface PackingTemplate {
  id: string;
  category_name: MasterDestinationCategory | string;
  item_name: string;
  is_mandatory: boolean;
  notes?: string;
}

// ============================================================================
// 24. NOTIFIKASI, AUTH, HEATMAP, BENCHMARK & GRUP
// ============================================================================
export interface Notifikasi {
  id: string;
  user_id?: string;
  notification_type?:
    | 'review_moderation'
    | 'new_tour_rejected'
    | 'pungli_action'
    | 'system'
    | string;
  title: string;
  message: string;
  reference_id?: string | null;
  is_read?: boolean;
  created_at: string;
  type?: string;
  broadcasted_at?: string;
  is_delivered?: boolean;
  target?: string;
  ref_id?: string;
}
export type SystemNotification = Notifikasi;

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

export interface BenchmarkRunResult {
  run_id: string;
  timestamp: string;
  concurrency: number;
  total_requests: number;
  latency_ms: number;
  latency_p50_ms: number;
  latency_p95_ms: number;
  latency_p99_ms: number;
  throughput_qps: number;
  error_rate_pct: number;
  memory_usage_mb: number;
  status: 'OPTIMAL' | 'NORMAL' | 'WARNING';
}

export interface SystemBenchmarkMetrics {
  server_uptime_pct: number;
  api_response_time_ms: number;
  go_engine_latency_ms: number;
  postgres_spatial_query_ms: number;
  panorama_load_speed_sec: number;
  database_connection_pool: string;
  cache_hit_rate_pct: number;
  backend_version: string;
  memory_allocated_mb: number;
  requests_per_second: number;
  last_stress_test_date: string;
  system_status: 'OPERATIONAL' | 'DEGRADED' | 'MAINTENANCE';
  benchmark_history: BenchmarkRunResult[];
}

// ============================================================================
// 26. BERITA WISATA & BENCANA SUMBAR (Sinkron FE-1 hazard_sos_screen.dart)
// ============================================================================
export type SosNewsCategory =
  | 'Bencana & Vulkanologi'
  | 'Cuaca & Bahari'
  | 'Akses Wisata'
  | 'Info Jalur & Bencana';

export type SosNewsSeverity = 'INFO WISATA' | 'WASPADA' | 'SIAGA HUJAN' | 'DARURAT';

export interface SosNewsItem {
  id: string;
  category: SosNewsCategory;
  severity: SosNewsSeverity;
  title: string;
  region: string;
  summary: string;
  advice: string;
  source: string;
  is_published: boolean;
  published_at: string;
}

// ============================================================================
// 27. POI SEARAH RUTE (SHUNLU) (Sinkron FE-1 map_explore_pois_data.dart)
// ============================================================================
export type ShunluPoiCategory = 'RM Padang' | 'SPBU' | 'Masjid' | 'ATM & Bengkel';

export interface ShunluPoiItem {
  id: string;
  category: ShunluPoiCategory;
  name: string;
  detour: string;
  route: string;
  latitude: number;
  longitude: number;
  address: string;
  is_active: boolean;
}
