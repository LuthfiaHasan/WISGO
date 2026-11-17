-- ============================================================================
-- WISGO SUMBAR (Ekosistem Wisata Pintar Sumatera Barat)
-- Skema Database PostgreSQL + PostGIS (Supabase Production Ready)
-- Target Host: aws-0-ap-southeast-1.pooler.supabase.com
-- ============================================================================

-- 1. Ekstensi Spasial & UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Tabel Destinasi Wisata Unggulan (20 Destinasi & Medan)
CREATE TABLE IF NOT EXISTS destinations (
    id VARCHAR(64) PRIMARY KEY,
    slug VARCHAR(128) UNIQUE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geom GEOMETRY(Point, 4326),
    cover_image TEXT,
    crowd_level VARCHAR(50) DEFAULT 'Sedang',
    estimated_distance_km INT DEFAULT 50,
    estimated_duration_min INT DEFAULT 60,
    ticket_price_summary VARCHAR(100) DEFAULT 'Rp 10.000',
    is_blank_spot BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger Otomatis Pembaruan Titik Geometri PostGIS
CREATE OR REPLACE FUNCTION update_destination_geom()
RETURNS TRIGGER AS $$
BEGIN
    NEW.geom = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_destination_geom ON destinations;
CREATE TRIGGER trg_update_destination_geom
BEFORE INSERT OR UPDATE ON destinations
FOR EACH ROW EXECUTE FUNCTION update_destination_geom();

-- Indeks Spasial PostGIS untuk Kueri Radius (ST_DWithin <= 200m)
CREATE INDEX IF NOT EXISTS idx_destinations_geom ON destinations USING GIST(geom);
CREATE INDEX IF NOT EXISTS idx_destinations_city ON destinations(city_regency);

-- 3. Tabel 5 Indikator Kesiapan Medan Lapangan
CREATE TABLE IF NOT EXISTS medan_indicators (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE CASCADE,
    vehicle_access VARCHAR(50) NOT NULL,
    trekking_level VARCHAR(50) NOT NULL,
    cellular_signal VARCHAR(50) NOT NULL,
    facilities VARCHAR(100) NOT NULL,
    guide_need VARCHAR(50) NOT NULL,
    vehicle_score INT DEFAULT 5,
    trekking_score INT DEFAULT 4,
    signal_score INT DEFAULT 4,
    facilities_score INT DEFAULT 4,
    guide_score INT DEFAULT 4,
    readiness_notes TEXT
);

-- 4. Tabel Tips Etika Adat & Kelestarian Alam
CREATE TABLE IF NOT EXISTS local_tips (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_important BOOLEAN DEFAULT false
);

-- 5. Tabel Standar Tarif Resmi Perda (Fair-Price Barometer)
CREATE TABLE IF NOT EXISTS official_tariffs (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE CASCADE,
    category VARCHAR(50) DEFAULT 'Tiket Masuk',
    item_name VARCHAR(255) NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    fair_price_min NUMERIC(12, 2),
    fair_price_max NUMERIC(12, 2),
    unit VARCHAR(50) NOT NULL,
    regulation_ref VARCHAR(255) NOT NULL
);

-- 6. Tabel Scene Panorama 360° (Aerial & Ground)
CREATE TABLE IF NOT EXISTS scenes_360 (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'ground',
    panorama_url TEXT NOT NULL,
    initial_pitch DOUBLE PRECISION DEFAULT 0.0,
    initial_yaw DOUBLE PRECISION DEFAULT 0.0,
    ambient_audio_url TEXT
);

-- 7. Tabel Hotspot Pin Fasilitas Fisik & Navigasi 360°
CREATE TABLE IF NOT EXISTS hotspot_pins (
    id VARCHAR(64) PRIMARY KEY,
    scene_id VARCHAR(64) REFERENCES scenes_360(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL, -- fasilitas_umum, mitra_umkm, loket_info, navigasi_arah
    title VARCHAR(255) NOT NULL,
    description TEXT,
    pitch DOUBLE PRECISION NOT NULL,
    yaw DOUBLE PRECISION NOT NULL,
    target_scene_id VARCHAR(64),
    audio_url TEXT,
    partner_name VARCHAR(255),
    partner_fee NUMERIC(12, 2),
    whatsapp_number VARCHAR(50),
    facility_subtype VARCHAR(100),
    operating_hours VARCHAR(100)
);

-- 8. Tabel Direktori 5 Kategori Mitra UMKM Nagari
CREATE TABLE IF NOT EXISTS partner_nagari (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    whatsapp VARCHAR(50) NOT NULL,
    spicy_level INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT true,
    standard_fee NUMERIC(12, 2) DEFAULT 0,
    nagari_name VARCHAR(100) NOT NULL,
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Tabel Laporan Saber Pungli & Karcis Liar
CREATE TABLE IF NOT EXISTS pungli_reports (
    id VARCHAR(64) PRIMARY KEY,
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE SET NULL,
    reporter_name VARCHAR(255) DEFAULT 'Anonim',
    reporter_phone VARCHAR(50),
    photo_evidence TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'Masuk', -- Masuk, Diverifikasi, Ditindaklanjuti, Selesai
    created_at TIMESTAMPTZ DEFAULT NOW(),
    bap_notes TEXT
);

-- 10. Tabel Tiket Darurat SOS GPS Tim SAR
CREATE TABLE IF NOT EXISTS sos_emergency_tickets (
    id VARCHAR(64) PRIMARY KEY,
    tourist_name VARCHAR(255) NOT NULL,
    tourist_phone VARCHAR(50) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    battery_level INT DEFAULT 100,
    signal_status VARCHAR(50) DEFAULT '4G Kuat',
    emergency_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'SIAGA_DARURAT', -- SIAGA_DARURAT, TIM_DIKERAHKAN, BERHASIL_DIEVAKUASI
    assigned_officer VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Tabel Pantau Live Hazard 5 Jalur Ekstrem
CREATE TABLE IF NOT EXISTS hazard_alerts (
    id VARCHAR(64) PRIMARY KEY,
    location VARCHAR(255) NOT NULL,
    severity VARCHAR(50) NOT NULL DEFAULT 'Aman', -- Aman, Waspada, Buka-Tutup, Tutup Total
    message TEXT NOT NULL,
    detour_route TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Tabel Gamifikasi "Challenge" Checklist Tempat Wisata (Non-Poin)
CREATE TABLE IF NOT EXISTS tourist_challenges (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    target_count INT NOT NULL DEFAULT 5,
    reward_description TEXT NOT NULL,
    duration_days INT DEFAULT 30,
    participant_count INT DEFAULT 0,
    completed_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. Tabel Verifikasi Klaim Hadiah Wisatawan
CREATE TABLE IF NOT EXISTS tourist_checklist_claims (
    id VARCHAR(64) PRIMARY KEY,
    challenge_id VARCHAR(64) REFERENCES tourist_challenges(id) ON DELETE CASCADE,
    challenge_title VARCHAR(255) NOT NULL,
    tourist_name VARCHAR(255) NOT NULL,
    tourist_phone VARCHAR(50) NOT NULL,
    target_count INT NOT NULL,
    completed_count INT NOT NULL DEFAULT 0,
    completed_destinations TEXT[],
    reward_description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'DALAM_PROGRES', -- DALAM_PROGRES, SIAP_KLAIM, HADIAH_TERKIRIM
    completed_at TIMESTAMPTZ,
    reward_sent_at TIMESTAMPTZ,
    reward_notes TEXT
);

-- 14. Tabel Usulan Destinasi Wisatawan (UGC - User Generated Content)
CREATE TABLE IF NOT EXISTS tourist_destination_submissions (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    submitter_name VARCHAR(255) NOT NULL,
    submitter_phone VARCHAR(50) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    photo_url TEXT,
    estimated_price VARCHAR(100) DEFAULT 'Rp 10.000',
    status VARCHAR(50) DEFAULT 'MENUNGGU', -- MENUNGGU, DISETUJUI, DITOLAK
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    admin_notes TEXT
);

-- 15. Tabel Moderasi Ulasan & Komentar Wisatawan
CREATE TABLE IF NOT EXISTS tourist_reviews (
    id VARCHAR(64) PRIMARY KEY,
    tourist_name VARCHAR(255) NOT NULL,
    destination_id VARCHAR(64) REFERENCES destinations(id) ON DELETE CASCADE,
    destination_name VARCHAR(255) NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_hidden BOOLEAN DEFAULT false,
    admin_moderation_reason TEXT
);

-- Seed Contoh Data Jalur Ekstrem
INSERT INTO hazard_alerts (id, location, severity, message, detour_route, updated_at) VALUES
('hz-01', 'Sitinjau Lauik (Padang - Solok)', 'Waspada', 'Hujan lebat di lereng bukit, truk berat mogok di tanjakan tikungan 1.', 'Gunakan jalur alternatif Padang Panjang - Malalak', NOW()),
('hz-02', 'Lembah Anai (Padang Panjang)', 'Aman', 'Aliran debit air terjun terpantau normal dan arus lalu lintas lancar.', 'Jalur utama beroperasi 2 arah', NOW()),
('hz-03', 'Kelok 9 (Payakumbuh - Riau)', 'Aman', 'Flyover kering dan cuaca cerah berkabut tipis.', 'Patuhi rambu larangan berhenti di atas jembatan layang', NOW()),
('hz-04', 'Jalur Malalak (Bukittinggi - Pariaman)', 'Buka-Tutup', 'Pembersihan material longsoran tebing tanah oleh alat berat BPBD.', 'Disarankan via Lembah Anai / Padang Panjang', NOW()),
('hz-05', 'Kelok 44 (Danau Maninjau)', 'Aman', 'Kondisi aspal baik dan tikungan tajam berpenanda cermin cembung lengkap.', 'Kendaraan roda 6 ke atas wajib prioritaskan kendaraan menanjak', NOW())
ON CONFLICT (id) DO NOTHING;
