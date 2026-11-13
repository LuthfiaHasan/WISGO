-- ============================================================================
-- MIGRASI & SEEDER POSTGRESQL + POSTGIS KHUSUS BE-1 (SPRINT 1)
-- Repo: github.com/LuthfiaHasan/WISGO (Branch: dev)
-- Lokasi File: backend/internal/be1_core/migrations_sprint1.sql
-- Catatan: Sinkron 100% dengan backend/internal/models/models.go
--          TIDAK menyentuh tabel milik BE-2 (users, group_rooms, partners, dll)
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Tabel Induk: destinations (Sesuai struct models.Destination)
CREATE TABLE IF NOT EXISTS destinations (
    id VARCHAR(36) PRIMARY KEY,
    slug VARCHAR(120) UNIQUE,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(64) NOT NULL,
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
    qr_placard_code VARCHAR(64) UNIQUE,
    opening_hours VARCHAR(100) NOT NULL DEFAULT '08.00 - 17.30 WIB',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_destinations_geog ON destinations USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_destinations_city_regency ON destinations (city_regency);
CREATE INDEX IF NOT EXISTS idx_destinations_category ON destinations (category);

-- 2. Tabel 5 Indikator Medan: medan_indicators (Sesuai struct models.MedanIndicator)
CREATE TABLE IF NOT EXISTS medan_indicators (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    vehicle_access VARCHAR(160) NOT NULL,  -- Mobil OK, Hanya Motor, Jalan Kaki
    trekking_level VARCHAR(160) NOT NULL,  -- Datar / Mudah, Sedang, Curam / Ekstrem
    cellular_signal VARCHAR(160) NOT NULL, -- 4G Kuat, Sinyal Lemah, Blank Spot
    facilities VARCHAR(200) NOT NULL,      -- Toilet & Musala Lengkap, Terbatas, Belum Ada
    guide_need VARCHAR(160) NOT NULL,      -- Wajib Pemandu, Disarankan, Mandiri
    pokdarwis_name VARCHAR(160) NOT NULL DEFAULT ''
);

-- 3. Tabel Tips Menjaga Tempat: local_tips (Sesuai struct models.LocalTip)
CREATE TABLE IF NOT EXISTS local_tips (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    title VARCHAR(160) NOT NULL DEFAULT 'Tips Menjaga Tempat Ini',
    category VARCHAR(48) NOT NULL DEFAULT 'kelestarian_alam',
    content TEXT NOT NULL,
    is_important BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_local_tips_dest_id ON local_tips (destination_id);

-- 4. Tabel Fair-Price Barometer: official_tariffs (Sesuai struct models.OfficialTariff)
CREATE TABLE IF NOT EXISTS official_tariffs (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    item_name VARCHAR(160) NOT NULL,      -- Tiket Masuk, Parkir Motor, Parkir Mobil, Sewa Bendi
    category VARCHAR(48) NOT NULL DEFAULT 'tiket',
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    unit VARCHAR(48) NOT NULL,            -- per orang, per kendaraan, per jam
    regulation_ref VARCHAR(160) NOT NULL  -- No Perda / Peraturan Nagari
);

CREATE INDEX IF NOT EXISTS idx_official_tariffs_dest_id ON official_tariffs (destination_id);

COMMIT;
