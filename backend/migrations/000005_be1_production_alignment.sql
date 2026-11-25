-- =============================================================================
-- MIGRATION: 000005_be1_production_alignment.sql
-- DESKRIPSI: Standarisasi 5 Master Categories Revisi (Poin 6) & Sinkronisasi
--            Kolom Production BE-1 di Supabase PostgreSQL
-- =============================================================================

BEGIN;

-- 1. Pastikan tabel categories mendukung skema v2 maupun skema ringkas
ALTER TABLE categories ADD COLUMN IF NOT EXISTS slug VARCHAR(100);
ALTER TABLE categories ADD COLUMN IF NOT EXISTS module_type VARCHAR(50) DEFAULT 'destination';
ALTER TABLE categories ADD COLUMN IF NOT EXISTS icon_url TEXT DEFAULT '';
ALTER TABLE categories ADD COLUMN IF NOT EXISTS color_hex VARCHAR(10) DEFAULT '#2E7D32';
ALTER TABLE categories ADD COLUMN IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- 2. Upsert 5 Master Categories Resmi Revisi #1 (Poin 6)
INSERT INTO categories (id, slug, name, module_type, description, icon_url, color_hex, sort_order, is_active)
VALUES
    ('cat-alam-geopark', 'alam-geopark', 'Alam & Geopark', 'destination', 'Wisata bentang alam, tebing granit purba, ngarai, danau pegunungan, dan geopark Sumatera Barat.', 'https://cdn.wisgo.sumbarprov.go.id/icons/cat-alam.png', '#2E7D32', 1, TRUE),
    ('cat-budaya-nagari', 'budaya-nagari', 'Budaya & Nagari', 'destination', 'Wisata warisan budaya Minangkabau, rumah gadang, desa adat terindah, dan sejarah peradaban Minang.', 'https://cdn.wisgo.sumbarprov.go.id/icons/cat-budaya.png', '#C62828', 2, TRUE),
    ('cat-hidden-gem', 'hidden-gem', 'Hidden Gem', 'destination', 'Destinasi wisata tersembunyi yang masih asri, sepi pengunjung, dan membutuhkan edukasi kelestarian khusus.', 'https://cdn.wisgo.sumbarprov.go.id/icons/cat-hiddengem.png', '#00695C', 3, TRUE),
    ('cat-religi', 'religi', 'Religi', 'destination', 'Wisata religi, masjid berarsitektur khas Minangkabau, surau tua bersejarah, dan ziarah ulama.', 'https://cdn.wisgo.sumbarprov.go.id/icons/cat-religi.png', '#1565C0', 4, TRUE),
    ('cat-kuliner', 'kuliner', 'Kuliner', 'destination', 'Sentra kuliner legendaris Minangkabau, pasar kuliner tradisional, kapau, rendang, dan sate khas darek/pesisir.', 'https://cdn.wisgo.sumbarprov.go.id/icons/cat-kuliner.png', '#EF6C00', 5, TRUE)
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon_url = EXCLUDED.icon_url,
    is_active = TRUE;

-- 3. Pastikan kolom category_id dan verification_status tersedia di destinations
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS category_id VARCHAR(64);
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS verification_status VARCHAR(24) NOT NULL DEFAULT 'verified';

-- 4. Auto-Category Mapping 20 Destinasi ke 5 Kategori Induk Resmi
UPDATE destinations SET category_id = 'cat-religi', category = 'Religi'
WHERE name ILIKE '%masjid%' OR name ILIKE '%surau%' OR category ILIKE '%religi%';

UPDATE destinations SET category_id = 'cat-kuliner', category = 'Kuliner'
WHERE category_id NOT IN ('cat-religi') AND (name ILIKE '%kuliner%' OR name ILIKE '%kapau%' OR name ILIKE '%sate%' OR name ILIKE '%rendang%' OR category ILIKE '%kuliner%');

UPDATE destinations SET category_id = 'cat-hidden-gem', category = 'Hidden Gem'
WHERE is_hidden_gem = TRUE AND category_id NOT IN ('cat-religi', 'cat-kuliner');

UPDATE destinations SET category_id = 'cat-budaya-nagari', category = 'Budaya & Nagari'
WHERE is_hidden_gem = FALSE AND category_id NOT IN ('cat-religi', 'cat-kuliner', 'cat-hidden-gem')
  AND (category ILIKE '%budaya%' OR category ILIKE '%sejarah%' OR category ILIKE '%nagari%' OR name ILIKE '%istano%' OR name ILIKE '%jam gadang%' OR name ILIKE '%pariangan%' OR name ILIKE '%sawahlunto%' OR name ILIKE '%pandai sikek%' OR name ILIKE '%seribu rumah gadang%');

UPDATE destinations SET category_id = 'cat-alam-geopark', category = 'Alam & Geopark'
WHERE category_id IS NULL OR category_id NOT IN ('cat-alam-geopark', 'cat-budaya-nagari', 'cat-hidden-gem', 'cat-religi', 'cat-kuliner');

COMMIT;
