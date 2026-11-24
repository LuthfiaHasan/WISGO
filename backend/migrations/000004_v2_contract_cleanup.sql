-- ============================================================================
-- MIGRATION: 000004_v2_contract_cleanup.sql
-- EKOSISTEM WISATA PINTAR SUMATERA BARAT (RANCAK.IN / WISGO)
-- STRATEGI: FASE 3 (CONTRACT / CLEANUP)
-- DESKRIPSI: Menghapus tabel-tabel legacy dan klaster fitur yang telah
--            disepakati untuk dihapus (Rombongan, Itinerary, & Escrow)
--            sehingga Supabase murni menyisakan 26 tabel sesuai DBML.
-- ============================================================================

BEGIN;

-- 1. Hapus tabel indikator medan lama (digantikan oleh indikator_medan)
DROP TABLE IF EXISTS medan_indicators CASCADE;

-- 2. Hapus tabel tips lama (digantikan oleh aturan_destinasi)
DROP TABLE IF EXISTS local_tips CASCADE;

-- 3. Hapus tabel POI shunlu lama (digantikan oleh visit_point)
DROP TABLE IF EXISTS shunlu_pois CASCADE;

-- 4. Hapus tabel paspor digital lama (digantikan oleh stemp_visit)
DROP TABLE IF EXISTS digital_passports CASCADE;

-- 5. Hapus tabel tempat komunitas lama (digantikan oleh new_tour)
DROP TABLE IF EXISTS community_places CASCADE;

-- 6. Hapus tabel shared trips lama (digantikan oleh open_trips)
DROP TABLE IF EXISTS shared_trips CASCADE;

-- 7. Hapus tabel peta mikro yang tidak lagi digunakan
DROP TABLE IF EXISTS scenic_micro_maps CASCADE;

-- 8. Hapus tabel Klaster Rombongan (Private Group Room)
DROP TABLE IF EXISTS group_votes CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS group_rooms CASCADE;

-- 9. Hapus tabel Klaster Itinerary (Smart Trip Planner 7 Hari)
DROP TABLE IF EXISTS itinerary_items CASCADE;
DROP TABLE IF EXISTS itineraries CASCADE;

-- 10. Hapus tabel Klaster Mitra Nagari & Escrow
DROP TABLE IF EXISTS booking_escrows CASCADE;
DROP TABLE IF EXISTS partners CASCADE;

-- 11. Hapus tabel junction challenge_destinations agar presisi 26 tabel DBML
DROP TABLE IF EXISTS challenge_destinations CASCADE;

COMMIT;
