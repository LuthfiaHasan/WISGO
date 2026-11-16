# Laporan Lengkap Pekerjaan FS-1 (Fullstack) — Minggu 1 Tuntas (`FS1-M1-01` s.d. `FS1-M1-04`)

**Proyek:** WISGO / Rancak.in — Ekosistem Wisata Pintar Sumatera Barat  
**Instansi Pengguna:** Dinas Pariwisata Provinsi Sumatera Barat & Satgas Saber Pungli Pariwisata  
**Branch Git:** `Fullstack` (Sinkron dengan `origin/dev`)  
**Alamat Aplikasi Lokal:** `http://localhost:3000/`

---

## Bagian 1. Penjelasan Lengkap Seluruh Fitur yang Tampil di `http://localhost:3000/`

Saat aplikasi dibuka di browser pada alamat **`http://localhost:3000/`**, seluruh antarmuka telah dirancang sebagai **Portal Eksekutif Produksi Resmi Pemerintah Provinsi Sumatera Barat** (menggunakan palet warna organik `desain.md`: Latar Krem `#F6F3EC`, Hijau Rimba `#234B24`, Hijau Terverifikasi `#1E9E5A`, dan Aksen Koral `#F26B4B`).

Berikut adalah rincian setiap halaman, panel, dan fitur interaktif yang berjalan di `localhost:3000`:

### 1. Halaman Otentikasi Pejabat & Operator ([LoginPage.tsx](file:///d:/WISGO/web-admin/src/pages/LoginPage.tsx))
Halaman pertama saat pengguna belum memiliki sesi aktif:
- **Panel Identitas Instansi (Kiri)**:
  - Menampilkan identitas resmi **Pemerintah Provinsi Sumatera Barat — Sistem Kendali Ekosistem Wisata Pintar Rancak.in**.
  - Menampilkan **Indikator Status Sistem** secara *real-time*:
    - `Status Sistem: Terhubung (Database Utama)` jika server Go (`:8080`) menyala.
    - `Status Sistem: Mode Lokal Aktif (Sinkronisasi Otomatis)` jika berjalan mandiri dengan penyimpanan lokal browser.
- **Panel Formulir Otentikasi (Kanan)**:
  - **Akses Cepat Otoritas (Mode Pengujian Internal)**: Dua tombol praktis untuk langsung masuk dengan sekali klik:
    1. **Masuk sebagai Kadispar Sumbar** (`kadispar@sumbarprov.go.id` — Otoritas Dinas Pariwisata Prov. Sumbar).
    2. **Masuk sebagai Satgas Saber Pungli** (`satgas.pungli@sumbarprov.go.id` — Otoritas Satgas Saber Pungli Pariwisata).
  - **Pilihan Unit Kerja**: Radio pilihan antara *Dinas Pariwisata Prov. Sumbar* dan *Satgas Saber Pungli Pariwisata*.
  - **Validasi Kredensial & Tombol Lihat Sandi**: Input email kedinasan dan kata sandi dengan tombol *Tampilkan/Sembunyikan* yang aksesibel, menghasilkan token sesi JWT yang disimpan di `localStorage`.

---

### 2. Sidebar Navigasi Utama & Panel Pejabat Aktif ([Sidebar.tsx](file:///d:/WISGO/web-admin/src/components/Sidebar.tsx))
Begitu berhasil masuk, sisi kiri layar menampilkan Sidebar tetap berwarna hijau `#234B24`:
- **Indikator Status Sistem**: Menampilkan status koneksi database utama atau mode lokal aktif.
- **6 Menu Operasional Resmi**:
  1. **Manajemen Destinasi & Medan** *(dilengkapi badge jumlah lokasi aktif, misal `20 Lokasi`)*
  2. **Standar Tarif Perda & QR** *(dilengkapi badge jumlah total item tarif resmi, misal `26 Tarif`)*
  3. **Studio Virtual 360°** *(Kurasi Panorama & Titik Interaktif)*
  4. **Komando Saber Pungli** *(Tindak Lanjut Laporan Lapangan — badge `Siaga`)*
  5. **Monitoring Mitra & Escrow** *(Direktori 5 Kategori UMKM Nagari & Rekening Bersama)*
  6. **Analitik Eksekutif Dispar** *(Kunjungan & Ekonomi 19 Kab/Kota)*
- **Kartu Pejabat Terotentikasi & Tombol Keluar**: Menampilkan nama lengkap pejabat, instansi, email kedinasan, dan tombol kapsul **Keluar dari Portal Eksekutif**.

---

### 3. Halaman Manajemen Destinasi Wisata & Kesiapan Medan ([DestinationsPage.tsx](file:///d:/WISGO/web-admin/src/pages/DestinationsPage.tsx))
Halaman utama untuk mengelola direktori destinasi wisata Sumatera Barat (`FS1-M1-01` & `FS1-M1-03`):

#### a. 4 Kartu Ringkasan Eksekutif (KPI Cards)
1. **Destinasi Terdaftar**: Menampilkan total destinasi (20 destinasi prioritas) dan jumlah cakupan Kabupaten/Kota.
2. **Kawasan Blank Spot (Zero-Signal)**: Menghitung otomatis jumlah destinasi yang berada di area tanpa sinyal (seperti Lembah Harau, Air Terjun Nyarai, Geopark Silokek, dan Pedalaman Mentawai) yang wajib mengaktifkan fitur *Offline Pocket*.
3. **Komponen Tarif Resmi Perda**: Menghitung total item tarif resmi yang terdaftar di seluruh destinasi untuk *Fair-Price Barometer*.
4. **Pemetaan Kesiapan Medan**: Ringkasan standar 5 Indikator Medan Lapangan.

#### b. Bilah Pencarian & Penyaringan Berlapis (`<search>`)
- **Input Pencarian Kata Kunci**: Mencari secara instan berdasarkan nama destinasi, kategori wisata, nama kabupaten/kota, deskripsi, maupun nomor peraturan daerah (contoh ketik: `Harau`, `Nyarai`, `UNESCO`, atau `Perwako`).
- **Dropdown Wilayah Kabupaten / Kota**: Menyaring destinasi berdasarkan **19 Kabupaten/Kota di Sumatera Barat**.
- **Pemilih Tingkat Keramaian**: Menyaring berdasarkan status `Semua`, `Sepi` (Hijau), `Sedang` (Sage), atau `Ramai` (Koral).
- **Filter Khusus Zona Blank Spot**: Kotak centang untuk langsung menampilkan destinasi yang tidak memiliki sinyal seluler.
- **Tombol Atur Ulang Semua Filter**: Muncul otomatis saat salah satu filter aktif.

#### c. Tabel Direktori Responsif & Dapat Diurutkan (*Sortable Table*)
- **Pengurutan Kolom (*Sorting*)**: Klik pada judul kolom **Destinasi Wisata**, **Wilayah & Kategori**, **4 Statistik Keputusan** (diurutkan berdasarkan jarak km), atau **Standar Tarif Perda** (diurutkan berdasarkan nominal harga tiket) untuk mengurutkan secara menaik (*ascending*) atau menurun (*descending*).
- **7 Kolom Informasi Lengkap**:
  1. **Destinasi Wisata**: Foto sampul, kode ID (`DEST-001`), badge `Offline Pocket` (jika blank spot), nama destinasi, dan titik koordinat GPS.
  2. **Wilayah & Kategori**: Nama Kabupaten/Kota dan kategori wisata.
  3. **4 Statistik Keputusan**: Badge Keramaian (`Sepi`/`Sedang`/`Ramai`), estimasi jarak (`km`), dan estimasi waktu tempuh (`jam/menit`).
  4. **5 Indikator Kesiapan Medan**: Menampilkan lencana *Akses Kendaraan*, *Tingkat Trekking*, *Sinyal Seluler*, *Fasilitas Resmi*, dan *Kebutuhan Pemandu*.
  5. **Standar Tarif Perda**: Menampilkan harga tiket utama dalam Rupiah, nama layanan, nomor referensi Perda/Nagari, dan jumlah komponen tarif tambahan.
  6. **Edukasi & Adat**: Menampilkan kartu hijau sage berisi kutipan *Tips Menjaga Tempat Ini*.
  7. **Tindakan Pengelolaan**: 5 tombol aksi pada setiap baris:
     - **`Detail`**: Membuka jendela ringkasan lengkap destinasi.
     - **`Edit`**: Membuka Modal Editor 3 Bagian (Bagian A, B, dan C).
     - **`Kelola Tarif & QR`**: Membuka halaman pengelolaan Standar Tarif Perda & QR khusus untuk destinasi tersebut.
     - **`Plang QR`**: Membuka pratinjau Plang Fisik Smart QR siap cetak.
     - **Ikon Tempat Sampah (`Hapus`)**: Membuka dialog konfirmasi penghapusan destinasi.

---

### 4. Modal Editor Destinasi 3 Bagian ([DestinationsPage.tsx](file:///d:/WISGO/web-admin/src/pages/DestinationsPage.tsx) — `FS1-M1-03`)
Saat tombol **+ Tambah Destinasi Baru** atau tombol **Edit** diklik, terbuka jendela modal terstruktur dengan 3 tab bagian:

- **Bagian A — Profil & 4 Statistik Keputusan**:
  - Input Nama Destinasi (otomatis membentuk *slug* `/qr/:destinationSlug`), pilihan 19 Kabupaten/Kota, pilihan Kategori Wisata, serta input Koordinat GPS (`Latitude` & `Longitude`).
  - **4 Statistik Keputusan Wisatawan**: Input Estimasi Jarak (`km`), Waktu Tempuh (`menit`), Status Keramaian (`Sepi`/`Sedang`/`Ramai`), dan Ringkasan Biaya Tiket.
  - **Sakelar Kawasan Blank Spot (Wajib Unduh Offline Pocket)**: Jika diaktifkan, otomatis menandai destinasi sebagai zona *Zero-Signal* sehingga aplikasi wisatawan memprioritaskan penyimpanan luring.
  - Input Deskripsi Kawasan dan URL Foto Sampul.
- **Bagian B — Editor Visual 5 Indikator Medan**:
  - Menyediakan dropdown status sekaligus **Slider Skor Kesiapan 1–5** untuk:
    1. **Akses Kendaraan** (`Mobil OK` / `Hanya Motor` / `Jalan Kaki Saja`) + Skor 1–5.
    2. **Tingkat Kesulitan Trekking** (`Landai / Mudah` / `Sedang` / `Curam / Ekstrem`) + Skor 1–5.
    3. **Kualitas Sinyal Seluler** (`4G Lancar` / `Sinyal Lemah` / `Zero-Signal (Blank Spot)`) + Skor 1–5.
    4. **Ketersediaan Fasilitas Resmi** (`Toilet, Musala & Parkir Lengkap` / `Terbatas` / `Belum Ada`) + Skor 1–5.
    5. **Kebutuhan Pemandu Lokal / Pokdarwis** (`Bisa Mandiri` / `Disarankan` / `Wajib Pemandu`) + Skor 1–5.
  - Dilengkapi kolom **Deskripsi Kesiapan Fisik & Kendaraan di Lapangan** (misal peringatan tanjakan Sitinjau Lauik atau Kelok 44).
- **Bagian C — Edukasi & Adat Minangkabau**:
  - Mengelola daftar panduan **Tips Menjaga Tempat Ini** (bisa menambah beberapa butir panduan, mengubah teks, menghapus butir, dan mencentang penanda **Tandai sebagai Peringatan Penting**).

---

### 5. Halaman Standar Tarif Perda & Plang Smart QR ([TariffsAndQRPage.tsx](file:///d:/WISGO/web-admin/src/pages/TariffsAndQRPage.tsx) — `FS1-M1-04`)
Dapat diakses melalui menu Sidebar **Standar Tarif Perda & QR** atau tombol **Kelola Tarif & QR** pada baris destinasi:
- **Pemilih Destinasi Cepat**: Dropdown untuk memilih destinasi mana pun dari 20 destinasi Sumatera Barat, menampilkan foto, wilayah, tautan `/qr/:slug`, dan jumlah komponen tarif aktif.
- **Tabel & Formulir CRUD Komponen Tarif Resmi (*Fair-Price Barometer*)**:
  - Tombol **+ Tambah Komponen Tarif Resmi**, tombol **Ubah**, dan tombol **Hapus** (dengan konfirmasi aman).
  - Setiap item tarif menyimpan:
    1. **Nama Item / Komponen Layanan** (contoh: *Tiket Masuk Dewasa*, *Parkir Mobil Resmi*, *Sewa Bendi Rute Kota*, *Paket Kapal 4 Pulau*).
    2. **Kategori Komponen** (`Tiket Masuk`, `Parkir Kendaraan`, `Jasa Pemandu/Kapal`, `Kuliner/Fasilitas`).
    3. **Harga Resmi (IDR)**.
    4. **Batas Harga Wajar Min–Max (IDR)** sebagai acuan *Fair-Price Barometer*.
    5. **Satuan Pengenaan Tarif** (`per orang`, `per kendaraan`, `per kapal`, `per malam`, `per putaran`, dll.).
    6. **Nomor Referensi Perda / SK Nagari** (contoh: `Perwako Bukittinggi No. 12/2024`).

---

### 6. Pratinjau & Cetak Plang Fisik Smart QR ([SmartQRPlacardModal.tsx](file:///d:/WISGO/web-admin/src/components/SmartQRPlacardModal.tsx) — `FS1-M1-04`)
Tampil di bagian bawah halaman Tarif maupun sebagai jendela modal saat tombol **Plang QR** diklik:
- **Desain Plang Fisik Standar Pemerintah Provinsi Sumatera Barat**:
  - Kop resmi **PEMERINTAH PROVINSI SUMATERA BARAT · DINAS PARIWISATA**, nama destinasi, wilayah, koordinat GPS, dan kode ID plang kawasan.
  - **Visual Kode QR Unik (SVG)** yang di-generate secara deterministik untuk alamat `rancak.in/qr/:destinationSlug` beserta penanda khusus jika kawasan tersebut merupakan **Zona Blank Spot**.
  - **Tabel Daftar Tarif Resmi Perda / Nagari (*Fair-Price Barometer*)** yang langsung memperbarui isinya saat admin menambah/mengubah tarif.
  - **Ringkasan 5 Indikator Medan** di bawah tabel tarif.
  - **Kotak Peringatan Resmi Satgas Saber Pungli Provinsi Sumatera Barat** (mencantumkan ancaman pidana Pasal 368 KUHP & UU No. 20 Tahun 2001 terhadap pungutan liar di luar tarif Perda).
  - **Tombol `Cetak Plang QR (PDF/Print)`**: Memanggil fungsi cetak browser dengan aturan CSS `@media print` khusus sehingga hanya plang fisik Smart QR yang tercetak bersih ke kertas atau PDF.

---

### 7. Halaman Monitoring Mitra UMKM Nagari & Persistensi Data ([App.tsx](file:///d:/WISGO/web-admin/src/App.tsx), [api.ts](file:///d:/WISGO/web-admin/src/services/api.ts))
- **Menu Monitoring Mitra & Escrow**: Menampilkan kartu direktori 5 kategori Mitra UMKM Nagari terverifikasi (*Homestay Rumah Gadang*, *Kuliner Halal*, *Kapal & Transportasi*, *Pemandu Pokdarwis*, dan *Sewa Baju Adat*) lengkap dengan nomor WhatsApp, nama Nagari, dan tarif standar.
- **Persistensi `localStorage` Otomatis**: Seluruh perubahan (tambah destinasi, edit 5 indikator medan, tambah/ubah/hapus tarif Perda) langsung disimpan ke `localStorage` (`rancakin_dispar_destinations_v2`) dan diumumkan melalui **Notifikasi Toast** di kanan bawah layar. Saat halaman di-refresh (`F5`), data yang telah diubah tetap tersimpan utuh. Tersedia pula tombol **Pulihkan 20 Data Standar** jika admin ingin mengembalikan data ke kondisi awal.

---

## Bagian 2. Kesimpulan Kronologis Apa Saja yang Telah Kita Lakukan dari Awal

Berikut adalah rangkuman urut dari awal sesi hingga seluruh target Minggu 1 selesai dan berjalan di browser:

1. **Sinkronisasi Git & Persiapan Branch `Fullstack`**:
   - Memeriksa status repository lokal di `d:\WISGO`.
   - Menjalankan `git fetch --all`, berpindah (*checkout*) ke branch khusus **`Fullstack`**, dan menarik (*fast-forward merge*) commit terbaru dari **`origin/dev`** (`b701a98`) agar struktur monorepo sinkron dengan seluruh tim.
2. **Pemetaan Struktur Monorepo & Analisis Kode Backend/Mobile**:
   - Memeriksa seluruh isi folder `backend/`, `mobile/`, `web-admin/`, dan `docs/`.
   - Membaca langsung kode Go di [models.go](file:///d:/WISGO/backend/internal/models/models.go), [be1_core/handlers.go](file:///d:/WISGO/backend/internal/be1_core/handlers.go), dan [be2_group/handlers.go](file:///d:/WISGO/backend/internal/be2_group/handlers.go) serta referensi token warna di `mobile/` dan `docs/Desain_System_Token.md`.
3. **Setup Fondasi Proyek `web-admin/` & Kontrak JSON TypeScript (`FS1-M1-01` & `FS1-M1-02`)**:
   - Mengonfigurasi **Vite + React 18 + TypeScript + Tailwind CSS + Axios** di dalam folder `web-admin/` dengan *proxy* otomatis `/api` dan `/health` ke `http://localhost:8080`.
   - Menyusun kontrak TypeScript lengkap di [contract.ts](file:///d:/WISGO/web-admin/src/types/contract.ts) untuk `Destination`, `MedanIndicator`, `OfficialTariff`, `DestinationTip` (`LocalTip`), dan `Partner` (`PartnerNagari`) agar 100% sinkron dengan struct Go.
4. **Penyusunan Data 20 Destinasi Prioritas Sumatera Barat & Jembatan API Axios**:
   - Membuat data lengkap 20 destinasi unggulan lintas 19 Kabupaten/Kota Sumatera Barat di [mockDestinations.ts](file:///d:/WISGO/web-admin/src/data/mockDestinations.ts) beserta 5 indikator medan, dasar hukum Perda, dan tips menjaga tempat.
   - Membangun jembatan API Axios di [api.ts](file:///d:/WISGO/web-admin/src/services/api.ts) yang mendukung otentikasi Bearer Token JWT, sinkronisasi ke server Go Gin, dan *fallback* penyimpanan persisten di `localStorage`.
5. **Perombakan Tampilan Produksi Resmi Dispar Sumbar & Penyelesaian Fitur CRUD (`FS1-M1-03` & `FS1-M1-04`)**:
   - Menghapus seluruh istilah teknis/demo/sprint dan menggantinya dengan terminologi operasional resmi Dinas Pariwisata Provinsi Sumatera Barat.
   - Membangun fitur pengurutan kolom tabel (*sortable table*), filter berlapis, serta **Modal Editor 3 Bagian** (Profil & 4 Statistik Keputusan, Editor Visual 5 Indikator Medan dengan skor 1–5, dan Edukasi Adat).
   - Membangun halaman khusus **Standar Tarif Perda & QR** untuk CRUD komponen tarif resmi (*Fair-Price Barometer*) beserta **Pratinjau & Cetak Plang Fisik Smart QR** (`/qr/:destinationSlug`).
6. **Instalasi Dependensi, Verifikasi Build, dan Pengaktifan Server Lokal**:
   - Menjalankan `npm install` (158 paket), menambahkan deklarasi tipe Vite di [vite-env.d.ts](file:///d:/WISGO/web-admin/src/vite-env.d.ts), serta memastikan `npx tsc --noEmit` dan `npx vite build` berhasil **100% tanpa error**.
   - Menjalankan server pengembangan Vite di **`http://localhost:3000/`** sehingga seluruh fitur dapat langsung digunakan dan diuji di browser.
   - Mendokumentasikan seluruh hasil kerja ke dalam file [laporan_harian_fs1.md](file:///d:/WISGO/docs/laporan_harian_fs1.md) di folder `docs/`.
