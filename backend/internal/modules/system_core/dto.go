package system_core

// EndpointContractItem mendeskripsikan satu kontrak API resmi BE-1 untuk katalog 24 Endpoint Final
type EndpointContractItem struct {
	Number       int    `json:"number"`
	Sprint       string `json:"sprint"`
	Day          string `json:"day"`
	Method       string `json:"method"`
	Path         string `json:"path"`
	Title        string `json:"title"`
	PillarRef    string `json:"pillar_ref"`
	AuthGuard    string `json:"auth_guard"`
	ConsumerRole string `json:"consumer_role"` // FE-1, FE-2, FS-1
	TargetSLAMS  int    `json:"target_sla_ms"`
	CacheOrGuard string `json:"cache_or_guard"`
}

// SystemContractsCatalogResponse respon katalog 24 endpoint resmi BE-1
type SystemContractsCatalogResponse struct {
	Project              string                 `json:"project"`
	Role                 string                 `json:"role"`
	TotalEndpoints       int                    `json:"total_endpoints"`
	ReturnedEndpoints    int                    `json:"returned_endpoints"`
	FridayWeek4Milestone string                 `json:"friday_week4_milestone"`
	Endpoints            []EndpointContractItem `json:"endpoints"`
}

// SLAVerificationDetail rincian verifikasi SLA <100ms
type SLAVerificationDetail struct {
	TargetMaxLatencyMS float64 `json:"target_max_latency_ms"`
	P50LatencyMS       float64 `json:"p50_latency_ms"`
	P95LatencyMS       float64 `json:"p95_latency_ms"`
	P99LatencyMS       float64 `json:"p99_latency_ms"`
	SLAPassed          bool    `json:"sla_passed"`
	Verdict            string  `json:"verdict"`
}

// ProbeBreakdownDetail rincian pengukuran latensi tiap komponen inti
type ProbeBreakdownDetail struct {
	Probe     string  `json:"probe"`
	LatencyMS float64 `json:"latency_ms"`
	IndexUsed string  `json:"index_used"`
}

// SystemBenchmarkResponse respon hasil benchmark performa langsung
type SystemBenchmarkResponse struct {
	Status            string                 `json:"status"`
	Sprint            string                 `json:"sprint"`
	BenchmarkedAt     string                 `json:"benchmarked_at"`
	SLAVerification   SLAVerificationDetail  `json:"sla_verification"`
	ProbeBreakdownMS  []ProbeBreakdownDetail `json:"probe_breakdown_ms"`
	CacheLayer        map[string]interface{} `json:"cache_layer"`
	RateLimitLayer    map[string]interface{} `json:"rate_limit_layer"`
	DatabaseReadiness map[string]interface{} `json:"database_readiness"`
}

// CacheFlushResponse respon hasil pengosongan cache manual oleh admin
type CacheFlushResponse struct {
	Status          string `json:"status"`
	FlushedKeys     int    `json:"flushed_keys"`
	FlushedAt       string `json:"flushed_at"`
	TriggeredByRole string `json:"triggered_by_role"`
	Message         string `json:"message"`
}

// GetBE1Catalog24Endpoints mengembalikan daftar lengkap 24 Endpoint BE-1 dari Minggu 1 s/d Minggu 4
func GetBE1Catalog24Endpoints() []EndpointContractItem {
	return []EndpointContractItem{
		// --- SPRINT 1 (MINGGU 1: HARI 1-5) -> 7 ENDPOINT ---
		{Number: 1, Sprint: "Minggu 1 (Sprint 1)", Day: "Hari 1", Method: "GET", Path: "/api/v1/health", Title: "Healthcheck Server & Kesiapan 11 Tabel PostGIS BE-1", PillarRef: "Infrastruktur", AuthGuard: "Public", ConsumerRole: "FE-1, FE-2, FS-1", TargetSLAMS: 10, CacheOrGuard: "Zero-Latency Direct"},
		{Number: 2, Sprint: "Minggu 1 (Sprint 1)", Day: "Hari 4", Method: "GET", Path: "/api/v1/destinations", Title: "Direktori 20 Destinasi Sumbar + Filter Spasial ST_DistanceSphere", PillarRef: "Pilar 2 (P2.1)", AuthGuard: "Public", ConsumerRole: "FE-1 (Layar 01 Beranda)", TargetSLAMS: 45, CacheOrGuard: "InMemoryTTLCache + ETag (304)"},
		{Number: 3, Sprint: "Minggu 1 (Sprint 1)", Day: "Hari 4", Method: "GET", Path: "/api/v1/destinations/{id}", Title: "Aggregate Detail Destinasi (4 Statistik + 5 Indikator Medan + Tips + Tarif)", PillarRef: "Pilar 2 & 3 (P2.2, P3.1)", AuthGuard: "Public", ConsumerRole: "FE-1 (Layar 02) & FE-2", TargetSLAMS: 50, CacheOrGuard: "Composite Index PostGIS"},
		{Number: 4, Sprint: "Minggu 1 (Sprint 1)", Day: "Hari 4", Method: "GET", Path: "/api/v1/destinations/{id}/tariffs", Title: "Tabel Fair-Price Barometer Resmi Perda / Nagari", PillarRef: "Pilar 3 (P3.1)", AuthGuard: "Public", ConsumerRole: "FE-2 (Fair-Price Table)", TargetSLAMS: 35, CacheOrGuard: "B-Tree Index Tariffs"},
		{Number: 5, Sprint: "Minggu 1 (Sprint 1)", Day: "Hari 4 & 10", Method: "GET", Path: "/api/v1/destinations/{id}/offline-bundle", Title: "Bundel JSON Offline v2 (Destinasi + 360° + Peta Mikro + Audio Trigger)", PillarRef: "Pilar 7 (P7.1)", AuthGuard: "Public", ConsumerRole: "FE-1 (Offline Hive/Sqflite)", TargetSLAMS: 65, CacheOrGuard: "InMemoryTTLCache + ETag (304)"},
		{Number: 6, Sprint: "Minggu 1 (Sprint 1)", Day: "Hari 5", Method: "POST", Path: "/api/v1/admin/destinations", Title: "CMS Tambah Destinasi Baru + 5 Indikator Medan", PillarRef: "CMS FS-1", AuthGuard: "JWT RBAC (admin_dispar, pokdarwis)", ConsumerRole: "FS-1 (Web Admin CMS)", TargetSLAMS: 70, CacheOrGuard: "Auto-Invalidate Cache"},
		{Number: 7, Sprint: "Minggu 1 (Sprint 1)", Day: "Hari 5", Method: "PUT", Path: "/api/v1/admin/destinations/{id}/tariffs", Title: "CMS Pembaruan Tarif Resmi Perda / Nagari", PillarRef: "Pilar 3 (P3.1)", AuthGuard: "JWT RBAC (admin_dispar, pokdarwis)", ConsumerRole: "FS-1 (Web Admin CMS)", TargetSLAMS: 65, CacheOrGuard: "Auto-Invalidate Cache"},

		// --- SPRINT 2 (MINGGU 2: HARI 6-10) -> 7 ENDPOINT ---
		{Number: 8, Sprint: "Minggu 2 (Sprint 2)", Day: "Hari 7", Method: "GET", Path: "/api/v1/destinations/{id}/scenes-360", Title: "Tur Imersif 360° Aerial-to-Ground & 4 Jenis Pin Interaktif", PillarRef: "Pilar 1 (P1.1, P1.2)", AuthGuard: "Public", ConsumerRole: "FE-1 (Layar 03 Kanvas 360°)", TargetSLAMS: 40, CacheOrGuard: "InMemoryTTLCache + ETag (304)"},
		{Number: 9, Sprint: "Minggu 2 (Sprint 2)", Day: "Hari 7", Method: "POST", Path: "/api/v1/admin/scenes-360/{sceneId}/hotspots", Title: "CMS Studio 360° Visual Editor (Drag & Drop Pitch/Yaw 4 Pin)", PillarRef: "Pilar 1 (P1.2)", AuthGuard: "JWT RBAC (admin_dispar, pokdarwis)", ConsumerRole: "FS-1 (Studio 360° Editor)", TargetSLAMS: 60, CacheOrGuard: "Auto-Invalidate Cache"},
		{Number: 10, Sprint: "Minggu 2 (Sprint 2)", Day: "Hari 8", Method: "POST", Path: "/api/v1/spatial/shunlu", Title: "Pencarian Searah Rute (Along-the-Route 'Shunlu' +X Menit Detour)", PillarRef: "Pilar 2 (P2.3)", AuthGuard: "Public", ConsumerRole: "FE-1 (Shunlu Filter Chip)", TargetSLAMS: 55, CacheOrGuard: "GIST Spatial Buffer Index"},
		{Number: 11, Sprint: "Minggu 2 (Sprint 2)", Day: "Hari 8", Method: "GET", Path: "/api/v1/destinations/{id}/micro-map", Title: "Peta Mikro Internal Kawasan Wisata + Titik Audio GPS <=15m", PillarRef: "Pilar 1 & 2 (P1.3, P2.5)", AuthGuard: "Public", ConsumerRole: "FE-1 (Peta Mikro & Audio)", TargetSLAMS: 45, CacheOrGuard: "GIST Spatial Index"},
		{Number: 12, Sprint: "Minggu 2 (Sprint 2)", Day: "Hari 9", Method: "GET", Path: "/api/v1/qr/{qrCode}", Title: "Resolusi Cepat Scanner Plang Smart QR Fisik di Lokasi", PillarRef: "Pilar 3 (P3.2)", AuthGuard: "Public", ConsumerRole: "FE-2 (Scanner Plang QR)", TargetSLAMS: 30, CacheOrGuard: "Unique QR Code Index"},
		{Number: 13, Sprint: "Minggu 2 (Sprint 2)", Day: "Hari 9", Method: "POST", Path: "/api/v1/pungli/report", Title: "Pengiriman Bukti Lapor Pungli (Foto + Tag GPS + Kalkulasi Selisih Perda)", PillarRef: "Pilar 3 (P3.3)", AuthGuard: "Public (Boleh Anonim)", ConsumerRole: "FE-2 (Form Lapor Pungli)", TargetSLAMS: 75, CacheOrGuard: "Token Bucket Rate-Limit (HTTP 429)"},
		{Number: 14, Sprint: "Minggu 2 (Sprint 2)", Day: "Hari 9", Method: "PATCH", Path: "/api/v1/admin/pungli/{id}/status", Title: "Pusat Komando Satgas Saber Pungli (Tindak Lanjut Status Laporan)", PillarRef: "Pilar 3 (P3.3)", AuthGuard: "JWT RBAC (admin_dispar)", ConsumerRole: "FS-1 (Dashboard Satgas)", TargetSLAMS: 60, CacheOrGuard: "RBAC Strict Audit"},

		// --- SPRINT 3 (MINGGU 3: HARI 11-15) -> 7 ENDPOINT ---
		{Number: 15, Sprint: "Minggu 3 (Sprint 3)", Day: "Hari 12", Method: "GET", Path: "/api/v1/destinations/rankings/gaode", Title: "Leaderboard Behavior-Based Ranking (Gaode Guide Anti-Bintang Palsu)", PillarRef: "Pilar 2 (P2.4)", AuthGuard: "Public", ConsumerRole: "FE-1 (Leaderboard Gaode)", TargetSLAMS: 35, CacheOrGuard: "Materialized View mv_gaode_leaderboard"},
		{Number: 16, Sprint: "Minggu 3 (Sprint 3)", Day: "Hari 12", Method: "POST", Path: "/api/v1/spatial/navigation-telemetry", Title: "Ingesti Telemetri Navigasi Nyata & Dwell Time GPS (>=20m Valid)", PillarRef: "Pilar 2 (P2.4)", AuthGuard: "Public", ConsumerRole: "FE-1 (Background GPS Hook)", TargetSLAMS: 50, CacheOrGuard: "Token Bucket Rate-Limit (HTTP 429)"},
		{Number: 17, Sprint: "Minggu 3 (Sprint 3)", Day: "Hari 13", Method: "GET", Path: "/api/v1/spatial/hazards", Title: "Radar Live Hazard Alert 4 Jalur Ekstrem Sumbar + Rute Alternatif", PillarRef: "Pilar 7 (P7.2)", AuthGuard: "Public", ConsumerRole: "FE-1 (Banner Bahaya & Detour)", TargetSLAMS: 35, CacheOrGuard: "Partial GIST Index Active Hazards"},
		{Number: 18, Sprint: "Minggu 3 (Sprint 3)", Day: "Hari 13", Method: "POST", Path: "/api/v1/admin/hazards/trigger", Title: "Simulasi & Trigger Status Bencana Jalur Ekstrem oleh Admin Dispar/BPBD", PillarRef: "Pilar 7 (P7.2)", AuthGuard: "JWT RBAC (admin_dispar, pokdarwis)", ConsumerRole: "FS-1 (Panel Kendali Cuaca/Bencana)", TargetSLAMS: 60, CacheOrGuard: "Auto-Invalidate Cache"},
		{Number: 19, Sprint: "Minggu 3 (Sprint 3)", Day: "Hari 13", Method: "POST", Path: "/api/v1/spatial/sos", Title: "Pancaran Sinyal Darurat SOS GPS Wisatawan + Auto-Assign Pos SAR Terdekat", PillarRef: "Pilar 7 (P7.2)", AuthGuard: "Public (Darurat)", ConsumerRole: "FE-1 (Tombol Darurat SOS)", TargetSLAMS: 55, CacheOrGuard: "Token Bucket Rate-Limit (HTTP 429)"},
		{Number: 20, Sprint: "Minggu 3 (Sprint 3)", Day: "Hari 14", Method: "GET", Path: "/api/v1/culture/minang-phrases", Title: "Kamus Saku Audio Bahasa Minang Sehari-hari (Kato Nan Ampek)", PillarRef: "Pilar 1 (P1.4)", AuthGuard: "Public", ConsumerRole: "FE-1 (Kamus Saku Audio)", TargetSLAMS: 30, CacheOrGuard: "InMemoryTTLCache + ETag (304)"},
		{Number: 21, Sprint: "Minggu 3 (Sprint 3)", Day: "Hari 14", Method: "GET", Path: "/api/v1/culture/events", Title: "Kalender Budaya & Hari Pakan (Pasar Tradisional Nagari) Terdekat", PillarRef: "Pilar 1 (P1.4)", AuthGuard: "Public", ConsumerRole: "FE-1 (Kalender Budaya)", TargetSLAMS: 40, CacheOrGuard: "Spatial Distance Sort"},

		// --- SPRINT 4 (MINGGU 4: HARI 16-20) -> 3 ENDPOINT PENUTUP (TOTAL = 24 ENDPOINT) ---
		{Number: 22, Sprint: "Minggu 4 (Sprint 4)", Day: "Hari 19", Method: "GET", Path: "/api/v1/admin/system/benchmark", Title: "Live Performance Benchmark (<100ms SLA), Cache Stats & Audit 11 Tabel PostGIS", PillarRef: "Hardening & SLA", AuthGuard: "JWT RBAC (admin_dispar, pokdarwis)", ConsumerRole: "FS-1 & QA Workbench", TargetSLAMS: 45, CacheOrGuard: "Real-Time Latency Probe"},
		{Number: 23, Sprint: "Minggu 4 (Sprint 4)", Day: "Hari 19", Method: "POST", Path: "/api/v1/admin/cache/flush", Title: "Manual Flush In-Memory TTL Cache & Reset ETag oleh Admin FS-1", PillarRef: "Caching 360° & Rute", AuthGuard: "JWT RBAC (admin_dispar, pokdarwis)", ConsumerRole: "FS-1 (Web Admin CMS)", TargetSLAMS: 15, CacheOrGuard: "Atomic Cache Reset"},
		{Number: 24, Sprint: "Minggu 4 (Sprint 4)", Day: "Hari 19", Method: "GET", Path: "/api/v1/system/contracts", Title: "Katalog Kontrak 24 Endpoint BE-1 (Sprint 1-4) & Matriks Sinkronisasi Tim", PillarRef: "Dokumentasi Final", AuthGuard: "Public", ConsumerRole: "FE-1, FE-2, FS-1", TargetSLAMS: 20, CacheOrGuard: "Static Contract Registry"},
	}
}
