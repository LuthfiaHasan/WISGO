package be1_core

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestBE1Sprint2Suite(t *testing.T) {
	mux := setupWISGOTestMux()

	t.Run("TC-S2-01 (Hari 7): GET /api/v1/destinations/{id}/scenes-360 mengembalikan scene Aerial-to-Ground & 4 Pin Interaktif", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations/dest-001/scenes-360", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var body map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("failed to parse JSON: %v", err)
		}
		scenes, ok := body["scenes_360"].([]interface{})
		if !ok || len(scenes) < 2 {
			t.Fatalf("expected at least 2 scenes (aerial & ground) for Lembah Harau, got %v", len(scenes))
		}
	})

	t.Run("TC-S2-02 (Hari 7): POST /api/v1/admin/scenes-360/{sceneId}/hotspots menempelkan Pin 360 baru dari CMS Studio FS-1", func(t *testing.T) {
		payload := []byte(`{"type":"mitra","pitch":-10.5,"yaw":225.0,"title":"Kopi Kawa Daun Harau","target_ref":"partner-004","description":"Klik untuk pesan Kopi Kawa Daun hangat"}`)
		req := httptest.NewRequest("POST", "/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created, got %d: %s", rec.Code, rec.Body.String())
		}
	})

	t.Run("TC-S2-03 (Hari 8): POST /api/v1/spatial/shunlu memfilter POI searah rute (+X menit detour)", func(t *testing.T) {
		payload := []byte(`{"origin_lat":-0.9471,"origin_lng":100.4172,"destination_lat":-0.3051,"destination_lng":100.3692,"category":"rm_padang","max_detour_min":10}`)
		req := httptest.NewRequest("POST", "/api/v1/spatial/shunlu", bytes.NewBuffer(payload))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		pois, ok := res["shunlu_pois"].([]interface{})
		if !ok || len(pois) == 0 {
			t.Fatal("expected shunlu_pois along route to be returned")
		}
	})

	t.Run("TC-S2-04 (Hari 8): GET /api/v1/destinations/{id}/micro-map & POST /api/v1/spatial/audio-trigger-check memicu cerita otomatis <=15m", func(t *testing.T) {
		reqMap := httptest.NewRequest("GET", "/api/v1/destinations/dest-001/micro-map", nil)
		recMap := httptest.NewRecorder()
		mux.ServeHTTP(recMap, reqMap)
		if recMap.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on micro-map, got %d", recMap.Code)
		}

		payloadTrig := []byte(`{"destination_id":"dest-001","user_lat":-0.1025,"user_lng":100.6725}`)
		reqTrig := httptest.NewRequest("POST", "/api/v1/spatial/audio-trigger-check", bytes.NewBuffer(payloadTrig))
		recTrig := httptest.NewRecorder()
		mux.ServeHTTP(recTrig, reqTrig)
		if recTrig.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on audio-trigger-check, got %d", recTrig.Code)
		}

		var trigBody map[string]interface{}
		_ = json.Unmarshal(recTrig.Body.Bytes(), &trigBody)
		if trigBody["trigger_status"] != "AUTO_PLAY_ACTIVE" {
			t.Fatalf("expected AUTO_PLAY_ACTIVE within 15m radius, got %v", trigBody["trigger_status"])
		}
	})

	t.Run("TC-S2-05 (Hari 9): GET /api/v1/qr/{qrCode} meresolusi Plang Smart QR ke data destinasi + Fair-Price + 360", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/qr/QR-SMBR-LPK-001", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK for valid QR placard code, got %d", rec.Code)
		}
	})

	t.Run("TC-S2-06 (Hari 9): POST /api/v1/pungli/report mencatat bukti foto + GPS & menghitung selisih terhadap Perda", func(t *testing.T) {
		payload := []byte(`{"destination_id":"dest-001","reporter_name":"Wisatawan Anonim","incident_category":"parkir_liar","charged_amount_idr":20000,"photo_evidence":"https://cdn.rancak.in/evidence/parkir-20rb.jpg","latitude":-0.1023,"longitude":100.6728,"description":"Diminta parkir mobil Rp20.000 padahal Perda Rp5.000"}`)
		req := httptest.NewRequest("POST", "/api/v1/pungli/report", bytes.NewBuffer(payload))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created on pungli report, got %d", rec.Code)
		}
	})

	t.Run("TC-S2-07 (Hari 9): PATCH /api/v1/admin/pungli/{id}/status mengubah status tiket di Pusat Komando Satgas (FS-1)", func(t *testing.T) {
		payload := []byte(`{"status":"Ditindaklanjuti","satgas_notes":"Petugas Dishub & Satpol PP telah menertibkan oknum di lokasi."}`)
		req := httptest.NewRequest("PATCH", "/api/v1/admin/pungli/PGL-202611-0091/status", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on Satgas status update, got %d: %s", rec.Code, rec.Body.String())
		}
	})

	t.Run("TC-S2-08 (Hari 10): GET /api/v1/destinations/{id}/offline-bundle v2 menyertakan 360 scenes, micro-map & audio triggers", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations/dest-001/offline-bundle", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var bundle map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &bundle)
		if bundle["bundle_version"] != "v2.0-sprint2-complete" {
			t.Fatalf("expected bundle_version v2.0-sprint2-complete, got %v", bundle["bundle_version"])
		}
	})
}
