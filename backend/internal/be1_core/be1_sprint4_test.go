package be1_core

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestSprint4IntegrationSuite menjalankan 8 skenario pengujian otomatis Minggu 4 (Hari 16-20):
// 1. TC-S4-01: In-Memory TTL Cache MISS pada panggilan pertama GET /api/v1/destinations/{id}/scenes-360
// 2. TC-S4-02: In-Memory TTL Cache HIT & header ETag pada panggilan kedua
// 3. TC-S4-03: HTTP 304 Not Modified saat header If-None-Match cocok dengan ETag
// 4. TC-S4-04: Proteksi Token Bucket Rate-Limiting (HTTP 429 Too Many Requests) pada Lapor Pungli (Burst Spam)
// 5. TC-S4-05: Proteksi Token Bucket Rate-Limiting (HTTP 429 Too Many Requests) pada Pancaran SOS GPS (Burst Spam)
// 6. TC-S4-06: Live Performance Benchmark Admin (GET /api/v1/admin/system/benchmark) memverifikasi p99 < 100ms
// 7. TC-S4-07: Manual Cache Flush Admin (POST /api/v1/admin/cache/flush) mereset cache kembali ke MISS
// 8. TC-S4-08: Katalog Final 24 Endpoint BE-1 (GET /api/v1/system/contracts) mengembalikan tepat 24 kontrak
func TestSprint4IntegrationSuite(t *testing.T) {
	mux := http.NewServeMux()
	h := NewHandlerBE1()
	h.RegisterSprint1Routes(mux)

	var savedETag string

	// TC-S4-01: Cache MISS pada panggilan pertama Kanvas 360°
	t.Run("TC-S4-01_CacheMissOnFirstScenes360Request", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
		if xCache := rec.Header().Get("X-Cache"); xCache != "MISS" {
			t.Fatalf("expected X-Cache=MISS on first call, got %s", xCache)
		}
		savedETag = rec.Header().Get("ETag")
		if savedETag == "" {
			t.Fatalf("expected ETag header to be generated")
		}
	})

	// TC-S4-02: Cache HIT pada panggilan kedua Kanvas 360°
	t.Run("TC-S4-02_CacheHitOnSecondScenes360Request", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
		if xCache := rec.Header().Get("X-Cache"); xCache != "HIT" {
			t.Fatalf("expected X-Cache=HIT on second call, got %s", xCache)
		}
	})

	// TC-S4-03: HTTP 304 Not Modified saat klien mengirim If-None-Match
	t.Run("TC-S4-03_ETag304NotModifiedWhenMatching", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		req.Header.Set("If-None-Match", savedETag)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotModified {
			t.Fatalf("expected 304 Not Modified, got %d", rec.Code)
		}
	})

	// TC-S4-04: Rate-Limiter HTTP 429 pada Lapor Pungli saat terdeteksi Burst Spam
	t.Run("TC-S4-04_RateLimit429OnPungliBurstSpam", func(t *testing.T) {
		body := []byte(`{"destination_id":"dest-001","incident_category":"parkir_liar","charged_amount_idr":25000}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/pungli/report", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Simulate-RateLimit", "burst")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusTooManyRequests {
			t.Fatalf("expected 429 Too Many Requests, got %d", rec.Code)
		}
	})

	// TC-S4-05: Rate-Limiter HTTP 429 pada Pancaran SOS GPS saat terdeteksi Burst Spam
	t.Run("TC-S4-05_RateLimit429OnSOSBurstSpam", func(t *testing.T) {
		body := []byte(`{"tourist_name":"Spam Bot","latitude":-0.9465,"longitude":100.5218}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/sos", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Simulate-RateLimit", "burst")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusTooManyRequests {
			t.Fatalf("expected 429 Too Many Requests on SOS burst, got %d", rec.Code)
		}
	})

	// TC-S4-06: Live Benchmark <100ms SLA (GET /api/v1/admin/system/benchmark)
	t.Run("TC-S4-06_LiveBenchmarkUnder100msSLA", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/admin/system/benchmark", nil)
		req.Header.Set("Authorization", "Bearer dev-token-admin-dispar")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK from benchmark endpoint, got %d", rec.Code)
		}

		var payload map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
			t.Fatalf("failed to decode benchmark response: %v", err)
		}
		sla, ok := payload["sla_verification"].(map[string]interface{})
		if !ok || sla["sla_passed"] != true {
			t.Fatalf("expected sla_passed=true (<100ms), got %+v", sla)
		}
	})

	// TC-S4-07: Admin Cache Flush mereset cache kembali ke MISS
	t.Run("TC-S4-07_AdminCacheFlushResetsToMiss", func(t *testing.T) {
		flushReq := httptest.NewRequest(http.MethodPost, "/api/v1/admin/cache/flush", nil)
		flushReq.Header.Set("Authorization", "Bearer dev-token-admin-dispar")
		flushRec := httptest.NewRecorder()
		mux.ServeHTTP(flushRec, flushReq)

		if flushRec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on cache flush, got %d", flushRec.Code)
		}

		// Verifikasi panggilan berikutnya ke scenes-360 kembali menjadi MISS
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if xCache := rec.Header().Get("X-Cache"); xCache != "MISS" {
			t.Fatalf("expected X-Cache=MISS after flush, got %s", xCache)
		}
	})

	// TC-S4-08: Katalog Final 24 Endpoint BE-1
	t.Run("TC-S4-08_VerifyComplete24EndpointsContractCatalog", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/system/contracts", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on contracts catalog, got %d", rec.Code)
		}

		var payload map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
			t.Fatalf("failed to parse contracts catalog: %v", err)
		}
		if total, ok := payload["total_endpoints"].(float64); !ok || int(total) != 24 {
			t.Fatalf("expected exactly 24 BE-1 endpoints in catalog, got %v", payload["total_endpoints"])
		}
	})
}
