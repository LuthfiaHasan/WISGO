-- =============================================================================
-- MIGRATION: 000002_be2_schema.sql
-- DOMAIN: BE-2 (Grup Rombongan, Itinerary, Mitra Nagari, Escrow, Komunitas & Gamifikasi)
-- EKOSISTEM WISATA PINTAR SUMATERA BARAT (RANCAK.IN)
-- =============================================================================

-- 1. TABEL USERS (Profil Wisatawan & Pengguna)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(30) NOT NULL DEFAULT 'tourist', -- 'tourist', 'partner', 'admin_dispar', 'satgas_pungli'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);

-- 2. TABEL PARTNERS (5 Kategori Mitra Nagari Minangkabau)
CREATE TABLE IF NOT EXISTS partners (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Homestay Rumah Gadang', 'Kuliner Halal', 'Transport & Perahu', 'Pemandu Pokdarwis', 'Sewa Baju Adat'
    whatsapp VARCHAR(20) NOT NULL,
    spicy_level INT DEFAULT 0, -- 0-5 khusus kuliner
    is_verified BOOLEAN DEFAULT TRUE,
    standard_fee NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    nagari_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_partners_category ON partners(category);
CREATE INDEX IF NOT EXISTS idx_partners_nagari ON partners(nagari_name);

-- 3. TABEL SAVED_PLACES (Bookmark Destinasi Wisatawan - Pilar 3 & Layar 04)
CREATE TABLE IF NOT EXISTS saved_places (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destination_id VARCHAR(64) NOT NULL, -- Merujuk ke destinations(id) BE-1
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_destination UNIQUE (user_id, destination_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_places_user ON saved_places(user_id);

-- 4. TABEL ITINERARIES (Master Rencana Perjalanan 7 Hari - Pilar 4 & Layar 06)
CREATE TABLE IF NOT EXISTS itineraries (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_itineraries_user ON itineraries(user_id);

-- 5. TABEL ITINERARY_ITEMS (Rincian per Jam & Destinasi per Hari)
CREATE TABLE IF NOT EXISTS itinerary_items (
    id VARCHAR(64) PRIMARY KEY,
    itinerary_id VARCHAR(64) NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
    day_number INT NOT NULL, -- Hari ke 1 sampai 7
    time_slot VARCHAR(10) NOT NULL, -- Contoh "09:00"
    destination_id VARCHAR(64) NOT NULL, -- Merujuk ke destinations(id) BE-1
    notes TEXT,
    traffic_alert VARCHAR(200), -- Peringatan jalur macet (misal: "Pasar Koto Baru Macet")
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_itinerary_items_parent ON itinerary_items(itinerary_id, day_number);

-- 6. TABEL GROUP_ROOMS (Ruang Rombongan via Link WA - Pilar 4)
CREATE TABLE IF NOT EXISTS group_rooms (
    id VARCHAR(64) PRIMARY KEY,
    room_code VARCHAR(32) NOT NULL UNIQUE, -- Contoh: "RANCAK-MINANG-88"
    title VARCHAR(150) NOT NULL,
    leader_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_group_rooms_code ON group_rooms(room_code);

-- 7. TABEL GROUP_MEMBERS (Daftar Anggota dalam Group Room)
CREATE TABLE IF NOT EXISTS group_members (
    id VARCHAR(64) PRIMARY KEY,
    group_room_id VARCHAR(64) NOT NULL REFERENCES group_rooms(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member', -- 'leader', 'member'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_group_member UNIQUE (group_room_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_room ON group_members(group_room_id);

-- 8. TABEL GROUP_VOTES (Live Voting Destinasi/Homestay Rombongan)
CREATE TABLE IF NOT EXISTS group_votes (
    id VARCHAR(64) PRIMARY KEY,
    group_room_id VARCHAR(64) NOT NULL REFERENCES group_rooms(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destination_id VARCHAR(64) NOT NULL,
    vote_type VARCHAR(20) NOT NULL, -- 'upvote', 'downvote'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_vote UNIQUE (group_room_id, user_id, destination_id)
);

CREATE INDEX IF NOT EXISTS idx_group_votes_room ON group_votes(group_room_id);

-- 9. TABEL BOOKING_ESCROWS (Ledger Transaksi Rekening Bersama & QR E-Ticket)
CREATE TABLE IF NOT EXISTS booking_escrows (
    id VARCHAR(64) PRIMARY KEY,
    partner_id VARCHAR(64) NOT NULL REFERENCES partners(id) ON DELETE RESTRICT,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) NOT NULL DEFAULT 'IDR', -- 'IDR', 'MYR'
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_WA', 
    -- Status Alur: 'PENDING_WA' -> 'CONFIRMED' -> 'ESCROW_LOCKED' -> 'REDEEMED' / 'REFUNDED'
    qr_code_ticket VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_escrow_status ON booking_escrows(status);
CREATE INDEX IF NOT EXISTS idx_escrow_user ON booking_escrows(user_id);
CREATE INDEX IF NOT EXISTS idx_escrow_partner ON booking_escrows(partner_id);

-- 10. TABEL COMMUNITY_PLACES (Tempat Baru Usulan Komunitas dengan Proteksi Sensitif)
CREATE TABLE IF NOT EXISTS community_places (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    city_regency VARCHAR(100) NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    tips_menjaga TEXT NOT NULL, -- Wajib untuk kelestarian alam hidden gem
    is_sensitive BOOLEAN DEFAULT FALSE, -- Sakelar proteksi radius hingga dikurasi Pokdarwis
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_CURATION', -- 'PENDING_CURATION', 'APPROVED', 'REJECTED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_community_places_status ON community_places(status);

-- 11. TABEL SHARED_TRIPS (Papan Tebengan & Cari Barengan Rombongan)
CREATE TABLE IF NOT EXISTS shared_trips (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    destination_route VARCHAR(200) NOT NULL,
    departure_date TIMESTAMP WITH TIME ZONE NOT NULL,
    available_seats INT NOT NULL DEFAULT 1,
    cost_per_person NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    contact_wa VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shared_trips_date ON shared_trips(departure_date);

-- 12. TABEL DIGITAL_PASSPORTS (Check-in GPS <= 200m Anti-Fake GPS & Sertifikat Gubernur)
CREATE TABLE IF NOT EXISTS digital_passports (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destination_id VARCHAR(64) NOT NULL,
    checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_gps_valid BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_passport_checkin UNIQUE (user_id, destination_id)
);

CREATE INDEX IF NOT EXISTS idx_digital_passports_user ON digital_passports(user_id);

