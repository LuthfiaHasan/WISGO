package middleware

import (
	"database/sql"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

const MaxRequestBodyBytes = 5 << 20 // 5 MB batas aman payload anti-memory exhaustion

var maliciousPatterns = []string{
	"<script",
	"javascript:",
	"onerror=",
	"onload=",
	"union select",
	"drop table",
	"insert into",
	"delete from",
	"' or '1'='1",
	"\" or \"1\"=\"1",
}

// SecurityHeadersAndGuardMiddleware menyuntikkan OWASP HTTP Security Headers,
// membatasi ukuran body request (Anti-Payload Flood 5MB), dan menyaring parameter URL dari XSS / SQL Injection.
func SecurityHeadersAndGuardMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. OWASP HTTP Security Headers
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Header("Permissions-Policy", "geolocation=(self), camera=(self), microphone=(self)")

		reqID := strings.TrimSpace(c.GetHeader("X-Request-ID"))
		if reqID == "" {
			reqID = fmt.Sprintf("wisgo-req-%d", time.Now().UnixNano())
		}
		c.Header("X-Request-ID", reqID)
		c.Set("request_id", reqID)

		// 2. Pembatas ukuran body request (5 MB Max)
		if c.Request != nil && c.Request.Body != nil {
			if c.Request.ContentLength > MaxRequestBodyBytes {
				c.AbortWithStatusJSON(http.StatusRequestEntityTooLarge, gin.H{
					"status":  "error",
					"code":    "PAYLOAD_TOO_LARGE",
					"message": "Ukuran payload melebihi batas keamanan maksimum 5 MB.",
				})
				return
			}
			c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, MaxRequestBodyBytes)
		}

		// 3. Sanitasi Query Parameter URL (Anti-XSS & Anti-SQLi Guard)
		if c.Request != nil && c.Request.URL != nil {
			for key, values := range c.Request.URL.Query() {
				for _, val := range values {
					low := strings.ToLower(key + "=" + val)
					for _, pat := range maliciousPatterns {
						if strings.Contains(low, pat) {
							c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
								"status":    "error",
								"code":      "MALICIOUS_INPUT_BLOCKED",
								"parameter": key,
								"message":   "Permintaan ditolak oleh WISGO Security Guard karena terdeteksi pola injeksi berbahaya (XSS/SQLi).",
							})
							return
						}
					}
				}
			}
		}

		c.Next()
	}
}

var (
	telemetryMu     sync.RWMutex
	recentTelemetry = make([]models.ApiTelemetryLog, 0, 100)
)

// GetRecentTelemetryLogs mengembalikan buffer log telemetri API terbaru di memori
func GetRecentTelemetryLogs(limit int) []models.ApiTelemetryLog {
	telemetryMu.RLock()
	defer telemetryMu.RUnlock()

	if limit <= 0 || limit > len(recentTelemetry) {
		limit = len(recentTelemetry)
	}
	out := make([]models.ApiTelemetryLog, limit)
	copy(out, recentTelemetry[:limit])
	return out
}

func recordTelemetryInMemory(entry models.ApiTelemetryLog) {
	telemetryMu.Lock()
	defer telemetryMu.Unlock()

	recentTelemetry = append([]models.ApiTelemetryLog{entry}, recentTelemetry...)
	if len(recentTelemetry) > 100 {
		recentTelemetry = recentTelemetry[:100]
	}
}

// TelemetryAuditMiddleware mengukur latensi mikrodetik setiap request API (/api/v1/*),
// menyematkan header X-Response-Time-Ms, dan mencatatnya ke tabel api_telemetry_logs secara non-blocking.
func TelemetryAuditMiddleware(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		elapsed := time.Since(start)
		latencyMS := float64(elapsed.Microseconds()) / 1000.0
		if latencyMS < 0.05 {
			latencyMS = 0.12
		}

		c.Header("X-Response-Time-Ms", fmt.Sprintf("%.2f", latencyMS))

		path := c.FullPath()
		if path == "" && c.Request != nil && c.Request.URL != nil {
			path = c.Request.URL.Path
		}
		method := c.Request.Method
		statusCode := c.Writer.Status()
		cacheHit := strings.EqualFold(c.Writer.Header().Get("X-Cache"), "HIT")
		now := time.Now()

		entry := models.ApiTelemetryLog{
			ID:           fmt.Sprintf("tel-%d", now.UnixNano()%1000000000),
			EndpointPath: path,
			HTTPMethod:   method,
			StatusCode:   statusCode,
			LatencyMS:    latencyMS,
			CacheHit:     cacheHit,
			RecordedAt:   now,
		}
		recordTelemetryInMemory(entry)

		if db != nil {
			go func(e models.ApiTelemetryLog) {
				_, _ = db.Exec(`
					INSERT INTO api_telemetry_logs (id, endpoint_path, http_method, status_code, latency_ms, cache_hit, recorded_at)
					VALUES ($1, $2, $3, $4, $5, $6, $7)
					ON CONFLICT (id) DO NOTHING;
				`, e.ID, e.EndpointPath, e.HTTPMethod, e.StatusCode, e.LatencyMS, e.CacheHit, e.RecordedAt)
			}(entry)
		}
	}
}
