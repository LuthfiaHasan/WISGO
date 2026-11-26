package spatial

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Handler menangani endpoint HTTP Gin untuk modul spasial
type Handler struct {
	service     Service
	rateLimiter *middleware.TokenBucketRateLimiter
}

// NewHandler membuat instance Handler baru
func NewHandler(service Service, rateLimiter *middleware.TokenBucketRateLimiter) *Handler {
	return &Handler{
		service:     service,
		rateLimiter: rateLimiter,
	}
}

// RegisterRoutes mendaftarkan seluruh route spatial ke router group
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	// Publik / Wisatawan (+ Alias Mobile api_service.dart & Web Admin api.ts)
	rg.GET("/spatial/shunlu", h.GetShunluSearch)
	rg.POST("/spatial/shunlu", h.PostShunluSearch)
	rg.POST("/spatial/along-route", h.PostShunluSearch)
	rg.GET("/destinations/:id/micro-map", h.GetDestinationMicroMap)
	rg.GET("/spatial/micro-map/:id", h.GetDestinationMicroMap)
	rg.POST("/spatial/audio-trigger-check", h.PostCheckAudioGPSTrigger)
	rg.POST("/spatial/audio-guide", h.PostCheckAudioGPSTrigger)
	rg.GET("/spatial/hazards", h.GetLiveHazardAlerts)
	rg.GET("/hazards/active", h.GetLiveHazardAlerts)
	rg.GET("/hazards/alerts", h.GetLiveHazardAlerts)
	rg.GET("/spatial/nearby", h.GetNearbyDestinations)
	rg.GET("/spatial/emergency-contacts", h.GetEmergencyContacts)
	rg.POST("/routes/optimize-tsp", h.PostOptimizeTSP)

	// Rate-limited endpoints (Anti-Spam Token Bucket)
	rg.POST("/spatial/sos", h.rateLimiter.Protect("sos_emergency"), h.PostSOSEmergencySignal)
	rg.POST("/hazards/sos", h.rateLimiter.Protect("sos_emergency"), h.PostSOSEmergencySignal)
	rg.POST("/sos/signal", h.rateLimiter.Protect("sos_emergency"), h.PostSOSEmergencySignal)
	rg.POST("/spatial/navigation-telemetry", h.rateLimiter.Protect("nav_telemetry"), h.PostNavigationTelemetry)

	// Admin Command Center & Web Admin FS-1: Proteksi RBAC JWT (admin_dispar, admin_utama, pokdarwis)
	adminAuth := middleware.RequireRoles("admin_dispar", "pokdarwis")
	rg.PUT("/hazards/:id", adminAuth, h.PutUpdateHazardWebAdmin)
	rg.PUT("/sos/tickets/:id/status", adminAuth, h.PutUpdateSOSTicketStatus)
	rg.POST("/spatial/emergency-contacts", adminAuth, h.UpsertEmergencyContactAdmin)
	rg.PUT("/spatial/emergency-contacts/:id", adminAuth, h.UpsertEmergencyContactAdmin)
	rg.DELETE("/spatial/emergency-contacts/:id", adminAuth, h.DeleteEmergencyContactAdmin)

	admin := rg.Group("/admin")
	admin.Use(adminAuth)
	{
		admin.POST("/hazards/trigger", h.PostTriggerHazardAdmin)
		admin.GET("/sos", h.GetSOSSignalsAdmin)
		admin.PUT("/sos/:id/status", h.PutUpdateSOSTicketStatus)
		admin.POST("/emergency-contacts", h.UpsertEmergencyContactAdmin)
		admin.PUT("/emergency-contacts/:id", h.UpsertEmergencyContactAdmin)
		admin.DELETE("/emergency-contacts/:id", h.DeleteEmergencyContactAdmin)
	}
}

// GetShunluSearch GET /api/v1/spatial/shunlu (Kompatibilitas Mobile ApiService.searchShunlu)
func (h *Handler) GetShunluSearch(c *gin.Context) {
	_, lat, lng := parseGPS(c)
	req := ShunluSearchRequest{
		OriginLat: lat,
		OriginLng: lng,
		Category:  c.Query("category"),
	}
	resp, err := h.service.SearchShunlu(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, resp)
}

// PostShunluSearch POST /api/v1/spatial/shunlu
func (h *Handler) PostShunluSearch(c *gin.Context) {
	var req ShunluSearchRequest
	_ = c.ShouldBindJSON(&req)

	resp, err := h.service.SearchShunlu(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// GetDestinationMicroMap GET /api/v1/destinations/:id/micro-map
func (h *Handler) GetDestinationMicroMap(c *gin.Context) {
	idOrSlug := c.Param("id")

	microMap, err := h.service.GetMicroMap(idOrSlug)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": "Destinasi tidak ditemukan untuk pemuatan Peta Mikro Kawasan.",
		})
		return
	}

	c.JSON(http.StatusOK, microMap)
}

// PostCheckAudioGPSTrigger POST /api/v1/spatial/audio-trigger-check
func (h *Handler) PostCheckAudioGPSTrigger(c *gin.Context) {
	var req AudioTriggerCheckRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Payload JSON tidak valid"})
		return
	}

	resp, err := h.service.CheckAudioTrigger(req)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// GetLiveHazardAlerts GET /api/v1/spatial/hazards
func (h *Handler) GetLiveHazardAlerts(c *gin.Context) {
	severity := strings.TrimSpace(c.Query("severity"))
	corridor := strings.TrimSpace(c.Query("corridor"))
	hasGPS, lat, lng := parseGPS(c)

	resp, err := h.service.GetLiveHazards(severity, corridor, hasGPS, lat, lng)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// PostTriggerHazardAdmin POST /api/v1/admin/hazards/trigger
func (h *Handler) PostTriggerHazardAdmin(c *gin.Context) {
	var input TriggerHazardInput
	if err := c.ShouldBindJSON(&input); err != nil || strings.TrimSpace(input.CorridorCode) == "" || strings.TrimSpace(input.Severity) == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Field 'corridor_code' (misal: SITINJAU-LAUIK) dan 'severity' (Normal/Waspada/Siaga/Awas Tutup Total) wajib diisi.",
		})
		return
	}

	updated, err := h.service.TriggerHazard(input)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": fmt.Sprintf("Koridor jalur ekstrem '%s' tidak ditemukan.", input.CorridorCode),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":           "hazard_triggered",
		"broadcast_target": "FE-1 Banner Peringatan Jalur Rawan & Rute Pengalihan Otomatis",
		"hazard_alert":     updated,
	})
}

// PostSOSEmergencySignal POST /api/v1/spatial/sos
func (h *Handler) PostSOSEmergencySignal(c *gin.Context) {
	var input SOSEmergencyInput
	if err := c.ShouldBindJSON(&input); err != nil || (input.Latitude == 0 && input.Longitude == 0) {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Koordinat GPS ('latitude' & 'longitude') wajib disertakan saat memancarkan sinyal darurat SOS.",
		})
		return
	}

	resp, err := h.service.DispatchSOS(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// GetSOSSignalsAdmin GET /api/v1/admin/sos
func (h *Handler) GetSOSSignalsAdmin(c *gin.Context) {
	signals, _ := h.service.GetSOSSignals()
	c.JSON(http.StatusOK, gin.H{
		"status":      "ok",
		"total_sos":   len(signals),
		"sos_signals": signals,
	})
}

// PostNavigationTelemetry POST /api/v1/spatial/navigation-telemetry
func (h *Handler) PostNavigationTelemetry(c *gin.Context) {
	var input NavigationTelemetryInput
	if err := c.ShouldBindJSON(&input); err != nil || strings.TrimSpace(input.DestinationID) == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Payload telemetri tidak valid; field 'destination_id' dan 'dwell_time_minutes' wajib diisi.",
		})
		return
	}

	// Tolak ping GPS palsu jika dwell time < 10 menit (kendaraan hanya melintas)
	if input.DwellTimeMinutes < 10 {
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"status":              "rejected_pass_by",
			"destination_id":      input.DestinationID,
			"dwell_time_minutes":  input.DwellTimeMinutes,
			"anti_fake_guardrail": "Dwell time di bawah 10 menit terdeteksi sebagai kendaraan melintas (pass-by), tidak dihitung ke dalam Gaode Ranking.",
		})
		return
	}

	updated, err := h.service.RecordTelemetry(input)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Destinasi tidak ditemukan pada indeks Gaode Ranking.",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":         "telemetry_recorded",
		"message":        "Telemetri navigasi & dwell time GPS berhasil diverifikasi. Skor Gaode Ranking diperbarui otomatis.",
		"updated_metric": updated,
	})
}

// GetNearbyDestinations GET /api/v1/spatial/nearby
func (h *Handler) GetNearbyDestinations(c *gin.Context) {
	hasGPS, lat, lng := parseGPS(c)
	if !hasGPS {
		lat = -0.9471 // Fallback default Padang
		lng = 100.4172
	}

	radiusKm := 50.0
	if rStr := c.Query("radius"); rStr != "" {
		if rVal, err := strconv.ParseFloat(rStr, 64); err == nil && rVal > 0 {
			// Jika dikirim dalam meter (> 1000), konversi ke km
			if rVal > 1000 {
				rVal = rVal / 1000.0
			}
			radiusKm = rVal
		}
	}

	category := c.Query("category")
	list := h.service.GetNearbyDestinations(lat, lng, radiusKm, category)

	c.JSON(http.StatusOK, gin.H{
		"status":         "ok",
		"engine":         "PostGIS ST_DWithin Spatial Query",
		"user_latitude":  lat,
		"user_longitude": lng,
		"radius_km":      radiusKm,
		"total_nearby":   len(list),
		"destinations":   list,
	})
}

// PostOptimizeTSP POST /api/v1/routes/optimize-tsp
func (h *Handler) PostOptimizeTSP(c *gin.Context) {
	var req OptimizeTSPRequest
	_ = c.ShouldBindJSON(&req)

	resp, err := h.service.OptimizeTSP(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// GetEmergencyContacts GET /api/v1/spatial/emergency-contacts
func (h *Handler) GetEmergencyContacts(c *gin.Context) {
	corridor := c.Query("corridor")
	resp := h.service.GetEmergencyContacts(corridor)
	c.JSON(http.StatusOK, resp)
}

// PutUpdateHazardWebAdmin PUT /api/v1/hazards/:id (Web Admin api.ts)
func (h *Handler) PutUpdateHazardWebAdmin(c *gin.Context) {
	id := c.Param("id")
	var input TriggerHazardInput
	_ = c.ShouldBindJSON(&input)
	if input.CorridorCode == "" {
		input.CorridorCode = id
	}
	if input.Severity == "" {
		input.Severity = "Waspada"
	}
	updated, err := h.service.TriggerHazard(input)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "hazard_updated", "hazard_alert": updated})
}

// PutUpdateSOSTicketStatus PUT /api/v1/sos/tickets/:id/status (Web Admin api.ts)
func (h *Handler) PutUpdateSOSTicketStatus(c *gin.Context) {
	id := c.Param("id")
	var body struct {
		Status          string `json:"status"`
		SARUnitAssigned string `json:"sar_unit_assigned"`
	}
	_ = c.ShouldBindJSON(&body)
	updated, err := h.service.UpdateSOSTicketStatus(id, body.Status, body.SARUnitAssigned)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok", "sos_signal": updated})
}

// UpsertEmergencyContactAdmin POST/PUT /api/v1/spatial/emergency-contacts
func (h *Handler) UpsertEmergencyContactAdmin(c *gin.Context) {
	var input models.EmergencyContact
	if err := c.ShouldBindJSON(&input); err != nil || strings.TrimSpace(input.AgencyName) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Field 'agency_name' dan 'phone_number' wajib diisi."})
		return
	}
	if idParam := strings.TrimSpace(c.Param("id")); idParam != "" {
		input.ID = idParam
	}
	saved := h.service.UpsertEmergencyContact(input)
	c.JSON(http.StatusOK, gin.H{"status": "ok", "contact": saved})
}

// DeleteEmergencyContactAdmin DELETE /api/v1/spatial/emergency-contacts/:id
func (h *Handler) DeleteEmergencyContactAdmin(c *gin.Context) {
	id := c.Param("id")
	if err := h.service.DeleteEmergencyContact(id); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Kontak darurat tidak ditemukan."})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "deleted", "id": id})
}

func parseGPS(c *gin.Context) (bool, float64, float64) {
	latStr := c.Query("lat")
	lngStr := c.Query("lng")
	if latStr == "" || lngStr == "" {
		return false, 0, 0
	}
	lat, err1 := strconv.ParseFloat(latStr, 64)
	lng, err2 := strconv.ParseFloat(lngStr, 64)
	if err1 != nil || err2 != nil {
		return false, 0, 0
	}
	return true, lat, lng
}
