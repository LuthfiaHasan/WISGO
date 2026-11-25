-- =============================================================================
-- SEEDER: 000002_be2_seeders.sql
-- DOMAIN: BE-2 (Data Seeder Awal Pengguna, 5 Kategori Mitra Minang, Itinerary & Grup)
-- EKOSISTEM WISATA PINTAR SUMATERA BARAT (RANCAK.IN)
-- =============================================================================

-- 1. SEEDER USERS
INSERT INTO users (id, phone_number, full_name, role)
VALUES 
    ('usr-001', '6281211112222', 'Rahmat Hidayat (Wisatawan Mandiri)', 'tourist'),
    ('usr-002', '6281233334444', 'Etek Nurhasanah (Mitra Homestay)', 'partner'),
    ('usr-003', '6281255556666', 'Kadispar Sumatera Barat', 'admin_dispar')
ON CONFLICT (id) DO NOTHING;

-- 2. SEEDER 5 KATEGORI MITRA NAGARI MINANGKABAU (Pilar 5)
INSERT INTO partners (id, name, category, whatsapp, spicy_level, is_verified, standard_fee, nagari_name)
VALUES
    (
        'ptr-01',
        'Homestay Rumah Gadang Etek Nur',
        'Homestay Rumah Gadang',
        '6281234567890',
        0,
        TRUE,
        250000.00,
        'Nagari Sungai Buluah'
    ),
    (
        'ptr-02',
        'Itiak Lado Mudo Ngarai Sianok',
        'Kuliner Halal',
        '6281298765432',
        4, -- Level Pedas 4 (Otentik Minang)
        TRUE,
        45000.00,
        'Nagari Koto Gadang'
    ),
    (
        'ptr-03',
        'Perahu Wisata Bahari Pulau Mandeh',
        'Transport & Perahu',
        '6281311223344',
        0,
        TRUE,
        350000.00,
        'Nagari Tarusan Mandeh'
    ),
    (
        'ptr-04',
        'Pemandu Trekking Lembah Harau (Pokdarwis)',
        'Pemandu Pokdarwis',
        '6281355667788',
        0,
        TRUE,
        150000.00,
        'Nagari Harau'
    ),
    (
        'ptr-05',
        'Sanggar Busana Saluak & Suntiang Rang Minang',
        'Sewa Baju Adat',
        '6281399887766',
        0,
        TRUE,
        75000.00,
        'Kota Bukittinggi'
    )
ON CONFLICT (id) DO NOTHING;

-- 3. SEEDER SAVED PLACES (Bookmark Destinasi)
INSERT INTO saved_places (id, user_id, destination_id)
VALUES
    ('sp-001', 'usr-001', 'dest-001'), -- Lembah Harau
    ('sp-002', 'usr-001', 'dest-002')  -- Jam Gadang Bukittinggi
ON CONFLICT (id) DO NOTHING;

-- 4. SEEDER MASTER ITINERARY (Trip Planner 7 Hari - Pilar 4)
INSERT INTO itineraries (id, user_id, title, start_date, end_date, total_days)
VALUES
    ('itn-001', 'usr-001', 'Jelajah Luhak Nan Tigo (Padang - Bukittinggi - Harau)', '2026-11-20', '2026-11-26', 7)
ON CONFLICT (id) DO NOTHING;

-- 5. SEEDER ITINERARY ITEMS (Agenda Harian)
INSERT INTO itinerary_items (id, itinerary_id, day_number, time_slot, destination_id, notes, traffic_alert)
VALUES
    ('iti-001', 'itn-001', 1, '09:00', 'dest-001', 'Trekking santai tebing granit & sarapan katupek pical', NULL),
    ('iti-002', 'itn-001', 1, '13:00', 'dest-002', 'Menara Jam Gadang & belanja songket Pasar Ateh', 'Waspada macet Pasar Koto Baru pukul 12:00-14:00')
ON CONFLICT (id) DO NOTHING;

-- 6. SEEDER GROUP ROOM (Private Group Room)
INSERT INTO group_rooms (id, room_code, title, leader_id)
VALUES
    ('grp-001', 'RANCAK-MINANG-88', 'Trip Rombongan Ranah Minang 2026', 'usr-001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO group_members (id, group_room_id, user_id, role)
VALUES
    ('gm-001', 'grp-001', 'usr-001', 'leader')
ON CONFLICT (id) DO NOTHING;

