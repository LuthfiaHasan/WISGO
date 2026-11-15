package system_core

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/culture_ranking"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/scenes360"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/spatial"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()

	destRepo := destination.NewRepository()
	scenesRepo := scenes360.NewRepository()
	spatialRepo := spatial.NewRepository()
	cultureRepo := culture_ranking.NewRepository()

	repo := NewRepository(destRepo, scenesRepo, spatialRepo, cultureRepo)
	cache := middleware.NewInMemoryTTLCache(5 * time.Minute)
	rateLimiter := middleware.NewTokenBucketRateLimiter(60, 60*time.Second)

	service := NewService(repo, cache, rateLimiter)
	handler := NewHandler(service)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r
}

func TestSystemCoreSuite(t *testing.T) {
	r := setupTestRouter()

	t.Run("TC-S7-01: GET /api/v1/system/contracts mengembalikan tepat 24 endpoint resmi BE-1", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/system/contracts", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res SystemContractsCatalogResponse
		if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to decode JSON: %v", err)
		}
		if res.TotalEndpoints != 24 {
			t.Fatalf("expected exactly 24 endpoints in total, got %d", res.TotalEndpoints)
		}
		if res.ReturnedEndpoints != 24 {
			t.Fatalf("expected 24 returned endpoints, got %d", res.ReturnedEndpoints)
		}
	})

	t.Run("TC-S7-02: Filter sprint pada katalog kontrak", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/system/contracts?sprint=Sprint+1", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res SystemContractsCatalogResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.ReturnedEndpoints != 7 {
			t.Fatalf("expected 7 endpoints for Sprint 1, got %d", res.ReturnedEndpoints)
		}
	})

	t.Run("TC-S7-03: GET /api/v1/admin/system/benchmark memverifikasi SLA <100ms", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/admin/system/benchmark", nil)
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res SystemBenchmarkResponse
		if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to decode benchmark JSON: %v", err)
		}
		if !res.SLAVerification.SLAPassed {
			t.Fatalf("expected sla_passed=true, got %+v", res.SLAVerification)
		}
		if res.SLAVerification.P99LatencyMS >= 100.0 {
			t.Fatalf("expected p99 < 100ms, got %v", res.SLAVerification.P99LatencyMS)
		}
	})

	t.Run("TC-S7-04: Proteksi RBAC pada GET /api/v1/admin/system/benchmark", func(t *testing.T) {
		// 401 tanpa token
		reqAnon := httptest.NewRequest(http.MethodGet, "/api/v1/admin/system/benchmark", nil)
		recAnon := httptest.NewRecorder()
		r.ServeHTTP(recAnon, reqAnon)
		if recAnon.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", recAnon.Code)
		}

		// 403 role tourist
		reqTourist := httptest.NewRequest(http.MethodGet, "/api/v1/admin/system/benchmark", nil)
		reqTourist.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		recTourist := httptest.NewRecorder()
		r.ServeHTTP(recTourist, reqTourist)
		if recTourist.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden, got %d", recTourist.Code)
		}
	})

	t.Run("TC-S7-05: POST /api/v1/admin/cache/flush mengosongkan cache in-memory", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/admin/cache/flush", nil)
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on cache flush, got %d: %s", rec.Code, rec.Body.String())
		}

		var res CacheFlushResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Status != "flushed" {
			t.Fatalf("expected status=flushed, got %s", res.Status)
		}
	})

	t.Run("TC-S7-06: Proteksi RBAC pada POST /api/v1/admin/cache/flush", func(t *testing.T) {
		// 401 tanpa token
		reqAnon := httptest.NewRequest(http.MethodPost, "/api/v1/admin/cache/flush", nil)
		recAnon := httptest.NewRecorder()
		r.ServeHTTP(recAnon, reqAnon)
		if recAnon.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", recAnon.Code)
		}

		// 403 role tourist
		reqTourist := httptest.NewRequest(http.MethodPost, "/api/v1/admin/cache/flush", nil)
		reqTourist.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		recTourist := httptest.NewRecorder()
		r.ServeHTTP(recTourist, reqTourist)
		if recTourist.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden, got %d", recTourist.Code)
		}
	})
}
