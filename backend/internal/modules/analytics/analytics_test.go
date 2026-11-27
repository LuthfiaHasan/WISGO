package analytics

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

func setupTestRouter() (*gin.Engine, *Handler) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	repo := NewRepository()
	service := NewService(repo)
	handler := NewHandler(service)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r, handler
}

func TestGetDisparAnalyticsSummary_19RegenciesAndEconomicMetrics(t *testing.T) {
	r, _ := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/analytics/dispar/summary", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for Dispar analytics, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	// 1. Validasi metrik utama
	if data["total_visits"].(float64) < 1000 {
		t.Fatalf("Expected total_visits >= 1000, got %v", data["total_visits"])
	}
	if data["total_escrow_turnover"].(float64) <= 0 {
		t.Fatalf("Expected positive escrow turnover, got %v", data["total_escrow_turnover"])
	}

	// 2. Validasi 19 Kabupaten/Kota di Sumatera Barat
	heatmap := data["regency_density_heatmap"].([]interface{})
	if len(heatmap) != 19 {
		t.Fatalf("Expected exactly 19 regencies in heatmap, got %d", len(heatmap))
	}

	// 3. Validasi Top 5 Destinasi
	topDest := data["top_destinations"].([]interface{})
	if len(topDest) != 5 {
		t.Fatalf("Expected 5 top destinations, got %d", len(topDest))
	}

	// 4. Validasi Kategori Mitra UMKM
	mitraDist := data["mitra_category_distribution"].(map[string]interface{})
	if len(mitraDist) < 5 {
		t.Fatalf("Expected at least 5 mitra categories, got %d", len(mitraDist))
	}
}

