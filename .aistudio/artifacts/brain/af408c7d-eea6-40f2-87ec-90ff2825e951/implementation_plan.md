# Rencana Implementasi: Dokumen PDF Lengkap Minggu 1 – Minggu 4 (Unduh Otomatis `.pdf` + Pratinjau A4)
**Proyek**: Rancak.in (WISGO) — Aplikasi Wisata Sumatera Barat  
**Bagian Anda**: Backend 1 (`BE-1`: Peta, Tempat Wisata, Foto 360°, Anti-Pungli, Jalur Ekstrem & Budaya Minang)  
**Tujuan**: Menyediakan fitur **Download File PDF Lengkap (`Laporan_Lengkap_BE1_Rancakin_Minggu_1_4.pdf`) sekali klik** beserta **Layar Pratinjau Kertas A4** yang merangkum seluruh pekerjaan Minggu 1 sampai Minggu 4 lengkap dengan **gambar bagan 5 diagram visual** dan penjelasan bahasa sehari-hari yang mudah dimengerti.

---

## 1. Susunan 7 Bab di Dalam Dokumen PDF

Dokumen PDF dirancang berurutan seperti buku panduan/laporan rapi yang siap dibaca sendiri maupun diserahkan ke tim/dosen:

1. **Bab 1 — Sampul Laporan & Pembagian Tugas Tim (Supaya Tidak Bentrok)**
   - Penjelasan santai tentang peran Anda sebagai **BE-1** dan bagaimana pekerjaan Anda terhubung dengan **FE-1**, **FE-2**, **FS-1**, serta **BE-2**.
2. **Bab 2 — Rangkuman Pekerjaan Minggu 1 sampai Minggu 4 (Hari 1 s/d Hari 20)**
   - Ringkasan jelas per minggu:
     - **Minggu 1 (Hari 1–5)**: Server Go, keamanan login JWT, 4 tabel dasar wisata, dan data 20 tempat wisata Sumatera Barat.
     - **Minggu 2 (Hari 6–10)**: Foto keliling 360° dengan 4 jenis pin, tempat mampir searah (`+X menit`), peta jalan kaki dalam lokasi, dan lapor pungli anonim.
     - **Minggu 3 (Hari 11–15)**: Peringkat jujur dari kunjungan GPS (*Gaode*), peringatan bahaya 4 jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44), tombol darurat SOS, dan kamus suara bahasa Minang.
     - **Minggu 4 (Hari 16–20)**: Peta offline untuk daerah susah sinyal, memori cepat (*Cache ETag*) hemat kuota, penangkal spam (*Rate-Limiter*), dan tes kecepatan server ($<100\text{ ms}$).
3. **Bab 3 — Gambar Bagan ERD & Penjelasan 11 Tabel Database (Nama Tabel & Field Bahasa Indonesia)**
   - **Gambar Bagan Visual ERD**: Menampilkan kotak-kotak tabel beserta garis panah hubungannya (`1:1`, `1:N`) antara `destinasi_wisata` ke ke-10 tabel pendukung BE-1 dan 4 tabel batas milik BE-2.
   - **Tabel Rincian Kolom (Field)**: Menjelaskan arti setiap field dalam Bahasa Indonesia (`id_destinasi`, `nama_wisata`, `titik_koordinat_gps`, `bisa_masuk_mobil`, `kualitas_sinyal_hp`, `harga_resmi_rupiah`, dll.).
4. **Bab 4 — Gambar Bagan Class Diagram & Penjelasan 6 Bagian Kode Go BE-1**
   - **Gambar Bagan Visual Class Diagram**: Menampilkan susunan kotak komponen Go (`StatelessJWTMiddleware`, `TokenBucketRateLimiter`, `InMemoryTTLCache`, `HandlerBE1`, `RepositoryBE1`, `DomainEntitiesBE1`) lengkap dengan arah panah kerja samanya dan penjelasan fungsi di dalamnya.
5. **Bab 5 — Gambar Bagan Sequence Diagram (4 Cerita Alur Kerja Langkah demi Langkah)**
   - **Gambar Bagan Alur & Penjelasan Berurutan** untuk 4 skenario utama:
     1. Alur Buka Foto Keliling 360° & Memori Cepat (*Cache ETag*).
     2. Alur Kirim Laporan Pungli Anonim, Penangkal Spam & Penindakan Satgas.
     3. Alur Hitung Otomatis Peringkat Kunjungan GPS (*Gaode Ranking*).
     4. Alur Peringatan Bahaya Jalur Ekstrem (Sitinjau Lauik) & Tombol Darurat SOS.
6. **Bab 6 — Gambar Bagan Use Case (4 Pengguna) & Daftar Lengkap 24 Alamat API BE-1**
   - **Gambar Bagan Use Case**: Memetakan fitur apa saja yang bisa diakses oleh Wisatawan FE-1, Wisatawan FE-2, Admin Dispar FS-1, dan Petugas Satgas/BPBD FS-1.
   - **Tabel Katalog 24 API**: Daftar lengkap alamat endpoint (`/api/v1/...`), metode HTTP, siapa yang memakai, dan kegunaannya dalam bahasa sederhana.
7. **Bab 7 — Gambar Bagan Arsitektur Sistem 4 Lapisan & Ringkasan 32 Tes Otomatis**
   - **Gambar Bagan Arsitektur**: Aliran data dari Layar Aplikasi $\rightarrow$ Pintu Keamanan & Memori Cepat $\rightarrow$ Mesin BE-1 & BE-2 $\rightarrow$ Database PostGIS.

---

## 2. Cara Kerja Fitur Unduh PDF & Pratinjau Kertas A4

1. **Generator File `.pdf` Otomatis Sekali Klik (`src/utils/pdfReportGenerator.ts`)**:
   - Menggunakan pustaka `jspdf` untuk menggambar langsung teks, tabel rapi, kotak diagram berwarna (`#234B24` Hijau Rimba, `#1E9E5A` Hijau Daun, `#F6F3EC` Krem Kertas, `#E85D1A` Oranye), serta garis panah relasi ke dalam halaman PDF ukuran **A4 Portrait** beresolusi tajam (vektor).
   - Saat tombol **"Download PDF Lengkap (Minggu 1–4)"** diklik, browser langsung mengunduh file **`Laporan_Lengkap_BE1_Rancakin_Minggu_1_Sampai_4.pdf`**.
2. **Modal Pratinjau Dokumen Kertas A4 (`src/components/PdfReportPreviewModal.tsx`)**:
   - Menampilkan pratinjau lembaran kertas A4 langsung di layar lengkap dengan gambar bagan visual ke-5 diagram dan penjelasan tabelnya, sehingga Anda bisa memeriksa tampilannya terlebih dahulu sebelum menekan tombol unduh `.pdf`.

---

## 3. Rencana Perubahan File

1. **Instalasi Paket**: Menginstal `jspdf` melalui `install_applet_package`.
2. **`/src/utils/pdfReportGenerator.ts` (Baru)**: Mesin pembuat file `.pdf` multi-halaman ukuran A4 lengkap dengan gambar bagan visual 5 diagram (ERD, Class, Sequence, Use Case, Arsitektur) dan tabel penjelasan Minggu 1–4.
3. **`/src/components/PdfReportPreviewModal.tsx` (Baru)**: Komponen pratinjau lembaran dokumen A4 interaktif dengan tombol unduh `.pdf` sekali klik.
4. **`/src/components/ArchitectureDiagramsView.tsx` & `/src/App.tsx` (Update)**: Menambahkan tombol utama **"Download PDF Lengkap (Minggu 1–4)"** dan **"Pratinjau Dokumen A4"** pada bar atas aplikasi serta di halaman Studio Diagram.
