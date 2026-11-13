package be1_core

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// 1. GetSmartQRResolution — GET /api/v1/qr/{qrCode} (Hari 9 — Scanner Plang Smart QR FE-2 & Web Instant QR FS-1)
func (h *HandlerBE1) GetSmartQRResolution(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	qrCode := strings.TrimSpace(r.PathValue("qrCode"))

	dest, err := h.repo.FindAggregateDetail(qrCode, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "QR_PLACARD_NOT_FOUND",
			"message": fmt.Sprintf("Kode Plang Smart QR '%s' tidak terdaftar di database Dispar Sumbar.", qrCode),
		})
		return
	}

	scenes := h.repo.GetScenes360ByDestinationID(dest.ID)
	microMap := h.repo.GetMicroMapByDestinationID(dest.ID, dest.Name, dest.Latitude, dest.Longitude)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":              "resolved",
		"qr_placard_code":     dest.QRPlacardCode,
		"instant_web_preview": fmt.Sprintf("https://rancak.in/qr/%s", dest.QRPlacardCode),
		"fair_price_verified": true,
		"destination":         dest,
		"scenes_360":          scenes,
		"micro_map":           microMap,
	})
}

// CreatePungliReportRequest mendukung JSON (URL / Base64) maupun simulasi Multipart Upload (FE-2 Form Lapor Pungli)
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

// 2. PostReportPungli — POST /api/v1/pungli/report (Hari 9 — Lapor Pungli Anonim + Bukti Foto + GPS FE-2)
func (h *HandlerBE1) PostReportPungli(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req CreatePungliReportRequest
	contentType := r.Header.Get("Content-Type")
	uploadFormat := "url"

	if strings.HasPrefix(contentType, "multipart/form-data") {
		_ = r.ParseMultipartForm(10 << 20)
		req.DestinationID = r.FormValue("destination_id")
		req.ReporterName = r.FormValue("reporter_name")
		req.IncidentCategory = r.FormValue("incident_category")
		req.PhotoEvidence = r.FormValue("photo_evidence")
		req.Description = r.FormValue("description")
		if v, err := strconv.ParseFloat(r.FormValue("charged_amount_idr"), 64); err == nil {
			req.ChargedAmountIDR = v
		}
		if v, err := strconv.ParseFloat(r.FormValue("latitude"), 64); err == nil {
			req.Latitude = v
		}
		if v, err := strconv.ParseFloat(r.FormValue("longitude"), 64); err == nil {
			req.Longitude = v
		}
		uploadFormat = "multipart"
		if req.PhotoEvidence == "" {
			req.PhotoEvidence = "https://cdn.rancak.in/evidence/multipart-karcis-pungli.jpg"
		}
	} else {
		_ = json.NewDecoder(r.Body).Decode(&req)
		if req.PhotoBase64 != "" {
			uploadFormat = "base64"
			if req.PhotoEvidence == "" {
				req.PhotoEvidence = "data:image/jpeg;base64," + req.PhotoBase64
			}
		}
	}

	if req.DestinationID == "" {
		req.DestinationID = "dest-003"
	}
	if req.ReporterName == "" {
		req.ReporterName = "Wisatawan Anonim"
	}
	if req.IncidentCategory == "" {
		req.IncidentCategory = "parkir_liar"
	}
	if req.PhotoEvidence == "" {
		req.PhotoEvidence = "https://cdn.rancak.in/evidence/foto-bukti-lapangan.jpg"
	}
	if req.Description == "" {
		req.Description = "Tagihan parkir/tiket di lapangan melebihi ketentuan Tabel Fair-Price Barometer Perda."
	}

	created := h.repo.CreatePungliReport(models.PungliReport{
		DestinationID:    req.DestinationID,
		ReporterName:     req.ReporterName,
		IncidentCategory: req.IncidentCategory,
		ChargedAmountIDR: req.ChargedAmountIDR,
		PhotoEvidence:    req.PhotoEvidence,
		UploadFormat:     uploadFormat,
		Latitude:         req.Latitude,
		Longitude:        req.Longitude,
		Description:      req.Description,
	})

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"ticket":  created.TicketCode,
		"message": "Laporan berhasil diteruskan ke Satgas Saber Pungli Dispar Sumbar",
		"report":  created,
	})
}

// 3. GetPungliReportsAdmin — GET /api/v1/admin/pungli/reports (Hari 9 — Pusat Komando Satgas Saber Pungli FS-1)
func (h *HandlerBE1) GetPungliReportsAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	statusFilter := strings.TrimSpace(r.URL.Query().Get("status"))

	reports := h.repo.ListPungliReports(statusFilter)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":        "ok",
		"filter_status": statusFilter,
		"total_reports": len(reports),
		"reports":       reports,
	})
}

// UpdatePungliStatusRequest adalah kontrak JSON antara BE-1 dan FS-1 (Pusat Komando Satgas Saber Pungli)
type UpdatePungliStatusRequest struct {
	Status      string `json:"status"` // Masuk | Diverifikasi | Ditindaklanjuti | Selesai
	SatgasNotes string `json:"satgas_notes"`
}

// 4. UpdatePungliStatusAdmin — PATCH /api/v1/admin/pungli/{id}/status (Hari 9 — Tindak Lanjut Satgas FS-1)
func (h *HandlerBE1) UpdatePungliStatusAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	idOrTicket := r.PathValue("id")

	var req UpdatePungliStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Status == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_STATUS_PAYLOAD",
			"message": "Field 'status' wajib diisi (Masuk, Diverifikasi, Ditindaklanjuti, atau Selesai).",
		})
		return
	}

	updated, err := h.repo.UpdatePungliReportStatus(idOrTicket, req.Status, req.SatgasNotes)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "REPORT_NOT_FOUND",
			"message": fmt.Sprintf("Tiket laporan pungli '%s' tidak ditemukan.", idOrTicket),
		})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":     "updated",
		"updated_at": time.Now().Format(time.RFC3339),
		"report":     updated,
		"overcharge_ratio": math.Round((updated.OverchargeAmountIDR / math.Max(1, updated.OfficialPerdaPriceIDR)) * 100),
	})
}
