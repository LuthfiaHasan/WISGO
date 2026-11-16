// ============================================================================
// KONTRAK JSON & INTERFACE TYPESCRIPT RESMI RANCAK.IN SUMATERA BARAT
// Sinkron dengan backend/internal/models/models.go, be1_core & be2_group
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
 * Hotspot360 pin interaktif 4 jenis pada kanvas 360
 * Sinkron dengan models.Hotspot360
 */
export interface Hotspot360 {
  id: string;
  scene_id: string;
  type: 'navigasi' | 'audio' | 'fasilitas' | 'mitra';
  pitch: number;
  yaw: number;
  title: string;
  target_ref?: string;
  audio_url?: string;
  description?: string;
}

/**
 * Scene360 representasi scene tur imersif aerial & ground
 * Sinkron dengan models.Scene360
 */
export interface Scene360 {
  id: string;
  destination_id: string;
  title: string;
  type: 'aerial' | 'ground';
  panorama_url: string;
  initial_pitch: number;
  initial_yaw: number;
  hotspots?: Hotspot360[];
}

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
  scenes_360?: Scene360[];           // json:"scenes_360,omitempty"
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

export interface Partner {
  id: string;                        // json:"id"
  name: string;                      // json:"name"
  category: PartnerCategoryType | string; // json:"category"
  whatsapp: string;                  // json:"whatsapp"
  spicy_level?: number;              // json:"spicy_level,omitempty" (0-5)
  is_verified: boolean;              // json:"is_verified"
  standard_fee: number;              // json:"standard_fee"
  nagari_name: string;               // json:"nagari_name"
  destination_id?: string;
}

export type PartnerNagari = Partner;

// --- Kontrak Tambahan BE-1 & BE-2 ---

export interface ShunluSearchResponse {
  query: string;
  detour_time_min: number;
  detour_distance: string;
  recommended: string;
}

export type PungliStatus = 'Masuk' | 'Diverifikasi' | 'Ditindaklanjuti' | 'Selesai';

export interface PungliReport {
  id: string;
  destination_id: string;
  reporter_name: string;
  photo_evidence: string;
  latitude: number;
  longitude: number;
  description: string;
  status: PungliStatus;
  created_at: string;
}

export interface PungliReportResponse {
  status: string;
  ticket: string;
  message: string;
}

export interface HazardAlert {
  id: string;
  location: string;
  severity: 'Siaga' | 'Waspada' | 'Awas' | 'Tutup Total';
  message: string;
  detour_route: string;
  updated_at: string;
}

export interface User {
  id: string;
  phone_number: string;
  full_name: string;
  role: 'tourist' | 'partner' | 'admin_dispar' | 'satgas_pungli';
  created_at: string;
}

export interface AdminAuthCredentials {
  email: string;
  password: string;
  role?: 'admin_dispar' | 'satgas_pungli';
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

export interface GroupRoom {
  id: string;
  room_code: string;
  title: string;
  leader_id?: string;
  created_at?: string;
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
