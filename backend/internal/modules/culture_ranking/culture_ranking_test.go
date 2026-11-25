package culture_ranking

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()

	repo := NewRepository()
	service := NewService(repo)
	handler := NewHandler(service)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r
}

func TestCultureRankingSuite(t *testing.T) {
	r := setupTestRouter()

	t.Run("TC-S6-01: GET /api/v1/destinations/rankings/gaode mengembalikan leaderboard skor keaslian terurut", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/rankings/gaode", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res GaodeRankingsResponse
		if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to parse JSON: %v", err)
		}
		if res.Total < 5 {
			t.Fatalf("expected at least 5 ranked destinations, got %d", res.Total)
		}
		if res.Rankings[0].RankPosition != 1 || res.Rankings[0].DestinationID != "dest-001" {
			t.Fatalf("expected dest-001 at rank #1, got %+v", res.Rankings[0])
		}
		if res.Rankings[0].GaodeAuthenticityScore < res.Rankings[1].GaodeAuthenticityScore {
			t.Fatal("expected scores to be sorted in descending order")
		}
	})

	t.Run("TC-S6-02: Filter Kategori pada Gaode Ranking", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/rankings/gaode?category=Hidden+Gem", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res GaodeRankingsResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Total == 0 {
			t.Fatal("expected at least 1 Hidden Gem destination")
		}
		for _, item := range res.Rankings {
			if item.Category != "Hidden Gem" {
				t.Fatalf("expected category Hidden Gem, got %s", item.Category)
			}
		}
	})

	t.Run("TC-S6-03: GET /api/v1/culture/minang-phrases mengembalikan Kamus Saku Audio & Kato Nan Ampek", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/culture/minang-phrases", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res MinangPhrasesResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Total < 5 {
			t.Fatalf("expected at least 5 Minang phrases, got %d", res.Total)
		}
		if res.CulturalGuide == "" {
			t.Fatal("expected cultural_guide Kato Nan Ampek to be present")
		}
	})

	t.Run("TC-S6-04: Filter Kategori tawar_pasar pada Kamus Minang", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/culture/minang-phrases?category=tawar_pasar", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res MinangPhrasesResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Total == 0 {
			t.Fatal("expected at least 1 tawar_pasar phrase")
		}
		for _, p := range res.Phrases {
			if p.Category != "tawar_pasar" {
				t.Fatalf("expected tawar_pasar, got %s", p.Category)
			}
		}
	})

	t.Run("TC-S6-05: Pencarian teks q=harga pada Kamus Minang", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/culture/minang-phrases?q=harga", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res MinangPhrasesResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Total == 0 {
			t.Fatal("expected search match for 'harga'")
		}
	})

	t.Run("TC-S6-06: GET /api/v1/culture/events mengembalikan Kalender Budaya & Hari Pakan", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/culture/events", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res CulturalEventsResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Total < 5 {
			t.Fatalf("expected at least 5 cultural events, got %d", res.Total)
		}
	})

	t.Run("TC-S6-07: Filter type=Hari Pakan & kalkulasi jarak GPS", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/culture/events?type=Hari%20Pakan&lat=-0.4560&lng=100.5900", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res CulturalEventsResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Total == 0 {
			t.Fatal("expected at least 1 Hari Pakan event")
		}
		// Event Batusangkar berjarak sangat dekat dengan koordinat query (-0.4561, 100.5912)
		if res.Events[0].DistanceKm < 0 {
			t.Fatal("expected non-negative distance")
		}
	})

	t.Run("TC-S6-08: Formula ComputeGaodeScore berada dalam rentang terstandarisasi 82.0 - 99.8", func(t *testing.T) {
		minScore := ComputeGaodeScore(0, 0, 0)
		if minScore < 82.0 {
			t.Fatalf("expected min score >= 82.0, got %v", minScore)
		}

		maxScore := ComputeGaodeScore(10000, 300, 100)
		if maxScore > 99.8 {
			t.Fatalf("expected max score <= 99.8, got %v", maxScore)
		}
	})

	t.Run("TC-S6-09: POST /api/v1/culture/events berhasil diinput oleh Aktor Vendor", func(t *testing.T) {
		payload := []byte(`{
			"title": "Festival Tabuik Pariaman 2026",
			"event_type": "Festival Budaya",
			"nagari_location": "Pantai Gandoriah",
			"city_regency": "Kota Pariaman",
			"schedule_rule": "Setiap 10 Muharram (Puncak Hoyak Tabuik)",
			"next_event_date": "2026-07-25",
			"latitude": -0.6264,
			"longitude": 100.1190,
			"highlight_item": "Prosesi Hoyak Tabuik setinggi 12 meter dibuang ke laut saat matahari terbenam.",
			"cultural_etiquette": "Hormati jalannya prosesi arak-arakan dan jaga kebersihan pantai."
		}`)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/culture/events", bytes.NewBuffer(payload))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+middleware.TokenVendor)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created for Vendor event input, got %d: %s", rec.Code, rec.Body.String())
		}

		var res struct {
			Status string `json:"status"`
			Data   struct {
				ID        string `json:"id"`
				Title     string `json:"title"`
				UserID    string `json:"user_id"`
				EventType string `json:"event_type"`
			} `json:"data"`
		}
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Status != "success" || res.Data.Title != "Festival Tabuik Pariaman 2026" {
			t.Fatalf("unexpected response data: %+v", res)
		}
		if res.Data.UserID != "user-vendor-01" {
			t.Fatalf("expected user_id user-vendor-01, got %s", res.Data.UserID)
		}
	})

	t.Run("TC-S6-10: RBAC Guard pada /api/v1/admin/culture/events menolak tanpa token dan role tourist", func(t *testing.T) {
		payload := []byte(`{"title": "Event Ilegal"}`)

		// 1. Tanpa token -> 401 Unauthorized
		reqNoToken := httptest.NewRequest(http.MethodPost, "/api/v1/admin/culture/events", bytes.NewBuffer(payload))
		reqNoToken.Header.Set("Content-Type", "application/json")
		recNoToken := httptest.NewRecorder()
		r.ServeHTTP(recNoToken, reqNoToken)
		if recNoToken.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", recNoToken.Code)
		}

		// 2. Token tourist -> 403 Forbidden
		reqTourist := httptest.NewRequest(http.MethodPost, "/api/v1/admin/culture/events", bytes.NewBuffer(payload))
		reqTourist.Header.Set("Content-Type", "application/json")
		reqTourist.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		recTourist := httptest.NewRecorder()
		r.ServeHTTP(recTourist, reqTourist)
		if recTourist.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden for tourist role, got %d", recTourist.Code)
		}
	})

	t.Run("TC-S6-11: Admin Dispar CRUD Event Budaya (Create, Update, Delete)", func(t *testing.T) {
		// 1. Admin Create Event
		createPayload := []byte(`{
			"title": "Pacu Terbang Itik Payakumbuh",
			"event_type": "Tradisi Adat",
			"nagari_location": "Gelanggang Aur Kuning",
			"city_regency": "Kota Payakumbuh",
			"schedule_rule": "Setiap Minggu Ke-2 & Ke-4",
			"next_event_date": "2026-12-10",
			"latitude": -0.2248,
			"longitude": 100.6300,
			"highlight_item": "Perlombaan itik terbang melintasi jarak 800 meter hingga 1 km.",
			"cultural_etiquette": "Tidak bersorak saat itik dilepaskan agar fokus terbang lurus."
		}`)

		reqCreate := httptest.NewRequest(http.MethodPost, "/api/v1/admin/culture/events", bytes.NewBuffer(createPayload))
		reqCreate.Header.Set("Content-Type", "application/json")
		reqCreate.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recCreate := httptest.NewRecorder()
		r.ServeHTTP(recCreate, reqCreate)

		if recCreate.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created on Admin create event, got %d: %s", recCreate.Code, recCreate.Body.String())
		}

		var createRes struct {
			Data struct {
				ID string `json:"id"`
			} `json:"data"`
		}
		_ = json.Unmarshal(recCreate.Body.Bytes(), &createRes)
		createdID := createRes.Data.ID

		// 2. Admin Update Event
		updatePayload := []byte(`{
			"title": "Pacu Terbang Itik Payakumbuh Grand Prix",
			"schedule_rule": "Final Tahunan Setiap Akhir Tahun"
		}`)
		reqUpdate := httptest.NewRequest(http.MethodPut, "/api/v1/admin/culture/events/"+createdID, bytes.NewBuffer(updatePayload))
		reqUpdate.Header.Set("Content-Type", "application/json")
		reqUpdate.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recUpdate := httptest.NewRecorder()
		r.ServeHTTP(recUpdate, reqUpdate)

		if recUpdate.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on Admin update event, got %d: %s", recUpdate.Code, recUpdate.Body.String())
		}

		// 3. Admin Delete Event
		reqDelete := httptest.NewRequest(http.MethodDelete, "/api/v1/admin/culture/events/"+createdID, nil)
		reqDelete.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recDelete := httptest.NewRecorder()
		r.ServeHTTP(recDelete, reqDelete)

		if recDelete.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on Admin delete event, got %d: %s", recDelete.Code, recDelete.Body.String())
		}
	})
}
