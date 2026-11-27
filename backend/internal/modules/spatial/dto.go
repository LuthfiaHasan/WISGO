package spatial

import (
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ShunluSearchRequest parameter pencarian POI searah rute koridor (FE-1 Layar 03)
type ShunluSearchRequest struct {
	OriginLat      float64 `json:"origin_lat"`
	OriginLng      float64 `json:"origin_lng"`
	DestinationLat float64 `json:"destination_lat"`
	DestinationLng float64 `json:"destination_lng"`
	DestinationID  string  `json:"destination_id,omitempty"`
	Category       string  `json:"category,omitempty"`       // rm_padang | spbu | masjid_bersih | atm | bengkel
	MaxDetourMin   int     `json:"max_detour_min,omitempty"` // Default 15 menit
}

// ShunluSearchResponse respon hasil pencarian Shunlu
type ShunluSearchResponse struct {
	Status         string             `json:"status"`
	Engine         string             `json:"engine"`
	CategoryFilter string             `json:"category_filter,omitempty"`
	MaxDetourMin   int                `json:"max_detour_min"`
	DetourTimeMin  int                `json:"detour_time_min"`
	Recommended    string             `json:"recommended"`
	TotalMatches   int                `json:"total_matches"`
	ShunluPOIs     []models.ShunluPOI `json:"shunlu_pois"`
}

// AudioTriggerCheckRequest payload verifikasi posisi GPS terhadap radius pemicu audio <= 15m
type AudioTriggerCheckRequest struct {
	DestinationID string  `json:"destination_id"`
	UserLat       float64 `json:"user_lat"`
	UserLng       float64 `json:"user_lng"`
}

// TriggeredAudioStory informasi cerita yang terpicu dalam radius 15m
type TriggeredAudioStory struct {
	Trigger        models.AudioTriggerPoint `json:"trigger"`
	DistanceMeter  float64                  `json:"distance_meter"`
	AutoPlayStatus string                   `json:"auto_play_status"`
}

// AudioTriggerCheckResponse respon pemicu audio GPS
type AudioTriggerCheckResponse struct {
	DestinationID   string                `json:"destination_id"`
	DestinationName string                `json:"destination_name"`
	TriggerStatus   string                `json:"trigger_status"`
	MatchedCount    int                   `json:"matched_count"`
	TriggeredStories []TriggeredAudioStory `json:"triggered_stories"`
}

// TriggerHazardInput payload pembaruan/trigger status bencana jalur ekstrem dari FS-1
type TriggerHazardInput struct {
	CorridorCode     string `json:"corridor_code"` // SITINJAU-LAUIK, LEMBAH-ANAI, KELOK-9, KELOK-44
	Severity         string `json:"severity"`      // Normal, Waspada, Siaga, Awas Tutup Total
	HazardType       string `json:"hazard_type"`
	WeatherStatus    string `json:"weather_status"`
	Message          string `json:"message"`
	DetourRoute      string `json:"detour_route"`
	TriggeredByAdmin string `json:"triggered_by_admin"`
}

// LiveHazardsResponse respon daftar peringatan bahaya aktif
type LiveHazardsResponse struct {
	Status                 string               `json:"status"`
	MonitoredCorridorsCount int                 `json:"monitored_corridors_count"`
	UserInHazardZone       bool                 `json:"user_in_hazard_zone"`
	FE1ActiveWarningBanner *models.HazardAlert  `json:"fe1_active_warning_banner"`
	Hazards                []models.HazardAlert `json:"hazards"`
}

// OptimizeTSPRequest payload rute TSP cerdas
type OptimizeTSPRequest struct {
	DestinationIDs []string `json:"destination_ids"`
	StartLat       float64  `json:"start_lat"`
	StartLng       float64  `json:"start_lng"`
}

// TSPWaypoint hasil urutan titik kunjungan
type TSPWaypoint struct {
	Order          int                `json:"order"`
	Destination    models.Destination `json:"destination"`
	LegDistanceKm  float64            `json:"leg_distance_km"`
	LegDurationMin int                `json:"leg_duration_min"`
}

// OptimizeTSPResponse respon rute efisien TSP
type OptimizeTSPResponse struct {
	Status           string        `json:"status"`
	Algorithm        string        `json:"algorithm"`
	TotalWaypoints   int           `json:"total_waypoints"`
	TotalDistanceKm  float64       `json:"total_distance_km"`
	TotalDurationMin int           `json:"total_duration_min"`
	EfficiencyScore  string        `json:"efficiency_score"`
	Waypoints        []TSPWaypoint `json:"waypoints"`
}

// SOSEmergencyInput payload pancaran darurat SOS GPS dari wisatawan (FE-1)
type SOSEmergencyInput struct {
	SOSCode            string     `json:"sos_code,omitempty"`             // ID unik yang digenerate client saat offline
	IsOfflineSync      bool       `json:"is_offline_sync,omitempty"`      // True jika dikirim via auto-sync saat sinyal pulih
	OfflineTriggeredAt *time.Time `json:"offline_triggered_at,omitempty"` // Timestamp saat tombol ditekan offline
	TouristName        string     `json:"tourist_name"`
	PhoneNumber        string     `json:"phone_number"`
	EmergencyType      string     `json:"emergency_type"`
	Latitude           float64    `json:"latitude"`
	Longitude          float64    `json:"longitude"`
	BatteryPercent     int        `json:"battery_percent"`
	PassengersCount    int        `json:"passengers_count"`
	Notes              string     `json:"notes"`
}

// SOSEmergencyResponse respon penerimaan sinyal darurat SOS
type SOSEmergencyResponse struct {
	Status              string                        `json:"status"`
	Message             string                        `json:"message"`
	SOSSignal           models.SOSSignal              `json:"sos_signal"`
	SurvivalInstruction string                        `json:"survival_instruction"`
	EmergencyContacts   []models.EmergencyContact     `json:"emergency_contacts,omitempty"`
	EmergencyCall       *models.EmergencyCallProtocol `json:"emergency_call,omitempty"`
}

// EmergencyContactsResponse respon master kontak darurat & pos SAR Sumbar
type EmergencyContactsResponse struct {
	Status        string                        `json:"status"`
	Total         int                           `json:"total"`
	Contacts      []models.EmergencyContact     `json:"contacts"`
	EmergencyCall *models.EmergencyCallProtocol `json:"emergency_call,omitempty"`
}

// NavigationTelemetryInput payload telemetri navigasi dan dwell time GPS (FE-1)
type NavigationTelemetryInput struct {
	DestinationID     string  `json:"destination_id"`
	DwellTimeMinutes  int     `json:"dwell_time_minutes"`
	IsRepeatVisit     bool    `json:"is_repeat_visit"`
	GPSAccuracyMeters float64 `json:"gps_accuracy_meters"`
}
