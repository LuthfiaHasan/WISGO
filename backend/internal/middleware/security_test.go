package middleware

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func TestSecurityHeadersAndGuardMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(SecurityHeadersAndGuardMiddleware())
	r.Use(TelemetryAuditMiddleware(nil))

	r.GET("/api/v1/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
	r.POST("/api/v1/upload", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "uploaded"})
	})

	t.Run("TC-SEC-01: Menyuntikkan OWASP Security Headers & X-Response-Time-Ms Telemetry", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/test?city=Padang", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
		if rec.Header().Get("X-Content-Type-Options") != "nosniff" {
			t.Fatal("missing X-Content-Type-Options: nosniff")
		}
		if rec.Header().Get("X-Frame-Options") != "DENY" {
			t.Fatal("missing X-Frame-Options: DENY")
		}
		if rec.Header().Get("X-Request-ID") == "" {
			t.Fatal("missing X-Request-ID header")
		}
		if rec.Header().Get("X-Response-Time-Ms") == "" {
			t.Fatal("missing X-Response-Time-Ms telemetry header")
		}

		logs := GetRecentTelemetryLogs(5)
		if len(logs) == 0 {
			t.Fatal("expected telemetry log entry to be recorded in memory buffer")
		}
	})

	t.Run("TC-SEC-02: Memblokir Query Parameter Berbahaya (XSS & SQL Injection -> 400 Bad Request)", func(t *testing.T) {
		reqXSS := httptest.NewRequest(http.MethodGet, "/api/v1/test?q=<script>alert(1)</script>", nil)
		recXSS := httptest.NewRecorder()
		r.ServeHTTP(recXSS, reqXSS)

		if recXSS.Code != http.StatusBadRequest {
			t.Fatalf("expected 400 Bad Request on XSS payload, got %d", recXSS.Code)
		}

		reqSQLi := httptest.NewRequest(http.MethodGet, "/api/v1/test?category=alam%20UNION%20SELECT%20*%20FROM%20users", nil)
		recSQLi := httptest.NewRecorder()
		r.ServeHTTP(recSQLi, reqSQLi)

		if recSQLi.Code != http.StatusBadRequest {
			t.Fatalf("expected 400 Bad Request on SQLi payload, got %d", recSQLi.Code)
		}
	})

	t.Run("TC-SEC-03: Memblokir Request Body > 5 MB (413 Payload Too Large)", func(t *testing.T) {
		hugeBody := bytes.Repeat([]byte("A"), MaxRequestBodyBytes+1024)
		reqHuge := httptest.NewRequest(http.MethodPost, "/api/v1/upload", bytes.NewReader(hugeBody))
		recHuge := httptest.NewRecorder()
		r.ServeHTTP(recHuge, reqHuge)

		if recHuge.Code != http.StatusRequestEntityTooLarge {
			t.Fatalf("expected 413 Payload Too Large, got %d", recHuge.Code)
		}
	})

	t.Run("TC-SEC-04: Validasi Kriptografi HMAC-SHA256 JWT & Penolakan Token Kedaluwarsa (exp)", func(t *testing.T) {
		// 1. Token HMAC-SHA256 valid dengan exp masa depan
		validToken, err := SignHMACToken(map[string]interface{}{
			"sub":  "usr-admin-hmac-01",
			"role": "admin_dispar",
			"exp":  float64(time.Now().Add(1 * time.Hour).Unix()),
		}, DefaultJWTSecret)
		if err != nil {
			t.Fatalf("failed to sign HMAC token: %v", err)
		}

		role, uid, ok := ResolveTokenRole(validToken)
		if !ok || role != "admin_dispar" || uid != "usr-admin-hmac-01" {
			t.Fatalf("expected valid HMAC token, got ok=%v role=%s uid=%s", ok, role, uid)
		}

		// 2. Token HMAC-SHA256 yang sudah kedaluwarsa (exp di masa lalu) -> ditolak!
		expiredToken, _ := SignHMACToken(map[string]interface{}{
			"sub":  "usr-admin-hmac-01",
			"role": "admin_dispar",
			"exp":  float64(time.Now().Add(-10 * time.Minute).Unix()),
		}, DefaultJWTSecret)

		_, _, expOk := ResolveTokenRole(expiredToken)
		if expOk {
			t.Fatal("expected expired JWT token to be rejected")
		}
	})
}
