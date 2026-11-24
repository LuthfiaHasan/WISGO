package destination

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Handler menangani request HTTP untuk domain Direktori Destinasi, Spasial, Offline Bundle, dan CMS Admin
type Handler struct {
	service Service
	cache   *middleware.InMemoryTTLCache
}

// NewHandler membuat instance handler baru
func NewHandler(service Service, cache *middleware.InMemoryTTLCache) *Handler {
	return &Handler{
		service: service,
		cache:   cache,
	}
}

// RegisterRoutes mendaftarkan seluruh endpoint destinasi ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	// Publik
	rg.GET("/categories", h.GetCategories)
	rg.GET("/destinations/categories", h.GetCategories)
	rg.GET("/destinations", h.GetDestinations)
	rg.GET("/destinations/detail", h.GetDestinationDetail)
	rg.GET("/destinations/:id", h.GetDestinationByID)
	rg.GET("/destinations/:id/tariffs", h.GetDestinationTariffs)
	rg.GET("/destinations/:id/offline-bundle", h.GetOfflineBundle)

	// Wisatawan (Role: tourist): Input Wisata Hidden Gem (BE-1 Pilar 2 & 6)
	rg.POST("/destinations/hidden-gem", h.CreateHiddenGemTourist)

	// CMS Admin (Diproteksi Middleware JWT RBAC)
	cmsDisparOrPokdarwis := middleware.RequireRoles("admin_dispar", "pokdarwis")
	cmsDisparOnly := middleware.RequireRoles("admin_dispar")

	rg.POST("/destinations", cmsDisparOrPokdarwis, h.CreateDestination)
	rg.PUT("/destinations/:id", cmsDisparOrPokdarwis, h.UpdateDestination)
	rg.PUT("/destinations/:id/tariffs", cmsDisparOrPokdarwis, h.UpdateDestinationTariffsCMS)
	rg.DELETE("/destinations/:id", cmsDisparOnly, h.DeleteDestination)

	// Alias rute /admin/destinations (FS-1 CMS)
	rg.POST("/admin/destinations", cmsDisparOrPokdarwis, h.CreateDestination)
	rg.PUT("/admin/destinations/:id", cmsDisparOrPokdarwis, h.UpdateDestination)
	rg.PUT("/admin/destinations/:id/tariffs", cmsDisparOrPokdarwis, h.UpdateDestinationTariffsCMS)
	rg.DELETE("/admin/destinations/:id", cmsDisparOnly, h.DeleteDestination)

	// Kurasi & Verifikasi Input Wisata Hidden Gem oleh Admin Dispar (FS-1)
	rg.GET("/admin/destinations/pending", cmsDisparOrPokdarwis, h.GetPendingDestinationsAdmin)
	rg.PATCH("/admin/destinations/:id/verify", cmsDisparOrPokdarwis, h.VerifyDestinationAdmin)
	rg.PUT("/admin/destinations/:id/verify", cmsDisparOrPokdarwis, h.VerifyDestinationAdmin)
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

// GetDestinations menangani GET /api/v1/destinations
func (h *Handler) GetDestinations(c *gin.Context) {
	qCity := c.Query("city_regency")
	if qCity == "" {
		qCity = c.Query("kabupaten_kota")
	}
	hasGPS, lat, lng := parseGPS(c)

	catID := c.Query("category_id")
	params := SpatialFilterParams{
		CategoryID:  catID,
		Category:    c.Query("category"),
		CityRegency: qCity,
		CrowdLevel:  c.Query("crowd_level"),
		Signal:      c.Query("signal"),
		SearchQuery: c.Query("q"),
		HasUserGPS:  hasGPS,
		UserLat:     lat,
		UserLng:     lng,
	}

	if h.cache != nil {
		cacheKey := fmt.Sprintf("destinations:%s", c.Request.URL.RawQuery)
		h.cache.WriteCachedJSON(c, cacheKey, func() (interface{}, int, error) {
			list := h.service.FindAllWithSpatial(params)
			return list, http.StatusOK, nil
		})
		return
	}

	list := h.service.FindAllWithSpatial(params)
	c.JSON(http.StatusOK, list)
}

// GetDestinationDetail menangani GET /api/v1/destinations/detail?id=...
func (h *Handler) GetDestinationDetail(c *gin.Context) {
	id := c.Query("id")
	if id == "" {
		id = "dest-001"
	}
	h.writeDetail(c, id)
}

// GetDestinationByID menangani GET /api/v1/destinations/:id
func (h *Handler) GetDestinationByID(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		id = "dest-001"
	}
	h.writeDetail(c, id)
}

func (h *Handler) writeDetail(c *gin.Context, id string) {
	hasGPS, lat, lng := parseGPS(c)
	dest, err := h.service.FindByID(id, hasGPS, lat, lng)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": fmt.Sprintf("Destinasi '%s' tidak ditemukan", id),
		})
		return
	}
	c.JSON(http.StatusOK, dest)
}

// GetDestinationTariffs menangani GET /api/v1/destinations/:id/tariffs
func (h *Handler) GetDestinationTariffs(c *gin.Context) {
	id := c.Param("id")
	res, err := h.service.GetTariffs(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Destinasi tidak ditemukan",
		})
		return
	}
	c.JSON(http.StatusOK, res)
}

// GetOfflineBundle menangani GET /api/v1/destinations/:id/offline-bundle
func (h *Handler) GetOfflineBundle(c *gin.Context) {
	id := c.Param("id")
	res, err := h.service.GetOfflineBundle(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Destinasi tidak ditemukan",
		})
		return
	}
	c.JSON(http.StatusOK, res)
}

// CreateHiddenGemTourist menangani POST /api/v1/destinations/hidden-gem oleh Wisatawan (Role: tourist / publik)
func (h *Handler) CreateHiddenGemTourist(c *gin.Context) {
	// Validasi token jika Authorization header disertakan
	authHeader := c.GetHeader("Authorization")
	hasValidToken := false
	if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		if token != middleware.TokenTourist && token != middleware.TokenAdminDispar && token != middleware.TokenPokdarwis && token != middleware.TokenVendor {
			c.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"code":    "UNAUTHORIZED_INVALID_TOKEN",
				"message": "Token JWT tidak valid atau tidak dikenali oleh server WISGO.",
			})
			return
		}
		hasValidToken = true
	}

	var input CreateHiddenGemInput
	if err := c.ShouldBindJSON(&input); err != nil || strings.TrimSpace(input.Name) == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "INVALID_HIDDEN_GEM_PAYLOAD",
			"message": "Field 'name' wajib diisi untuk menginput wisata hidden gem.",
		})
		return
	}

	// Session validation hardening: Wajib valid Bearer token ATAU non-empty user_id
	resolvedUserID := strings.TrimSpace(input.UserID)
	if resolvedUserID == "" {
		resolvedUserID = strings.TrimSpace(c.Query("user_id"))
	}
	if !hasValidToken && resolvedUserID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "UNAUTHORIZED_MISSING_USER",
			"message": "user_id atau header Authorization wajib disertakan untuk mengusulkan destinasi hidden gem.",
		})
		return
	}
	if input.UserID == "" && resolvedUserID != "" {
		input.UserID = resolvedUserID
	}
	if input.Contributor == "" && resolvedUserID != "" {
		input.Contributor = resolvedUserID
	}

	created, err := h.service.CreateHiddenGem(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if h.cache != nil {
		h.cache.FlushAll()
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Wisata Hidden Gem berhasil diajukan dan sedang menunggu verifikasi oleh Admin Dispar sebelum dipublikasikan ke direktori publik.",
		"data":    created,
	})
}

// GetPendingDestinationsAdmin menangani GET /api/v1/admin/destinations/pending
func (h *Handler) GetPendingDestinationsAdmin(c *gin.Context) {
	list := h.service.GetPendingSubmissions()
	c.JSON(http.StatusOK, gin.H{
		"status":       "success",
		"total":        len(list),
		"destinations": list,
	})
}

// VerifyDestinationAdmin menangani PATCH/PUT /api/v1/admin/destinations/:id/verify
func (h *Handler) VerifyDestinationAdmin(c *gin.Context) {
	id := c.Param("id")
	var req VerifyDestinationRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.Status == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "INVALID_VERIFY_PAYLOAD",
			"message": "Field 'status' wajib diisi dengan nilai 'verified', 'approved', atau 'rejected'.",
		})
		return
	}

	updated, err := h.service.VerifySubmission(id, req.Status)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": err.Error(),
		})
		return
	}

	if h.cache != nil {
		h.cache.FlushAll()
	}

	msg := "Destinasi hidden gem berhasil disetujui dan dipublikasikan resmi ke direktori publik WISGO."
	if strings.ToLower(req.Status) == "rejected" {
		msg = "Pengajuan destinasi hidden gem telah ditolak oleh Admin Dispar."
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": msg,
		"data":    updated,
	})
}

// CreateDestination menangani POST /api/v1/admin/destinations dan POST /api/v1/destinations
func (h *Handler) CreateDestination(c *gin.Context) {
	var input models.Destination
	if err := c.ShouldBindJSON(&input); err != nil || input.Name == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Body JSON tidak valid; field 'name' wajib diisi.",
		})
		return
	}

	created, err := h.service.CreateCMS(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if h.cache != nil {
		h.cache.FlushAll()
	}

	c.JSON(http.StatusCreated, created)
}

// UpdateDestination menangani PUT /api/v1/admin/destinations/:id dan PUT /api/v1/destinations/:id
func (h *Handler) UpdateDestination(c *gin.Context) {
	id := c.Param("id")
	var payload models.Destination
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "JSON tidak valid"})
		return
	}

	updated, err := h.service.UpdateCMS(id, payload)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	if h.cache != nil {
		h.cache.FlushAll()
	}

	c.JSON(http.StatusOK, updated)
}

// DeleteDestination menangani DELETE /api/v1/admin/destinations/:id dan DELETE /api/v1/destinations/:id
func (h *Handler) DeleteDestination(c *gin.Context) {
	id := c.Param("id")
	deletedID, err := h.service.DeleteCMS(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	if h.cache != nil {
		h.cache.FlushAll()
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "deleted",
		"id":      deletedID,
		"message": "Destinasi berhasil dihapus oleh Admin Dispar.",
	})
}

// UpdateDestinationTariffsCMS menangani PUT /api/v1/admin/destinations/:id/tariffs
func (h *Handler) UpdateDestinationTariffsCMS(c *gin.Context) {
	id := c.Param("id")

	var body SyncTariffsPayload
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
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
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "EMPTY_TARIFFS_ARRAY",
			"message": "Wajib menyertakan minimal 1 item tarif resmi Perda pada array 'tariffs' atau 'official_tariffs'.",
		})
		return
	}

	updated, err := h.service.SyncTariffsCMS(id, items)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": err.Error(),
		})
		return
	}

	if h.cache != nil {
		h.cache.FlushAll()
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Tabel Fair-Price Barometer (Tarif Resmi Perda) berhasil disinkronkan oleh CMS FS-1.",
		"data":    updated,
	})
}

// GetCategories GET /api/v1/categories (ERD Revisi #1: Master Categories)
func (h *Handler) GetCategories(c *gin.Context) {
	resp := h.service.GetCategories()
	c.JSON(http.StatusOK, resp)
}
