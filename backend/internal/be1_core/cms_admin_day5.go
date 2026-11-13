package be1_core

import (
	"encoding/json"
	"net/http"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ============================================================================
// HARI 5 (JUMAT): API ADMIN CMS (SINKRONISASI FS-1) & SINKRONISASI TARIF PERDA
// File: backend/internal/be1_core/cms_admin_day5.go
// Sinkronisasi: FS-1 (Web Admin TypeScript — CMS Manajemen Destinasi,
//               5 Indikator Medan & Tabel Tarif Resmi Perda)
// ============================================================================

// SyncTariffsPayload mewakili format JSON dari Web Admin TS (FS-1) saat menyinkronkan tarif Perda
type SyncTariffsPayload struct {
	Tariffs         []models.OfficialTariff `json:"tariffs"`
	OfficialTariffs []models.OfficialTariff `json:"official_tariffs"`
}

// UpdateDestinationTariffsCMS menangani PUT /api/v1/destinations/{id}/tariffs
// dan PUT /api/v1/admin/destinations/{id}/tariffs (Khusus Role: admin_dispar / pokdarwis)
func (h *HandlerBE1) UpdateDestinationTariffsCMS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	var body SyncTariffsPayload
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_JSON_BODY",
			"message": "Format JSON tidak valid untuk sinkronisasi tarif Perda.",
		})
		return
	}

	items := body.Tariffs
	if len(items) == 0 {
		items = body.OfficialTariffs
	}

	if len(items) == 0 {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "EMPTY_TARIFFS_ARRAY",
			"message": "Wajib menyertakan minimal 1 item tarif resmi Perda pada array 'tariffs' atau 'official_tariffs'.",
		})
		return
	}

	updated, err := h.repo.SyncTariffsCMS(id, items)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": err.Error(),
		})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"message": "Tabel Fair-Price Barometer (Tarif Resmi Perda) berhasil disinkronkan oleh CMS FS-1.",
		"data":    updated,
	})
}
