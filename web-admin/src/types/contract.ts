// ============================================================================
// KONTRAK JSON & INTERFACE TYPESCRIPT RESMI WISGO SUMATERA BARAT
// Ekosistem Wisata Pintar Sumatera Barat — Dinas Pariwisata Prov. Sumbar
// Sinkron dengan backend/internal/models/models.go, be1_core & be2_group
// Arsitektur: Single Admin (Pusat Komando Terpadu Dispar • Pungli • Siaga SAR)
// ============================================================================

export type CrowdLevel = 'Sepi' | 'Sedang' | 'Ramai';

export type VehicleAccessType =
  | 'Mobil OK'
  | 'Hanya Motor'
  | 'Jalan Kaki'
  | 'Jalan Kaki Saja';

export type TrekkingLevelType =
  | 'Landai / Mudah'
  | 'Datar / Mudah'
  | 'Mudah (Datar)'
  | 'Sedang'
  | 'Curam / Ekstrem'
  | 'Ekstrem (Curam)';

export type CellularSignalType =
  | '4G Lancar'
  | '4G Kuat'
  | 'Sinyal Lemah'
  | 'Zero-Signal (Blank Spot)'
  | 'Blank Spot'
  | 'Blank Spot (Zero-Signal)';

export type FacilitiesType =
  | 'Toilet, Musala & Parkir Lengkap'
  | 'Toilet & Musala Lengkap'
  | 'Ada Toilet & Musala'
  | 'Terbatas'
  | 'Belum Ada';

export type GuideNeedType =
  | 'Wajib Pemandu'
  | 'Wajib Pemandu Lokal'
  | 'Disarankan'
  | 'Mandiri'
  | 'Bisa Mandiri';

export type TariffCategoryType =
  | 'Tiket Masuk'
  | 'Parkir Kendaraan'
  | 'Jasa Pemandu/Kapal'
  | 'Kuliner/Fasilitas';

/**
 * MedanIndicator memuat 5 Indikator Kesiapan Medan Lapangan
 * Sinkron dengan models.MedanIndicator (backend/internal/models/models.go)
 */
export interface MedanIndicator {
  id: string;
  destination_id: string;
  vehicle_access: VehicleAccessType | string;   // json:"vehicle_access"
  trekking_level: TrekkingLevelType | string;   // json:"trekking_level"
  cellular_signal: CellularSignalType | string; // json:"cellular_signal"
  facilities: FacilitiesType | string;          // json:"facilities"
  guide_need: GuideNeedType | string;           // json:"guide_need"

  // Skor kesiapan visual (1-5) & catatan operasional lapangan
  vehicle_score?: number;
  trekking_score?: number;
  signal_score?: number;
  facilities_score?: number;
  guide_score?: number;
  readiness_notes?: string;
}

/**
 * DestinationTip (LocalTip di Go) memuat tips etika adat & kelestarian alam
 * Sinkron dengan models.LocalTip (backend/internal/models/models.go)
 */
export interface DestinationTip {
  id: string;
  destination_id: string;
  content: string;       // json:"content"
  is_important: boolean; // json:"is_important"
}

export type LocalTip = DestinationTip;

/**
 * OfficialTariff tabel Fair-Price Barometer (Perda / SK Nagari)
 * Sinkron dengan models.OfficialTariff (backend/internal/models/models.go)
 */
export interface OfficialTariff {
  id: string;
  destination_id: string;
  item_name: string;      // json:"item_name"
  category?: TariffCategoryType | string; // Kategori item tarif
  price: number;          // json:"price" (Harga Resmi IDR)
  fair_price_min?: number; // Batas Bawah Harga Wajar (IDR)
  fair_price_max?: number; // Batas Atas Harga Wajar (IDR)
  unit: string;           // json:"unit" (per orang, per unit, per jam, per kendaraan)
  regulation_ref: string; // json:"regulation_ref" (No Perda / Peraturan Nagari)
}

/**
 * 4 Kategori Pin Hotspot Kanvas 360°
 */
export type HotspotPinCategory =
  | 'info_adat'      // Pin Info Adat/Sejarah (Emas/Kuning)
  | 'navigasi'       // Pin Navigasi Pindah Scene (Biru)
  | 'audio_budaya'   // Pin Spatial Audio/Narasi (Ungu/Indigo)
  | 'mitra_umkm';    // Pin Katalog/Booking Mitra UMKM (Oranye)

/**
 * HotspotPin / Hotspot360 pada Kanvas 360°
 * Mendukung koordinat visual pitch (-90 s.d. 90) dan yaw (-180 s.d. 180)
 */
export interface HotspotPin {
  id: string;
  scene_id: string;
  category: HotspotPinCategory;
  title: string;
  description?: string;
  pitch: number; // Sudut vertikal (-90 s.d. 90 derajat atau persen posisi visual)
  yaw: number;   // Sudut horizontal (-180 s.d. 180 derajat atau persen posisi visual)
  target_scene_id?: string; // Untuk pin navigasi pindah scene
  audio_url?: string;        // Untuk pin audio budaya / narasi Minang
  partner_id?: string;       // Untuk pin mitra UMKM
  partner_name?: string;
  partner_fee?: number;

  // Backwards compatibility
  type?: 'navigasi' | 'audio' | 'fasilitas' | 'mitra';
  target_ref?: string;
}

export type Hotspot360 = HotspotPin;

/**
 * PanoramaScene / Scene360 representasi scene tur imersif aerial & ground
 * Sinkron dengan models.Scene360
 */
export interface PanoramaScene {
  id: string;
  destination_id: string;
  title: string;
  type: 'aerial' | 'ground';
  panorama_url: string;
  initial_pitch: number;
  initial_yaw: number;
  ambient_audio_url?: string;
  hotspots?: HotspotPin[];
}

export type Scene360 = PanoramaScene;

/**
 * Destination merepresentasikan destinasi wisata di Sumatera Barat
 * Sinkron dengan models.Destination & be1_core/handlers.go
 */
export interface Destination {
  id: string;                        // json:"id"
  slug?: string;                     // Slug URL untuk Plang Smart QR (/qr/:destinationSlug)
  name: string;                      // json:"name"
  category: string;                  // json:"category"
  city_regency: string;              // json:"city_regency" (19 Kab/Kota Sumbar)
  description: string;               // json:"description"
  latitude: number;                  // json:"latitude"
  longitude: number;                 // json:"longitude"
  cover_image: string;               // json:"cover_image"
  crowd_level: CrowdLevel | string;  // json:"crowd_level" (Sepi, Sedang, Ramai)
  created_at: string;                // json:"created_at"
  updated_at: string;                // json:"updated_at"

  // 4 Statistik Keputusan di Paruh Atas Layar & Status Offline Pocket
  estimated_distance_km?: number;    // Estimasi jarak dari pusat kota/bandara (km)
  estimated_duration_min?: number;   // Estimasi waktu tempuh (menit)
  ticket_price_summary?: string;     // Ringkasan biaya tiket masuk
  is_blank_spot?: boolean;           // Sakelar Kawasan Blank Spot (Wajib Unduh Offline Pocket)

  // Relasi (omitempty di Go)
  medan_indicator?: MedanIndicator;  // json:"medan_indicator,omitempty"
  tips?: DestinationTip[];           // json:"tips,omitempty"
  tariffs?: OfficialTariff[];        // json:"tariffs,omitempty"
  scenes_360?: PanoramaScene[];      // json:"scenes_360,omitempty"
}

/**
 * Partner (PartnerNagari di Go) 5 kategori mitra UMKM lokal nagari
 * Sinkron dengan models.PartnerNagari (backend/internal/models/models.go)
 */
export type PartnerCategoryType =
  | 'Homestay Rumah Gadang'
  | 'Kapal & Transportasi'
  | 'Pemandu Pokdarwis'
  | 'Kuliner Halal'
  | 'Sewa Baju Adat';

export interface EscrowTransaction {
  id: string;
  booking_code: string;
  tourist_name: string;
  tourist_phone: string;
  amount: number;
  fee_currency: 'IDR' | 'MYR';
  status: 'ESCROW_LOCKED' | 'READY_PAYOUT' | 'REDEEMED';
  wa_status: 'CONFIRMED' | 'PENDING' | 'REJECTED';
  service_date: string;
  created_at: string;
}

export interface Partner {
  id: string;                        // json:"id"
  name: string;                      // json:"name"
  category: PartnerCategoryType | string; // json:"category"
  whatsapp: string;                  // json:"whatsapp"
  spicy_level?: number;              // json:"spicy_level,omitempty" (0-5 cabai)
  is_verified: boolean;              // json:"is_verified"
  standard_fee: number;              // json:"standard_fee" (IDR)
  fee_myr_estimate?: number;         // Estimasi konversi Ringgit Malaysia (MYR)
  nagari_name: string;               // json:"nagari_name"
  city_regency?: string;             // 19 Kab/Kota Sumbar
  owner_name?: string;               // Nama pemilik usaha / pengelola
  pokdarwis_sk_number?: string;      // Nomor Surat Keputusan verifikasi Pokdarwis/Nagari
  photo_url?: string;                // Foto profil / produk mitra (unggah device)
  photo_360_url?: string;            // Foto panorama spot 360 mitra
  destination_id?: string;           // Keterkaitan dengan destinasi
  destination_name?: string;
  scene_id?: string;                 // Keterkaitan dengan scene 360
  pin_id?: string;                   // ID pin di Studio 360
  pitch?: number;                    // Koordinat vertikal pin di scene 360
  yaw?: number;                      // Koordinat horizontal pin di scene 360
  has_360_pin?: boolean;             // Penanda apakah mitra memiliki pin aktif di tur 360
  halal_certified?: boolean;         // Sertifikat Halal MUI / Kemenag
  created_at?: string;
  ledger?: EscrowTransaction[];      // Riwayat transaksi buku besar escrow
}

export type PartnerNagari = Partner;

// ============================================================================
// PUSAT KOMANDO TERPADU: PENINDAKAN PUNGLI & SIAGA SOS TIM SAR (FS1-M2-03)
// ============================================================================

export type PungliCategoryType =
  | 'Parkir Liar'
  | 'Tiket Di Atas Perda'
  | 'Pemaksaan Pemandu/Kapal'
  | 'Fasilitas Rusak';

export type PungliStatus =
  | 'Laporan Baru'
  | 'Sedang Diverifikasi'
  | 'Ditindaklanjuti Lapangan'
  | 'Selesai';

/**
 * PungliReport tiket laporan aduan pungli / pelanggaran tarif dari wisatawan
 * Sinkron dengan models.PungliReport
 */
export interface PungliReport {
  id: string;
  destination_id: string;
  destination_name: string;
  kab_kota: string;
  reporter_name: string;
  reporter_phone: string;
  category: PungliCategoryType;
  reported_amount: number;       // Nominal yang dipungut oknum (IDR)
  official_amount: number;       // Nominal resmi sesuai Perda (IDR)
  description: string;
  photo_url: string;             // Bukti foto karcis / bukti lokasi
  lat: number;
  lng: number;
  status: PungliStatus;
  admin_notes?: string;          // Catatan tindakan resmi dari Admin
  created_at: string;

  // Backwards compatibility
  photo_evidence?: string;
  latitude?: number;
  longitude?: number;
}

export interface PungliReportResponse {
  status: string;
  ticket: string;
  message: string;
}

export type SosEmergencyStatus =
  | 'Sinyal SOS Masuk'
  | 'Tim SAR Dikerahkan'
  | 'Evakuasi Berjalan'
  | 'Penanganan Selesai';

/**
 * SosEmergencyTicket tiket sinyal darurat SOS GPS dari wisatawan di lapangan
 */
export interface SosEmergencyTicket {
  id: string;
  tourist_name: string;
  tourist_phone: string;
  destination_name: string;
  kab_kota: string;
  lat: number;
  lng: number;
  battery_level: number;        // Sisa baterai HP wisatawan (1-100%)
  signal_status: string;        // Status koneksi (4G / Zero-Signal / Satelit Mesh)
  medical_notes: string;        // Catatan medis/kondisi (misal: terkilir, tersesat kabut, butuh tandu)
  status: SosEmergencyStatus;
  sar_unit_assigned?: string;   // Unit SAR/BPBD/Pokdarwis yang ditugaskan
  created_at: string;
}

export type HazardSeverity =
  | 'Aman Terkendali'
  | 'Waspada Bencana'
  | 'Buka-Tutup Jalur'
  | 'Tutup Total';

/**
 * HazardZoneAlert alert jalur ekstrem rawan bencana (Sitinjau Lauik, Lembah Anai, Kelok 9)
 * Sinkron dengan models.HazardAlert
 */
export interface HazardZoneAlert {
  id: string;
  location: string;
  severity: HazardSeverity;
  message: string;
  detour_route: string;
  updated_at: string;
}

export type HazardAlert = HazardZoneAlert;

// ============================================================================
// WEB GROUP INVITE & PRIVATE GROUP ROOM (FS1-M2-04)
// ============================================================================

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

// ============================================================================
// AUTENTIKASI SINGLE ADMIN & LAINNYA
// ============================================================================

export interface User {
  id: string;
  phone_number: string;
  full_name: string;
  role: 'admin_utama' | 'admin_dispar' | 'satgas_pungli' | 'tourist' | 'partner';
  created_at: string;
}

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

export interface OTPRequestResponse {
  status: string;
  message: string;
}

export interface WAWebhookResponse {
  action: '1' | '0';
  status: 'CONFIRMED' | 'REJECTED';
  ticket_qr?: string;
  escrow_info: string;
}

export interface BookingEscrow {
  id: string;
  partner_id: string;
  user_id: string;
  total_amount: number;
  currency: 'IDR' | 'MYR';
  status: 'PENDING_WA' | 'CONFIRMED' | 'ESCROW_LOCKED' | 'REDEEMED' | 'REFUNDED';
  qr_code_ticket: string;
  created_at: string;
}

// ============================================================================
// ANALITIK EKSEKUTIF, HEATMAP 19 KAB/KOTA & KURASI KOMUNITAS (MINGGU 3 & 4)
// ============================================================================

export type RegencyCrowdStatus = 'Sepi' | 'Sedang' | 'Ramai' | 'Overload';

export interface RegencyHeatmapData {
  id: string;
  name: string;           // Nama 19 Kab/Kota Sumbar
  code: string;
  crowd_status: RegencyCrowdStatus;
  visitor_count_week: number;
  domestic_pct: number;
  foreign_myr_pct: number;
  top_destination: string;
  escrow_circulation: number; // IDR perputaran dana mitra di kab/kota ini
}

export type ModerationStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export interface CommunityHiddenGemSubmission {
  id: string;
  title: string;
  pokdarwis_name: string;
  city_regency: string;
  category: string;
  description: string;
  latitude: number;
  longitude: number;
  is_masked: boolean;     // Sakelar Masking Koordinat Lokasi Sensitif (Wajib Pemandu Pokdarwis)
  status: ModerationStatus;
  submitted_at: string;
  reviewer_notes?: string;
}

export interface DigitalPassportMetrics {
  total_gps_checkins_verified: number; // Check-in GPS radius <= 200m
  total_governor_certificates_issued: number; // Sertifikat Digital Gubernur diunduh
  top_nagari_escrow: { nagari: string; amount: number }[];
  escrow_by_category: { category: PartnerCategoryType; total_amount: number; count: number }[];
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

// ============================================================================
// KAMUS SAKU AUDIO MINANG (USE CASE ADMIN DISPAR)
// ============================================================================

export type MinangPhraseCategory =
  | 'Belanja & Menawar'
  | 'Salam & Sapaan'
  | 'Arah & Navigasi'
  | 'Kuliner'
  | 'Darurat & Bantuan';

export interface MinangAudioPhrase {
  id: string;
  phrase: string;              // Frasa Minang asli, e.g. "Bara ko ciek, Da?"
  pronunciation: string;       // Cara baca / pelafalan fonetik, e.g. "Bara ko ci-ek, Da?"
  meaning_id: string;          // Arti Bahasa Indonesia
  meaning_en: string;          // Arti Bahasa Inggris
  category: MinangPhraseCategory;
  audio_url?: string;          // Data URL audio MP3 atau path
  notes?: string;              // Konteks adat / etika pemakaian
  updated_at: string;
}

// ============================================================================
// KALENDER BUDAYA SUMATERA BARAT (19 KAB/KOTA)
// ============================================================================

export type CultureEventCategory =
  | 'Upacara Tradisi'
  | 'Festival Seni & Musik'
  | 'Atraksi Adat'
  | 'Wisata Alam & Olahraga';

export type CultureEventStatus =
  | 'Akan Datang'
  | 'Sedang Berlangsung'
  | 'Selesai';

export interface CultureCalendarEvent {
  id: string;
  title: string;               // Nama Festival / Acara Budaya
  city_regency: string;        // 19 Kab/Kota
  location: string;            // Lokasi spesifik
  start_date: string;          // YYYY-MM-DD
  end_date: string;            // YYYY-MM-DD
  category: CultureEventCategory;
  description: string;         // Deskripsi dan filosofi adat
  poster_url: string;          // Foto poster festival (dari device)
  organizer: string;           // Dinas Pariwisata / Kerapatan Adat Nagari (KAN)
  status: CultureEventStatus;
  updated_at: string;
}

// ============================================================================
// REKALKULASI GAODE RANKING DESTINASI WISATA SUMBAR
// ============================================================================

export interface GaodeWeightConfig {
  satisfaction_weight: number; // Persentase bobot kepuasan (default 35%)
  pungli_free_weight: number;   // Persentase bobot bebas pungli (default 30%)
  medan_access_weight: number;  // Persentase bobot aksesibilitas medan (default 20%)
  visit_volume_weight: number;  // Persentase bobot volume kunjungan (default 15%)
}

export interface GaodeRankingItem {
  id: string;
  destination_id: string;
  name: string;
  city_regency: string;
  category: string;
  weekly_visits: number;
  avg_dwell_hours: number;
  satisfaction_rate: number;    // % (misal 96.5)
  pungli_free_index: number;    // % (misal 98.2)
  medan_score: number;          // 1 - 5
  calculated_gaode_score: number; // 0 - 100
  previous_rank: number;
  current_rank: number;
  trend: 'up' | 'down' | 'same';
}

// ============================================================================
// PANTAU OPEN TRIP / CARI BARENGAN WISATAWAN
// ============================================================================

export type OpenTripStatus =
  | 'Menunggu Kuota'
  | 'Terkonfirmasi & Siaga'
  | 'Berjalan'
  | 'Ditangguhkan';

export interface OpenTripItem {
  id: string;
  trip_code: string;            // e.g. "TRIP-HARAU-042"
  title: string;                // e.g. "Eksplor Lembah Harau & Kelok 9"
  destination_routes: string[]; // e.g. ["Lembah Harau", "Kelok 9", "Istano Basa Pagaruyung"]
  city_regency: string;
  leader_name: string;          // Ketua Rombongan / Pemandu Pokdarwis
  leader_phone: string;
  pokdarwis_partner: string;    // Pokdarwis Pendamping Nagari
  departure_date: string;       // YYYY-MM-DD
  duration_days: number;        // Durasi hari
  quota_max: number;            // Kuota maks (misal 12)
  quota_filled: number;         // Kuota terisi (misal 9)
  split_bill_idr: number;       // Biaya patungan per orang (IDR)
  split_bill_myr: number;       // Biaya patungan per orang (MYR)
  status: OpenTripStatus;
  notes?: string;
  created_at: string;
}

// ============================================================================
// HEALTH & BENCHMARK SISTEM ENDPOINT
// ============================================================================

export interface BenchmarkRunResult {
  total_requests: number;
  concurrency: number;
  latency_p50_ms: number;
  latency_p95_ms: number;
  latency_p99_ms: number;
  error_rate_pct: number;
  throughput_qps: number;
  timestamp: string;
}

export interface SystemBenchmarkMetrics {
  server_status: 'ONLINE' | 'STANDBY_LOCAL';
  backend_version: string;
  go_engine_latency_ms: number;
  postgres_spatial_query_ms: number; // < 100ms PostGIS ST_DWithin
  offline_360_bundle_speed_sec: number;
  rate_limit_status: string;
  memory_allocated_mb: number;
  requests_per_second: number;
  last_benchmark_time?: string;
  benchmark_history: BenchmarkRunResult[];
}


