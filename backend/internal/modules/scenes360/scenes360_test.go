package scenes360

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
)

func setupTestRouter() (*gin.Engine, *middleware.InMemoryTTLCache) {
	gin.SetMode(gin.TestMode)
	r := gin.New()

	destRepo := destination.NewRepository()
	repo := NewRepository()
	service := NewService(repo, destRepo)
	cache := middleware.NewInMemoryTTLCache(5 * time.Minute)
	handler := NewHandler(service, cache)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r, cache
}

func TestScenes360Suite(t *testing.T) {
	r, cache := setupTestRouter()

	t.Run("TC-S3-01: GET /api/v1/destinations/:id/scenes-360 mengembalikan scene Aerial-to-Ground & 4 Pin Interaktif", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var body map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("failed to parse JSON: %v", err)
		}

		if body["view_mode"] != "photo_panorama" {
			t.Fatalf("expected view_mode 'photo_panorama', got '%v'", body["view_mode"])
		}
		if body["image_resolution"] != "4K Equirectangular Panorama" {
			t.Fatalf("expected image_resolution '4K Equirectangular Panorama', got '%v'", body["image_resolution"])
		}

		scenes, ok := body["scenes_360"].([]interface{})
		if !ok || len(scenes) < 2 {
			t.Fatalf("expected at least 2 scenes (aerial & ground) for Lembah Harau, got %v", len(scenes))
		}

		// Verifikasi voice_text pada hotspot
		firstScene := scenes[0].(map[string]interface{})
		hotspots, ok := firstScene["hotspots"].([]interface{})
		if !ok || len(hotspots) == 0 {
			t.Fatal("expected hotspots in first scene")
		}
		audioHotspot := hotspots[1].(map[string]interface{})
		if audioHotspot["voice_text"] == nil || audioHotspot["voice_text"] == "" {
			t.Fatal("expected voice_text to be populated for voice guidance")
		}

		legend, ok := body["pin_legend"].(map[string]interface{})
		if !ok || len(legend) < 4 {
			t.Fatalf("expected pin_legend with 4 colors, got %v", legend)
		}
	})

	t.Run("TC-S3-02: Cache ETag HIT & HTTP 304 Not Modified pada kanvas 360", func(t *testing.T) {
		cache.FlushAll()

		// Panggilan 1: MISS
		req1 := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		rec1 := httptest.NewRecorder()
		r.ServeHTTP(rec1, req1)
		if rec1.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec1.Code)
		}
		if xCache := rec1.Header().Get("X-Cache"); xCache != "MISS" {
			t.Fatalf("expected X-Cache=MISS on first call, got %s", xCache)
		}
		etag := rec1.Header().Get("ETag")
		if etag == "" {
			t.Fatal("expected non-empty ETag on first response")
		}

		// Panggilan 2: HIT
		req2 := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		rec2 := httptest.NewRecorder()
		r.ServeHTTP(rec2, req2)
		if rec2.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec2.Code)
		}
		if xCache := rec2.Header().Get("X-Cache"); xCache != "HIT" {
			t.Fatalf("expected X-Cache=HIT on second call, got %s", xCache)
		}

		// Panggilan 3: 304 Not Modified
		req3 := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		req3.Header.Set("If-None-Match", etag)
		rec3 := httptest.NewRecorder()
		r.ServeHTTP(rec3, req3)
		if rec3.Code != http.StatusNotModified {
			t.Fatalf("expected 304 Not Modified, got %d", rec3.Code)
		}
	})

	t.Run("TC-S3-03: POST /api/v1/admin/scenes-360/:sceneId/hotspots menempelkan Pin 360 baru dari CMS Studio FS-1", func(t *testing.T) {
		payload := []byte(`{"type":"mitra","pitch":-10.5,"yaw":225.0,"title":"Kopi Kawa Daun Harau","target_ref":"partner-004","description":"Klik untuk pesan Kopi Kawa Daun hangat"}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created, got %d: %s", rec.Code, rec.Body.String())
		}

		var res map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res["status"] != "pin_attached" {
			t.Fatalf("expected status=pin_attached, got %v", res["status"])
		}
	})

	t.Run("TC-S3-04: Validasi Koordinat Bola 360 derajat (Pitch & Yaw Invalid)", func(t *testing.T) {
		invalidPitch := []byte(`{"type":"navigasi","pitch":95.0,"yaw":180.0,"title":"Spot Langit"}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots", bytes.NewBuffer(invalidPitch))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected 400 Bad Request for pitch > 90, got %d", rec.Code)
		}

		invalidYaw := []byte(`{"type":"navigasi","pitch":0.0,"yaw":380.0,"title":"Spot Luar Sudut"}`)
		req2 := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots", bytes.NewBuffer(invalidYaw))
		req2.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req2.Header.Set("Content-Type", "application/json")
		rec2 := httptest.NewRecorder()
		r.ServeHTTP(rec2, req2)

		if rec2.Code != http.StatusBadRequest {
			t.Fatalf("expected 400 Bad Request for yaw > 360, got %d", rec2.Code)
		}
	})

	t.Run("TC-S3-05: POST /api/v1/admin/scenes-360 berhasil menambah Scene 360 baru via CMS Studio", func(t *testing.T) {
		payload := []byte(`{"destination_id":"dest-001","title":"Sudut Tebing Echo Lembah Harau","type":"ground","panorama_url":"https://cdn.rancak.in/360/harau-echo.jpg"}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created, got %d: %s", rec.Code, rec.Body.String())
		}
	})

	t.Run("TC-S3-06: POST /api/v1/admin/scenes-360 validasi field wajib kosong", func(t *testing.T) {
		payload := []byte(`{"destination_id":""}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected 400 Bad Request, got %d", rec.Code)
		}
	})

	t.Run("TC-S3-07: Proteksi RBAC JWT Admin CMS 360 (401 Unauthorized & 403 Forbidden)", func(t *testing.T) {
		// 401 tanpa token
		reqAnon := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360", nil)
		recAnon := httptest.NewRecorder()
		r.ServeHTTP(recAnon, reqAnon)
		if recAnon.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", recAnon.Code)
		}

		// 403 role tourist
		reqTourist := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360", nil)
		reqTourist.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		recTourist := httptest.NewRecorder()
		r.ServeHTTP(recTourist, reqTourist)
		if recTourist.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden, got %d", recTourist.Code)
		}
	})

	t.Run("TC-S3-08: Invalidation Cache Otomatis saat Admin Mengunggah Pin Baru", func(t *testing.T) {
		// Isi cache
		reqGet := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		recGet := httptest.NewRecorder()
		r.ServeHTTP(recGet, reqGet)
		if recGet.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", recGet.Code)
		}

		// Panggilan kedua pasti HIT
		reqGet2 := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		recGet2 := httptest.NewRecorder()
		r.ServeHTTP(recGet2, reqGet2)
		if recGet2.Header().Get("X-Cache") != "HIT" {
			t.Fatalf("expected X-Cache=HIT, got %s", recGet2.Header().Get("X-Cache"))
		}

		// Admin tempel pin baru -> FlushAll()
		payload := []byte(`{"type":"audio","pitch":5.0,"yaw":90.0,"title":"Cerita Baru"}`)
		reqPin := httptest.NewRequest(http.MethodPost, "/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots", bytes.NewBuffer(payload))
		reqPin.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		reqPin.Header.Set("Content-Type", "application/json")
		recPin := httptest.NewRecorder()
		r.ServeHTTP(recPin, reqPin)
		if recPin.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created on pin attachment, got %d", recPin.Code)
		}

		// Panggilan berikutnya harus kembali menjadi MISS
		reqGet3 := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil)
		recGet3 := httptest.NewRecorder()
		r.ServeHTTP(recGet3, reqGet3)
		if recGet3.Header().Get("X-Cache") != "MISS" {
			t.Fatalf("expected X-Cache=MISS after mutation, got %s", recGet3.Header().Get("X-Cache"))
		}
	})
}
