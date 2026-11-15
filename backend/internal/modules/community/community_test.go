package community

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

func TestCreateCommunityPlace_SensitiveWithMasking(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(CreateCommunityPlaceRequest{
		UserID:      "usr-001",
		Name:        "Lembah Taruko Hidden Paradise",
		Category:    "Hidden Gem",
		CityRegency: "Kabupaten Agam",
		Description: "Lembah tenang di balik Ngarai Sianok",
		Latitude:    -0.3120,
		Longitude:   100.3550,
		TipsMenjaga: "Wajib membawa kantong sampah sendiri, dilarang menyalakan api unggun sembarangan",
		IsSensitive: true,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/community/places", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	if data["masking_applied"] != true {
		t.Fatalf("Expected masking_applied to be true for sensitive spot")
	}

	place := data["place"].(map[string]interface{})
	if place["status"] != "PENDING_CURATION" {
		t.Fatalf("Expected status PENDING_CURATION, got %v", place["status"])
	}

	// Verify latitude was masked by +0.0075
	expectedLat := -0.3120 + 0.0075
	actualLat := place["latitude"].(float64)
	if actualLat < expectedLat-0.0001 || actualLat > expectedLat+0.0001 {
		t.Fatalf("Expected masked latitude around %f, got %f", expectedLat, actualLat)
	}
}

func TestCreateCommunityPlace_MandatoryTipsMenjaga_Validation(t *testing.T) {
	r, _ := setupTestRouter()

	// Missing tips_menjaga
	body, _ := json.Marshal(map[string]interface{}{
		"name":         "Bukit Paralayang Lintau",
		"category":     "Alam",
		"city_regency": "Tanah Datar",
		"latitude":     -0.45,
		"longitude":    100.55,
		"is_sensitive": false,
		// tips_menjaga is deliberately omitted
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/community/places", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request when tips_menjaga is empty, got %d", w.Code)
	}
}

func TestGetCommunityPlaces_List(t *testing.T) {
	r, _ := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/community/places", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	places := data["places"].([]interface{})
	if len(places) == 0 {
		t.Fatalf("Expected at least 1 community place from seeder, got 0")
	}
}

func TestCreateAndGetSharedTrips(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Create Shared Trip
	body, _ := json.Marshal(CreateSharedTripRequest{
		UserID:           "usr-003",
		Title:            "Cari Barengan Sewa HiAce: Wisata Mandeh One Day Tour",
		DestinationRoute: "Padang -> Dermaga Tarusan -> Pulau Mandeh PP",
		DepartureDate:    "2026-11-20",
		AvailableSeats:   4,
		CostPerPerson:    60000.0,
		ContactWA:        "6281299887766",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created on CreateSharedTrip, got %d. Body: %s", w.Code, w.Body.String())
	}

	// 2. Get Shared Trips List
	getReq := httptest.NewRequest(http.MethodGet, "/api/v1/community/shared-trips", nil)
	getW := httptest.NewRecorder()
	r.ServeHTTP(getW, getReq)

	if getW.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on GetSharedTrips, got %d", getW.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(getW.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	trips := data["trips"].([]interface{})

	if len(trips) < 2 {
		t.Fatalf("Expected at least 2 shared trips (1 seed + 1 created), got %d", len(trips))
	}
}

