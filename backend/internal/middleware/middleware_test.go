package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func TestJWTRBACMiddleware(t *testing.T) {
	r := gin.New()
	adminRoute := r.Group("/admin")
	adminRoute.Use(RequireRoles("admin_dispar"))
	adminRoute.GET("/dashboard", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "message": "Admin Access Granted"})
	})

	// 1. Missing Token -> 401
	req1 := httptest.NewRequest(http.MethodGet, "/admin/dashboard", nil)
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)
	if w1.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401 Unauthorized for missing token, got %d", w1.Code)
	}

	// 2. Invalid Token -> 401
	req2 := httptest.NewRequest(http.MethodGet, "/admin/dashboard", nil)
	req2.Header.Set("Authorization", "Bearer invalid-token-xyz")
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)
	if w2.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401 Unauthorized for invalid token, got %d", w2.Code)
	}

	// 3. Insufficient Role (Tourist token accessing Admin route) -> 403
	req3 := httptest.NewRequest(http.MethodGet, "/admin/dashboard", nil)
	req3.Header.Set("Authorization", "Bearer "+TokenTourist)
	w3 := httptest.NewRecorder()
	r.ServeHTTP(w3, req3)
	if w3.Code != http.StatusForbidden {
		t.Fatalf("Expected 403 Forbidden for tourist role on admin route, got %d", w3.Code)
	}

	// 4. Valid Admin Token -> 200 OK
	req4 := httptest.NewRequest(http.MethodGet, "/admin/dashboard", nil)
	req4.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
	w4 := httptest.NewRecorder()
	r.ServeHTTP(w4, req4)
	if w4.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for admin_dispar token, got %d", w4.Code)
	}
}

func TestTokenBucketRateLimiter(t *testing.T) {
	limiter := NewTokenBucketRateLimiter(2, 10*time.Second) // Max burst 2 tokens
	r := gin.New()
	r.POST("/report", limiter.RateLimit("report"), func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// 1. Request 1 -> 200 OK
	req1 := httptest.NewRequest(http.MethodPost, "/report", nil)
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)
	if w1.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on request 1, got %d", w1.Code)
	}

	// 2. Request 2 -> 200 OK
	req2 := httptest.NewRequest(http.MethodPost, "/report", nil)
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)
	if w2.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on request 2, got %d", w2.Code)
	}

	// 3. Request 3 -> 429 Too Many Requests (Exceeded burst)
	req3 := httptest.NewRequest(http.MethodPost, "/report", nil)
	w3 := httptest.NewRecorder()
	r.ServeHTTP(w3, req3)
	if w3.Code != http.StatusTooManyRequests {
		t.Fatalf("Expected 429 Too Many Requests on request 3, got %d", w3.Code)
	}
	if w3.Header().Get("Retry-After") != "60" {
		t.Fatalf("Expected Retry-After=60 header on 429 response")
	}

	// 4. Test QA simulation header
	reqSim := httptest.NewRequest(http.MethodPost, "/report", nil)
	reqSim.Header.Set("X-Simulate-RateLimit", "burst")
	wSim := httptest.NewRecorder()
	r.ServeHTTP(wSim, reqSim)
	if wSim.Code != http.StatusTooManyRequests {
		t.Fatalf("Expected 429 Too Many Requests on simulation header, got %d", wSim.Code)
	}
}

func TestInMemoryTTLCache(t *testing.T) {
	cache := NewInMemoryTTLCache(1 * time.Minute)
	r := gin.New()
	r.GET("/data", func(c *gin.Context) {
		cache.WriteCachedJSON(c, "data-key", func() (interface{}, int, error) {
			return map[string]interface{}{"value": "minang-tourism"}, http.StatusOK, nil
		})
	})

	// 1. First Request -> MISS (200 OK)
	req1 := httptest.NewRequest(http.MethodGet, "/data", nil)
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, req1)
	if w1.Code != http.StatusOK || w1.Header().Get("X-Cache") != "MISS" {
		t.Fatalf("Expected 200 OK and X-Cache MISS, got %d and %s", w1.Code, w1.Header().Get("X-Cache"))
	}
	etag := w1.Header().Get("ETag")
	if etag == "" {
		t.Fatalf("Expected ETag header to be generated")
	}

	// 2. Second Request -> HIT (200 OK)
	req2 := httptest.NewRequest(http.MethodGet, "/data", nil)
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)
	if w2.Code != http.StatusOK || w2.Header().Get("X-Cache") != "HIT" {
		t.Fatalf("Expected 200 OK and X-Cache HIT, got %d and %s", w2.Code, w2.Header().Get("X-Cache"))
	}

	// 3. If-None-Match with matching ETag -> 304 Not Modified
	req3 := httptest.NewRequest(http.MethodGet, "/data", nil)
	req3.Header.Set("If-None-Match", etag)
	w3 := httptest.NewRecorder()
	r.ServeHTTP(w3, req3)
	if w3.Code != http.StatusNotModified {
		t.Fatalf("Expected 304 Not Modified, got %d", w3.Code)
	}

	// 4. FlushAll -> next request is MISS
	cache.FlushAll()
	req4 := httptest.NewRequest(http.MethodGet, "/data", nil)
	w4 := httptest.NewRecorder()
	r.ServeHTTP(w4, req4)
	if w4.Code != http.StatusOK || w4.Header().Get("X-Cache") != "MISS" {
		t.Fatalf("Expected 200 OK and X-Cache MISS after flush, got %d and %s", w4.Code, w4.Header().Get("X-Cache"))
	}

	// Check stats
	stats := cache.Stats()
	if stats["active_keys"].(int) != 1 {
		t.Fatalf("Expected 1 active key in stats, got %v", stats["active_keys"])
	}
}
