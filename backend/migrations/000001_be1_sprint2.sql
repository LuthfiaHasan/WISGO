-- ============================================================================
-- MIGRASI POSTGRESQL + POSTGIS KHUSUS BE-1 (SPRINT 2: MINGGU 2 / HARI 6-10)
-- Repo: github.com/LuthfiaHasan/WISGO (Branch: dev)
-- Lokasi File: backend/internal/be1_core/migrations_sprint2.sql
-- Prinsip: ZERO MERGE CONFLICT (Hanya menyentuh 5 tabel milik BE-1 di Minggu 2)
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

-- 5. Tabel Tur Virtual 360° Aerial-to-Ground: panorama_scenes (Pilar 1 - P1.1)
CREATE TABLE IF NOT EXISTS panorama_scenes (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_panorama_scenes_dest_id ON panorama_scenes (destination_id);

-- 6. Tabel Sistem 4 Pin Interaktif Terstandarisasi: panorama_hotspots (Pilar 1 - P1.2)
-- Tipe Pin: navigasi (Biru), audio (Emas), fasilitas (Hijau), mitra (Oranye)
CREATE TABLE IF NOT EXISTS panorama_hotspots (
    id VARCHAR(36) PRIMARY KEY,
    scene_id VARCHAR(36) NOT NULL REFERENCES panorama_scenes(id) ON DELETE CASCADE,
    pin_type VARCHAR(24) NOT NULL CHECK (pin_type IN ('navigasi', 'audio', 'fasilitas', 'mitra')),
    color_token VARCHAR(24) NOT NULL DEFAULT '#2563EB',
    pitch DOUBLE PRECISION NOT NULL CHECK (pitch >= -90.0 AND pitch <= 90.0),
    yaw DOUBLE PRECISION NOT NULL CHECK (yaw >= 0.0 AND yaw <= 360.0),
    title VARCHAR(180) NOT NULL,
    target_ref VARCHAR(64) NOT NULL DEFAULT '', -- ID Scene tujuan (dive-in) atau ID Mitra Nagari (Quick Booking)
    audio_url TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_panorama_hotspots_scene_id ON panorama_hotspots (scene_id);

-- 7. Tabel Pencarian Searah Rute ("Shunlu"): shunlu_pois (Pilar 2 - P2.1)
CREATE TABLE IF NOT EXISTS shunlu_pois (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(32) NOT NULL CHECK (category IN ('rm_padang', 'spbu', 'masjid_bersih', 'atm', 'bengkel')),
    corridor_road VARCHAR(120) NOT NULL,
    city_regency VARCHAR(80) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    detour_minutes INTEGER NOT NULL DEFAULT 3,
    detour_distance_meter INTEGER NOT NULL DEFAULT 250,
    highlight_note TEXT NOT NULL DEFAULT '',
    opening_hours VARCHAR(80) NOT NULL DEFAULT '06.00 - 22.00 WIB',
    is_recommended BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_shunlu_pois_geog ON shunlu_pois USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_shunlu_pois_category ON shunlu_pois (category);

-- 8. Tabel Peta Mikro Kawasan & Audio GPS <=15m: scenic_micro_maps (Pilar 2 - P2.2 & P2.3)
CREATE TABLE IF NOT EXISTS scenic_micro_maps (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    area_size_hectare NUMERIC(6,1) NOT NULL DEFAULT 12.5,
    walkway_geojson JSONB NOT NULL DEFAULT '{}'::jsonb,
    child_friendly_path BOOLEAN NOT NULL DEFAULT TRUE,
    elderly_friendly_path BOOLEAN NOT NULL DEFAULT TRUE,
    internal_pois JSONB NOT NULL DEFAULT '[]'::jsonb,
    audio_triggers JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Tabel Laporan Satgas Saber Pungli Anonim: pungli_reports (Pilar 3 & 8 - P3.4 & P8.1)
CREATE TABLE IF NOT EXISTS pungli_reports (
    id VARCHAR(36) PRIMARY KEY,
    ticket_code VARCHAR(32) NOT NULL UNIQUE,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    reporter_name VARCHAR(120) NOT NULL DEFAULT 'Wisatawan Anonim',
    incident_category VARCHAR(48) NOT NULL DEFAULT 'parkir_liar',
    charged_amount_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    official_perda_price_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    overcharge_amount_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    photo_evidence TEXT NOT NULL,
    upload_format VARCHAR(24) NOT NULL DEFAULT 'url',
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    incident_geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    description TEXT NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'Masuk' CHECK (status IN ('Masuk', 'Diverifikasi', 'Ditindaklanjuti', 'Selesai')),
    satgas_notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pungli_reports_geog ON pungli_reports USING GIST (incident_geog);
CREATE INDEX IF NOT EXISTS idx_pungli_reports_status ON pungli_reports (status);

COMMIT;
