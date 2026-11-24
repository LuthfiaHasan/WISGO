-- =============================================================================
-- MIGRATION & SEEDER: 000004_seed_real_emergency_contacts.sql
-- DOMAIN: BE-1 (Pilar 7 - Nomor Kontak Resmi Darurat Kebencanaan Sumatera Barat)
-- =============================================================================

-- 1. Bersihkan data dummy yang tidak real
DELETE FROM emergency_contacts 
WHERE id NOT IN ('emg-001', 'emg-002', 'emg-003', 'emg-004', 'emg-005', 'emg-006');

-- 2. Sinkronisasi 6 Kontak Resmi Bencana Sumatera Barat Sesuai Data Real Lapangan
INSERT INTO emergency_contacts (id, agency_name, agency_type, phone_number, city_regency, geog, created_by_admin_id, is_active, created_at)
VALUES 
    (
        'emg-001',
        'BPBD Sumatera Barat',
        'BPBD',
        '(0751) 890721',
        'Provinsi Sumatera Barat',
        ST_SetSRID(ST_MakePoint(100.3543, -0.9471), 4326)::geography,
        'usr-003',
        TRUE,
        NOW()
    ),
    (
        'emg-002',
        'PMI Sumatera Barat',
        'PMI',
        '(0751) 27882',
        'Kota Padang',
        ST_SetSRID(ST_MakePoint(100.3621, -0.9324), 4326)::geography,
        'usr-003',
        TRUE,
        NOW()
    ),
    (
        'emg-003',
        'Damkar Kota Padang',
        'Damkar',
        '08116606113',
        'Kota Padang',
        ST_SetSRID(ST_MakePoint(100.3705, -0.9512), 4326)::geography,
        'usr-003',
        TRUE,
        NOW()
    ),
    (
        'emg-004',
        'BPBD Padang Pariaman',
        'BPBD',
        '08116662114',
        'Kab. Padang Pariaman',
        ST_SetSRID(ST_MakePoint(100.2811, -0.6272), 4326)::geography,
        'usr-003',
        TRUE,
        NOW()
    ),
    (
        'emg-005',
        'BPBD Pesisir Selatan',
        'BPBD',
        '085269380950',
        'Kab. Pesisir Selatan',
        ST_SetSRID(ST_MakePoint(100.5694, -1.3502), 4326)::geography,
        'usr-003',
        TRUE,
        NOW()
    ),
    (
        'emg-006',
        'Damkar Bukittinggi',
        'Damkar',
        '085355157883',
        'Kota Bukittinggi',
        ST_SetSRID(ST_MakePoint(100.3692, -0.3055), 4326)::geography,
        'usr-003',
        TRUE,
        NOW()
    )
ON CONFLICT (id) DO UPDATE SET
    agency_name = EXCLUDED.agency_name,
    agency_type = EXCLUDED.agency_type,
    phone_number = EXCLUDED.phone_number,
    city_regency = EXCLUDED.city_regency,
    geog = EXCLUDED.geog,
    created_by_admin_id = EXCLUDED.created_by_admin_id,
    is_active = EXCLUDED.is_active;
