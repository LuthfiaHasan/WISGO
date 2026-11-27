package itinerary

import (
	"bytes"
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

func TestAutoGenerateItinerary_Success(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(AutoItineraryRequest{
		UserID:       "usr-001",
		DurationDays: 3,
		ArrivalPoint: "BIM",
		TravelerType: "family",
		Preferences:  []string{"nature", "culinary"},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/itineraries/auto-generate", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	if int(data["total_days"].(float64)) != 3 {
		t.Fatalf("Expected total_days=3, got %v", data["total_days"])
	}

	items := data["items"].([]interface{})
	if len(items) == 0 {
		t.Fatalf("Expected non-empty itinerary items")
	}

	// Pastikan ada peringatan macet (Traffic Alert)
	firstItem := items[0].(map[string]interface{})
	if firstItem["traffic_alert"] == nil || firstItem["traffic_alert"].(string) == "" {
		t.Fatalf("Expected traffic alert to be populated")
	}
}

func TestGetItineraries_List(t *testing.T) {
	r, _ := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/itineraries?user_id=usr-001", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	list := resp.Data.([]interface{})
	if len(list) == 0 {
		t.Fatalf("Expected at least 1 itinerary from seeder, got 0")
	}
}

func TestCreateManualItinerary_Success(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(CreateItineraryRequest{
		UserID:    "usr-001",
		Title:     "Trip Mandiri Bukittinggi & Harau",
		StartDate: "2026-12-01",
		EndDate:   "2026-12-03",
		TotalDays: 2,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/itineraries", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created for manual itinerary, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	if data["title"].(string) != "Trip Mandiri Bukittinggi & Harau" {
		t.Fatalf("Expected title match, got %s", data["title"])
	}
}

