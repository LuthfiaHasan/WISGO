-- =============================================================================
-- WISGO (Rancak.in) — MIGRASI DATABASE BE-1 SESUAI ERD REVISI 26 TABEL
-- Author       : Backend 1 (BE-1: Core & Spasial)
-- Standard     : PostgreSQL 16 + PostGIS 3.4
-- Cakupan      : Seluruh 15 Tabel BE-1 + 2 Tabel Tambahan Sistem
-- Relasi       : Terhubung dengan Master categories (category_id) & Relasi Frontend
-- Prinsip      : Menjaga Zero Conflict, tidak mengganggu modul BE-2
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================================================
-- 1. TABEL MASTER KATEGORI: categories (Menyatukan category_id lintas modul)
-- =============================================================================
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed Master Kategori Resmi Wisata & Kebudayaan Ranah Minang
INSERT INTO categories (id, name, description) VALUES
    ('cat-alam-geopark', 'Alam & Geopark', 'Wisata bentang alam, tebing granit, ngarai, dan geopark Sumatera Barat'),
    ('cat-budaya-nagari', 'Budaya & Nagari', 'Wisata kearifan lokal, rumah gadang, desa adat, dan upacara nagari'),
    ('cat-kuliner-legendaris', 'Kuliner Legendaris', 'Sentra kuliner Minangkabau otentik, rumah makan legendaris & rendang'),
    ('cat-hidden-gem', 'Hidden Gem', 'Destinasi wisata tersembunyi yang membutuhkan edukasi kelestarian khusus'),
    ('cat-bahari-pulau', 'Bahari & Pulau', 'Kawasan pesisir pantai, kepulauan Mandeh, dan wisata bawah laut'),
    ('cat-sejarah-peradaban', 'Sejarah & Peradaban', 'Situs cagar budaya, museum perjuangan, dan jejak heritage Minang'),
    ('cat-tiket-masuk', 'Tiket Masuk', 'Kategori tarif resmi tiket masuk kawasan wisata sesuai Perda'),
    ('cat-parkir-resmi', 'Parkir Resmi', 'Kategori tarif resmi retribusi parkir kendaraan roda 2 dan roda 4'),
    ('cat-wahana-atraksi', 'Wahana & Atraksi', 'Kategori tarif wahana perahu, flying fox, sewa pakaian adat, dll'),
    ('cat-aturan-kelestarian', 'Kelestarian Alam', 'Pedoman etika menjaga kebersihan dan ekosistem alam'),
    ('cat-aturan-adat', 'Etika Adat Minangkabau', 'Aturan adat sopan santun, Kato Nan Ampek, dan kearifan nagari'),
    ('cat-aturan-keselamatan', 'Keselamatan Medan', 'Panduan keselamatan pada medan curam, tebing, dan cuaca ekstrem'),
    ('cat-poi-kuliner', 'RM Padang Singgah', 'Titik mampir searah rute rumah makan Minang otentik'),
    ('cat-poi-spbu', 'SPBU & Rest Area', 'Titik mampir searah pengisian bahan bakar dan tempat istirahat'),
    ('cat-poi-ibadah', 'Masjid Bersih', 'Titik mampir searah fasilitas ibadah nyaman dan bersih'),
    ('cat-kato-mandaki', 'Kato Mandaki', 'Tutur kata sopan kepada orang yang lebih tua atau dituakan'),
    ('cat-kato-manurun', 'Kato Manurun', 'Tutur kata lembut dan mendidik kepada yang lebih muda'),
    ('cat-kato-malereang', 'Kato Malereang', 'Tutur kata kiasan dan diplomatis antar sesama besan/penghulu'),
    ('cat-kato-mandata', 'Kato Mandata', 'Tutur kata akrab setara antar teman sebaya')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description;

-- =============================================================================
-- 2. TABEL INDUK DESTINASI: destinations (+ category_id, geog, qr_placard_code)
-- =============================================================================
CREATE TABLE IF NOT EXISTS destinations (
    id VARCHAR(64) PRIMARY KEY,
    slug VARCHAR(120) UNIQUE,
    name VARCHAR(180) NOT NULL,
    category_id VARCHAR(64) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
    category VARCHAR(64) NOT NULL DEFAULT 'Alam & Geopark',
    city_regency VARCHAR(80) NOT NULL,
    description TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    elevation_m INTEGER NOT NULL DEFAULT 0,
    cover_image TEXT NOT NULL DEFAULT '',
    crowd_level VARCHAR(24) NOT NULL DEFAULT 'Sedang',
    distance_km NUMERIC(6,1) NOT NULL DEFAULT 0.0,
    travel_time_min INTEGER NOT NULL DEFAULT 0,
    estimated_cost NUMERIC(12,2) NOT NULL DEFAULT 0,
    is_hidden_gem BOOLEAN NOT NULL DEFAULT FALSE,
    verification_status VARCHAR(24) NOT NULL DEFAULT 'verified',
    qr_placard_code VARCHAR(64) UNIQUE,
    opening_hours VARCHAR(100) NOT NULL DEFAULT '08.00 - 17.30 WIB',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_destinations_geog_gist ON destinations USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_destinations_category_id ON destinations (category_id);
CREATE INDEX IF NOT EXISTS idx_destinations_city_regency ON destinations (city_regency);

-- =============================================================================
-- 3. TABEL 5 INDIKATOR MEDAN: indikator_medan (pokdarwis_name dihapus)
-- =============================================================================
CREATE TABLE IF NOT EXISTS indikator_medan (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    vehicle_access VARCHAR(160) NOT NULL,  -- Mobil OK, Hanya Motor, Jalan Kaki
    trekking_level VARCHAR(160) NOT NULL,  -- Datar / Mudah, Sedang, Curam / Ekstrem
    cellular_signal VARCHAR(160) NOT NULL, -- 4G Kuat, Sinyal Lemah, Blank Spot
    facilities VARCHAR(200) NOT NULL,      -- Toilet & Musala Lengkap, Terbatas, Belum Ada
    guide_need VARCHAR(160) NOT NULL       -- Wajib Pemandu, Disarankan, Mandiri
);

CREATE INDEX IF NOT EXISTS idx_indikator_medan_dest ON indikator_medan (destination_id);

-- Backward compatibility view untuk sistem legacy yang membaca medan_indicators
CREATE OR REPLACE VIEW medan_indicators AS
SELECT id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need, '' AS pokdarwis_name
FROM indikator_medan;

-- =============================================================================
-- 4. TABEL ATURAN DESTINASI: aturan_destinasi (is_important dihapus, pakai category_id)
-- =============================================================================
CREATE TABLE IF NOT EXISTS aturan_destinasi (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
    title VARCHAR(160) NOT NULL DEFAULT 'Aturan & Tips Menjaga Tempat',
    aturan TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_aturan_destinasi_dest ON aturan_destinasi (destination_id);
CREATE INDEX IF NOT EXISTS idx_aturan_destinasi_cat ON aturan_destinasi (category_id);

-- Backward compatibility view untuk sistem legacy yang membaca local_tips
CREATE OR REPLACE VIEW local_tips AS
SELECT 
    id, destination_id, title, 
    COALESCE(category_id, 'kelestarian_alam') AS category, 
    aturan AS content, 
    TRUE AS is_important
FROM aturan_destinasi;

-- =============================================================================
-- 5. TABEL STANDAR HARGA RESMI: official_tariffs (+ category_id)
-- =============================================================================
CREATE TABLE IF NOT EXISTS official_tariffs (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
    item_name VARCHAR(160) NOT NULL,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    unit VARCHAR(48) NOT NULL,
    regulation_ref VARCHAR(160) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_official_tariffs_dest ON official_tariffs (destination_id);
CREATE INDEX IF NOT EXISTS idx_official_tariffs_cat ON official_tariffs (category_id);

-- =============================================================================
-- 6. TABEL TUR VIRTUAL 360°: panorama_scenes (Aerial-to-Ground)
-- =============================================================================
CREATE TABLE IF NOT EXISTS panorama_scenes (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    title VARCHAR(180) NOT NULL,
    scene_type VARCHAR(24) NOT NULL CHECK (scene_type IN ('aerial', 'ground')),
    panorama_url TEXT NOT NULL,
    upload_format VARCHAR(24) NOT NULL DEFAULT 'url',
    spatial_audio_url TEXT NOT NULL DEFAULT '',
    initial_pitch DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    initial_yaw DOUBLE PRECISION NOT NULL DEFAULT 180.0,
    is_default_scene BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_panorama_scenes_dest ON panorama_scenes (destination_id);

-- =============================================================================
-- 7. TABEL PIN HOTSPOT 360°: panorama_hotspots (audio_url -> voice_text)
-- =============================================================================
CREATE TABLE IF NOT EXISTS panorama_hotspots (
    id VARCHAR(64) PRIMARY KEY,
    scene_id VARCHAR(64) NOT NULL REFERENCES panorama_scenes(id) ON DELETE CASCADE,
    pin_type VARCHAR(24) NOT NULL CHECK (pin_type IN ('navigasi', 'audio', 'fasilitas', 'mitra')),
    color_radar VARCHAR(24) NOT NULL DEFAULT '#2563EB',
    pitch DOUBLE PRECISION NOT NULL CHECK (pitch >= -90.0 AND pitch <= 90.0),
    yaw DOUBLE PRECISION NOT NULL CHECK (yaw >= 0.0 AND yaw <= 360.0),
    title VARCHAR(180) NOT NULL,
    target_ref VARCHAR(64) NOT NULL DEFAULT '',
    voice_text TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_panorama_hotspots_scene ON panorama_hotspots (scene_id);

-- =============================================================================
-- 8. TABEL BUNDEL OFFLINE: offline_bundles (Paket JSON + Tiles)
-- =============================================================================
CREATE TABLE IF NOT EXISTS offline_bundles (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    bundle_version VARCHAR(32) NOT NULL DEFAULT 'v2.0',
    bundle_size_mb NUMERIC(6,2) NOT NULL DEFAULT 15.5,
    map_tiles_url TEXT NOT NULL DEFAULT '',
    compressed_package JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_offline_bundles_dest ON offline_bundles (destination_id);

-- =============================================================================
-- 9. TABEL LAPORAN PUNGLI: pungli_reports (Wisatawan vs Perda)
-- =============================================================================
CREATE TABLE IF NOT EXISTS pungli_reports (
    id VARCHAR(64) PRIMARY KEY,
    qr_code VARCHAR(64),
    user_id VARCHAR(64),
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE CASCADE,
    tariff_id VARCHAR(64) REFERENCES official_tariffs(id) ON DELETE SET NULL,
    incident_category VARCHAR(64) NOT NULL DEFAULT 'parkir_liar',
    charged_amount_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    official_perda_price_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    overcharge_amount_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    photo_evidence TEXT NOT NULL,
    incident_geog GEOGRAPHY(Point, 4326),
    status VARCHAR(24) NOT NULL DEFAULT 'MASUK' CHECK (status IN ('MASUK', 'DIVERIFIKASI', 'DITINDAKLANJUTI', 'SELESAI', 'Masuk', 'Diverifikasi', 'Ditindaklanjuti', 'Selesai')),
    verified_by_admin_id VARCHAR(64),
    admin_action_notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pungli_reports_dest ON pungli_reports (destination_id);
CREATE INDEX IF NOT EXISTS idx_pungli_reports_status ON pungli_reports (status);

-- =============================================================================
-- 10. TABEL GAODE BEHAVIOR RANKINGS: gaode_behavior_rankings (+ category_id)
-- =============================================================================
CREATE TABLE IF NOT EXISTS gaode_behavior_rankings (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
    rank_position INT NOT NULL DEFAULT 1,
    gaode_score NUMERIC(5,2) NOT NULL DEFAULT 85.00,
    actual_dwell_time_min INT NOT NULL DEFAULT 45,
    avg_dwell_time_min INT NOT NULL DEFAULT 45,
    return_visitor_rate NUMERIC(5,2) NOT NULL DEFAULT 15.00,
    trending_badge VARCHAR(120) NOT NULL DEFAULT 'Terverifikasi Kunjungan Nyata',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gaode_rankings_score ON gaode_behavior_rankings (gaode_score DESC);
CREATE INDEX IF NOT EXISTS idx_gaode_rankings_cat ON gaode_behavior_rankings (category_id);

-- =============================================================================
-- 11. TABEL TEMPAT MAMPIR SEARAH: visit_point (Nama revisi dari shunlu_pois)
-- =============================================================================
CREATE TABLE IF NOT EXISTS visit_point (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(180) NOT NULL,
    category_id VARCHAR(64) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
    corridor_road VARCHAR(120) NOT NULL,
    city_regency VARCHAR(80) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    detour_distance_meter INT NOT NULL DEFAULT 250,
    detour_estimated_minute INT NOT NULL DEFAULT 3,
    highlight_note TEXT NOT NULL DEFAULT '',
    opening_hours VARCHAR(80) NOT NULL DEFAULT '06.00 - 22.00 WIB',
    is_recommended BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_visit_point_geog_gist ON visit_point USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_visit_point_cat ON visit_point (category_id);

-- Backward compatibility view untuk sistem legacy yang membaca shunlu_pois
CREATE OR REPLACE VIEW shunlu_pois AS
SELECT 
    id, name, 
    COALESCE(category_id, 'rm_padang') AS category, 
    corridor_road, city_regency, latitude, longitude, geog, 
    detour_estimated_minute AS detour_minutes, 
    detour_distance_meter, highlight_note, opening_hours, is_recommended
FROM visit_point;

-- =============================================================================
-- 12. TABEL ALERT RAWAN BENCANA: hazard_alerts (4 Koridor Jalur Ekstrem)
-- =============================================================================
CREATE TABLE IF NOT EXISTS hazard_alerts (
    id VARCHAR(64) PRIMARY KEY,
    corridor_code VARCHAR(64) NOT NULL UNIQUE,
    title VARCHAR(160) NOT NULL,
    road_segment VARCHAR(180) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    severity_level VARCHAR(32) NOT NULL DEFAULT 'Normal',
    hazard_status VARCHAR(80) NOT NULL,
    weather_status VARCHAR(80) NOT NULL,
    steep_gradient_deg INT NOT NULL DEFAULT 18,
    message TEXT NOT NULL,
    detour_route TEXT NOT NULL,
    detour_route_geojson JSONB NOT NULL DEFAULT '{}'::jsonb,
    nearest_rescue_post VARCHAR(160) NOT NULL,
    emergency_contact VARCHAR(64) NOT NULL,
    triggered_by_admin VARCHAR(100),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hazard_alerts_geog_gist ON hazard_alerts USING GIST (geog);

-- =============================================================================
-- 13. TABEL SINYAL DARURAT: sos_signals (Panggilan Bantuan Cepat GPS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS sos_signals (
    id VARCHAR(64) PRIMARY KEY,
    sos_code VARCHAR(40) NOT NULL UNIQUE,
    tourist_name VARCHAR(120) NOT NULL,
    phone_number VARCHAR(40) NOT NULL,
    emergency_type VARCHAR(80) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    battery_percent INT NOT NULL DEFAULT 50,
    passengers_count INT NOT NULL DEFAULT 1,
    current_corridor VARCHAR(120) NOT NULL,
    nearest_rescue_post VARCHAR(160) NOT NULL,
    distance_to_rescue_km NUMERIC(6,2) NOT NULL DEFAULT 2.5,
    eta_rescue_minutes INT NOT NULL DEFAULT 12,
    status VARCHAR(40) NOT NULL DEFAULT 'Dipancarkan',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sos_signals_geog_gist ON sos_signals USING GIST (geog);

-- =============================================================================
-- 14. TABEL KAMUS AUDIO MINANG: minang_phrases (voice_text + category_id)
-- =============================================================================
CREATE TABLE IF NOT EXISTS minang_phrases (
    id VARCHAR(64) PRIMARY KEY,
    category_id VARCHAR(64) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
    minang_phrase TEXT NOT NULL,
    indonesian_meaning TEXT NOT NULL,
    context_usage TEXT NOT NULL,
    voice_text TEXT NOT NULL,
    kato_type VARCHAR(48) NOT NULL,
    cultural_etiquette TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_minang_phrases_cat ON minang_phrases (category_id);

-- =============================================================================
-- 15. TABEL KALENDER BUDAYA: cultural_events (+ user_id)
-- =============================================================================
CREATE TABLE IF NOT EXISTS cultural_events (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64),
    event_name VARCHAR(160) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    event_location VARCHAR(140) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    schedule_rule VARCHAR(120) NOT NULL,
    next_event_date DATE NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    significance TEXT NOT NULL DEFAULT '',
    cultural_etiquette TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_cultural_events_geog ON cultural_events USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_cultural_events_user ON cultural_events (user_id);

-- =============================================================================
-- (+) TABEL MASTER KONTAK DARURAT: emergency_contacts
-- =============================================================================
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id VARCHAR(64) PRIMARY KEY,
    corridor_code VARCHAR(64) REFERENCES hazard_alerts(corridor_code) ON UPDATE CASCADE ON DELETE SET NULL,
    agency_type VARCHAR(64) NOT NULL, -- BPBD, Basarnas, Kepolisian, PMI
    agency_name VARCHAR(120) NOT NULL,
    phone_number VARCHAR(40) NOT NULL,
    whatsapp_number VARCHAR(40),
    geog GEOGRAPHY(Point, 4326),
    city VARCHAR(80) NOT NULL,
    created_by_admin_id VARCHAR(64),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_corridor ON emergency_contacts (corridor_code);

-- =============================================================================
-- (+) TABEL LOG TELEMETRI SISTEM: api_telemetry_logs (<100ms SLA Audit)
-- =============================================================================
CREATE TABLE IF NOT EXISTS api_telemetry_logs (
    id VARCHAR(64) PRIMARY KEY,
    endpoint_path VARCHAR(255) NOT NULL,
    http_method VARCHAR(10) NOT NULL,
    latency_ms NUMERIC(8,2) NOT NULL,
    status_code INT NOT NULL,
    cache_hit BOOLEAN NOT NULL DEFAULT FALSE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_api_telemetry_recorded_at ON api_telemetry_logs (recorded_at DESC);

COMMIT;
