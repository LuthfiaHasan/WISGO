package culture_ranking

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
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
}
