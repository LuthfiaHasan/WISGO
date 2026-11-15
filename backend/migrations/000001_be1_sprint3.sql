-- =============================================================================
-- WISGO (Rancak.in) — MIGRASI DATABASE SPRINT 3 (MINGGU 3: HARI 11–15)
-- Author       : Backend 1 (BE-1: Core & Spasial)
-- Cakupan      : Menyelesaikan Kuota 11/11 Tabel Milik BE-1
--                Tabel #10: hazard_alerts & sos_signals (Pilar 7 — P7.2)
--                Tabel #11: gaode_behavior_rankings, minang_phrases, & cultural_events (Pilar 1 & 2)
-- Jaminan      : Zero Merge Conflict — Tidak menyentuh tabel transaksi/grup milik BE-2
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. TABEL #10A (KUOTA BE-1): gaode_behavior_rankings (Pilar 2 — P2.4)
-- Menyimpan metrik telemetri perilaku nyata (navigasi selesai + dwell time GPS) anti-bintang palsu
CREATE TABLE IF NOT EXISTS gaode_behavior_rankings (
    id                          VARCHAR(64) PRIMARY KEY,
    destination_id              VARCHAR(64) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    category                    VARCHAR(64) NOT NULL, -- Hidden Gem, Kuliner Legendaris, Alam & Geopark, Budaya & Nagari
    rank_position               INT NOT NULL DEFAULT 1,
    gaode_authenticity_score    NUMERIC(5, 2) NOT NULL DEFAULT 85.00,
    active_nav_count_30d        INT NOT NULL DEFAULT 0,
    avg_dwell_time_min          INT NOT NULL DEFAULT 45,
    return_visit_rate_pct       NUMERIC(5, 2) NOT NULL DEFAULT 15.00,
    anti_fake_review_verified   BOOLEAN NOT NULL DEFAULT TRUE,
    trending_badge              VARCHAR(120) NOT NULL DEFAULT 'Terverifikasi Telemetri GPS',
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gaode_rankings_score ON gaode_behavior_rankings (gaode_authenticity_score DESC);
CREATE INDEX IF NOT EXISTS idx_gaode_rankings_category ON gaode_behavior_rankings (category);

-- 2. TABEL #10B (KUOTA BE-1): hazard_alerts & sos_signals (Pilar 7 — P7.2)
-- Koridor jalur ekstrem Sumatera Barat (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44) & Sinyal SOS GPS
CREATE TABLE IF NOT EXISTS hazard_alerts (
    id                      VARCHAR(64) PRIMARY KEY,
    corridor_code           VARCHAR(64) NOT NULL UNIQUE, -- SITINJAU-LAUIK, LEMBAH-ANAI, KELOK-9, KELOK-44
    location                VARCHAR(160) NOT NULL,
    road_segment            VARCHAR(180) NOT NULL,
    city_regency            VARCHAR(100) NOT NULL,
    latitude                DOUBLE PRECISION NOT NULL,
    longitude               DOUBLE PRECISION NOT NULL,
    geog                    GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
    radius_meter            INT NOT NULL DEFAULT 2500,
    severity                VARCHAR(32) NOT NULL DEFAULT 'Normal', -- Normal, Waspada, Siaga, Awas Tutup Total
    hazard_type             VARCHAR(80) NOT NULL,
    weather_status          VARCHAR(80) NOT NULL,
    slope_gradient_deg      INT NOT NULL DEFAULT 18,
    message                 TEXT NOT NULL,
    detour_route            TEXT NOT NULL,
    detour_route_geojson    JSONB NOT NULL DEFAULT '{}'::jsonb,
    nearest_rescue_post     VARCHAR(160) NOT NULL,
    emergency_contact       VARCHAR(64) NOT NULL,
    triggered_by_admin      VARCHAR(100),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hazard_alerts_geog_gist ON hazard_alerts USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_hazard_alerts_severity ON hazard_alerts (severity);

CREATE TABLE IF NOT EXISTS sos_signals (
    id                      VARCHAR(64) PRIMARY KEY,
    sos_code                VARCHAR(40) NOT NULL UNIQUE,
    tourist_name            VARCHAR(120) NOT NULL,
    phone_number            VARCHAR(40) NOT NULL,
    emergency_type          VARCHAR(80) NOT NULL,
    latitude                DOUBLE PRECISION NOT NULL,
    longitude               DOUBLE PRECISION NOT NULL,
    geog                    GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
    battery_percent         INT NOT NULL DEFAULT 50,
    passengers_count        INT NOT NULL DEFAULT 1,
    nearest_corridor        VARCHAR(120) NOT NULL,
    nearest_rescue_post     VARCHAR(160) NOT NULL,
    distance_to_rescue_km   NUMERIC(6, 2) NOT NULL DEFAULT 2.5,
    eta_rescue_minutes      INT NOT NULL DEFAULT 12,
    status                  VARCHAR(40) NOT NULL DEFAULT 'Dipancarkan',
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sos_signals_geog_gist ON sos_signals USING GIST (geog);

-- 3. TABEL #11 (KUOTA BE-1): minang_phrases & cultural_events (Pilar 1 — P1.4)
-- Kamus Saku Audio Bahasa Minang & Kalender Budaya / Hari Pakan Pasar Tradisional Nagari
CREATE TABLE IF NOT EXISTS minang_phrases (
    id                  VARCHAR(64) PRIMARY KEY,
    category            VARCHAR(48) NOT NULL, -- sapaan_adat, tawar_pasar, kuliner_rm, navigasi_darurat
    indonesian_text     TEXT NOT NULL,
    minang_text         TEXT NOT NULL,
    phonetic_guide      TEXT NOT NULL,
    audio_url           TEXT NOT NULL,
    dialect_note        VARCHAR(120) NOT NULL,
    usage_context_tip   TEXT NOT NULL,
    politeness_level    VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS cultural_events (
    id                  VARCHAR(64) PRIMARY KEY,
    title               VARCHAR(160) NOT NULL,
    event_type          VARCHAR(64) NOT NULL, -- Hari Pakan Nagari, Festival Budaya, Tradisi Adat
    nagari_location     VARCHAR(140) NOT NULL,
    city_regency        VARCHAR(100) NOT NULL,
    schedule_rule       VARCHAR(120) NOT NULL,
    next_event_date     VARCHAR(40) NOT NULL,
    latitude            DOUBLE PRECISION NOT NULL,
    longitude           DOUBLE PRECISION NOT NULL,
    geog                GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
    highlight_item      TEXT NOT NULL,
    cultural_etiquette  TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cultural_events_geog_gist ON cultural_events USING GIST (geog);
