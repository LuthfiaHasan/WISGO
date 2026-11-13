package be1_core

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ============================================================================
// HARI 5 (JUMAT QA): AUTOMATED INTEGRATION TEST SUITE SPRINT 1 BE-1
// File: backend/internal/be1_core/be1_sprint1_test.go
// Cara Jalankan: cd backend && go test -v ./internal/be1_core/... -run TestBE1Sprint1Suite
// ============================================================================

func setupWISGOTestMux() *http.ServeMux {
	mux := http.NewServeMux()
	be1 := NewHandlerBE1()
	be1.RegisterSprint1Routes(mux)
	return mux
}

func TestBE1Sprint1Suite(t *testing.T) {
	mux := setupWISGOTestMux()

	// --- PENGUJIAN HARI 3 & 4: SEEDER 20 DESTINASI, SPASIAL & DETAIL AGGREGATE ---
	t.Run("TC-01 [Hari 3]: GET /api/v1/destinations mengembalikan minimal 20 destinasi Sumbar", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var list []models.Destination
		if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if len(list) < 20 {
			t.Fatalf("expected at least 20 seeded destinations, got %d", len(list))
		}
	})

	t.Run("TC-02 [Hari 4]: Kalkulasi Jarak Spasial GPS Mengurutkan Jam Gadang Terdekat dari Bukittinggi", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations?lat=-0.30519&lng=100.36947", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var list []models.Destination
		_ = json.Unmarshal(rec.Body.Bytes(), &list)
		if len(list) == 0 || list[0].Slug != "jam-gadang-bukittinggi" {
			t.Fatalf("expected jam-gadang-bukittinggi as nearest #1 destination, got %+v", list[0].Slug)
		}
		if list[0].DistanceKm > 1.0 {
			t.Fatalf("expected distance <= 1.0 km, got %v", list[0].DistanceKm)
		}
	})

	t.Run("TC-03 [Hari 4]: GET /api/v1/destinations/{id} memuat 4 Statistik + 5 Indikator Medan + Tips + Tarif Perda", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations/lembah-harau?lat=-0.9471&lng=100.4172", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var detail models.Destination
		if err := json.Unmarshal(rec.Body.Bytes(), &detail); err != nil {
			t.Fatalf("failed to decode detail: %v", err)
		}
		if detail.MedanIndicator == nil {
			t.Fatal("expected MedanIndicator (5 Indikator Medan) to be present")
		}
		if len(detail.Tips) == 0 {
			t.Fatal("expected LocalTips (Kartu Tips Menjaga Tempat) to be present")
		}
		if len(detail.Tariffs) == 0 {
			t.Fatal("expected OfficialTariffs (Tabel Fair-Price Perda) to be present")
		}
	})

	t.Run("TC-04 [Hari 4]: GET /api/v1/destinations/{id}/tariffs & /offline-bundle berfungsi untuk FE-1 & FE-2", func(t *testing.T) {
		reqTariff := httptest.NewRequest("GET", "/api/v1/destinations/dest-001/tariffs", nil)
		recTariff := httptest.NewRecorder()
		mux.ServeHTTP(recTariff, reqTariff)
		if recTariff.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on /tariffs, got %d", recTariff.Code)
		}

		reqOffline := httptest.NewRequest("GET", "/api/v1/destinations/dest-004/offline-bundle", nil)
		recOffline := httptest.NewRecorder()
		mux.ServeHTTP(recOffline, reqOffline)
		if recOffline.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on /offline-bundle, got %d", recOffline.Code)
		}
	})

	// --- PENGUJIAN HARI 5: PROTEKSI RBAC & INTEGRASI CMS ADMIN FS-1 ---
	t.Run("TC-05 [Hari 5]: POST /api/v1/admin/destinations menolak request tanpa Bearer Token (401 Unauthorized)", func(t *testing.T) {
		body := []byte(`{"name":"Destinasi Tanpa Token"}`)
		req := httptest.NewRequest("POST", "/api/v1/admin/destinations", bytes.NewBuffer(body))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", rec.Code)
		}
	})

	t.Run("TC-06 [Hari 5]: PUT /api/v1/admin/destinations/{id} menolak Role Tourist (403 Forbidden)", func(t *testing.T) {
		body := []byte(`{"crowd_level":"Sepi"}`)
		req := httptest.NewRequest("PUT", "/api/v1/admin/destinations/dest-001", bytes.NewBuffer(body))
		req.Header.Set("Authorization", "Bearer "+TokenTourist)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden for role tourist, got %d", rec.Code)
		}
	})

	t.Run("TC-07 [Hari 5]: POST & PUT /api/v1/admin/destinations dengan Token Admin Dispar (FS-1) berhasil", func(t *testing.T) {
		createBody := []byte(`{"name":"Tabek Patah Tanah Datar","category":"Alam & Tebing","city_regency":"Kab. Tanah Datar","estimated_cost":10000}`)
		reqCreate := httptest.NewRequest("POST", "/api/v1/admin/destinations", bytes.NewBuffer(createBody))
		reqCreate.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		recCreate := httptest.NewRecorder()
		mux.ServeHTTP(recCreate, reqCreate)

		if recCreate.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created, got %d", recCreate.Code)
		}

		updateBody := []byte(`{"crowd_level":"Ramai","medan_indicator":{"vehicle_access":"Mobil & Bus Pariwisata OK","trekking_level":"Datar / Mudah","cellular_signal":"4G Kuat","facilities":"Toilet & Musala Lengkap","guide_need":"Mandiri"}}`)
		reqUpdate := httptest.NewRequest("PUT", "/api/v1/admin/destinations/dest-001", bytes.NewBuffer(updateBody))
		reqUpdate.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		recUpdate := httptest.NewRecorder()
		mux.ServeHTTP(recUpdate, reqUpdate)

		if recUpdate.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on CMS update, got %d", recUpdate.Code)
		}
	})

	t.Run("TC-08 [Hari 5]: PUT /api/v1/admin/destinations/{id}/tariffs berhasil sinkronisasi Tarif Perda", func(t *testing.T) {
		tariffBody := []byte(`{"tariffs":[{"item_name":"Tiket Masuk Resmi Perda Baru","category":"tiket","price":15000,"unit":"per orang","regulation_ref":"Perda Sumbar Terbaru 2026"}]}`)
		req := httptest.NewRequest("PUT", "/api/v1/admin/destinations/dest-001/tariffs", bytes.NewBuffer(tariffBody))
		req.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on tariff sync, got %d", rec.Code)
		}
	})
}
