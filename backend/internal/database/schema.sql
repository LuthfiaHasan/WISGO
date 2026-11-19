-- ============================================================================
-- WISGO SUMBAR (Ekosistem Wisata Pintar Sumatera Barat) — Rancak.in
-- REVISI SKEMA DATABASE FINAL — 26 TABEL POSTGRESQL 16 + POSTGIS 3.4
-- Target Database: Supabase PostgreSQL (aws-0-ap-southeast-1.pooler.supabase.com)
-- ============================================================================

-- 0. EKSTENSI DATABASE
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- ZONA 5: MASTER ENTITAS UTAMA (categories & users)
-- ============================================================================

-- 1. TABEL categories (Master Kategori Multiguna)
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    module_type VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_categories_module ON categories(module_type);

-- 2. TABEL users (Pengguna, Turis, Admin, Pokdarwis)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    phone_number VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    jenis_input VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- ============================================================================
-- ZONA 2: DESTINASI & REKAMAN GAODE (destinations, indikator, aturan, tarif)
-- ============================================================================

-- 3. TABEL destinations (Destinasi Wisata Unggulan)
CREATE TABLE IF NOT EXISTS destinations (
    id VARCHAR(64) PRIMARY KEY,
    slug VARCHAR(128) UNIQUE,
    name VARCHAR(255) NOT NULL,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    city_regency VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326),
    elevation_m INT NOT NULL DEFAULT 0,
    cover_image TEXT NOT NULL,
    crowd_level VARCHAR(50) NOT NULL DEFAULT 'Sedang',
    distance_km NUMERIC(8, 2) NOT NULL DEFAULT 0,
    travel_time_min INT NOT NULL DEFAULT 0,
    estimated_cost NUMERIC(12, 2) NOT NULL DEFAULT 0,
    is_hidden_gem BOOLEAN NOT NULL DEFAULT false,
    qr_placard_code VARCHAR(128) UNIQUE,
    opening_hours VARCHAR(100) NOT NULL DEFAULT '08:00 - 18:00 WIB',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_destinations_geog ON destinations USING GIST(geog);
CREATE INDEX IF NOT EXISTS idx_destinations_category ON destinations(category_id);
CREATE INDEX IF NOT EXISTS idx_destinations_city ON destinations(city_regency);

-- Auto Trigger Update Geog destinations
CREATE OR REPLACE FUNCTION update_destinations_geog()
RETURNS TRIGGER AS $$
BEGIN
    NEW.geog = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_destinations_geog ON destinations;
CREATE TRIGGER trg_update_destinations_geog
BEFORE INSERT OR UPDATE ON destinations
FOR EACH ROW EXECUTE FUNCTION update_destinations_geog();

-- 4. TABEL indikator_medan (Relasi 1-to-1 Kesiapan Medan)
CREATE TABLE IF NOT EXISTS indikator_medan (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) UNIQUE NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    vehicle_access VARCHAR(100) NOT NULL,
    trekking_level VARCHAR(100) NOT NULL,
    cellular_signal VARCHAR(100) NOT NULL,
    facilities VARCHAR(255) NOT NULL,
    guide_need VARCHAR(100) NOT NULL
);

-- 5. TABEL aturan_destinasi (Kearifan Lokal & Tips Menjaga Lingkungan)
CREATE TABLE IF NOT EXISTS aturan_destinasi (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_aturan_destination ON aturan_destinasi(destination_id);

-- 6. TABEL official_tariffs (Standar Tarif Resmi Perda Prov Sumbar)
CREATE TABLE IF NOT EXISTS official_tariffs (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    item_name VARCHAR(255) NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    regulation_ref VARCHAR(255) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_tariffs_destination ON official_tariffs(destination_id);

-- ============================================================================
-- ZONA 1: STUDIO 360° & OFFLINE (panorama_scenes, panorama_hotspots, bundles)
-- ============================================================================

-- 7. TABEL panorama_scenes (Pemandangan Virtual 360°)
CREATE TABLE IF NOT EXISTS panorama_scenes (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    scene_type VARCHAR(50) NOT NULL,
    panorama_url TEXT NOT NULL,
    upload_format VARCHAR(50) NOT NULL,
    spatial_audio_url TEXT NOT NULL DEFAULT '',
    initial_pitch DOUBLE PRECISION NOT NULL DEFAULT 0,
    initial_yaw DOUBLE PRECISION NOT NULL DEFAULT 0,
    is_default_scene BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_scenes_destination ON panorama_scenes(destination_id);

-- 8. TABEL panorama_hotspots (Hotspot Pin Interaktif 360°)
CREATE TABLE IF NOT EXISTS panorama_hotspots (
    id VARCHAR(64) PRIMARY KEY,
    scene_id VARCHAR(64) NOT NULL REFERENCES panorama_scenes(id) ON DELETE CASCADE,
    pin_type VARCHAR(100) NOT NULL,
    color_token VARCHAR(50) NOT NULL,
    pitch DOUBLE PRECISION NOT NULL,
    yaw DOUBLE PRECISION NOT NULL,
    title VARCHAR(255) NOT NULL,
    target_ref VARCHAR(255) NOT NULL DEFAULT '',
    voice_text TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_hotspots_scene ON panorama_hotspots(scene_id);

-- 9. TABEL offline_bundles (Paket Peta & Data Pocket Offline)
CREATE TABLE IF NOT EXISTS offline_bundles (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) UNIQUE NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    bundle_version VARCHAR(50) NOT NULL,
    file_size_kb INT NOT NULL,
    map_tiles_url TEXT NOT NULL,
    compressed_payload JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- ZONA 2: GAODE, PUNGLI, REVIEWS & TELEMETRY
-- ============================================================================

-- 10. TABEL gaode_behavior_rankings (Peringkat Perilaku Otentik Turis)
CREATE TABLE IF NOT EXISTS gaode_behavior_rankings (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) UNIQUE NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    rank_position INT NOT NULL,
    gaode_authenticity_score NUMERIC(5, 2) NOT NULL,
    active_nav_count_30d INT NOT NULL,
    avg_dwell_time_min INT NOT NULL,
    return_visit_rate_pct NUMERIC(5, 2) NOT NULL,
    anti_fake_review_verified BOOLEAN NOT NULL DEFAULT true,
    trending_badge VARCHAR(100) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_gaode_rank ON gaode_behavior_rankings(rank_position);

-- 11. TABEL pungli_reports (Laporan Aduan Saber Pungli)
CREATE TABLE IF NOT EXISTS pungli_reports (
    id VARCHAR(64) PRIMARY KEY,
    ticket_code VARCHAR(100) UNIQUE NOT NULL,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id),
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id),
    tariff_id VARCHAR(64) REFERENCES official_tariffs(id),
    incident_category VARCHAR(100) NOT NULL,
    charged_amount_idr NUMERIC(12, 2) NOT NULL,
    official_perda_price_idr NUMERIC(12, 2) NOT NULL,
    overcharge_amount_idr NUMERIC(12, 2) NOT NULL,
    photo_evidence TEXT NOT NULL,
    incident_geog GEOGRAPHY(Point, 4326),
    status VARCHAR(50) NOT NULL DEFAULT 'Masuk',
    verified_by_admin_id VARCHAR(64) REFERENCES users(id),
    admin_action_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pungli_destination ON pungli_reports(destination_id);
CREATE INDEX IF NOT EXISTS idx_pungli_status ON pungli_reports(status);

-- 12. TABEL stemp_visit (Validasi Stempel Check-in GPS Turis)
CREATE TABLE IF NOT EXISTS stemp_visit (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMPTZ DEFAULT NOW(),
    is_gps_valid BOOLEAN NOT NULL DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_stemp_user ON stemp_visit(user_id);
CREATE INDEX IF NOT EXISTS idx_stemp_destination ON stemp_visit(destination_id);

-- 13. TABEL destination_reviews (Ulasan Wisatawan & Moderasi)
CREATE TABLE IF NOT EXISTS destination_reviews (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id),
    stemp_visit_id VARCHAR(64) UNIQUE REFERENCES stemp_visit(id) ON DELETE SET NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_comment TEXT NOT NULL,
    photo_url TEXT,
    is_gps_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reviews_destination ON destination_reviews(destination_id);

-- 14. TABEL api_telemetry_logs (Log Latensi SLA & Cache)
CREATE TABLE IF NOT EXISTS api_telemetry_logs (
    id VARCHAR(64) PRIMARY KEY,
    endpoint_path VARCHAR(255) NOT NULL,
    http_method VARCHAR(20) NOT NULL,
    status_code INT NOT NULL,
    latency_ms NUMERIC(8, 2) NOT NULL,
    cache_hit BOOLEAN NOT NULL DEFAULT false,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_telemetry_path ON api_telemetry_logs(endpoint_path);

-- ============================================================================
-- ZONA 3: VISIT POINT, HAZARD, SOS, MINANG & DARURAT
-- ============================================================================

-- 15. TABEL visit_point (Titik Singgah Searah / Shunlu)
CREATE TABLE IF NOT EXISTS visit_point (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    corridor_road VARCHAR(255) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326),
    detour_minutes INT NOT NULL,
    detour_distance_meter INT NOT NULL,
    highlight_note TEXT NOT NULL,
    opening_hours VARCHAR(100) NOT NULL,
    is_recommended BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_visit_point_geog ON visit_point USING GIST(geog);

-- 16. TABEL hazard_alerts (Peringatan Bahaya Jalur Ekstrem)
CREATE TABLE IF NOT EXISTS hazard_alerts (
    id VARCHAR(64) PRIMARY KEY,
    corridor_code VARCHAR(100) UNIQUE NOT NULL,
    location VARCHAR(255) NOT NULL,
    road_segment VARCHAR(255) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326),
    radius_meter INT NOT NULL,
    severity VARCHAR(50) NOT NULL,
    hazard_type VARCHAR(100) NOT NULL,
    weather_status VARCHAR(100) NOT NULL,
    slope_gradient_deg INT NOT NULL,
    message TEXT NOT NULL,
    detour_route TEXT NOT NULL,
    detour_route_geojson JSONB NOT NULL DEFAULT '{}',
    nearest_rescue_post VARCHAR(255) NOT NULL,
    emergency_contact VARCHAR(100) NOT NULL,
    triggered_by_admin VARCHAR(64) REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_hazard_corridor ON hazard_alerts(corridor_code);
CREATE INDEX IF NOT EXISTS idx_hazard_geog ON hazard_alerts USING GIST(geog);

-- 17. TABEL sos_signals (Sinyal Darurat SOS Wisatawan)
CREATE TABLE IF NOT EXISTS sos_signals (
    id VARCHAR(64) PRIMARY KEY,
    sos_code VARCHAR(100) UNIQUE NOT NULL,
    tourist_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    emergency_type VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326),
    battery_percent INT NOT NULL,
    passengers_count INT NOT NULL,
    nearest_corridor VARCHAR(100) NOT NULL REFERENCES hazard_alerts(corridor_code),
    nearest_rescue_post VARCHAR(255) NOT NULL,
    distance_to_rescue_km NUMERIC(8, 2) NOT NULL,
    eta_rescue_minutes INT NOT NULL,
    status VARCHAR(50) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sos_corridor ON sos_signals(nearest_corridor);
CREATE INDEX IF NOT EXISTS idx_sos_status ON sos_signals(status);

-- 18. TABEL minang_phrases (Kamus Saku Frasa Minang)
CREATE TABLE IF NOT EXISTS minang_phrases (
    id VARCHAR(64) PRIMARY KEY,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    indonesian_text TEXT NOT NULL,
    minang_text TEXT NOT NULL,
    phonetic_guide TEXT NOT NULL,
    voice_text TEXT NOT NULL,
    dialect_note VARCHAR(100) NOT NULL,
    usage_context_tip TEXT NOT NULL,
    politeness_level VARCHAR(50) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_phrases_category ON minang_phrases(category_id);

-- 19. TABEL emergency_contacts (Daftar Kontak Posko SAR & Instansi)
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id VARCHAR(64) PRIMARY KEY,
    agency_name VARCHAR(255) NOT NULL,
    agency_type VARCHAR(50) NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    whatsapp_number VARCHAR(50),
    city_regency VARCHAR(100) NOT NULL,
    geog GEOGRAPHY(Point, 4326) NOT NULL,
    created_by_admin_id VARCHAR(64) NOT NULL REFERENCES users(id),
    is_active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_emergency_geog ON emergency_contacts USING GIST(geog);

-- ============================================================================
-- ZONA 4: EVENT, SAVED, NEW TOUR, CHALLENGES & REWARDS
-- ============================================================================

-- 20. TABEL cultural_events (Kalender Event Budaya Sumbar)
CREATE TABLE IF NOT EXISTS cultural_events (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    nagari_location VARCHAR(255) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    schedule_rule VARCHAR(100) NOT NULL,
    next_event_date VARCHAR(50) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326),
    highlight_item TEXT NOT NULL,
    cultural_etiquette TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_cultural_events_date ON cultural_events(next_event_date);

-- 21. TABEL saved_places (Bookmark Destinasi Wisatawan)
CREATE TABLE IF NOT EXISTS saved_places (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_saved_places UNIQUE (user_id, destination_id)
);

-- 22. TABEL new_tour (Usulan Destinasi Baru dari Komunitas/Turis)
CREATE TABLE IF NOT EXISTS new_tour (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    city_regency VARCHAR(100) NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    tips_menjaga TEXT NOT NULL,
    is_sensitive BOOLEAN DEFAULT false,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_new_tour_status ON new_tour(status);

-- 23. TABEL challenges (Program Tantangan Ceklis Wisata)
CREATE TABLE IF NOT EXISTS challenges (
    id VARCHAR(64) PRIMARY KEY,
    created_by_admin_id VARCHAR(64) NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    target_destination_count INT NOT NULL,
    reward_title VARCHAR(255) NOT NULL,
    reward_type VARCHAR(100) NOT NULL,
    reward_points INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 24. TABEL user_challenge_rewards (Klaim & Verifikasi Piagam Hadiah)
CREATE TABLE IF NOT EXISTS user_challenge_rewards (
    id VARCHAR(64) PRIMARY KEY,
    challenge_id VARCHAR(64) NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id),
    progress_count INT NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'DALAM_PROGRES',
    jenis_reward VARCHAR(100) NOT NULL,
    reward VARCHAR(255) NOT NULL,
    certificate_code VARCHAR(100) UNIQUE,
    certificate_url TEXT,
    completed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_rewards_challenge ON user_challenge_rewards(challenge_id);
CREATE INDEX IF NOT EXISTS idx_rewards_status ON user_challenge_rewards(status);

-- ============================================================================
-- ZONA 5: OPEN TRIPS & NOTIFIKASI
-- ============================================================================

-- 25. TABEL open_trips (Trip Bersama & Auto-Itinerary)
CREATE TABLE IF NOT EXISTS open_trips (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    destination_route VARCHAR(255) NOT NULL,
    departure_date TIMESTAMPTZ NOT NULL,
    available_seats INT NOT NULL,
    cost_per_person NUMERIC(12, 2) NOT NULL,
    contact_wa VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_open_trips_departure ON open_trips(departure_date);

-- 26. TABEL notifikasi (Notifikasi Pengguna & Alasan Penolakan)
CREATE TABLE IF NOT EXISTS notifikasi (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    reference_id VARCHAR(64),
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifikasi_user ON notifikasi(user_id);
