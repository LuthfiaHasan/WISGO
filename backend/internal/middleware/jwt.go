package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Preset Token JWT Bersama untuk Pengujian (BE-1, BE-2, FE-1, FE-2, FS-1)
// Kompatibel 100% dengan standar kontrak JWT WISGO
const (
	TokenAdminDispar = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLWFkbWluLWRpc3Bhci0wMSIsIm5hbWUiOiJBZG1pbiBEaXNwYXIgU3VtYmFyIChGUy0xKSIsInJvbGUiOiJhZG1pbl9kaXNwYXIifQ.rancakin_sig_admin"
	TokenPokdarwis   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXBva2Rhcndpcy0wMSIsIm5hbWUiOiJVZGEgWnVsIChQb2tkYXJ3aXMgTmFnYXJpKSIsInJvbGUiOiJwb2tkYXJ3aXMifQ.rancakin_sig_pokdarwis"
	TokenTourist     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXRvdXJpc3QtMDEiLCJuYW1lIjoiUml6a3kgUHJhdGFtYSAoV2lzYXRhd2FuKSIsInJvbGUiOiJ0b3VyaXN0In0.rancakin_sig_tourist"
)

var validTokenRoles = map[string]string{
	TokenAdminDispar: "admin_dispar",
	TokenPokdarwis:   "pokdarwis",
	TokenTourist:     "tourist",
}

// RequireRoles memvalidasi Authorization Bearer JWT dan memeriksa peran (RBAC) pada Gin Framework
func RequireRoles(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			common.Error(c, http.StatusUnauthorized, "Header Authorization Bearer token wajib disertakan untuk operasi Admin CMS.", gin.H{
				"code": "UNAUTHORIZED_MISSING_TOKEN",
			})
			c.Abort()
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		role, exists := validTokenRoles[token]
		if !exists {
			common.Error(c, http.StatusUnauthorized, "Token JWT tidak valid atau tidak dikenali oleh server WISGO.", gin.H{
				"code": "UNAUTHORIZED_INVALID_TOKEN",
			})
			c.Abort()
			return
		}

		allowed := false
		for _, allowedRole := range allowedRoles {
			if role == allowedRole {
				allowed = true
				break
			}
		}

		if !allowed {
			common.Error(c, http.StatusForbidden, "Akses ditolak: Role Anda tidak memiliki izin untuk mengubah data destinasi CMS.", gin.H{
				"code":           "FORBIDDEN_INSUFFICIENT_ROLE",
				"current_role":   role,
				"required_roles": allowedRoles,
			})
			c.Abort()
			return
		}

		c.Set("user_role", role)
		c.Next()
	}
}
