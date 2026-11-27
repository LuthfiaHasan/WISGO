-- ============================================================================
-- MIGRATION: 000003_v2_new_schema.sql
-- EKOSISTEM WISATA PINTAR SUMATERA BARAT (RANCAK.IN / WISGO)
-- STRATEGI: SAFE EVOLUTIONARY MIGRATION (EXPAND PHASE)
-- DESKRIPSI: Menerapkan 26 Tabel DBML Baru + Perbaikan Audit tanpa merusak
--            kompatibilitas kode yang sedang berjalan di backend/frontend.
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

-- ----------------------------------------------------------------------------
-- 1. TABEL MASTER: categories (Normalisasi Taksonomi Terpusat)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    slug VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    module_type VARCHAR(50) NOT NULL, -- 'destination', 'tariff', 'rule', 'poi', 'phrase'
    description TEXT,
    icon_url TEXT,
    color_hex VARCHAR(10),
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_categories_slug UNIQUE (module_type, slug),
    CONSTRAINT uq_categories_name UNIQUE (module_type, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_lookup ON categories (module_type, is_active, sort_order);

-- SEEDER MASTER DATA CATEGORIES AWAL
INSERT INTO categories (id, slug, name, module_type, description, color_hex, sort_order) VALUES
    ('cat_dst_alam', 'alam-geopark', 'Alam & Geopark', 'destination', 'Wisata pegunungan, lembah, dan bentang alam karst', '#2E7D32', 1),
    ('cat_dst_budaya', 'budaya-nagari', 'Budaya & Nagari', 'destination', 'Desa wisata adat, rumah gadang, dan tradisi Minang', '#C62828', 2),
    ('cat_dst_kuliner', 'kuliner-legendaris', 'Kuliner Legendaris', 'destination', 'Rumah makan otentik, rendang, dan kuliner khas nagari', '#EF6C00', 3),
    ('cat_dst_bahari', 'bahari-pulau', 'Bahari & Pulau', 'destination', 'Wisata pantai pesisir barat dan kepulauan mandeh', '#0277BD', 4),
    ('cat_dst_sejarah', 'sejarah-heritage', 'Sejarah & Heritage', 'destination', 'Museum, benteng, dan peninggalan bersejarah Minangkabau', '#4E342E', 5),
    ('cat_dst_geowisata', 'geowisata-gua', 'Geowisata Gua', 'destination', 'Gua alam, ngalau, dan formasi batuan purba', '#00695C', 6),

    ('cat_trf_tiket', 'tiket-masuk', 'Tiket Masuk', 'tariff', 'Retribusi resmi tiket masuk kawasan wisata Perda', '#1565C0', 1),
    ('cat_trf_parkir', 'parkir-kendaraan', 'Parkir Kendaraan', 'tariff', 'Tarif resmi parkir motor, mobil, dan bus Perda', '#37474F', 2),
    ('cat_trf_sewa', 'sewa-perahu-bendi', 'Sewa Perahu & Bendi', 'tariff', 'Sewa transportasi lokal khas nagari', '#F57F17', 3),
    ('cat_trf_pemandu', 'jasa-pemandu', 'Jasa Pemandu Pokdarwis', 'tariff', 'Tarif resmi jasa pemandu lokal tersertifikasi', '#6A1B9A', 4),

    ('cat_rul_alam', 'kelestarian-alam', 'Kelestarian Alam', 'rule', 'Larangan buang sampah, perusakan flora/fauna, dan etika camping', '#2E7D32', 1),
    ('cat_rul_adat', 'etika-adat', 'Etika Adat & Kesopanan', 'rule', 'Pakaian sopan, norma kesantunan Minang, dan adab nagari', '#AD1457', 2),
    ('cat_rul_medan', 'keselamatan-medan', 'Keselamatan Medan', 'rule', 'Jalur licin, batas tebing curam, dan larangan berenang tanpa pelampung', '#D84315', 3),

    ('cat_poi_rm', 'rm-padang', 'Rumah Makan Padang', 'poi', 'Titik singgah kuliner halal sepanjang jalur koridor jalan', '#E65100', 1),
    ('cat_poi_spbu', 'spbu-rest-area', 'SPBU & Rest Area', 'poi', 'Pengisian bahan bakar dan area istirahat sopir', '#C62828', 2),
    ('cat_poi_masjid', 'masjid-bersih', 'Masjid & Musala Bersih', 'poi', 'Fasilitas ibadah dengan toilet bersih di jalur lintas', '#2E7D32', 3),
    ('cat_poi_atm', 'atm-perbankan', 'ATM & Bank', 'poi', 'Anjungan tunai mandiri di jalur lintas wisata', '#1565C0', 4),
    ('cat_poi_bengkel', 'bengkel-tambal-ban', 'Bengkel & Tambal Ban', 'poi', 'Bantuan darurat kendaraan di tanjakan ekstrem', '#424242', 5),

    ('cat_phr_sapaan', 'sapaan-adat', 'Sapaan Adat', 'phrase', 'Frasa salam, tegur sapa, dan rasa hormat Minang', '#00838F', 1),
    ('cat_phr_pasar', 'tawar-pasar', 'Tawar Menawar Pasar', 'phrase', 'Percakapan bertransaksi di pasar tradisional hari pakan', '#F9A825', 2),
    ('cat_phr_kuliner', 'pesan-kuliner', 'Pesan Kuliner RM', 'phrase', 'Istilah memesan makanan khas Minangkabau di kedai nasi', '#D84315', 3),
    ('cat_phr_darurat', 'navigasi-darurat', 'Navigasi & Darurat', 'phrase', 'Frasa minta tolong, arah jalan, dan situasi darurat', '#C2185B', 4)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. PENYELARASAN TABEL USERS (Tambah jenis_input)
-- ----------------------------------------------------------------------------
ALTER TABLE users ADD COLUMN IF NOT EXISTS jenis_input VARCHAR(50) DEFAULT 'wa_otp';

-- ----------------------------------------------------------------------------
-- 3. PENYELARASAN TABEL DESTINATIONS (Tambah category_id)
-- ----------------------------------------------------------------------------
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS category_id VARCHAR(64) REFERENCES categories(id) ON DELETE RESTRICT;

-- Hubungkan 20 destinasi yang ada ke category_id yang sesuai
UPDATE destinations SET category_id = 'cat_dst_alam' WHERE category_id IS NULL AND (category ILIKE '%alam%' OR category ILIKE '%geopark%');
UPDATE destinations SET category_id = 'cat_dst_budaya' WHERE category_id IS NULL AND (category ILIKE '%budaya%' OR category ILIKE '%nagari%');
UPDATE destinations SET category_id = 'cat_dst_kuliner' WHERE category_id IS NULL AND category ILIKE '%kuliner%';
UPDATE destinations SET category_id = 'cat_dst_bahari' WHERE category_id IS NULL AND (category ILIKE '%bahari%' OR category ILIKE '%pantai%' OR category ILIKE '%pulau%');
UPDATE destinations SET category_id = 'cat_dst_sejarah' WHERE category_id IS NULL AND (category ILIKE '%sejarah%' OR category ILIKE '%heritage%');
-- Fallback jika masih ada yang kosong
UPDATE destinations SET category_id = 'cat_dst_alam' WHERE category_id IS NULL;

-- ----------------------------------------------------------------------------
-- 4. TABEL: indikator_medan (5 Indikator Medan Lapangan)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS indikator_medan (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    vehicle_access VARCHAR(160) NOT NULL,
    trekking_level VARCHAR(160) NOT NULL,
    cellular_signal VARCHAR(160) NOT NULL,
    facilities VARCHAR(200) NOT NULL,
    guide_need VARCHAR(160) NOT NULL
);

-- Sinkronisasi dari medan_indicators lama jika ada
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'medan_indicators') THEN
        EXECUTE 'INSERT INTO indikator_medan (id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need)
                 SELECT id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need 
                 FROM medan_indicators
                 ON CONFLICT (destination_id) DO NOTHING;';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 5. TABEL: aturan_destinasi (Etika & Peraturan Kelestarian)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS aturan_destinasi (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    title VARCHAR(180) NOT NULL,
    content TEXT NOT NULL
);

-- Sinkronisasi dari local_tips lama jika ada
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'local_tips') THEN
        EXECUTE 'INSERT INTO aturan_destinasi (id, destination_id, category_id, title, content)
                 SELECT id, destination_id, ''cat_rul_alam'', title, content 
                 FROM local_tips
                 ON CONFLICT (id) DO NOTHING;';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 6. PENYELARASAN TABEL: official_tariffs (Tambah category_id & Constraint)
-- ----------------------------------------------------------------------------
ALTER TABLE official_tariffs ADD COLUMN IF NOT EXISTS category_id VARCHAR(64) REFERENCES categories(id) ON DELETE RESTRICT;

UPDATE official_tariffs SET category_id = 'cat_trf_tiket' WHERE category_id IS NULL AND (item_name ILIKE '%tiket%' OR item_name ILIKE '%masuk%');
UPDATE official_tariffs SET category_id = 'cat_trf_parkir' WHERE category_id IS NULL AND item_name ILIKE '%parkir%';
UPDATE official_tariffs SET category_id = 'cat_trf_sewa' WHERE category_id IS NULL AND (item_name ILIKE '%sewa%' OR item_name ILIKE '%bendi%' OR item_name ILIKE '%perahu%');
UPDATE official_tariffs SET category_id = 'cat_trf_tiket' WHERE category_id IS NULL;

-- ----------------------------------------------------------------------------
-- 7. TABEL: offline_bundles (Paket Data Blank Spot)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS offline_bundles (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    bundle_version VARCHAR(32) NOT NULL DEFAULT 'v1.0.0',
    file_size_kb INT NOT NULL DEFAULT 0,
    map_tiles_url TEXT NOT NULL DEFAULT '',
    compressed_payload JSONB NOT NULL DEFAULT '{}',
    checksum_sha256 VARCHAR(64),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 8. TABEL: visit_point (Titik Singgah Sepanjang Jalur / Shunlu POI)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS visit_point (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(180) NOT NULL,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    corridor_road VARCHAR(150) NOT NULL,
    city_regency VARCHAR(80) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    detour_minutes INT NOT NULL DEFAULT 0,
    detour_distance_meter INT NOT NULL DEFAULT 0,
    highlight_note TEXT NOT NULL,
    opening_hours VARCHAR(100) NOT NULL DEFAULT '24 Jam',
    is_recommended BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_visit_point_geog ON visit_point USING GIST (geog);

-- Sinkronisasi dari shunlu_pois lama jika ada
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'shunlu_pois') THEN
        EXECUTE 'INSERT INTO visit_point (id, name, category_id, corridor_road, city_regency, latitude, longitude, detour_minutes, detour_distance_meter, highlight_note, opening_hours, is_recommended)
                 SELECT id, name, ''cat_poi_rm'', corridor_road, city_regency, latitude, longitude, detour_minutes, detour_distance_meter, highlight_note, opening_hours, is_recommended 
                 FROM shunlu_pois
                 ON CONFLICT (id) DO NOTHING;';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 9. TABEL: emergency_contacts (Nomor Instansi Darurat Spasial)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id VARCHAR(64) PRIMARY KEY,
    agency_name VARCHAR(150) NOT NULL,
    agency_type VARCHAR(50) NOT NULL, -- 'SAR', 'POLISI', 'BPBD', 'RUMAH_SAKIT', 'DEREK'
    phone_number VARCHAR(30) NOT NULL,
    whatsapp_number VARCHAR(30),
    city_regency VARCHAR(80) NOT NULL,
    geog GEOGRAPHY(Point, 4326),
    created_by_admin_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_geog ON emergency_contacts USING GIST (geog);

-- ----------------------------------------------------------------------------
-- 10. TABEL: stemp_visit (Stempel Kunjungan Paspor Digital Minang)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stemp_visit (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_gps_valid BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_stemp_visit UNIQUE (user_id, destination_id)
);

CREATE INDEX IF NOT EXISTS idx_stemp_visit_user ON stemp_visit (user_id);

-- Sinkronisasi dari digital_passports lama jika ada
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'digital_passports') THEN
        EXECUTE 'INSERT INTO stemp_visit (id, user_id, destination_id, checked_in_at, is_gps_valid)
                 SELECT id, user_id, destination_id, checked_in_at, is_gps_valid 
                 FROM digital_passports
                 ON CONFLICT (user_id, destination_id) DO NOTHING;';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 11. TABEL: destination_reviews (Ulasan Berbasis Kunjungan Nyata & GPS)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS destination_reviews (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stemp_visit_id VARCHAR(64) UNIQUE REFERENCES stemp_visit(id) ON DELETE SET NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_comment TEXT NOT NULL,
    photo_url TEXT,
    is_gps_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_review_gps_integrity CHECK (
        (stemp_visit_id IS NOT NULL AND is_gps_verified = TRUE) OR 
        (stemp_visit_id IS NULL AND is_gps_verified = FALSE)
    )
);

CREATE INDEX IF NOT EXISTS idx_destination_reviews_dest ON destination_reviews (destination_id, rating);

-- ----------------------------------------------------------------------------
-- 12. TABEL: new_tour (Tempat Baru Usulan Komunitas dengan Radius Masking)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS new_tour (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    city_regency VARCHAR(80) NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    tips_menjaga TEXT NOT NULL,
    is_sensitive BOOLEAN DEFAULT FALSE,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_CURATION' CHECK (status IN ('PENDING_CURATION', 'APPROVED', 'REJECTED')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_new_tour_status ON new_tour (status);

-- Sinkronisasi dari community_places lama jika ada
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'community_places') THEN
        EXECUTE 'INSERT INTO new_tour (id, user_id, name, category_id, city_regency, description, latitude, longitude, tips_menjaga, is_sensitive, status, created_at)
                 SELECT id, user_id, name, ''cat_dst_alam'', city_regency, description, latitude, longitude, tips_menjaga, is_sensitive, status, created_at 
                 FROM community_places
                 ON CONFLICT (id) DO NOTHING;';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 13. TABEL: challenges & challenge_destinations (Gamifikasi Misi Wisata)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS challenges (
    id VARCHAR(64) PRIMARY KEY,
    created_by_admin_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    title VARCHAR(180) NOT NULL,
    description TEXT NOT NULL,
    target_destination_count INT NOT NULL CHECK (target_destination_count > 0),
    reward_title VARCHAR(150) NOT NULL,
    reward_type VARCHAR(50) NOT NULL, -- 'Sertifikat Gubernur', 'Voucher UMKM', 'Badge Paspor'
    reward_points INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Junction Target Destinasi Spesifik Misi
CREATE TABLE IF NOT EXISTS challenge_destinations (
    challenge_id VARCHAR(64) NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    destination_id VARCHAR(64) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    PRIMARY KEY (challenge_id, destination_id)
);

-- ----------------------------------------------------------------------------
-- 14. TABEL: user_challenge_rewards (Progres & Sertifikat Wisatawan)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_challenge_rewards (
    id VARCHAR(64) PRIMARY KEY,
    challenge_id VARCHAR(64) NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    progress_count INT NOT NULL DEFAULT 0 CHECK (progress_count >= 0),
    status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'CLAIMED')),
    jenis_reward VARCHAR(50) NOT NULL,
    reward VARCHAR(150) NOT NULL,
    certificate_code VARCHAR(64) UNIQUE,
    certificate_url TEXT,
    completed_at TIMESTAMPTZ,
    CONSTRAINT uq_user_challenge UNIQUE (challenge_id, user_id)
);

-- ----------------------------------------------------------------------------
-- 15. TABEL: open_trips (Papan Tebengan & Cari Barengan Rombongan)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS open_trips (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    destination_route VARCHAR(200) NOT NULL,
    departure_date TIMESTAMPTZ NOT NULL,
    available_seats INT NOT NULL DEFAULT 1 CHECK (available_seats >= 0),
    cost_per_person NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (cost_per_person >= 0),
    contact_wa VARCHAR(25) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_open_trips_date ON open_trips (departure_date);

-- Sinkronisasi dari shared_trips lama jika ada
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'shared_trips') THEN
        EXECUTE 'INSERT INTO open_trips (id, user_id, title, destination_route, departure_date, available_seats, cost_per_person, contact_wa, created_at)
                 SELECT id, user_id, title, destination_route, departure_date, available_seats, cost_per_person, contact_wa, created_at 
                 FROM shared_trips
                 ON CONFLICT (id) DO NOTHING;';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 16. TABEL: notifikasi (Notifikasi In-App Pengguna)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifikasi (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- 'HAZARD_ALERT', 'PUNGLI_STATUS', 'BOOKING_UPDATE', 'CHALLENGE_REWARD'
    title VARCHAR(180) NOT NULL,
    message TEXT NOT NULL,
    reference_id VARCHAR(64),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifikasi_user_unread ON notifikasi (user_id, is_read, created_at DESC);

-- ----------------------------------------------------------------------------
-- 17. TABEL: api_telemetry_logs (Observabilitas SLA & Cache Hit)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS api_telemetry_logs (
    id VARCHAR(64) PRIMARY KEY,
    endpoint_path VARCHAR(200) NOT NULL,
    http_method VARCHAR(10) NOT NULL,
    status_code INT NOT NULL,
    latency_ms NUMERIC(8,2) NOT NULL,
    cache_hit BOOLEAN NOT NULL DEFAULT FALSE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_telemetry_recorded_at ON api_telemetry_logs (recorded_at DESC);

-- ----------------------------------------------------------------------------
-- 18. PENYELARASAN TABEL LAIN: gaode_behavior_rankings, cultural_events, saved_places
-- ----------------------------------------------------------------------------
ALTER TABLE gaode_behavior_rankings ADD COLUMN IF NOT EXISTS category_id VARCHAR(64) REFERENCES categories(id) ON DELETE RESTRICT;

-- Perbaikan tipe data cultural_events.next_event_date jika masih text
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cultural_events' 
        AND column_name = 'next_event_date' 
        AND data_type = 'character varying'
    ) THEN
        ALTER TABLE cultural_events ALTER COLUMN next_event_date TYPE DATE USING (next_event_date::date);
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- Abaikan jika ada data teks yang tidak bisa di-cast otomatis
    NULL;
END $$;

-- Pastikan unique constraint pada saved_places
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_user_destination'
    ) THEN
        ALTER TABLE saved_places ADD CONSTRAINT uq_user_destination UNIQUE (user_id, destination_id);
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

COMMIT;
