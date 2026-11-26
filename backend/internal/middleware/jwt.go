package middleware

import (
	"encoding/base64"
	"encoding/json"
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
	TokenVendor      = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXZlbmRvci0wMSIsIm5hbWUiOiJTYW5nZ2FyIEJ1ZGF5YSBNaW5hbmcgKFZlbmRvcikiLCJyb2xlIjoidmVuZG9yIn0.rancakin_sig_vendor"
)

var validTokenRoles = map[string]string{
	TokenAdminDispar: "admin_dispar",
	TokenPokdarwis:   "pokdarwis",
	TokenTourist:     "tourist",
	TokenVendor:      "vendor",
}

var validTokenUserIDs = map[string]string{
	TokenAdminDispar: "user-admin-dispar-01",
	TokenPokdarwis:   "user-pokdarwis-01",
	TokenTourist:     "user-tourist-01",
	TokenVendor:      "user-vendor-01",
}

func decodeBase64Segment(seg string) ([]byte, error) {
	if b, err := base64.RawURLEncoding.DecodeString(seg); err == nil {
		return b, nil
	}
	if b, err := base64.URLEncoding.DecodeString(seg); err == nil {
		return b, nil
	}
	if b, err := base64.RawStdEncoding.DecodeString(seg); err == nil {
		return b, nil
	}
	return base64.StdEncoding.DecodeString(seg)
}

func normalizeRole(r string) string {
	switch strings.ToLower(strings.TrimSpace(r)) {
	case "admin_utama", "admin_dispar", "admin", "superadmin":
		return "admin_dispar"
	case "pokdarwis":
		return "pokdarwis"
	case "vendor", "mitra":
		return "vendor"
	case "tourist", "wisatawan", "user":
		return "tourist"
	default:
		return r
	}
}

// ResolveTokenRole memvalidasi token preset pengujian, token Web Admin FS-1 (admin_utama), maupun token sesi dinamis OTP/Google BE-2
func ResolveTokenRole(token string) (role string, userID string, valid bool) {
	token = strings.TrimSpace(token)
	if token == "" {
		return "", "", false
	}

	// 1. Cek preset token standar
	if r, ok := validTokenRoles[token]; ok {
		return r, validTokenUserIDs[token], true
	}

	// 2. Cek token dinamis yang diterbitkan oleh modul auth BE-2 (format: jwt-wisgo-[role-]<userID>-<timestamp>)
	if strings.HasPrefix(token, "jwt-wisgo-") {
		rest := strings.TrimPrefix(token, "jwt-wisgo-")
		switch {
		case strings.HasPrefix(rest, "vendor-"):
			return "vendor", strings.TrimPrefix(rest, "vendor-"), true
		case strings.HasPrefix(rest, "admin-"):
			return "admin_dispar", strings.TrimPrefix(rest, "admin-"), true
		case strings.HasPrefix(rest, "pokdarwis-"):
			return "pokdarwis", strings.TrimPrefix(rest, "pokdarwis-"), true
		default:
			return "tourist", rest, true
		}
	}

	// 3. Cek format JWT 3-segmen standar (header.payload.signature) termasuk token Web Admin FS-1 (.wisgo-komando-sig-2026)
	parts := strings.Split(token, ".")
	if len(parts) == 3 && (strings.HasPrefix(parts[2], "rancakin_sig_") ||
		strings.HasPrefix(parts[2], "wisgo_sig_") ||
		strings.HasPrefix(parts[2], "wisgo-komando-sig")) {
		if payloadBytes, err := decodeBase64Segment(parts[1]); err == nil {
			var claims map[string]interface{}
			if err := json.Unmarshal(payloadBytes, &claims); err == nil {
				r, _ := claims["role"].(string)
				sub, _ := claims["sub"].(string)
				if r != "" {
					return normalizeRole(r), sub, true
				}
			}
		}
	}

	return "", "", false
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
		role, userID, exists := ResolveTokenRole(token)
		if !exists {
			common.Error(c, http.StatusUnauthorized, "Token JWT tidak valid atau tidak dikenali oleh server WISGO.", gin.H{
				"code": "UNAUTHORIZED_INVALID_TOKEN",
			})
			c.Abort()
			return
		}

		allowed := false
		for _, allowedRole := range allowedRoles {
			if role == normalizeRole(allowedRole) {
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
		if userID != "" {
			c.Set("user_id", userID)
		}
		c.Next()
	}
}
