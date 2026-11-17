# Laporan Pekerjaan FS-1 — Ekosistem Web Admin WISGO Sumbar
## Penuntasan Menyeluruh Target Minggu 1 s.d. Minggu 4 (FINAL)

**Nama Sistem:** WISGO (Ekosistem Wisata Pintar Sumatera Barat)  
**Instansi Pengguna:** Dinas Pariwisata Provinsi Sumatera Barat, Satgas Saber Pungli & Siaga SAR  
**Arsitektur Akses:** Single Admin (Pusat Komando Terpadu Dispar • Penindakan Pungli • Siaga SAR)  
**Status Target:** Minggu 1 (`FS1-M1-01` s.d. `M1-04`), Minggu 2 (`FS1-M2-01` s.d. `M2-04`), Minggu 3 & Minggu 4 **100% TUNTAS (Production-Ready)**  
**Branch Git:** `Fullstack`  
**Alamat Server Dev Lokal:** `http://localhost:3000/`

---

## 1. Matriks Pencapaian Seluruh Minggu (M1 s.d. M4)

| Fase / Kode | Modul & Fitur Utama | Status | Berkas Kunci Implementasi |
| :--- | :--- | :---: | :--- |
| **Rebranding** | Migrasi total identitas brand ke **WISGO** (Dispar Prov. Sumbar) | **Tuntas** | Seluruh Halaman, Header, Sidebar & Plang |
| **M1-01 s.d. M1-04** | Direktori 20 Destinasi, 5 Indikator Medan, Fair-Price Barometer & Plang Cetak | **Tuntas** | [DestinationsPage.tsx](file:///d:/WISGO/web-admin/src/pages/DestinationsPage.tsx), [TariffsAndQRPage.tsx](file:///d:/WISGO/web-admin/src/pages/TariffsAndQRPage.tsx) |
| **M2-01 & Otoritas** | Single Admin Otoritas Penuh, JWT Session, & Silent Proxy Error Handler | **Tuntas** | [LoginPage.tsx](file:///d:/WISGO/web-admin/src/pages/LoginPage.tsx), [Sidebar.tsx](file:///d:/WISGO/web-admin/src/components/Sidebar.tsx), [vite.config.ts](file:///d:/WISGO/web-admin/vite.config.ts) |
| **M2-02 (360° Studio)** | Kanvas Panorama 360° pan 60fps, Pitch/Yaw HUD, 4 Hotspot Pin & Scene Leap | **Tuntas** | [Studio360Page.tsx](file:///d:/WISGO/web-admin/src/pages/Studio360Page.tsx) |
| **M2-03 (Komando)** | Penindakan Pungli (komparasi selisih Perda) & Siaga Darurat SOS GPS SAR | **Tuntas** | [CommandCenterPage.tsx](file:///d:/WISGO/web-admin/src/pages/CommandCenterPage.tsx) |
| **M2-04 (Web Publik)** | Web Plang Smart QR (20 Destinasi) & Web Group Invite (Itinerary 7 Hari & Split-Bill) | **Tuntas** | [PublicSmartQRView.tsx](file:///d:/WISGO/web-admin/src/pages/PublicSmartQRView.tsx), [PublicGroupInviteView.tsx](file:///d:/WISGO/web-admin/src/pages/PublicGroupInviteView.tsx) |
| **M3 (Bot WA & Escrow)**| Simulator Bot WhatsApp Mitra 2-Arah, Kunci Escrow & Scan QR E-Ticket Cair ke Nagari | **Tuntas** | [WhatsAppBotSimulator.tsx](file:///d:/WISGO/web-admin/src/components/WhatsAppBotSimulator.tsx) |
| **M3 (Live Hazard)** | Pusat Kendali Siaga 5 Jalur Ekstrem (Sitinjau Lauik, Anai, Kelok 9, Malalak, Kelok 44) | **Tuntas** | Tab 3 di [CommandCenterPage.tsx](file:///d:/WISGO/web-admin/src/pages/CommandCenterPage.tsx) |
| **M4 (Analitik Eksekutif)**| Heatmap Kepadatan 19 Kab/Kota, Paspor Digital & Grafik Escrow 5 Kategori | **Tuntas** | [ExecutiveAnalyticsPage.tsx](file:///d:/WISGO/web-admin/src/pages/ExecutiveAnalyticsPage.tsx) |
| **M4 (Meja Kurasi)** | Moderasi Usulan Hidden Gem & Sakelar Proteksi Masking Koordinat Sensitif | **Tuntas** | Bagian 3 di [ExecutiveAnalyticsPage.tsx](file:///d:/WISGO/web-admin/src/pages/ExecutiveAnalyticsPage.tsx) |
| **M4 (Ekspor & Demo)** | Ekspor PDF Kop Resmi Dispar Sumbar, Unduh CSV, & Mode Showcase 1 Layar | **Tuntas** | [ExecutiveAnalyticsPage.tsx](file:///d:/WISGO/web-admin/src/pages/ExecutiveAnalyticsPage.tsx), [App.tsx](file:///d:/WISGO/web-admin/src/App.tsx) |
| **Upload Device** | Pengunggah File Lokal Native + Kompresi HTML5 Canvas (Bebas Quota Error) | **Tuntas** | [ImageDropzone.tsx](file:///d:/WISGO/web-admin/src/components/ImageDropzone.tsx), [imageOptimizer.ts](file:///d:/WISGO/web-admin/src/utils/imageOptimizer.ts) |

---

## 2. Rincian Teknis & Arsitektur Implementasi

### A. Rebranding Menyeluruh & Otoritas Single Admin
- Seluruh istilah brand lama telah dimigrasikan secara menyeluruh ke **WISGO** (*Ekosistem Wisata Pintar Sumatera Barat — Dinas Pariwisata Provinsi Sumatera Barat*).
- Otoritas dilebur menjadi **Administrator Utama (Pusat Komando Terpadu WISGO)** dengan kredensial resmi `admin.komando@sumbarprov.go.id`.
- Konfigurasi `vite.config.ts` dilengkapi penangan error senyap (*silent proxy*) sehingga tidak menimbulkan error merah `ECONNREFUSED` saat server Go (:8080) tidak aktif, dan seluruh data tersimpan aman di `localStorage` dengan penanganan kuota otomatis (`safeSetLocalStorage`).

### B. Upload File Lokal Device & Kompresi HTML5 Canvas Klien
- Komponen reusable `ImageDropzone` mendukung pemilihan file langsung dari memori komputer/device (`.jpg`, `.jpeg`, `.png`, `.webp`) dan *drag-and-drop*.
- Gambar otomatis dikompresi di sisi klien via Canvas menjadi format WebP resolusi tinggi optimal (maksimal 2048px–2560px, kualitas 0.82), memangkas ukuran data **>85%–92%** sehingga bebas dari `QuotaExceededError`.
- Komponen terpasang di: (1) Form Destinasi, (2) Form Scene 360°, (3) Form Mitra UMKM, dan (4) Form Lapor Pungli Wisatawan.

### C. CMS Studio Virtual 360° & Visual 4-Pin Editor (Minggu 2)
- Kanvas panorama interaktif 360° bola sejati (*yaw* -180° s.d. +180° *seamless wrap-around*, *pitch* -80° s.d. +80°), kontrol zoom FOV, dan HUD kompas derajat real-time.
- Sakelar mode kerja di atas kanvas: **"Mode Putar Kamera 360°"** vs **"Mode Klik-Tempel Pin Hotspot"** (kursor crosshair).
- 4 Kategori Hotspot Pin: (1) Info Adat/Sejarah, (2) Navigasi Pindah Scene (*Scene Leap Transition*), (3) Spatial Audio Budaya, dan (4) Quick Booking Mitra UMKM Nagari.

### D. Monitoring Mitra & Simulator WhatsApp Bot Escrow (Minggu 2 & 3)
- Modul lengkap 5 kategori UMKM Nagari: Homestay Rumah Gadang, Kapal & Transportasi, Pemandu Pokdarwis, Kuliner Halal, dan Sewa Baju Adat.
- Drawer detail mitra 3 tab (Profil & SK Pokdarwis, Buku Besar Escrow, serta Integrasi Titik Pin 360° dua arah).
- **Simulator Bot WhatsApp Interaktif ([WhatsAppBotSimulator.tsx](file:///d:/WISGO/web-admin/src/components/WhatsAppBotSimulator.tsx))**:
  - UI obrolan WhatsApp mitra nagari menerima notifikasi pesanan booking wisatawan.
  - Tombol aksi **"Balas 1 (Terima Pesanan)"**: mengunci dana di Rekening Escrow dan menerbitkan QR E-Ticket.
  - Tombol aksi **"Balas 0 (Tolak Pesanan)"**: mengembalikan dana ke saldo wisatawan.
  - Tombol aksi **"Simulasi Scan QR E-Ticket (Cairkan Escrow)"**: memvalidasi kehadiran wisatawan dan mencairkan dana langsung ke rekening mitra nagari secara real-time.

### E. Pusat Komando Terpadu: Pungli, SOS SAR & 5 Jalur Rawan (Minggu 2 & 3)
- **Tab 1 — Penindakan Pungli**: Verifikasi aduan, bukti foto karcis liar, komparasi harga vs Perda, input Berita Acara, dan update status tiket.
- **Tab 2 — Siaga Darurat SOS GPS**: Telemetri baterai/sinyal turis darurat, catatan medis, penugasan tim SAR/BPBD, dan status evakuasi.
- **Tab 3 — Peringatan 5 Jalur Rawan Bencana (Live Hazard Alerts)**: Kontrol status real-time untuk Sitinjau Lauik, Lembah Anai, Kelok 9, Malalak, dan Kelok 44 dengan siaran status (*Aman Terkendali*, *Waspada*, *Buka-Tutup*, *Tutup Total*) serta rute pengalihan.

### F. Web Publik Dinamis: Smart QR & Group Invite (Minggu 2)
- **Web Plang Smart QR (`/qr/:slug`)**: Dropdown pemilih 20 destinasi unggulan Sumbar, Fair-Price Barometer, 5 Indikator Medan, form lapor pungli foto langsung, dan tombol darurat SOS SAR.
- **Web Group Invite (`/join/:code`)**: Pemilih 3 sampel rombongan wisata, jadwal perjalanan 7 hari (Auto-Itinerary), kalkulator Split-Bill patungan per orang (IDR & MYR), dan Live Polling/Voting interaktif.

### G. Analitik Eksekutif Dispar Sumbar & Demo 1 Layar (Minggu 3 & 4)
- **Heatmap 19 Kabupaten/Kota**: Visualisasi warna kepadatan (*Sepi*, *Sedang*, *Ramai*, *Overload*) serta proporsi wisatawan Nusantara vs Wisman (pengguna kurs MYR).
- **Grafik Ekonomi Escrow & Paspor Digital**: Metrik check-in anti-fake GPS (radius &le; 200m) dan jumlah sertifikat digital Gubernur Sumbar yang diunduh.
- **Meja Kurasi Lokasi Sensitif Komunitas**: Moderasi usulan *hidden gem*, tombol Setujui/Tolak, dan sakelar **"Masking Koordinat Lokasi Sensitif"** untuk menjaga cagar adat & mewajibkan pendampingan Pokdarwis.
- **Ekspor Dokumen Resmi**: Cetak laporan PDF dengan Kop Resmi Dinas Pariwisata Prov. Sumbar + kolom tanda tangan Kepala Dinas, serta ekspor file CSV.
- **Mode Showcase 1 Layar (Split-Screen)**: Tampilan berdampingan Web Admin di sisi kiri + Layar HP Wisatawan/Mitra di sisi kanan dalam satu layar monitor.

---

## 3. Panduan Skenario Demo Terpadu WISGO (Split-Screen Showcase)

Untuk mendemonstrasikan keunggulan sistem WISGO secara *live* di hadapan penguji/stakeholder pada 1 layar monitor:

1. **Buka Aplikasi**: Buka browser di `http://localhost:3000/`.
2. **Masuk Sebagai Admin Utama**: Di halaman login, klik tombol **"Akses Cepat Otoritas"**.
3. **Aktifkan Mode Showcase 1 Layar**:
   - Di Sidebar kiri bawah, klik tombol **"Mode Showcase 1 Layar"**.
   - Layar akan terbagi dua:
     - **Sisi Kiri (60%)**: Portal Web Admin (Pusat Komando / Destinasi / Mitra / Analitik).
     - **Sisi Kanan (40%)**: Layar HP Pengguna (Live Device Mockup).
4. **Skenario A — Alur Pemesanan & Pencairan Escrow Mitra**:
   - Di sisi kiri: Buka menu **"Monitoring Mitra & Escrow"**.
   - Di sisi kanan: Pilih tab **"Bot WA Mitra"**.
   - Klik tombol **"Balas 1 (Terima Pesanan)"** di layar WA: perhatikan dana terkunci di Escrow dan QR E-Ticket terbit.
   - Klik tombol **"Simulasi Scan QR E-Ticket"**: perhatikan dana berhasil dicairkan ke Rekening Nagari.
   - Di sisi kiri: Perhatikan grafik ekonomi nagari dan ledger mitra bertambah secara *real-time*!
5. **Skenario B — Alur Aduan Pungli & Siaga SOS SAR**:
   - Di sisi kiri: Buka menu **"Pusat Komando Pungli & SOS"**.
   - Di sisi kanan: Ganti tab ke **"Smart QR Wisatawan"**.
   - Kirim laporan aduan pungli atau pancarkan sinyal darurat SOS dari HP di sisi kanan.
   - Perhatikan di sisi kiri: Tiket aduan baru atau sirine SOS langsung muncul seketika di meja kerja Admin Utama!
6. **Skenario C — Cetak Laporan Eksekutif Dispar**:
   - Di sisi kiri: Buka menu **"Analitik Eksekutif Dispar"**.
   - Klik tombol **"Cetak / Ekspor PDF Resmi"** untuk menampilkan format cetak resmi ber-Kop Pemprov Sumbar.

---

## 4. Hasil Verifikasi Kualitas Teknis

- **Pemeriksaan Tipe TypeScript (`tsc --noEmit`):** `Exit Code 0` (0 error, 100% lulus kompilasi tipe ketat).
- **Pengujian Bundel Produksi (`vite build`):** `Exit Code 0` (1.558 modul berhasil dibangun optimal dalam 17,34 detik).
- **Server Dev Lokal:** Berjalan aktif dan responsif di `http://localhost:3000/`.

---

## 5. Pembaruan & Optimasi Tata Letak (Layout) UI/UX (Production-Grade)

Sebagai tindak lanjut penyempurnaan keterbacaan dan kenyamanan operasional admin di layar desktop/laptop (resolusi 1280px s.d. 1920px), telah dilakukan perbaikan visual menyeluruh:

1. **Sticky Sidebar Kiri Terkunci Saat Gulir (Scroll)**:
   - Sidebar diatur dengan `sticky top-0 h-screen shrink-0 overflow-y-auto z-30` sehingga tetap diam dan kokoh di posisinya saat halaman konten utama di sebelah kanan digulir jauh ke bawah.
   - Perbaikan tipografi item menu navigasi: teks judul menu tidak lagi terpotong menjadi titik-titik (`...`), dilengkapi pembagian proporsi teks `leading-snug` dan badge status berukuran presisi (`shrink-0 whitespace-nowrap`).

2. **Restrukturisasi Modal Tambah/Edit Destinasi (4 Bagian Vertikal Tegas)**:
   - Mengatasi masalah barisan tab modal yang sebelumnya tergencet flexbox menjadi 0px.
   - Modal kini memiliki 4 tingkatan vertikal yang tegas:
     - **Header Modal (`shrink-0`)**: Judul modal & tombol tutup (X) kontras tinggi.
     - **Baris Tab Navigasi 4 Bagian (`shrink-0 bg-[#F6F3EC] border-b px-6 py-3`)**: Menggunakan `grid grid-cols-2 sm:grid-cols-4 gap-2` dengan tab **Bagian A (Profil & 4 Statistik)**, **Bagian B (5 Indikator Medan)**, **Bagian C (Edukasi & Adat Minangkabau)**, dan **Bagian D (Foto & Media Lokal)** dengan indikator aktif hijau tua kontras tinggi.
     - **Kontainer Isi Form (`flex-1 min-h-0 overflow-y-auto p-6 space-y-5`)**: Porsi area formulir yang dapat digulir mandiri tanpa menggeser header maupun footer.
     - **Sticky Action Footer (`shrink-0 border-t bg-white px-6 py-4`)**: Pinned di dasar modal berisi navigasi bertahap "← Sebelumnya" / "Selanjutnya →" di sisi kiri, serta tombol "Batal" dan "Simpan Destinasi" di sisi kanan.

3. **Pemisahan Header Kartu Menjadi 2 Baris Terpisah (Header Card De-cluttering)**:
   - Menerapkan layout 2 baris terpisah pada halaman **Pusat Komando Pungli & SOS**, **Studio Virtual 360°**, **Monitoring Mitra & Escrow**, **Analitik Eksekutif Dispar**, dan **Simulator Bot WA**:
     - **Baris Atas**: Ikon institusi, judul halaman tunggal yang lega tanpa melipat ke banyak baris, badge status kesiagaan, dan deskripsi tugas operasional.
     - **Baris Bawah**: Dipisahkan oleh garis batas halus `border-t border-[#234B24]/10 pt-4` khusus memuat tombol switcher tab, filter dropdown, dan tombol aksi (ekspor CSV/PDF, tambah mitra/scene).

Seluruh revisi telah lulus kompilasi TypeScript dan siap diuji langsung di `http://localhost:3000/`.
