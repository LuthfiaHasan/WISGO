package community

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
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

type mockDestinationLookup struct {
	items []models.Destination
}

func (m *mockDestinationLookup) FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error) {
	q := strings.ToLower(strings.TrimSpace(idOrSlugOrQR))
	for i := range m.items {
		d := m.items[i]
		if strings.ToLower(d.ID) == q || strings.ToLower(d.Slug) == q {
			return &d, nil
		}
	}
	return nil, errors.New("destination not found")
}

func setupTestRouterWithDestinations() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	repo := NewRepository()
	destLookup := &mockDestinationLookup{
		items: []models.Destination{
			{
				ID:       "dst-harau",
				Slug:     "lembah-harau",
				Name:     "Lembah Harau",
				Category: "Alam",
			},
			{
				ID:       "dst-pagaruyung",
				Slug:     "istano-basa-pagaruyung",
				Name:     "Istano Basa Pagaruyung",
				Category: "Budaya",
			},
		},
	}
	service := NewServiceWithDestinations(repo, destLookup)
	handler := NewHandler(service)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)
	return r
}

func TestCreateSharedTrip_WithDestinationID_AutoCategoryAndRoute(t *testing.T) {
	r := setupTestRouterWithDestinations()

	// 1. Lookup menggunakan ID destinasi BE-1, tanpa destination_route & tanpa user_id
	body, _ := json.Marshal(CreateSharedTripRequest{
		Title:          "Open Trip Santai Lembah Harau",
		DestinationID:  "dst-harau",
		DepartureDate:  "2026-12-01",
		AvailableSeats: 5,
		CostPerPerson:  85000,
		ContactWA:      "6281234567899",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	trip := data["trip"].(map[string]interface{})

	if trip["destination_id"] != "dst-harau" {
		t.Fatalf("Expected destination_id 'dst-harau', got %v", trip["destination_id"])
	}
	if trip["category"] != "Alam" {
		t.Fatalf("Expected auto category 'Alam', got %v", trip["category"])
	}
	if trip["destination_route"] != "Lembah Harau" {
		t.Fatalf("Expected auto destination_route 'Lembah Harau', got %v", trip["destination_route"])
	}
	if trip["user_id"] != "usr-001" {
		t.Fatalf("Expected fallback user_id 'usr-001', got %v", trip["user_id"])
	}

	// 2. Lookup menggunakan slug destinasi BE-1 dengan custom destination_route
	slugBody, _ := json.Marshal(CreateSharedTripRequest{
		UserID:           "usr-099",
		Title:            "Wisata Sejarah Minangkabau",
		DestinationID:    "istano-basa-pagaruyung",
		DestinationRoute: "Padang -> Batusangkar -> Istano Basa Pagaruyung",
		DepartureDate:    "2026-12-05",
		AvailableSeats:   3,
		CostPerPerson:    70000,
		ContactWA:        "6281200011122",
	})
	slugReq := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips", bytes.NewReader(slugBody))
	slugReq.Header.Set("Content-Type", "application/json")
	slugW := httptest.NewRecorder()
	r.ServeHTTP(slugW, slugReq)

	if slugW.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created on slug lookup, got %d. Body: %s", slugW.Code, slugW.Body.String())
	}

	var slugResp common.ResponseStandar
	_ = json.Unmarshal(slugW.Body.Bytes(), &slugResp)
	slugTrip := slugResp.Data.(map[string]interface{})["trip"].(map[string]interface{})
	if slugTrip["destination_id"] != "dst-pagaruyung" {
		t.Fatalf("Expected canonical destination_id 'dst-pagaruyung', got %v", slugTrip["destination_id"])
	}
	if slugTrip["category"] != "Budaya" {
		t.Fatalf("Expected auto category 'Budaya', got %v", slugTrip["category"])
	}
	if slugTrip["destination_route"] != "Padang -> Batusangkar -> Istano Basa Pagaruyung" {
		t.Fatalf("Expected custom destination_route to be preserved, got %v", slugTrip["destination_route"])
	}
}

func TestCreateSharedTrip_BackwardCompatible_RouteOnly(t *testing.T) {
	r := setupTestRouterWithDestinations()

	body, _ := json.Marshal(CreateSharedTripRequest{
		UserID:           "usr-007",
		Title:            "Barengan Ke Kelok 9",
		DestinationRoute: "Bukittinggi -> Payakumbuh -> Kelok 9",
		DepartureDate:    "2026-12-10",
		AvailableSeats:   2,
		CostPerPerson:    50000,
		ContactWA:        "6281211112222",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created for route-only backward compatibility, got %d. Body: %s", w.Code, w.Body.String())
	}
}

func TestCreateSharedTrip_ValidationErrors(t *testing.T) {
	r := setupTestRouterWithDestinations()

	cases := []struct {
		name    string
		payload map[string]interface{}
	}{
		{
			name: "empty title",
			payload: map[string]interface{}{
				"title":          "",
				"destination_id": "dst-harau",
			},
		},
		{
			name: "both destination_id and destination_route empty",
			payload: map[string]interface{}{
				"title":             "Trip Tanpa Tujuan",
				"destination_id":    "",
				"destination_route": "",
			},
		},
		{
			name: "unknown destination_id",
			payload: map[string]interface{}{
				"title":          "Trip Destinasi Tidak Ada",
				"destination_id": "dst-tidak-ada-999",
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			body, _ := json.Marshal(tc.payload)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips", bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			if w.Code != http.StatusBadRequest {
				t.Fatalf("[%s] Expected 400 Bad Request, got %d. Body: %s", tc.name, w.Code, w.Body.String())
			}
		})
	}
}

func TestJoinSharedTrip_SuccessAndEdgeCases(t *testing.T) {
	r, _ := setupTestRouter()

	// Seed trip st-001 memiliki UserID = "usr-002" dan AvailableSeats = 3

	// 1. Gagal jika user_id kosong -> 400
	t.Run("empty user_id returns 400", func(t *testing.T) {
		body, _ := json.Marshal(map[string]string{"user_id": "   "})
		req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips/st-001/join", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusBadRequest {
			t.Fatalf("Expected 400 Bad Request, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "user_id wajib diisi untuk bergabung ke Open Trip" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
	})

	// 2. Gagal jika trip tidak ada -> 404
	t.Run("trip not found returns 404", func(t *testing.T) {
		body, _ := json.Marshal(map[string]string{"user_id": "usr-010"})
		req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips/st-tidak-ada/join", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusNotFound {
			t.Fatalf("Expected 404 Not Found, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "Open Trip tidak ditemukan" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
	})

	// 3. Gagal jika host join ke trip miliknya sendiri -> 400
	t.Run("host joining own trip returns 400", func(t *testing.T) {
		body, _ := json.Marshal(map[string]string{"user_id": "usr-002"})
		req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips/st-001/join", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusBadRequest {
			t.Fatalf("Expected 400 Bad Request, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "Host tidak perlu bergabung ke trip miliknya sendiri" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
	})

	// 4. Berhasil bergabung -> kursi berkurang 3 -> 2 (via JSON body)
	t.Run("successful join decrements seats 3 to 2", func(t *testing.T) {
		body, _ := json.Marshal(map[string]string{"user_id": "usr-010"})
		req := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips/st-001/join", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("Expected 200 OK, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "Berhasil bergabung ke Open Trip" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
		data := resp.Data.(map[string]interface{})
		trip := data["trip"].(map[string]interface{})
		if int(trip["available_seats"].(float64)) != 2 {
			t.Fatalf("Expected available_seats 2, got %v", trip["available_seats"])
		}
	})

	// 5. Fallback query param user_id: habiskan sisa kursi 2 -> 1 -> 0, lalu gagal saat 0 -> 400
	t.Run("join until full then fail with 400", func(t *testing.T) {
		// 2 -> 1 via query param fallback
		req1 := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips/st-001/join?user_id=usr-011", nil)
		w1 := httptest.NewRecorder()
		r.ServeHTTP(w1, req1)
		if w1.Code != http.StatusOK {
			t.Fatalf("Expected 200 OK on 2nd join, got %d. Body: %s", w1.Code, w1.Body.String())
		}

		// 1 -> 0
		body2, _ := json.Marshal(map[string]string{"user_id": "usr-012"})
		req2 := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips/st-001/join", bytes.NewReader(body2))
		req2.Header.Set("Content-Type", "application/json")
		w2 := httptest.NewRecorder()
		r.ServeHTTP(w2, req2)
		if w2.Code != http.StatusOK {
			t.Fatalf("Expected 200 OK on 3rd join, got %d. Body: %s", w2.Code, w2.Body.String())
		}
		var resp2 common.ResponseStandar
		_ = json.Unmarshal(w2.Body.Bytes(), &resp2)
		trip2 := resp2.Data.(map[string]interface{})["trip"].(map[string]interface{})
		if int(trip2["available_seats"].(float64)) != 0 {
			t.Fatalf("Expected available_seats 0, got %v", trip2["available_seats"])
		}

		// Kursi sudah 0 -> 400 Bad Request
		body3, _ := json.Marshal(map[string]string{"user_id": "usr-013"})
		req3 := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips/st-001/join", bytes.NewReader(body3))
		req3.Header.Set("Content-Type", "application/json")
		w3 := httptest.NewRecorder()
		r.ServeHTTP(w3, req3)
		if w3.Code != http.StatusBadRequest {
			t.Fatalf("Expected 400 Bad Request when seats == 0, got %d. Body: %s", w3.Code, w3.Body.String())
		}
		var resp3 common.ResponseStandar
		_ = json.Unmarshal(w3.Body.Bytes(), &resp3)
		if resp3.Message != "Kuota kursi Open Trip sudah penuh" {
			t.Fatalf("Unexpected message: %s", resp3.Message)
		}
	})
}

func TestDeleteSharedTrip_AuthorizationAndRemoval(t *testing.T) {
	r, _ := setupTestRouter()

	// Seed trip st-001 dimiliki oleh host "usr-002"

	// 1. Gagal jika user_id kosong -> 400
	t.Run("empty user_id returns 400", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/community/shared-trips/st-001", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusBadRequest {
			t.Fatalf("Expected 400 Bad Request, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "user_id wajib diisi untuk menghapus Open Trip" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
	})

	// 2. Gagal jika trip tidak ada -> 404
	t.Run("trip not found returns 404", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/community/shared-trips/st-tidak-ada?user_id=usr-002", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusNotFound {
			t.Fatalf("Expected 404 Not Found, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "Open Trip tidak ditemukan" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
	})

	// 3. Gagal jika bukan host -> 403 Forbidden
	t.Run("non-host delete returns 403", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/community/shared-trips/st-001?user_id=usr-bukan-host", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusForbidden {
			t.Fatalf("Expected 403 Forbidden, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "Hanya pembuat (host) yang dapat menghapus Open Trip ini" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
	})

	// 4. Berhasil jika host menghapus -> 200 OK & trip hilang dari GetSharedTrips (uji JSON body)
	t.Run("host delete succeeds and removes trip from list", func(t *testing.T) {
		body, _ := json.Marshal(map[string]string{"user_id": "usr-002"})
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/community/shared-trips/st-001", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("Expected 200 OK, got %d. Body: %s", w.Code, w.Body.String())
		}
		var resp common.ResponseStandar
		_ = json.Unmarshal(w.Body.Bytes(), &resp)
		if resp.Message != "Open Trip berhasil dihapus" {
			t.Fatalf("Unexpected message: %s", resp.Message)
		}
		data := resp.Data.(map[string]interface{})
		if data["deleted_id"] != "st-001" {
			t.Fatalf("Expected deleted_id 'st-001', got %v", data["deleted_id"])
		}

		// Verifikasi trip hilang dari GetSharedTrips
		getReq := httptest.NewRequest(http.MethodGet, "/api/v1/community/shared-trips", nil)
		getW := httptest.NewRecorder()
		r.ServeHTTP(getW, getReq)
		if getW.Code != http.StatusOK {
			t.Fatalf("Expected 200 OK on GetSharedTrips, got %d", getW.Code)
		}
		var listResp common.ResponseStandar
		_ = json.Unmarshal(getW.Body.Bytes(), &listResp)
		trips := listResp.Data.(map[string]interface{})["trips"].([]interface{})
		for _, item := range trips {
			tripMap := item.(map[string]interface{})
			if tripMap["id"] == "st-001" {
				t.Fatalf("Expected trip st-001 to be removed from GetSharedTrips")
			}
		}
	})
}

