package destination

import (
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// SpatialFilterParams parameter filter direktori destinasi dan koordinat GPS pengguna
type SpatialFilterParams struct {
	Category           string  `form:"category"`
	CityRegency        string  `form:"city_regency"`
	CrowdLevel         string  `form:"crowd_level"`
	Signal             string  `form:"signal"`
	SearchQuery        string  `form:"q"`
	VerificationStatus string  `form:"verification_status"`
	IncludePending     bool    `form:"include_pending"`
	HasUserGPS         bool    `form:"-"`
	UserLat            float64 `form:"lat"`
	UserLng            float64 `form:"lng"`
}

// SyncTariffsPayload payload sinkronisasi tabel tarif resmi Perda dari CMS Web Admin TS (FS-1)
type SyncTariffsPayload struct {
	Tariffs         []models.OfficialTariff `json:"tariffs"`
	OfficialTariffs []models.OfficialTariff `json:"official_tariffs"`
}

// OfflineBundleResponse struktur paket offline bundle v2 (Flutter Hive / SQLite Ready)
type OfflineBundleResponse struct {
	BundleVersion   string                 `json:"bundle_version"`
	GeneratedAt     string                 `json:"generated_at"`
	LocalStorageSDK string                 `json:"local_storage_sdk"`
	OfflineBanner   string                 `json:"offline_banner"`
	Destination     *models.Destination    `json:"destination"`
	Scenes360       []models.Scene360      `json:"scenes_360"`
	MicroMap        *models.ScenicMicroMap     `json:"micro_map"`
	AudioTriggers   []models.AudioTriggerPoint `json:"audio_triggers"`
}

// TariffsResponse respon rincian tarif resmi Perda destinasi
type TariffsResponse struct {
	DestinationID   string                 `json:"destination_id"`
	DestinationName string                 `json:"destination_name"`
	CityRegency     string                 `json:"city_regency"`
	Tariffs         []models.OfficialTariff `json:"tariffs"`
}

// CreateHiddenGemInput payload kontribusi destinasi hidden gem oleh wisatawan (BE-1 Pilar 2 & 6)
type CreateHiddenGemInput struct {
	Name           string  `json:"name" binding:"required"`
	CityRegency    string  `json:"city_regency"`
	Description    string  `json:"description"`
	Latitude       float64 `json:"latitude"`
	Longitude      float64 `json:"longitude"`
	ElevationM     int     `json:"elevation_m,omitempty"`
	CoverImage     string  `json:"cover_image,omitempty"`
	CrowdLevel     string  `json:"crowd_level,omitempty"`
	TipsMenjaga    string  `json:"tips_menjaga"`    // Edukasi kelestarian alam hidden gem
	TipsAdat       string  `json:"tips_adat"`       // Etika kearifan lokal Minangkabau
	VehicleAccess  string  `json:"vehicle_access"`  // Mobil OK, Hanya Motor, Jalan Kaki
	TrekkingLevel  string  `json:"trekking_level"`  // Datar / Mudah, Sedang, Curam / Ekstrem
	CellularSignal string  `json:"cellular_signal"` // 4G Kuat, Sinyal Lemah, Blank Spot
	Facilities     string  `json:"facilities"`      // Terbatas, Belum Ada
	GuideNeed      string  `json:"guide_need"`      // Wajib Pemandu, Disarankan, Mandiri
	Contributor    string  `json:"contributor,omitempty"`
}

// VerifyDestinationRequest payload verifikasi persetujuan admin untuk hidden gem wisatawan
type VerifyDestinationRequest struct {
	Status     string `json:"status" binding:"required"` // "verified", "approved", "rejected"
	AdminNotes string `json:"admin_notes,omitempty"`
}

// NowTimestamp helper string waktu
func NowTimestamp() string {
	return time.Now().Format(time.RFC3339)
}
