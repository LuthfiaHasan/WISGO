package system_core

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
)

// Handler menangani endpoint HTTP Gin untuk modul system_core
type Handler struct {
	service Service
}

// NewHandler membuat instance Handler baru
func NewHandler(service Service) *Handler {
	return &Handler{
		service: service,
	}
}

// RegisterRoutes mendaftarkan seluruh endpoint system_core ke router group
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	// Publik: Katalog Kontrak 24 Endpoint & Sistem Notifikasi In-App (Tabel notifikasi BE-1)
	rg.GET("/system/contracts", h.GetSystemContractsCatalog)
	rg.GET("/notifications", h.GetSystemNotifications)
	rg.POST("/notifications/broadcast", h.PostBroadcastNotification)

	// Admin: Proteksi RBAC JWT (admin_dispar, admin_utama & pokdarwis)
	admin := rg.Group("/admin")
	admin.Use(middleware.RequireRoles("admin_dispar", "pokdarwis"))
	{
		admin.GET("/system/benchmark", h.GetSystemBenchmarkAdmin)
		admin.POST("/cache/flush", h.PostFlushCacheAdmin)
		admin.POST("/notifications/broadcast", h.PostBroadcastNotification)
	}
}

// GetSystemContractsCatalog GET /api/v1/system/contracts
func (h *Handler) GetSystemContractsCatalog(c *gin.Context) {
	sprintFilter := strings.TrimSpace(c.Query("sprint"))
	resp := h.service.GetContractsCatalog(sprintFilter)
	c.JSON(http.StatusOK, resp)
}

// GetSystemBenchmarkAdmin GET /api/v1/admin/system/benchmark
func (h *Handler) GetSystemBenchmarkAdmin(c *gin.Context) {
	resp := h.service.GetBenchmark()
	c.JSON(http.StatusOK, resp)
}

// PostFlushCacheAdmin POST /api/v1/admin/cache/flush
func (h *Handler) PostFlushCacheAdmin(c *gin.Context) {
	role := c.GetString("role")
	if role == "" {
		role = c.GetHeader("X-Authenticated-Role")
	}

	resp := h.service.FlushCache(role)
	c.JSON(http.StatusOK, resp)
}

// GetSystemNotifications GET /api/v1/notifications
func (h *Handler) GetSystemNotifications(c *gin.Context) {
	userID := strings.TrimSpace(c.Query("user_id"))
	list := h.service.ListNotifications(userID)
	c.JSON(http.StatusOK, gin.H{
		"status":        "ok",
		"total":         len(list),
		"notifications": list,
	})
}

// PostBroadcastNotification POST /api/v1/notifications/broadcast
func (h *Handler) PostBroadcastNotification(c *gin.Context) {
	var req BroadcastNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Title) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Field 'title' dan 'message' wajib diisi."})
		return
	}
	created := h.service.BroadcastNotification(req)
	c.JSON(http.StatusCreated, gin.H{
		"status":       "broadcasted",
		"notification": created,
	})
}
