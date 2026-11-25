package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
)

func TestIntegratedGinRouter(t *testing.T) {
	cfg := &config.Config{
		Port:        "8080",
		Environment: "test",
	}
	r := setupRouter(cfg)

	// 1. Test Health Check
	reqHealth := httptest.NewRequest(http.MethodGet, "/health", nil)
	wHealth := httptest.NewRecorder()
	r.ServeHTTP(wHealth, reqHealth)

	if wHealth.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on /health, got %d. Body: %s", wHealth.Code, wHealth.Body.String())
	}

	// 2. Test CORS Headers
	reqOptions := httptest.NewRequest(http.MethodOptions, "/api/v1/destinations", nil)
	wOptions := httptest.NewRecorder()
	r.ServeHTTP(wOptions, reqOptions)

	if wOptions.Header().Get("Access-Control-Allow-Origin") != "*" {
		t.Fatalf("Expected CORS Access-Control-Allow-Origin header to be *")
	}

	// 3. Test Modul BE-1 (Native Gin Routing)
	be1Endpoints := []struct {
		name   string
		method string
		path   string
	}{
		{"BE-1 Destinations Catalog", http.MethodGet, "/api/v1/destinations"},
		{"BE-1 360 Scenes", http.MethodGet, "/api/v1/destinations/dest-001/scenes-360"},
		{"BE-1 MicroMap", http.MethodGet, "/api/v1/destinations/dest-001/micro-map"},
		{"BE-1 Live Hazards", http.MethodGet, "/api/v1/spatial/hazards"},
		{"BE-1 Gaode Rankings", http.MethodGet, "/api/v1/destinations/rankings/gaode"},
		{"BE-1 Minang Phrases", http.MethodGet, "/api/v1/culture/minang-phrases"},
		{"BE-1 Cultural Events", http.MethodGet, "/api/v1/culture/events"},
		{"BE-1 System Contracts", http.MethodGet, "/api/v1/system/contracts"},
	}

	for _, tc := range be1Endpoints {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, nil)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			if w.Code != http.StatusOK {
				t.Fatalf("Expected 200 OK on %s (%s), got %d. Body: %s", tc.path, tc.name, w.Code, w.Body.String())
			}
		})
	}

	// 4. Test Modul BE-2 (Clean Vertical Slice Architecture - Active Clusters)
	be2Endpoints := []struct {
		name   string
		method string
		path   string
	}{
		{"Community Places Module", http.MethodGet, "/api/v1/community/places"},
		{"Community Open Trips Module", http.MethodGet, "/api/v1/community/shared-trips"},
		{"Gamification Passport Module", http.MethodGet, "/api/v1/gamification/passport"},
		{"Analytics Dispar Module", http.MethodGet, "/api/v1/analytics/dispar/summary"},
	}

	for _, tc := range be2Endpoints {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, nil)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			if w.Code != http.StatusOK {
				t.Fatalf("Expected 200 OK on %s (%s), got %d. Body: %s", tc.path, tc.name, w.Code, w.Body.String())
			}

			var resp common.ResponseStandar
			if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
				t.Fatalf("Failed to parse standard JSON response on %s: %v", tc.path, err)
			}
			if resp.Status != "success" {
				t.Fatalf("Expected status 'success' on %s, got: %s", tc.path, resp.Status)
			}
		})
	}
}
