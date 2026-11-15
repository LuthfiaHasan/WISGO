package destination

import (
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// SpatialFilterParams parameter filter direktori destinasi dan koordinat GPS pengguna
type SpatialFilterParams struct {
	Category    string  `form:"category"`
	CityRegency string  `form:"city_regency"`
	CrowdLevel  string  `form:"crowd_level"`
	Signal      string  `form:"signal"`
	SearchQuery string  `form:"q"`
	HasUserGPS  bool    `form:"-"`
	UserLat     float64 `form:"lat"`
	UserLng     float64 `form:"lng"`
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

// NowTimestamp helper string waktu
func NowTimestamp() string {
	return time.Now().Format(time.RFC3339)
}
