package models

import (
	"time"
)

// --- Domain Models BE-1: Core & Spasial (Pilar 1, 2, 3, 7) ---

// Destination merepresentasikan destinasi wisata di Sumatera Barat
// Dilengkapi 4 Statistik Keputusan di Depan (DistanceKm, TravelTimeMin, CrowdLevel, EstimatedCost)
type Destination struct {
	ID            string    `json:"id"`
	Slug          string    `json:"slug,omitempty"`
	Name          string    `json:"name"`
	Category      string    `json:"category"`       // Alam, Budaya, Kuliner, Sejarah, Bahari, Geopark, Nagari
	CityRegency   string    `json:"city_regency"`   // 19 Kab/Kota Sumbar
	Description   string    `json:"description"`
	Latitude      float64   `json:"latitude"`
	Longitude     float64   `json:"longitude"`
	ElevationM    int       `json:"elevation_m,omitempty"`
	CoverImage    string    `json:"cover_image"`
	CrowdLevel    string    `json:"crowd_level"`     // Sepi, Sedang, Ramai (Statistik Keputusan #3)
	DistanceKm    float64   `json:"distance_km"`     // Statistik Keputusan #1 (Jarak dari posisi user / Padang)
	TravelTimeMin int       `json:"travel_time_min"` // Statistik Keputusan #2 (Estimasi waktu tempuh menit)
	EstimatedCost float64   `json:"estimated_cost"`  // Statistik Keputusan #4 (Biaya tiket dasar resmi Perda)
	IsHiddenGem   bool      `json:"is_hidden_gem"`   // Penanda wajib tampil kartu Tips Menjaga Tempat
	QRPlacardCode string    `json:"qr_placard_code,omitempty"`
	OpeningHours  string    `json:"opening_hours,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`

	// Relasi Sprint 1 & Sprint 2 (1:1 MedanIndicator & MicroMap, 1:N Tips, Tariffs, Scenes360)
	MedanIndicator *MedanIndicator  `json:"medan_indicator,omitempty"`
	Tips           []LocalTip       `json:"tips,omitempty"`
	Tariffs        []OfficialTariff `json:"tariffs,omitempty"`
	Scenes360      []Scene360       `json:"scenes_360,omitempty"`
	MicroMap       *ScenicMicroMap  `json:"micro_map,omitempty"`
}

// MedanIndicator memuat 5 Indikator Medan Lapangan (Sprint 1)
type MedanIndicator struct {
	ID             string `json:"id"`
	DestinationID  string `json:"destination_id"`
	VehicleAccess  string `json:"vehicle_access"`  // Mobil OK, Hanya Motor, Jalan Kaki
	TrekkingLevel  string `json:"trekking_level"`  // Datar / Mudah, Sedang, Curam / Ekstrem
	CellularSignal string `json:"cellular_signal"` // 4G Kuat, Sinyal Lemah, Blank Spot
	Facilities     string `json:"facilities"`      // Toilet & Musala Lengkap, Terbatas, Belum Ada
	GuideNeed      string `json:"guide_need"`       // Wajib Pemandu, Disarankan, Mandiri
	PokdarwisName  string `json:"pokdarwis_name,omitempty"`
}

// LocalTip tips etika menjaga alam & kelestarian (Sprint 1)
type LocalTip struct {
	ID            string `json:"id"`
	DestinationID string `json:"destination_id"`
	Title         string `json:"title,omitempty"`
	Category      string `json:"category,omitempty"` // kelestarian_alam, etika_adat, keselamatan_medan
	Content       string `json:"content"`
	IsImportant   bool   `json:"is_important"`
}

// OfficialTariff tabel Fair-Price Barometer (Perda / Nagari - Sprint 1)
type OfficialTariff struct {
	ID            string  `json:"id"`
	DestinationID string  `json:"destination_id"`
	ItemName      string  `json:"item_name"`      // Tiket Masuk, Parkir Motor, Parkir Mobil, Sewa Bendi
	Category      string  `json:"category,omitempty"`
	Price         float64 `json:"price"`
	Unit          string  `json:"unit"`           // per orang, per kendaraan, per jam
	RegulationRef string  `json:"regulation_ref"` // No Perda / Peraturan Nagari
}

// --- Domain Models BE-1: Sprint 2 (Hari 6–10: 360° 4-Pin, Shunlu, Peta Mikro, Lapor Pungli) ---

// Scene360 representasi scene tur imersif aerial (drone 100-200m) & ground (spot utama)
type Scene360 struct {
	ID              string       `json:"id"`
	DestinationID   string       `json:"destination_id"`
	Title           string       `json:"title"`
	Type            string       `json:"type"` // aerial, ground
	PanoramaURL     string       `json:"panorama_url"`
	UploadFormat    string       `json:"upload_format,omitempty"` // url, base64, multipart
	SpatialAudioURL string       `json:"spatial_audio_url,omitempty"`
	InitialPitch    float64      `json:"initial_pitch"`
	InitialYaw      float64      `json:"initial_yaw"`
	IsDefaultScene  bool         `json:"is_default_scene"`
	Hotspots        []Hotspot360 `json:"hotspots,omitempty"`
}

// Hotspot360 pin interaktif 4 jenis terstandarisasi pada kanvas 360°
type Hotspot360 struct {
	ID          string  `json:"id"`
	SceneID     string  `json:"scene_id"`
	Type        string  `json:"type"`  // navigasi (biru), audio (emas), fasilitas (hijau), mitra (oranye)
	ColorToken  string  `json:"color_token,omitempty"`
	Pitch       float64 `json:"pitch"` // -90.0 s/d +90.0 derajat
	Yaw         float64 `json:"yaw"`   // 0.0 s/d 360.0 derajat
	Title       string  `json:"title"`
	TargetRef   string  `json:"target_ref,omitempty"` // ID Scene tujuan (dive-in) atau ID Mitra Nagari (Quick Booking)
	AudioURL    string  `json:"audio_url,omitempty"`
	Description string  `json:"description,omitempty"`
}

// ShunluPOI titik singgah searah rute aktif (Along-the-Route Search "Shunlu" +X mnt detour)
type ShunluPOI struct {
	ID                  string  `json:"id"`
	Name                string  `json:"name"`
	Category            string  `json:"category"`      // rm_padang, spbu, masjid_bersih, atm, bengkel
	CorridorRoad        string  `json:"corridor_road"` // Lintas Padang-Bukittinggi, Lintas Bukittinggi-Harau, dll.
	CityRegency         string  `json:"city_regency"`
	Latitude            float64 `json:"latitude"`
	Longitude           float64 `json:"longitude"`
	DetourMinutes       int     `json:"detour_minutes"`        // +X menit memutar dari rute utama
	DetourDistanceMeter int     `json:"detour_distance_meter"` // Jarak dari poros jalan utama (meter)
	HighlightNote       string  `json:"highlight_note"`
	OpeningHours        string  `json:"opening_hours"`
	IsRecommended       bool    `json:"is_recommended"`
}

// ScenicMicroMap peta mikro internal kawasan wisata luas + titik pemicu Audio GPS <=15m
type ScenicMicroMap struct {
	ID                  string              `json:"id"`
	DestinationID       string              `json:"destination_id"`
	DestinationName     string              `json:"destination_name"`
	AreaSizeHectare     float64             `json:"area_size_hectare"`
	WalkwayGeoJSON      string              `json:"walkway_geojson"`
	ChildFriendlyPath   bool                `json:"child_friendly_path"`
	ElderlyFriendlyPath bool                `json:"elderly_friendly_path"`
	InternalPOIs        []MicroMapPOI       `json:"internal_pois"`
	AudioTriggers       []AudioTriggerPoint `json:"audio_triggers"`
}

// MicroMapPOI fasilitas mikro di dalam kawasan wisata (Gerbang, Spot Foto, Toilet, Pos Pokdarwis)
type MicroMapPOI struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Type        string  `json:"type"` // gerbang, spot_foto, toilet_musala, pos_pokdarwis, gardu_pandang
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	Description string  `json:"description"`
}

// AudioTriggerPoint titik koordinat pemicu narasi cerita otomatis saat GPS wisatawan <=15 meter
type AudioTriggerPoint struct {
	ID              string  `json:"id"`
	DestinationID   string  `json:"destination_id"`
	Title           string  `json:"title"`
	Latitude        float64 `json:"latitude"`
	Longitude       float64 `json:"longitude"`
	TriggerRadiusM  float64 `json:"trigger_radius_m"` // Default <= 15.0 meter
	AudioURLID      string  `json:"audio_url_id"`
	AudioURLMinang  string  `json:"audio_url_minang,omitempty"`
	TranscriptShort string  `json:"transcript_short"`
}

// PungliReport laporan pungli / fasilitas rusak dari wisatawan ke Pusat Komando Satgas Saber Pungli
type PungliReport struct {
	ID                    string    `json:"id"`
	TicketCode            string    `json:"ticket_code"` // Contoh: PGL-202611-0091
	DestinationID         string    `json:"destination_id"`
	DestinationName       string    `json:"destination_name,omitempty"`
	ReporterName          string    `json:"reporter_name"`     // Boleh Anonim ("Wisatawan Anonim")
	IncidentCategory      string    `json:"incident_category"` // parkir_liar, tiket_di_atas_perda, paksaan_pemandu, fasilitas_rusak
	ChargedAmountIDR      float64   `json:"charged_amount_idr"`
	OfficialPerdaPriceIDR float64   `json:"official_perda_price_idr"`
	OverchargeAmountIDR   float64   `json:"overcharge_amount_idr"`
	PhotoEvidence         string    `json:"photo_evidence"`
	UploadFormat          string    `json:"upload_format,omitempty"` // url, base64, multipart
	Latitude              float64   `json:"latitude"`
	Longitude             float64   `json:"longitude"`
	Description           string    `json:"description"`
	Status                string    `json:"status"` // Masuk, Diverifikasi, Ditindaklanjuti, Selesai
	SatgasNotes           string    `json:"satgas_notes,omitempty"`
	CreatedAt             time.Time `json:"created_at"`
	UpdatedAt             time.Time `json:"updated_at"`
}

// --- Domain Models BE-1: Sprint 3 (Hari 11–15: Gaode Ranking, Hazard Alert, SOS GPS, Kamus Minang & Kalender Budaya) ---

// GaodeBehaviorRanking menyimpan metrik telemetri perilaku nyata anti-bintang palsu (Pilar 2 — P2.4)
type GaodeBehaviorRanking struct {
	ID                     string    `json:"id"`
	DestinationID          string    `json:"destination_id"`
	DestinationName        string    `json:"destination_name"`
	Category               string    `json:"category"` // Hidden Gem, Kuliner Legendaris, Alam & Geopark, Budaya & Nagari
	CityRegency            string    `json:"city_regency"`
	RankPosition           int       `json:"rank_position"`
	GaodeAuthenticityScore float64   `json:"gaode_authenticity_score"` // Skor 0 - 100 hasil kalkulasi telemetri GPS
	ActiveNavCount30d      int       `json:"active_nav_count_30d"`     // Jumlah navigasi diselesaikan dalam 30 hari terakhir
	AvgDwellTimeMin        int       `json:"avg_dwell_time_min"`       // Rata-rata waktu singgah nyata GPS (menit)
	ReturnVisitRatePct     float64   `json:"return_visit_rate_pct"`    // Persentase kunjungan berulang wisatawan
	AntiFakeReviewVerified bool      `json:"anti_fake_review_verified"`
	TrendingBadge          string    `json:"trending_badge"`
	UpdatedAt              time.Time `json:"updated_at"`
}

// HazardAlert alert jalur rawan bencana Sumatera Barat (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44 - Sprint 3 P7.2)
type HazardAlert struct {
	ID                  string    `json:"id"`
	CorridorCode        string    `json:"corridor_code"` // SITINJAU-LAUIK, LEMBAH-ANAI, KELOK-9, KELOK-44
	Location            string    `json:"location"`
	RoadSegment         string    `json:"road_segment"`
	CityRegency         string    `json:"city_regency"`
	Latitude            float64   `json:"latitude"`
	Longitude           float64   `json:"longitude"`
	RadiusMeter         int       `json:"radius_meter"`
	Severity            string    `json:"severity"`       // Normal, Waspada, Siaga, Awas Tutup Total
	HazardType          string    `json:"hazard_type"`    // Rawan Longsor, Kabut Tebal, Jalan Buka-Tutup, Banjir Bandang
	WeatherStatus       string    `json:"weather_status"` // Hujan Lebat, Gerimis Berkabut, Cerah Berawan
	SlopeGradientDeg    int       `json:"slope_gradient_deg"`
	Message             string    `json:"message"`
	DetourRoute         string    `json:"detour_route"`
	DetourRouteGeoJSON  string    `json:"detour_route_geojson"`
	NearestRescuePost   string    `json:"nearest_rescue_post"`
	EmergencyContact    string    `json:"emergency_contact"`
	TriggeredByAdmin    string    `json:"triggered_by_admin,omitempty"`
	UpdatedAt           time.Time `json:"updated_at"`
}

// SOSSignal sinyal pancaran darurat GPS dari wisatawan di jalur ekstrem / destinasi blank spot (Pilar 7 — P7.2)
type SOSSignal struct {
	ID                  string    `json:"id"`
	SOSCode             string    `json:"sos_code"` // Contoh: SOS-SUMBAR-202611-001
	TouristName         string    `json:"tourist_name"`
	PhoneNumber         string    `json:"phone_number"`
	EmergencyType       string    `json:"emergency_type"` // Kendaraan Mogok di Tanjakan, Terjebak Longsor, Darurat Medis, Tersesat di Jalur
	Latitude            float64   `json:"latitude"`
	Longitude           float64   `json:"longitude"`
	BatteryPercent      int       `json:"battery_percent"`
	PassengersCount     int       `json:"passengers_count"`
	NearestCorridor     string    `json:"nearest_corridor"`
	NearestRescuePost   string    `json:"nearest_rescue_post"`
	DistanceToRescueKm  float64   `json:"distance_to_rescue_km"`
	ETARescueMinutes    int       `json:"eta_rescue_minutes"`
	Status              string    `json:"status"` // Dipancarkan, Tim SAR Meluncur, Evakuasi Selesai
	Notes               string    `json:"notes"`
	CreatedAt           time.Time `json:"created_at"`
}

// MinangPhrase entri Kamus Saku Audio Bahasa Minang sehari-hari (Pilar 1 — P1.4)
type MinangPhrase struct {
	ID                string `json:"id"`
	Category          string `json:"category"` // sapaan_adat, tawar_pasar, kuliner_rm, navigasi_darurat
	IndonesianText    string `json:"indonesian_text"`
	MinangText        string `json:"minang_text"`
	PhoneticGuide     string `json:"phonetic_guide"`
	AudioURL          string `json:"audio_url"`
	DialectNote       string `json:"dialect_note"` // Dialek Padang / Bukittinggi (Darek) / Pesisir
	UsageContextTip   string `json:"usage_context_tip"`
	PolitenessLevel   string `json:"politeness_level"` // Kato Nan Ampek: Kato Mandaki, Katoiti, Kato Manurun, KatoMalereang
}

// CulturalEvent agenda Kalender Budaya & Hari Pakan (Pasar Tradisional Nagari) Sumatera Barat (Pilar 1 — P1.4)
type CulturalEvent struct {
	ID              string  `json:"id"`
	Title           string  `json:"title"`
	EventType       string  `json:"event_type"` // Hari Pakan Nagari, Festival Budaya, Tradisi Adat
	NagariLocation  string  `json:"nagari_location"`
	CityRegency     string  `json:"city_regency"`
	ScheduleRule    string  `json:"schedule_rule"` // Contoh: Setiap Hari Sabtu (Pakan Sabtu), Setiap Hari Rabu (Pakan Rabaa), Tahunan
	NextEventDate   string  `json:"next_event_date"`
	Latitude        float64 `json:"latitude"`
	Longitude       float64 `json:"longitude"`
	DistanceKm      float64 `json:"distance_km,omitempty"`
	HighlightItem   string  `json:"highlight_item"`
	CulturalEtiquette string `json:"cultural_etiquette"`
}

// --- Domain Models BE-2: Grup, Mitra, Escrow & Komunitas (Pilar 4, 5, 6, 8) ---
// CATATAN BE-1: Struct di bawah ini milik BE-2, JANGAN DIHAPUS agar tidak terjadi merge conflict!

type User struct {
	ID          string    `json:"id"`
	PhoneNumber string    `json:"phone_number"`
	FullName    string    `json:"full_name"`
	Role        string    `json:"role"` // tourist, partner, admin_dispar, satgas_pungli
	CreatedAt   time.Time `json:"created_at"`
}

type GroupRoom struct {
	ID        string    `json:"id"`
	RoomCode  string    `json:"room_code"`
	Title     string    `json:"title"`
	LeaderID  string    `json:"leader_id"`
	CreatedAt   time.Time `json:"created_at"`
}

type GroupVote struct {
	ID            string `json:"id"`
	GroupRoomID   string `json:"group_room_id"`
	UserID        string `json:"user_id"`
	DestinationID string `json:"destination_id"`
	VoteType      string `json:"vote_type"`
}

type PartnerNagari struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Category    string  `json:"category"`
	WhatsApp    string  `json:"whatsapp"`
	SpicyLevel  int     `json:"spicy_level,omitempty"`
	IsVerified  bool    `json:"is_verified"`
	StandardFee float64 `json:"standard_fee"`
	NagariName  string  `json:"nagari_name"`
}

type BookingEscrow struct {
	ID           string    `json:"id"`
	PartnerID    string    `json:"partner_id"`
	UserID       string    `json:"user_id"`
	TotalAmount  float64   `json:"total_amount"`
	Currency     string    `json:"currency"`
	Status       string    `json:"status"`
	QRCodeTicket string    `json:"qr_code_ticket"`
	CreatedAt    time.Time `json:"created_at"`
}

type DigitalPassport struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	DestinationID string    `json:"destination_id"`
	CheckedInAt   time.Time `json:"checked_in_at"`
	IsGPSValid    bool      `json:"is_gps_valid"`
}
