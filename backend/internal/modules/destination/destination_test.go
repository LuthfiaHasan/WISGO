package destination

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	repo := NewRepository()
	service := NewService(repo)
	cache := middleware.NewInMemoryTTLCache(5 * time.Minute)
	handler := NewHandler(service, cache)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r
}

func TestDestinationSuite(t *testing.T) {
	r := setupTestRouter()

	t.Run("TC-01: GET /api/v1/destinations mengembalikan minimal 20 destinasi Sumbar", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

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

	t.Run("TC-02: Kalkulasi Jarak Spasial GPS Mengurutkan Jam Gadang Terdekat dari Bukittinggi", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations?lat=-0.30519&lng=100.36947", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

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

	t.Run("TC-03: GET /api/v1/destinations/:id memuat 4 Statistik + 5 Indikator Medan + Tips + Tarif Perda", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/lembah-harau?lat=-0.9471&lng=100.4172", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

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

	t.Run("TC-04: GET /api/v1/destinations/:id/tariffs & /offline-bundle berfungsi untuk FE-1 & FE-2", func(t *testing.T) {
		reqTariff := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/tariffs", nil)
		recTariff := httptest.NewRecorder()
		r.ServeHTTP(recTariff, reqTariff)
		if recTariff.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on /tariffs, got %d", recTariff.Code)
		}

		reqOffline := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-004/offline-bundle", nil)
		recOffline := httptest.NewRecorder()
		r.ServeHTTP(recOffline, reqOffline)
		if recOffline.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on /offline-bundle, got %d", recOffline.Code)
		}

		var bundleRes OfflineBundleResponse
		_ = json.Unmarshal(recOffline.Body.Bytes(), &bundleRes)
		if len(bundleRes.EmergencyContacts) == 0 {
			t.Fatal("expected emergency_contacts to be included in offline-bundle")
		}
		if bundleRes.EmergencyCallProtocol == nil || bundleRes.EmergencyCallProtocol.NationalEmergency == "" {
			t.Fatal("expected emergency_call_protocol to be configured in offline-bundle")
		}
	})

	t.Run("TC-05: POST /api/v1/admin/destinations menolak request tanpa Bearer Token (401 Unauthorized)", func(t *testing.T) {
		body := []byte(`{"name":"Destinasi Tanpa Token"}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/admin/destinations", bytes.NewBuffer(body))
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", rec.Code)
		}
	})

	t.Run("TC-06: PUT /api/v1/admin/destinations/:id menolak Role Tourist (403 Forbidden)", func(t *testing.T) {
		body := []byte(`{"crowd_level":"Sepi"}`)
		req := httptest.NewRequest(http.MethodPut, "/api/v1/admin/destinations/dest-001", bytes.NewBuffer(body))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden for role tourist, got %d", rec.Code)
		}
	})

	t.Run("TC-07: POST & PUT /api/v1/admin/destinations dengan Token Admin Dispar (FS-1) berhasil", func(t *testing.T) {
		createBody := []byte(`{"name":"Tabek Patah Tanah Datar","category":"Alam & Tebing","city_regency":"Kab. Tanah Datar","estimated_cost":10000}`)
		reqCreate := httptest.NewRequest(http.MethodPost, "/api/v1/admin/destinations", bytes.NewBuffer(createBody))
		reqCreate.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recCreate := httptest.NewRecorder()
		r.ServeHTTP(recCreate, reqCreate)

		if recCreate.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created, got %d", recCreate.Code)
		}

		updateBody := []byte(`{"crowd_level":"Ramai","medan_indicator":{"vehicle_access":"Mobil & Bus Pariwisata OK","trekking_level":"Datar / Mudah","cellular_signal":"4G Kuat","facilities":"Toilet & Musala Lengkap","guide_need":"Mandiri"}}`)
		reqUpdate := httptest.NewRequest(http.MethodPut, "/api/v1/admin/destinations/dest-001", bytes.NewBuffer(updateBody))
		reqUpdate.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recUpdate := httptest.NewRecorder()
		r.ServeHTTP(recUpdate, reqUpdate)

		if recUpdate.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on CMS update, got %d", recUpdate.Code)
		}
	})

	t.Run("TC-08: PUT /api/v1/admin/destinations/:id/tariffs berhasil sinkronisasi Tarif Perda", func(t *testing.T) {
		tariffBody := []byte(`{"tariffs":[{"item_name":"Tiket Masuk Resmi Perda Baru","category":"tiket","price":15000,"unit":"per orang","regulation_ref":"Perda Sumbar Terbaru 2026"}]}`)
		req := httptest.NewRequest(http.MethodPut, "/api/v1/admin/destinations/dest-001/tariffs", bytes.NewBuffer(tariffBody))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on tariff sync, got %d", rec.Code)
		}
	})

	t.Run("TC-09: POST /api/v1/destinations/hidden-gem berhasil diinput oleh Wisatawan (Role Tourist)", func(t *testing.T) {
		hiddenGemPayload := []byte(`{
			"name": "Air Terjun Lubuk Hitam",
			"city_regency": "Kota Padang",
			"description": "Air terjun alami tiga tingkat yang tersembunyi di perbukitan Bungus Teluk Kabung.",
			"latitude": -1.025,
			"longitude": 100.415,
			"tips_menjaga": "Bawa kantong sampah sendiri dan dilarang membuat api unggun di area hutan lindung.",
			"vehicle_access": "Hanya Motor / Jalan Kaki",
			"cellular_signal": "Blank Spot",
			"trekking_level": "Curam / Ekstrem"
		}`)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/destinations/hidden-gem", bytes.NewBuffer(hiddenGemPayload))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created for tourist hidden gem, got %d: %s", rec.Code, rec.Body.String())
		}

		var res struct {
			Status  string             `json:"status"`
			Message string             `json:"message"`
			Data    models.Destination `json:"data"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to parse response: %v", err)
		}

		if !res.Data.IsHiddenGem {
			t.Fatal("expected IsHiddenGem to be true")
		}
		if res.Data.VerificationStatus != "pending" {
			t.Fatalf("expected VerificationStatus 'pending', got '%s'", res.Data.VerificationStatus)
		}
		if res.Data.Category != "Hidden Gem" {
			t.Fatalf("expected Category 'Hidden Gem', got '%s'", res.Data.Category)
		}
		if len(res.Data.Tips) == 0 {
			t.Fatal("expected Tips Menjaga to be auto-populated")
		}
		if res.Data.MedanIndicator == nil || res.Data.MedanIndicator.CellularSignal != "Blank Spot" {
			t.Fatal("expected MedanIndicator cellular_signal to be 'Blank Spot'")
		}
	})

	t.Run("TC-10: Kurasi & Verifikasi Input Hidden Gem oleh Admin Dispar", func(t *testing.T) {
		// 1. Wisatawan mencoba verifikasi sendiri -> Ditolak 403 Forbidden
		verifyPayload := []byte(`{"status":"approved"}`)
		reqTouristVerify := httptest.NewRequest(http.MethodPatch, "/api/v1/admin/destinations/dest-021/verify", bytes.NewBuffer(verifyPayload))
		reqTouristVerify.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		recTouristVerify := httptest.NewRecorder()
		r.ServeHTTP(recTouristVerify, reqTouristVerify)

		if recTouristVerify.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden for tourist verify, got %d", recTouristVerify.Code)
		}

		// 2. Admin Dispar melihat daftar pending
		reqPending := httptest.NewRequest(http.MethodGet, "/api/v1/admin/destinations/pending", nil)
		reqPending.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recPending := httptest.NewRecorder()
		r.ServeHTTP(recPending, reqPending)

		if recPending.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on admin pending list, got %d", recPending.Code)
		}

		// 3. Admin Dispar menyetujui destinasi hidden gem -> 200 OK
		reqAdminVerify := httptest.NewRequest(http.MethodPatch, "/api/v1/admin/destinations/dest-021/verify", bytes.NewBuffer(verifyPayload))
		reqAdminVerify.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recAdminVerify := httptest.NewRecorder()
		r.ServeHTTP(recAdminVerify, reqAdminVerify)

		if recAdminVerify.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on admin verify, got %d: %s", recAdminVerify.Code, recAdminVerify.Body.String())
		}

		var verifyRes struct {
			Status  string             `json:"status"`
			Message string             `json:"message"`
			Data    models.Destination `json:"data"`
		}
		_ = json.Unmarshal(recAdminVerify.Body.Bytes(), &verifyRes)
		if verifyRes.Data.VerificationStatus != "verified" {
			t.Fatalf("expected VerificationStatus 'verified' after admin approval, got '%s'", verifyRes.Data.VerificationStatus)
		}
	})

	t.Run("TC-11: GET /api/v1/categories mengembalikan 5 Master Categories & Auto-Category Mapping", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/categories", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var resp CategoriesResponse
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode categories: %v", err)
		}

		if resp.Total != 5 || len(resp.Categories) != 5 {
			t.Fatalf("expected 5 canonical categories, got total=%d len=%d", resp.Total, len(resp.Categories))
		}

		expectedIDs := map[string]bool{
			"cat-alam-geopark":  false,
			"cat-budaya-nagari": false,
			"cat-hidden-gem":    false,
			"cat-religi":        false,
			"cat-kuliner":       false,
		}

		for _, c := range resp.Categories {
			if _, exists := expectedIDs[c.ID]; exists {
				expectedIDs[c.ID] = true
			}
			if c.DestinationCount <= 0 {
				t.Fatalf("expected positive destination count for category %s, got %d", c.ID, c.DestinationCount)
			}
		}

		for id, found := range expectedIDs {
			if !found {
				t.Fatalf("category %s not found in response", id)
			}
		}

		// Filter by category_id pada /destinations
		reqFilter := httptest.NewRequest(http.MethodGet, "/api/v1/destinations?category_id=cat-religi", nil)
		recFilter := httptest.NewRecorder()
		r.ServeHTTP(recFilter, reqFilter)

		if recFilter.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on category_id filter, got %d", recFilter.Code)
		}

		var filtered []models.Destination
		_ = json.Unmarshal(recFilter.Body.Bytes(), &filtered)
		if len(filtered) == 0 {
			t.Fatal("expected at least 1 destination for cat-religi")
		}
		for _, d := range filtered {
			if d.CategoryID != "cat-religi" {
				t.Fatalf("expected CategoryID 'cat-religi', got '%s'", d.CategoryID)
			}
		}
	})

	t.Run("TC-12: GET /api/v1/destinations/:id menyajikan cuaca real-time & weather_status per kota/kabupaten", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var dest models.Destination
		if err := json.Unmarshal(rec.Body.Bytes(), &dest); err != nil {
			t.Fatalf("failed to decode destination: %v", err)
		}

		if dest.WeatherStatus == "" {
			t.Fatal("expected weather_status to be non-empty")
		}
		if dest.Weather == nil {
			t.Fatal("expected Weather object to be populated")
		}
		if dest.Weather.CityRegency != dest.CityRegency {
			t.Fatalf("expected weather city '%s', got '%s'", dest.CityRegency, dest.Weather.CityRegency)
		}
		if dest.Weather.TemperatureC <= 0 {
			t.Fatalf("expected positive temperature, got %d", dest.Weather.TemperatureC)
		}
		if dest.Weather.Forecast == "" {
			t.Fatal("expected forecast to be non-empty")
		}
	})
}
