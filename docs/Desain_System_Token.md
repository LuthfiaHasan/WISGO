# STANDAR DESAIN ANTARMUKA & TOKEN VISUAL (`desain.md`)
# Ekosistem Wisata Pintar Sumatera Barat (Rancak.in)

Sumber kebenaran visual: `Rancangan_Aplikasi_Wisata_Sumbar.figcraft` & `desain.md`. Seluruh kode UI di Flutter (FE-1, FE-2) dan Web Admin (FS-1) wajib mematuhi aturan berikut:

---

## 01. Palet Warna Hangat-Organik (Design Tokens)

| Token Name | Hex Code | Deskripsi & Peruntukan Penggunaan |
| :--- | :--- | :--- |
| `--cream-100` | `#F6F3EC` | **Latar Halaman Utama** (Pengganti putih murni `#FFFFFF` agar tidak silau di terik matahari Ranah Minang). |
| `--green-800` | `#234B24` | **Merek Utama & CTA Primer** (Tinggi tombol 52px). Melambangkan kesuburan alam Minangkabau. |
| `--green-500` | `#1E9E5A` | **Status Positif**: Lencana Terverifikasi Nagari, status aktif, dan badge keramaian **Sepi**. |
| `--ink-900` | `#1B1F1A` | **Teks Utama** (Pengganti hitam murni `#000000` untuk keterbacaan natural). |
| `--coral-500` | `#F26B4B` | **Aksen Kritis**: Hanya untuk tombol FAB (+), penanda tren, ikon hati/favorit, & badge keramaian **Ramai**. |
| `--orange-500` | `#E85D1A` | **Pin Kuliner, Vendor Nagari & Tanggal Aktif** di kalender perjalanan. |
| `--indigo-500` | `#5B6AE8` | **Khusus Kategori Event & Budaya** (Tabuik, Pacu Jawi, Hari Pakan). |
| `--sage-100` | `#E4E9DA` | **Latar Kartu**: Kartu ajakan lokasi & kartu "Tips Menjaga Tempat Ini". |

---

## 02. Standar Tipografi & Geometri
- **Font Utama**: *Plus Jakarta Sans* (Sentence case, rata kiri / left-aligned).
- **Kanvas Mobile Utama**: 390 × 844 px (Viewport modern responsif).
- **Tombol Utama (CTA)**:
  - Bentuk: Kapsul (*Pill-shaped*)
  - Tinggi: **52 px**
  - Radius: **26 px**
- **Touch Target Minimum**: **44 × 44 px** untuk semua ikon, tombol kecil, dan elemen sentuh.
- **Drawer / Modal Bottom Sheet**: Border radius paruh atas **28 px**.

---

## 03. Sistem 4 Pin Kanvas 360° Terstandarisasi

Setiap scene panorama 360° menggunakan 4 pin dengan icon & warna baku:
1. **Pin Navigasi (Biru)**: Berpindah antar-scene udara ke darat, atau titik pandang berikutnya.
2. **Pin Audio Budaya (Emas / Amber)**: Memutar narasi sejarah & instrumen musik khas Minang.
3. **Pin Fasilitas Resmi (Hijau - `#1E9E5A`)**: Toilet, musala, loket karcis resmi, tempat parkir.
4. **Pin Mitra Nagari (Oranye - `#E85D1A`)**: Homestay Rumah Gadang, kuliner, persewaan baju adat, perahu lokal. Membuka *Quick Booking Drawer* setengah layar.

---

## 04. Format 4 Statistik Keputusan & 5 Indikator Medan

### Grid 4 Statistik (Paruh Atas Layar Detail Tempat):
1. **Jarak** (km dari posisi saat ini)
2. **Waktu Tempuh** (menit / jam)
3. **Tingkat Keramaian**:
   - `Sepi` (Badge Hijau `#1E9E5A`)
   - `Sedang` (Badge Kuning/Sage `#E4E9DA`)
   - `Ramai` (Badge Koral `#F26B4B`)
4. **Biaya Masuk**: Rp X / Orang (Sesuai Perda)

### Kartu 5 Indikator Medan:
1. **Akses Kendaraan**: `Mobil OK` / `Hanya Motor` / `Jalan Kaki Saja`
2. **Tingkat Trekking**: `Mudah (Datar)` / `Sedang` / `Ekstrem (Curam)`
3. **Kekuatan Sinyal**: `4G Kuat` / `Sinyal Lemah` / `Blank Spot (Zero-Signal)`
4. **Fasilitas**: `Ada Toilet & Musala` / `Terbatas` / `Belum Ada`
5. **Kebutuhan Pemandu**: `Wajib Pemandu Lokal` / `Disarankan` / `Bisa Mandiri`

