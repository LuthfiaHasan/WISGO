# Laporan Lengkap Pekerjaan FS-1 (Fullstack) — Minggu 1 & Minggu 2 Tuntas (`FS1-M1-01` s.d. `FS1-M2-04`)

**Proyek:** WISGO / Rancak.in — Ekosistem Wisata Pintar Sumatera Barat  
**Instansi Pengguna:** Dinas Pariwisata Provinsi Sumatera Barat, Satgas Saber Pungli & Siaga SAR  
**Arsitektur Sistem:** Single Admin (Pusat Komando Terpadu Dispar • Penindakan Pungli • Siaga SAR)  
**Branch Git:** `Fullstack`  
**Alamat Aplikasi Lokal:** `http://localhost:3000/`

---

## Bagian 1. Ringkasan Eksekutif Pencapaian Sprint Minggu 1 & Minggu 2

Pengembangan aplikasi web administrasi dan pusat komando (`web-admin/`) untuk ekosistem **Rancak.in Sumatera Barat** telah menuntaskan seluruh target **Minggu 1 (`FS1-M1-01` s.d. `FS1-M1-04`)** dan **Minggu 2 (`FS1-M2-01` s.d. `FS1-M2-04`)** secara menyeluruh dengan standar produksi resmi (*production-ready*), tanpa label demo/mock/sprint, dan mematuhi palet warna organik Sumatera Barat (`#F6F3EC` Krem, `#234B24` Hijau Rimba, `#1E9E5A` Hijau Terverifikasi, dan `#F26B4B` Koral).

| Kode Target | Fitur & Modul Utama | Status | Bukti Implementasi |
| :--- | :--- | :---: | :--- |
| **FS1-M1-01** | Direktori 20 Destinasi & 19 Kab/Kota Sumbar | **TUNTAS** | [DestinationsPage.tsx](file:///d:/WISGO/web-admin/src/pages/DestinationsPage.tsx) |
| **FS1-M1-02** | Kontrak JSON & Persistensi Data `localStorage` + Go Gin | **TUNTAS** | [contract.ts](file:///d:/WISGO/web-admin/src/types/contract.ts), [api.ts](file:///d:/WISGO/web-admin/src/services/api.ts) |
| **FS1-M1-03** | Form CRUD Destinasi, 4 Statistik & 5 Indikator Medan | **TUNTAS** | Modal Editor 3 Bagian di `DestinationsPage.tsx` |
| **FS1-M1-04** | Fair-Price Barometer Tarif Perda & Plang Smart QR Cetak | **TUNTAS** | [TariffsAndQRPage.tsx](file:///d:/WISGO/web-admin/src/pages/TariffsAndQRPage.tsx), [SmartQRPlacardModal.tsx](file:///d:/WISGO/web-admin/src/components/SmartQRPlacardModal.tsx) |
| **FS1-M2-01** | Arsitektur Single Admin & Kontrak Data Imersif/Darurat | **TUNTAS** | [LoginPage.tsx](file:///d:/WISGO/web-admin/src/pages/LoginPage.tsx), [Sidebar.tsx](file:///d:/WISGO/web-admin/src/components/Sidebar.tsx) |
| **FS1-M2-02** | CMS Studio Virtual 360° & Visual 4-Pin Editor (Pitch/Yaw) | **TUNTAS** | [Studio360Page.tsx](file:///d:/WISGO/web-admin/src/pages/Studio360Page.tsx) |
| **FS1-M2-03** | Pusat Komando Terpadu: Penindakan Pungli & Siaga SOS SAR | **TUNTAS** | [CommandCenterPage.tsx](file:///d:/WISGO/web-admin/src/pages/CommandCenterPage.tsx) |
| **FS1-M2-04** | Web Instan Smart QR (`/qr`) & Group Invite (`/join`) | **TUNTAS** | [PublicSmartQRView.tsx](file:///d:/WISGO/web-admin/src/pages/PublicSmartQRView.tsx), [PublicGroupInviteView.tsx](file:///d:/WISGO/web-admin/src/pages/PublicGroupInviteView.tsx) |

---

## Bagian 2. Rincian Fitur Minggu 2 yang Aktif di `http://localhost:3000/`

### 1. Perombakan Otoritas Single Admin (Pusat Komando Terpadu)
- **Halaman Masuk Otoritas ([LoginPage.tsx](file:///d:/WISGO/web-admin/src/pages/LoginPage.tsx))**:
  - Menghilangkan pemisahan login dan dropdown unit kerja. Kini seluruh kewenangan dilebur menjadi satu otoritas tunggal: **Administrator Utama (Pusat Komando Dispar, Penindakan Pungli & Siaga SAR)**.
  - Tombol **Akses Cepat Otoritas** otomatis mengisi kredensial resmi `admin.komando@sumbarprov.go.id` dan menerbitkan JWT Bearer Token yang terenkripsi.
- **Navigasi Terintegrasi ([Sidebar.tsx](file:///d:/WISGO/web-admin/src/components/Sidebar.tsx))**:
  - Profil pengguna aktif menampilkan: *"Administrator Utama — Pusat Komando Terpadu Rancak.in (Dispar Sumbar • Penindakan Pungli • Siaga SAR)"*.
  - Menu pengawasan diperbarui menjadi **"Pusat Komando Pungli & SOS SAR"** lengkap dengan lencana (*badge*) penghitung tiket darurat aktif secara *real-time*.
  - Menambahkan menu pintasan cepat pratinjau publik: **"Web Plang Smart QR (/qr)"** dan **"Web Group Invite (/join)"**.

---

### 2. CMS Studio Virtual 360° & Visual 4-Pin Editor ([Studio360Page.tsx](file:///d:/WISGO/web-admin/src/pages/Studio360Page.tsx) — `FS1-M2-02`)
Modul kurasi tur imersif budaya dan alam Minangkabau:
- **Pemilih Destinasi & Manajemen Scene Panorama (`Aerial-to-Ground`)**:
  - Mendukung penambahan dan pengeditan scene 360° (tinjauan udara drone 150m vs pelataran permukaan tanah).
  - Admin dapat mengatur judul scene, tipe (*aerial/ground*), URL gambar panorama equirectangular, URL audio latar spasial, dan sudut pandang awal (*initial pitch & yaw*).
- **Kanvas Interaktif Penempatan Pin Otomatis**:
  - Admin cukup mengklik area gambar panorama equirectangular untuk menempatkan pin baru.
  - Sistem otomatis mengonversi posisi klik menjadi koordinat bola:
    - **Sudut Vertikal / Pitch**: `-90°` (bawah) s.d. `+90°` (atas).
    - **Sudut Horizontal / Yaw**: `-180°` s.d. `+180°`.
  - Dilengkapi garis bantu horizon (Pitch 0°) dan animasi *crosshair* bidik yang interaktif.
- **Editor 4 Kategori Hotspot Pin**:
  1. **Pin Info Adat & Sejarah (Kuning Emas `#CA8A04`)**: Narasi filosofi adat Minangkabau, legenda nagari, dan sejarah geologi batu cagar alam.
  2. **Pin Navigasi Pindah Scene (Biru Langit `#1D4ED8`)**: Pindah pandangan dari aerial ke ground atau sebaliknya.
  3. **Pin Audio Budaya (Ungu Indigo `#4F46E5`)**: Pemutar narasi lisan Minang dan instrumen tradisional (saluang, talempong).
  4. **Pin Mitra UMKM Nagari (Koral Oranye `#F26B4B`)**: Promosi homestay nagari, sewa baju adat, kuliner, dan kapal wisata dengan nominal tarif resmi.
- **Pratinjau & Notifikasi**: Setiap pin di kanvas dapat diklik untuk menampilkan kartu ringkasan atau membuka modal pengeditan, serta tersimpan persisten ke `localStorage` dan jembatan server Go.

---

### 3. Pusat Komando Terpadu: Penindakan Pungli & Siaga SOS Tim SAR ([CommandCenterPage.tsx](file:///d:/WISGO/web-admin/src/pages/CommandCenterPage.tsx) — `FS1-M2-03`)
Pusat kendali operasional lapangan terpadu yang terbagi dalam 2 tab:

#### Tab 1 — Penindakan Aduan Pungli & Fasilitas
- **4 Kartu KPI Ringkasan Eksekutif**:
  - *Laporan Baru* (merah/koral dengan animasi ping), *Sedang Diverifikasi* (kuning), *Ditindaklanjuti Lapangan* (biru), dan *Selesai Ditertibkan* (hijau).
- **Penyaringan Berlapis**: Filter berdasarkan kata kunci, 4 status penanganan, dan 4 kategori pelanggaran (*Parkir Liar*, *Tiket Di Atas Perda*, *Pemaksaan Pemandu/Kapal*, *Fasilitas Rusak*).
- **Tabel & Modal Verifikasi Aduan**:
  - Menampilkan bukti foto karcis/lokasi kejadian dari wisatawan.
  - Titik koordinat GPS presisi dengan tombol langsung ke *Google Maps*.
  - Komparasi langsung **Nominal Dipungut Oknum vs Standar Tarif Resmi Perda** beserta kalkulasi selisih lebih pungutan liar.
  - Kolom **Catatan Tindakan Resmi Admin/Satgas** untuk menginput Berita Acara penertiban.
  - Tombol pengubah status satu-klik: *Verifikasi Laporan*, *Tindak di Lapangan*, dan *Selesaikan Laporan*.

#### Tab 2 — Siaga Darurat SOS GPS & Koordinasi Tim SAR
- **Peringatan Siaga Merah Tingkat 1**: Otomatis muncul saat terdapat sinyal darurat aktif dari wisatawan.
- **Telemetri Sinyal Darurat Lapangan**:
  - Menampilkan nama wisatawan, jumlah rombongan, nomor telepon darurat, dan koordinat GPS.
  - Indikator sisa baterai ponsel wisatawan (*battery level meter*, merah jika di bawah 20%).
  - Kualitas sinyal lapangan (*Satelit Mesh / Zero-Signal Seluler*).
  - Catatan kondisi medis darurat (misal cedera terkilir, tersesat di tebing karst, butuh tandu).
  - Penugasan unit penyelamat (*Pos SAR Basarnas, BPBD, atau Pokdarwis*).
  - Tombol pembaruan status: *Sinyal SOS Masuk* → *Tim SAR Dikerahkan* → *Evakuasi Berjalan* → *Penanganan Selesai*.
- **Panel Kontrol Jalur Rawan Bencana (Hazard Zone Alerts)**:
  - Kendali status peringatan dini untuk 4 jalur ekstrem Sumatera Barat:
    1. **Jalur Ekstrem Sitinjau Lauik (Padang - Solok)**
    2. **Jalur Lembah Anai (Padang - Bukittinggi)**
    3. **Flyover & Kelok 9 (Payakumbuh - Riau)**
    4. **Jalur Malalak (Sicincin - Balingka)**
  - Pengubahan status langsung (*Aman Terkendali*, *Waspada Bencana*, *Buka-Tutup Jalur*, *Tutup Total*) yang langsung tersiar ke aplikasi wisatawan lengkap dengan rute pengalihan/alternatif.

---

### 4. Halaman Web Instan Smart QR & Group Invite ([PublicSmartQRView.tsx](file:///d:/WISGO/web-admin/src/pages/PublicSmartQRView.tsx), [PublicGroupInviteView.tsx](file:///d:/WISGO/web-admin/src/pages/PublicGroupInviteView.tsx) — `FS1-M2-04`)
Dua tampilan web publik responsif (*mobile-first*) yang dapat diakses turis maupun dipratinjau langsung dari admin:

1. **Web Plang Smart QR (`/qr/:destinationSlug`)**:
   - Tampil saat turis memindai Plang Smart QR fisik di lokasi destinasi.
   - Menampilkan kop resmi Pemprov Sumbar, foto panorama, dan status blank spot.
   - **Tab Tarif Perda (*Fair-Price Barometer*)**: Menampilkan daftar harga tiket, parkir, dan sewa resmi agar wisatawan terlindungi dari oknum pemeras.
   - **Tab Medan**: Rangkuman 5 Indikator Medan Lapangan (Akses Mobil, Trekking, Sinyal, Fasilitas, Pemandu).
   - **Tab Form Cepat Lapor Pungli**: Wisatawan dapat langsung mengirim laporan aduan dan bukti dari HP mereka, yang seketika menerbitkan tiket di Pusat Komando Admin.
   - **Tab Tombol Darurat SOS GPS**: Tombol merah besar untuk memancarkan koordinat darurat ke Pusat Komando dan Tim SAR terdekat.
2. **Web Group Invite Rombongan (`/join/:groupCode`)**:
   - Tampil saat calon wisatawan membuka tautan undangan perjalanan (contoh kode: `RANCAK-MINANG-88`).
   - Menampilkan nama rombongan, ketua perjalanan, tanggal tur 7 hari, dan jumlah anggota.
   - Menampilkan daftar 5 destinasi yang akan dikunjungi.
   - **Fitur Live Polling / Voting**: Calon peserta tur dapat langsung mengklik tombol **Vote** pada pilihan aktivitas/penginapan dan skor bertambah secara *real-time*.
   - Tombol ajakan aksi (CTA): **"Gabung & Buka di Aplikasi Rancak.in"**.

---

### 5. Analitik Eksekutif Dinas Pariwisata ([App.tsx](file:///d:/WISGO/web-admin/src/App.tsx))
Halaman dashboard eksekutif untuk pimpinan Dispar Sumbar yang menyajikan:
- Total destinasi terdaftar (20 destinasi) dengan status 100% terpetakan 5 indikator medan.
- Total item tarif resmi Perda yang tercakup dalam *Fair-Price Barometer*.
- Rekapitulasi kawasan *Blank Spot* yang diwajibkan mengunduh paket luring (*Offline Pocket*).
- Jumlah mitra UMKM nagari yang terverifikasi dan terlindungi sistem penampung dana bersama (*Escrow*).

---

## Bagian 3. Hasil Pengujian & Verifikasi Teknis

1. **Pengecekan Tipe TypeScript (`tsc`)**:
   - Perintah: `cd web-admin; npx.cmd tsc --noEmit`
   - Hasil: **`Exit Code 0` (0 error, 100% lulus kompilasi tipe)**.
2. **Pengujian Bundel Produksi (`vite build`)**:
   - Perintah: `cd web-admin; npx.cmd vite build`
   - Hasil: **`Exit Code 0` (Berhasil membangun 1.552 modul dalam 11,82 detik)**:
     - `dist/index.html` (0.84 kB)
     - `dist/assets/index.css` (39.16 kB)
     - `dist/assets/index.js` (469.78 kB)
3. **Penyelarasan Server Dev Lokal**:
   - Server berjalan stabil di port 3000 (`http://localhost:3000/`) dengan konfigurasi penanganan error proxy `vite.config.ts` yang bersih tanpa peringatan terminal.
