package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/LuthfiaHasan/WISGO/backend/internal/database"
)

// DatabaseGuardMiddleware memastikan database online sebelum melayani request data API di mode dev & prod
func DatabaseGuardMiddleware(env string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if env != "test" && !database.IsConnected() {
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{
				"status":  "error",
				"message": "Koneksi ke database pusat terputus (offline). Data tidak dapat diakses, silakan periksa koneksi internet Anda.",
			})
			return
		}
		c.Next()
	}
}
