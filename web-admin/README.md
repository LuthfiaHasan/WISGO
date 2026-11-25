# Rancak.in Web Admin & Portal Eksekutif Dispar Sumatera Barat

Portal administrasi berbasis **Vite + React + TypeScript + Tailwind CSS** untuk pengelolaan Ekosistem Wisata Pintar Sumatera Barat (`Rancak.in`):

1. **Manajemen Destinasi & Kesiapan Medan**: CRUD penuh 20+ destinasi unggulan di 19 Kabupaten/Kota Sumatera Barat, 4 Statistik Keputusan, Editor Visual 5 Indikator Medan (skor 1–5), sakelar Kawasan Blank Spot (Offline Pocket), dan panduan adat & kelestarian alam.
2. **Standar Tarif Perda & Plang Smart QR**: Pengelolaan komponen tarif resmi Peraturan Daerah / Peraturan Nagari (Fair-Price Barometer) lengkap dengan pratinjau dan cetak Plang Fisik Smart QR (`/qr/:destinationSlug`) beridentitas resmi Dinas Pariwisata & peringatan Satgas Saber Pungli.
3. **Monitoring Mitra UMKM Nagari & Escrow**: Direktori 5 kategori mitra lokal terverifikasi Nagari/Pokdarwis.
4. **Sinkronisasi Otomatis**: Terhubung dengan API Go Gin (`/api/v1`) dengan persistensi `localStorage` otomatis saat server bekerja pada mode lokal.

## Menjalankan Aplikasi Web Admin
```bash
cd web-admin
npm install
npm run dev
# Terbuka di http://localhost:3000
```
