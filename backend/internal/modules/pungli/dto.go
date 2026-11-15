package pungli

import "github.com/LuthfiaHasan/WISGO/backend/internal/models"

// SmartQRResolutionResponse respon resolusi Plang Smart QR ke destinasi + Fair-Price + 360 + Peta Mikro
type SmartQRResolutionResponse struct {
	Status             string                `json:"status"`
	QRPlacardCode      string                `json:"qr_placard_code"`
	InstantWebPreview  string                `json:"instant_web_preview"`
	FairPriceVerified  bool                  `json:"fair_price_verified"`
	Destination        *models.Destination   `json:"destination"`
	Scenes360          []models.Scene360     `json:"scenes_360"`
	MicroMap           models.ScenicMicroMap `json:"micro_map"`
}

// CreatePungliReportRequest payload pelaporan pungli dari form mobile FE-2
type CreatePungliReportRequest struct {
	DestinationID    string  `json:"destination_id"`
	ReporterName     string  `json:"reporter_name"`
	IncidentCategory string  `json:"incident_category"` // parkir_liar | tiket_di_atas_perda | paksaan_pemandu | fasilitas_rusak
	ChargedAmountIDR float64 `json:"charged_amount_idr"`
	PhotoEvidence    string  `json:"photo_evidence"`
	PhotoBase64      string  `json:"photo_base64,omitempty"`
	Latitude         float64 `json:"latitude"`
	Longitude        float64 `json:"longitude"`
	Description      string  `json:"description"`
}

// CreatePungliReportResponse respon sukses pelaporan aduan pungli
type CreatePungliReportResponse struct {
	Status  string              `json:"status"`
	Ticket  string              `json:"ticket"`
	Message string              `json:"message"`
	Report  models.PungliReport `json:"report"`
}

// UpdatePungliStatusRequest payload pembaruan status laporan oleh Satgas Saber Pungli FS-1
type UpdatePungliStatusRequest struct {
	Status      string `json:"status"` // Masuk | Diverifikasi | Ditindaklanjuti | Selesai
	SatgasNotes string `json:"satgas_notes"`
}

// UpdatePungliStatusResponse respon pembaruan status laporan di Pusat Komando
type UpdatePungliStatusResponse struct {
	Status          string               `json:"status"`
	UpdatedAt       string               `json:"updated_at"`
	Report          *models.PungliReport `json:"report"`
	OverchargeRatio float64              `json:"overcharge_ratio"`
}
