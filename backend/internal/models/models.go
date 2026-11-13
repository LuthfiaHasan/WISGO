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

// SavedPlace bookmark tempat favorit wisatawan (Pilar 3 & Layar 04)
type SavedPlace struct {
	ID            string       `json:"id"`
	UserID        string       `json:"user_id"`
	DestinationID string       `json:"destination_id"`
	CreatedAt     time.Time    `json:"created_at"`
	Destination   *Destination `json:"destination,omitempty"`
}

// Itinerary master rencana perjalanan (Pilar 4 & Layar 06)
type Itinerary struct {
	ID          string          `json:"id"`
	UserID      string          `json:"user_id"`
	Title       string          `json:"title"`
	StartDate   string          `json:"start_date"` // format YYYY-MM-DD
	EndDate     string          `json:"end_date"`
	TotalDays   int             `json:"total_days"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
	Items       []ItineraryItem `json:"items,omitempty"`
}

// ItineraryItem rincian per jam & destinasi per hari dalam trip
type ItineraryItem struct {
	ID            string       `json:"id"`
	ItineraryID   string       `json:"itinerary_id"`
	DayNumber     int          `json:"day_number"` // Hari ke 1 - 7
	TimeSlot      string       `json:"time_slot"`  // Contoh "09:00"
	DestinationID string       `json:"destination_id"`
	Notes         string       `json:"notes,omitempty"`
	TrafficAlert  string       `json:"traffic_alert,omitempty"` // Contoh "Pasar Koto Baru Macet"
	Destination   *Destination `json:"destination,omitempty"`
}

// GroupRoom ruang perjalanan bersama untuk koordinasi rombongan
type GroupRoom struct {
	ID        string        `json:"id"`
	RoomCode  string        `json:"room_code"` // Unik, dibagikan via link WA
	Title     string        `json:"title"`
	LeaderID  string        `json:"leader_id"`
	CreatedAt time.Time     `json:"created_at"`
	Members   []GroupMember `json:"members,omitempty"`
}

// GroupMember anggota dalam group room
type GroupMember struct {
	ID          string    `json:"id"`
	GroupRoomID string    `json:"group_room_id"`
	UserID      string    `json:"user_id"`
	Role        string    `json:"role"` // leader, member
	JoinedAt    time.Time `json:"joined_at"`
	User        *User     `json:"user,omitempty"`
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

// CommunityPlace tempat baru usulan komunitas (Pilar 6)
type CommunityPlace struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"`
	Name        string    `json:"name"`
	Category    string    `json:"category"`
	CityRegency string    `json:"city_regency"`
	Description string    `json:"description"`
	Latitude    float64   `json:"latitude"`
	Longitude   float64   `json:"longitude"`
	TipsMenjaga string    `json:"tips_menjaga"` // Wajib diisi untuk kelestarian alam
	IsSensitive bool      `json:"is_sensitive"` // Proteksi radius perkiraan hingga dikurasi Pokdarwis
	Status      string    `json:"status"`       // PENDING_CURATION, APPROVED, REJECTED
	CreatedAt   time.Time `json:"created_at"`
}

// SharedTrip papan tebengan / cari barengan sewa armada (Pilar 6)
type SharedTrip struct {
	ID               string    `json:"id"`
	UserID           string    `json:"user_id"`
	Title            string    `json:"title"`
	DestinationRoute string    `json:"destination_route"`
	DepartureDate    time.Time `json:"departure_date"`
	AvailableSeats   int       `json:"available_seats"`
	CostPerPerson    float64   `json:"cost_per_person"`
	ContactWA        string    `json:"contact_wa"`
	CreatedAt        time.Time `json:"created_at"`
}

// DigitalPassport stempel check-in anti-fake GPS (radius <= 200m)
type DigitalPassport struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	DestinationID string    `json:"destination_id"`
	CheckedInAt   time.Time `json:"checked_in_at"`
	IsGPSValid    bool      `json:"is_gps_valid"`
}

// --- DTO (Data Transfer Object) untuk API BE-2 ---

// OTPRequest request kirim OTP 4 kotak
type OTPRequest struct {
	PhoneNumber string `json:"phone_number"`
}

// OTPVerifyRequest request verifikasi kode OTP
type OTPVerifyRequest struct {
	PhoneNumber string `json:"phone_number"`
	OTPCode     string `json:"otp_code"`
}

// AuthResponse response token JWT & profil
type AuthResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

// AutoItineraryRequest request generator jadwal otomatis 1-7 hari
type AutoItineraryRequest struct {
	UserID       string   `json:"user_id"`
	DurationDays int      `json:"duration_days"` // 1 - 7 hari
	ArrivalPoint string   `json:"arrival_point"` // "BIM" atau "Darat"
	TravelerType string   `json:"traveler_type"` // "family", "backpacker", "culinary", "open_trip"
	Preferences  []string `json:"preferences,omitempty"`
}

// CreateGroupRequest request buat ruang rombongan baru
type CreateGroupRequest struct {
	LeaderID string `json:"leader_id"`
	Title    string `json:"title"`
}

// GroupVoteRequest request voting destinasi/homestay
type GroupVoteRequest struct {
	GroupRoomID   string `json:"group_room_id"`
	UserID        string `json:"user_id"`
	DestinationID string `json:"destination_id"`
	VoteType      string `json:"vote_type"` // "upvote" / "downvote"
}

// VoteResultItem ringkasan voting per destinasi
type VoteResultItem struct {
	DestinationID   string  `json:"destination_id"`
	DestinationName string  `json:"destination_name"`
	Upvotes         int     `json:"upvotes"`
	Downvotes       int     `json:"downvotes"`
	ApprovalPercent float64 `json:"approval_percent"`
}

// CommunityPlaceRequest request pengajuan tempat baru komunitas
type CommunityPlaceRequest struct {
	UserID      string  `json:"user_id"`
	Name        string  `json:"name"`
	Category    string  `json:"category"`
	CityRegency string  `json:"city_regency"`
	Description string  `json:"description"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	TipsMenjaga string  `json:"tips_menjaga"` // Wajib untuk hidden gem
	IsSensitive bool    `json:"is_sensitive"` // Proteksi radius perkiraan hingga dikurasi Pokdarwis
}

// --- DTO MINGGU 3: ESCROW, BOT WA, SPLIT-BILL & RADAR ---

// CreateBookingRequest request pemesanan via Quick Drawer 360
type CreateBookingRequest struct {
	PartnerID   string  `json:"partner_id"`
	UserID      string  `json:"user_id"`
	TotalAmount float64 `json:"total_amount"`
	Currency    string  `json:"currency"` // IDR / MYR
}

// WAWebhookRequest payload webhook respon Bot WhatsApp mitra
type WAWebhookRequest struct {
	BookingID string `json:"booking_id"`
	Action    string `json:"action"` // "1" = Terima, "0" = Tolak
	Notes     string `json:"notes,omitempty"`
}

// ScanRedeemRequest payload scan QR E-Ticket saat tamu tiba di lokasi
type ScanRedeemRequest struct {
	PartnerID    string `json:"partner_id"`
	QRCodeTicket string `json:"qr_code_ticket"`
}

// SplitBillRequest payload kalkulator patungan rombongan
type SplitBillRequest struct {
	TotalAmount float64  `json:"total_amount"`
	Description string   `json:"description"`
	MemberIDs   []string `json:"member_ids,omitempty"`
}

// SplitBillResponse rincian pembagian tagihan per orang
type SplitBillResponse struct {
	TotalAmount     float64                `json:"total_amount"`
	MemberCount     int                    `json:"member_count"`
	AmountPerPerson float64                `json:"amount_per_person"`
	Description     string                 `json:"description"`
	Shares          []SplitBillMemberShare `json:"shares"`
}

// SplitBillMemberShare porsi tagihan individu beserta link bayar QRIS
type SplitBillMemberShare struct {
	UserID      string  `json:"user_id"`
	Amount      float64 `json:"amount"`
	PaymentLink string  `json:"payment_link"`
}

// RadarPingRequest koordinat GPS opt-in anggota rombongan
type RadarPingRequest struct {
	UserID    string  `json:"user_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

// MemberRadarLocation posisi radar anggota terkini
type MemberRadarLocation struct {
	UserID    string    `json:"user_id"`
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	UpdatedAt time.Time `json:"updated_at"`
}

// CreateSharedTripRequest postingan baru papan cari barengan
type CreateSharedTripRequest struct {
	UserID           string    `json:"user_id"`
	Title            string    `json:"title"`
	DestinationRoute string    `json:"destination_route"`
	DepartureDate    time.Time `json:"departure_date"`
	AvailableSeats   int       `json:"available_seats"`
	CostPerPerson    float64   `json:"cost_per_person"`
	ContactWA        string    `json:"contact_wa"`
}

// --- DTO MINGGU 4: GAMIFIKASI PASPOR DIGITAL, ANTI-FAKE GPS & ANALITIK DISPAR ---

// CheckInRequest payload check-in validasi radius <= 200m
type CheckInRequest struct {
	UserID         string  `json:"user_id"`
	DestinationID  string  `json:"destination_id"`
	Latitude       float64 `json:"latitude"`
	Longitude      float64 `json:"longitude"`
	IsCarvingFound bool    `json:"is_carving_found,omitempty"` // Opsional tantangan ukiran 360
}

// CheckInResponse rincian hasil validasi check-in GPS
type CheckInResponse struct {
	DestinationID   string    `json:"destination_id"`
	DestinationName string    `json:"destination_name"`
	DistanceMeters  float64   `json:"distance_meters"`
	IsWithinRadius  bool      `json:"is_within_radius"`
	CheckedInAt     time.Time `json:"checked_in_at"`
	BadgeEarned     string    `json:"badge_earned"`
	TotalStamps     int       `json:"total_stamps"`
	MaxStamps       int       `json:"max_stamps"`
}

// IconicSpotItem data titik ikonik paspor digital Minang
type IconicSpotItem struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	Regency     string     `json:"regency"`
	Latitude    float64    `json:"latitude"`
	Longitude   float64    `json:"longitude"`
	BadgeName   string     `json:"badge_name"`
	IsCompleted bool       `json:"is_completed"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
}

// PassportSummaryResponse rekap stempel paspor digital wisatawan
type PassportSummaryResponse struct {
	UserID                   string           `json:"user_id"`
	TotalStamps              int              `json:"total_stamps"`
	RequiredStamps           int              `json:"required_stamps"`
	CompletionPercentage     float64          `json:"completion_percentage"`
	IsEligibleForCertificate bool             `json:"is_eligible_for_certificate"`
	Spots                    []IconicSpotItem `json:"spots"`
}

// CertificateRequest permintaan terbit sertifikat digital gubernur
type CertificateRequest struct {
	UserID   string `json:"user_id"`
	FullName string `json:"full_name"`
}

// CertificateResponse sertifikat digital resmi gubernur Sumbar
type CertificateResponse struct {
	CertificateID     string    `json:"certificate_id"`
	RecipientName     string    `json:"recipient_name"`
	IssuedAt          time.Time `json:"issued_at"`
	TotalSpotsVisited int       `json:"total_spots_visited"`
	SignatoryTitle    string    `json:"signatory_title"`
	SignatoryName     string    `json:"signatory_name"`
	VerificationURL   string    `json:"verification_url"`
	QRCodeURL         string    `json:"qr_code_url"`
	PDFDownloadURL    string    `json:"pdf_download_url"`
}

// DisparAnalyticsSummary rekap analitik Dispar Sumbar & satgas
type DisparAnalyticsSummary struct {
	TotalVisits               int                    `json:"total_visits"`
	TotalQRScans              int                    `json:"total_qr_scans"`
	TotalEscrowTurnover       float64                `json:"total_escrow_turnover"`
	TotalUMKMPartners         int                    `json:"total_umkm_partners"`
	RegencyDensityHeatmap     []RegencyDensityItem   `json:"regency_density_heatmap"`
	TopDestinations           []TopDestinationMetric `json:"top_destinations"`
	MitraCategoryDistribution map[string]int         `json:"mitra_category_distribution"`
}

// RegencyDensityItem kepadatan per 19 kab/kota di Sumbar
type RegencyDensityItem struct {
	RegencyName  string `json:"regency_name"`
	Occupancy    string `json:"occupancy"` // "tinggi", "sedang", "normal"
	ActiveGuests int    `json:"active_guests"`
}

// TopDestinationMetric metrik kunjungan per destinasi
type TopDestinationMetric struct {
	DestinationID   string `json:"destination_id"`
	DestinationName string `json:"destination_name"`
	Regency         string `json:"regency"`
	TotalCheckIns   int    `json:"total_checkins"`
}


