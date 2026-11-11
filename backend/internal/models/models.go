package models

import (
	"time"
)

// --- Domain Models BE-1: Core & Spasial (Pilar 1, 2, 3, 7) ---

// Destination merepresentasikan destinasi wisata di Sumatera Barat
type Destination struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Category    string    `json:"category"` // Alam, Budaya, Kuliner, Sejarah
	CityRegency string    `json:"city_regency"` // 19 Kab/Kota Sumbar
	Description string    `json:"description"`
	Latitude    float64   `json:"latitude"`
	Longitude   float64   `json:"longitude"`
	CoverImage  string    `json:"cover_image"`
	CrowdLevel  string    `json:"crowd_level"` // Sepi, Sedang, Ramai
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Relasi
	MedanIndicator *MedanIndicator `json:"medan_indicator,omitempty"`
	Tips           []LocalTip       `json:"tips,omitempty"`
	Tariffs        []OfficialTariff `json:"tariffs,omitempty"`
	Scenes360      []Scene360       `json:"scenes_360,omitempty"`
}

// MedanIndicator memuat 5 Indikator Medan Lapangan
type MedanIndicator struct {
	ID             string `json:"id"`
	DestinationID  string `json:"destination_id"`
	VehicleAccess  string `json:"vehicle_access"`  // Mobil OK, Hanya Motor, Jalan Kaki
	TrekkingLevel  string `json:"trekking_level"`  // Datar / Mudah, Sedang, Curam / Ekstrem
	CellularSignal string `json:"cellular_signal"` // 4G Kuat, Sinyal Lemah, Blank Spot
	Facilities     string `json:"facilities"`      // Toilet & Musala Lengkap, Terbatas, Belum Ada
	GuideNeed      string `json:"guide_need"`       // Wajib Pemandu, Disarankan, Mandiri
}

// LocalTip tips etika menjaga alam & kelestarian (khususnya hidden gem)
type LocalTip struct {
	ID            string `json:"id"`
	DestinationID string `json:"destination_id"`
	Content       string `json:"content"`
	IsImportant   bool   `json:"is_important"`
}

// OfficialTariff tabel Fair-Price Barometer (Perda / Nagari)
type OfficialTariff struct {
	ID            string  `json:"id"`
	DestinationID string  `json:"destination_id"`
	ItemName      string  `json:"item_name"` // Tiket Masuk, Parkir Motor, Parkir Mobil, Sewa Bendi
	Price         float64 `json:"price"`
	Unit          string  `json:"unit"`      // per orang, per kendaraan, per jam
	RegulationRef string  `json:"regulation_ref"` // No Perda / Peraturan Nagari
}

// Scene360 representasi scene tur imersif aerial & ground
type Scene360 struct {
	ID            string            `json:"id"`
	DestinationID string            `json:"destination_id"`
	Title         string            `json:"title"`
	Type          string            `json:"type"` // aerial (100-200m), ground (gerbang/spot utama)
	PanoramaURL   string            `json:"panorama_url"`
	InitialPitch  float64           `json:"initial_pitch"`
	InitialYaw    float64           `json:"initial_yaw"`
	Hotspots      []Hotspot360      `json:"hotspots,omitempty"`
}

// Hotspot360 pin interaktif 4 jenis pada kanvas 360
type Hotspot360 struct {
	ID          string  `json:"id"`
	SceneID     string  `json:"scene_id"`
	Type        string  `json:"type"` // navigasi (biru), audio (emas), fasilitas (hijau), mitra (oranye)
	Pitch       float64 `json:"pitch"`
	Yaw         float64 `json:"yaw"`
	Title       string  `json:"title"`
	TargetRef   string  `json:"target_ref,omitempty"` // ID Scene tujuan atau ID Mitra Nagari
	AudioURL    string  `json:"audio_url,omitempty"`
	Description string  `json:"description,omitempty"`
}

// PungliReport laporan pungli / fasilitas rusak dari wisatawan ke Satgas
type PungliReport struct {
	ID            string    `json:"id"`
	DestinationID string    `json:"destination_id"`
	ReporterName  string    `json:"reporter_name"` // Boleh Anonim
	PhotoEvidence string    `json:"photo_evidence"`
	Latitude      float64   `json:"latitude"`
	Longitude     float64   `json:"longitude"`
	Description   string    `json:"description"`
	Status        string    `json:"status"` // Masuk, Diverifikasi, Ditindaklanjuti, Selesai
	CreatedAt     time.Time `json:"created_at"`
}

// HazardAlert alert jalur rawan bencana (Sitinjau Lauik, Lembah Anai, Kelok 9)
type HazardAlert struct {
	ID          string    `json:"id"`
	Location    string    `json:"location"`
	Severity    string    `json:"severity"` // Siaga, Waspada, Awas, Tutup Total
	Message     string    `json:"message"`
	DetourRoute string    `json:"detour_route"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// --- Domain Models BE-2: Grup, Mitra, Escrow & Komunitas (Pilar 4, 5, 6, 8) ---

// User profil pengguna / wisatawan
type User struct {
	ID          string    `json:"id"`
	PhoneNumber string    `json:"phone_number"`
	FullName    string    `json:"full_name"`
	Role        string    `json:"role"` // tourist, partner, admin_dispar, satgas_pungli
	CreatedAt   time.Time `json:"created_at"`
}

// GroupRoom ruang perjalanan bersama untuk koordinasi rombongan
type GroupRoom struct {
	ID        string    `json:"id"`
	RoomCode  string    `json:"room_code"` // Unik, dibagikan via link WA
	Title     string    `json:"title"`
	LeaderID  string    `json:"leader_id"`
	CreatedAt time.Time `json:"created_at"`
}

// GroupVote hasil pemungutan suara destinasi di dalam rombongan
type GroupVote struct {
	ID            string `json:"id"`
	GroupRoomID   string `json:"group_room_id"`
	UserID        string `json:"user_id"`
	DestinationID string `json:"destination_id"`
	VoteType      string `json:"vote_type"` // upvote / downvote
}

// PartnerNagari 5 kategori mitra lokal (Homestay, Transport, Pokdarwis, Kuliner, Baju Adat)
type PartnerNagari struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Category    string  `json:"category"`
	WhatsApp    string  `json:"whatsapp"`
	SpicyLevel  int     `json:"spicy_level,omitempty"` // Khusus kuliner (0-5)
	IsVerified  bool    `json:"is_verified"`
	StandardFee float64 `json:"standard_fee"`
	NagariName  string  `json:"nagari_name"`
}

// BookingEscrow transaksi rekening bersama terhubung bot WA
type BookingEscrow struct {
	ID           string    `json:"id"`
	PartnerID    string    `json:"partner_id"`
	UserID       string    `json:"user_id"`
	TotalAmount  float64   `json:"total_amount"`
	Currency     string    `json:"currency"` // IDR / MYR
	Status       string    `json:"status"`   // PENDING_WA, CONFIRMED, ESCROW_LOCKED, REDEEMED, REFUNDED
	QRCodeTicket string    `json:"qr_code_ticket"`
	CreatedAt    time.Time `json:"created_at"`
}

// DigitalPassport stempel check-in anti-fake GPS (radius <= 200m)
type DigitalPassport struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	DestinationID string    `json:"destination_id"`
	CheckedInAt   time.Time `json:"checked_in_at"`
	IsGPSValid    bool      `json:"is_gps_valid"`
}

