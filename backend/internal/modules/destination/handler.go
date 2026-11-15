package destination

import (
	"fmt"
	"net/http"
	"strconv"

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
	rg.GET("/destinations", h.GetDestinations)
	rg.GET("/destinations/detail", h.GetDestinationDetail)
	rg.GET("/destinations/:id", h.GetDestinationByID)
	rg.GET("/destinations/:id/tariffs", h.GetDestinationTariffs)
	rg.GET("/destinations/:id/offline-bundle", h.GetOfflineBundle)

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

	params := SpatialFilterParams{
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
