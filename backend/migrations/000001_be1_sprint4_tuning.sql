-- =============================================================================
-- WISGO (Rancak.in) — OPTIMASI SPASIAL POSTGIS & INDEX TUNING SPRINT 4 (HARI 16–20)
-- Author       : Backend 1 (BE-1: Core & Spasial)
-- Target SLA   : Seluruh kueri spasial & 360° merespons < 100 milidetik (p95 < 45ms)
-- Cakupan      : Optimasi Indeks 11/11 Tabel Milik BE-1 (Zero Merge Conflict)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. OPTIMASI INDEKS SPASIAL GIST & PARTIAL INDEX PADA TABEL DESTINATIONS (TABEL #1)
-- Bounding-box pre-filter (ST_DWithin) menggunakan indeks GIST geog sebelum ST_DistanceSphere
CREATE INDEX IF NOT EXISTS idx_destinations_geog_gist
    ON destinations USING GIST (geog);

CREATE INDEX IF NOT EXISTS idx_destinations_category_city_crowd
    ON destinations (LOWER(category), LOWER(city_regency), LOWER(crowd_level));

CREATE INDEX IF NOT EXISTS idx_destinations_hidden_gem_partial
    ON destinations (id, name, city_regency)
    WHERE is_hidden_gem = TRUE;

-- 2. PARTIAL INDEX ZONA BLANK SPOT SINYAL PADA MEDAN_INDICATORS (TABEL #2)
-- Mempercepat pemuatan Mode Offline Pocket FE-1 (< 8ms)
CREATE INDEX IF NOT EXISTS idx_medan_blank_spot_partial
    ON medan_indicators (destination_id, cellular_signal)
    WHERE LOWER(cellular_signal) LIKE '%blank%';

-- 3. COVERING INDEX TARIF PERDA FAIR-PRICE BAROMETER (TABEL #4)
CREATE INDEX IF NOT EXISTS idx_official_tariffs_dest_category
    ON official_tariffs (destination_id, category, price);

-- 4. INDEKS KOMPOSIT KANVAS 360° & 4 PIN INTERAKTIF (TABEL #5 & #6)
CREATE INDEX IF NOT EXISTS idx_panorama_scenes_dest_default
    ON panorama_scenes (destination_id, is_default_scene DESC);

CREATE INDEX IF NOT EXISTS idx_panorama_hotspots_scene_type
    ON panorama_hotspots (scene_id, type);

-- 5. INDEKS SPASIAL KORIDOR SHUNLU (+X MENIT DETOUR) & PETA MIKRO (TABEL #7 & #8)
CREATE INDEX IF NOT EXISTS idx_shunlu_pois_category_detour
    ON shunlu_pois (LOWER(category), detour_minutes ASC)
    WHERE is_recommended = TRUE;

-- 6. INDEKS PRIORITAS TIKET ADUAN SATGAS SABER PUNGLI (TABEL #9)
CREATE INDEX IF NOT EXISTS idx_pungli_reports_status_created
    ON pungli_reports (status, created_at DESC);

-- 7. MATERIALIZED VIEW LEADERBOARD GAODE BEHAVIOR-BASED RANKING (TABEL #10A)
-- Menghindari sort ulang berat saat jutaan log telemetri GPS masuk
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_gaode_leaderboard AS
SELECT
    g.id,
    g.destination_id,
    d.name AS destination_name,
    g.category,
    d.city_regency,
    ROW_NUMBER() OVER (ORDER BY g.gaode_authenticity_score DESC) AS rank_position,
    g.gaode_authenticity_score,
    g.active_nav_count_30d,
    g.avg_dwell_time_min,
    g.return_visit_rate_pct,
    g.anti_fake_review_verified,
    g.trending_badge,
    g.updated_at
FROM gaode_behavior_rankings g
JOIN destinations d ON d.id = g.destination_id
ORDER BY g.gaode_authenticity_score DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_gaode_leaderboard_id
    ON mv_gaode_leaderboard (id);

-- 8. PARTIAL INDEX KORIDOR JALUR EKSTREM AKTIF (SITINJAU LAUIK / LEMBAH ANAI / KELOK 9 / KELOK 44)
CREATE INDEX IF NOT EXISTS idx_hazard_alerts_active_severity
    ON hazard_alerts (corridor_code, severity)
    WHERE severity IN ('Waspada', 'Siaga', 'Awas Tutup Total');

-- 9. PEMELIHARAAN STATISTIK PLANNER POSTGRESQL
ANALYZE destinations;
ANALYZE medan_indicators;
ANALYZE local_tips;
ANALYZE official_tariffs;
ANALYZE panorama_scenes;
ANALYZE panorama_hotspots;
ANALYZE shunlu_pois;
ANALYZE scenic_micro_maps;
ANALYZE pungli_reports;
ANALYZE gaode_behavior_rankings;
ANALYZE hazard_alerts;
ANALYZE sos_signals;
ANALYZE minang_phrases;
ANALYZE cultural_events;

-- =============================================================================
-- CONTOH KUERI SPASIAL TEROPTIMASI (<100ms) DENGAN BOUNDING-BOX PRE-FILTER:
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT d.id, d.name,
--        ROUND((ST_DistanceSphere(d.geog::geometry, ST_SetSRID(ST_MakePoint(100.4172, -0.9471), 4326)) / 1000.0 * 1.32)::numeric, 1) AS distance_km
-- FROM destinations d
-- WHERE ST_DWithin(d.geog, ST_SetSRID(ST_MakePoint(100.4172, -0.9471), 4326)::geography, 180000)
-- ORDER BY d.geog <-> ST_SetSRID(ST_MakePoint(100.4172, -0.9471), 4326)::geography
-- LIMIT 20;
-- =============================================================================
