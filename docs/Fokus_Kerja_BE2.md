# 📋 PANDUAN FOKUS KERJA & LIVING CONTRACT — BE-2
# Ekosistem Wisata Pintar Sumatera Barat (Rancak.in)

> **Status Dokumen**: *Living Document* (Dapat diperbarui sewaktu-waktu mengikuti kesepakatan integrasi tim).  
> **Terakhir Diperbarui**: 2026-11-23  
> **Pemegang Peran**: **BE-2 (Backend 2 — Grup, Mitra, Escrow & Gamifikasi)**  
> **Branch Git**: `Backend-2`  
> **Direktori Kerja Utama**: [`backend/internal/modules/`](file:///D:/WISGO/backend/internal/modules/) (Clean Architecture Vertical Slices)  
> **Stack Teknologi**: Go 1.22+ (Gin Web Framework v1.10.0) + PostgreSQL

---

## 01. Batasan Tanggung Jawab (Zero Merge Conflict)

Untuk menjaga prinsip zero merge conflict dan konsistensi arsitektur sistem:
- **Arsitektur Modul Terpadu**: Seluruh modul backend kini terstandarisasi di folder [`backend/internal/modules/`](file:///D:/WISGO/backend/internal/modules/), [`backend/internal/common/`](file:///D:/WISGO/backend/internal/common/), [`backend/internal/middleware/`](file:///D:/WISGO/backend/internal/middleware/) dengan arsitektur 3-Layer (DTO, Repository, Service, Handler) dan test suite lengkap.
- **Area Eksklusif BE-2**: Modul `auth`, `partner`, `itinerary`, `group`, `booking_escrow`, `community`, `gamification`, `analytics`.
- **Modul Domain BE-1 (Direfaktor & Teruji)**: Modul `destination`, `scenes360`, `spatial`, `pungli`, `culture_ranking`, `system_core`.
- **Area Bersama (Terpusat)**: 
  - [`backend/cmd/api/main.go`](file:///D:/WISGO/backend/cmd/api/main.go) (Registrasi route terpadu v1 Gin)
  - [`backend/internal/models/models.go`](file:///D:/WISGO/backend/internal/models/models.go) (Entitas domain backend)
  - [`backend/internal/database/db.go`](file:///D:/WISGO/backend/internal/database/db.go) (Pool koneksi PostgreSQL)
- **Status Legacy Code**: Folder `backend/internal/be1_core/` dan `backend/internal/be2_group/` telah sepenuhnya dihapus dan dimigrasi secara aman tanpa regresi.

---

## 02. Log Perubahan Fitur & Sinkronisasi Tim (Change Log)

*Tabel ini wajib diperbarui setiap kali ada penyesuaian request endpoint atau payload dari rekan tim (FE-2, FS-1, atau BE-1).*

| Tanggal | Fitur / Endpoint Terdampak | Rekan Terkait | Ringkasan Perubahan & Alasan | Status |
| :--- | :--- | :--- | :--- | :--- |
| 2026-11-13 | Inisialisasi Kontrak 24 Endpoint | Tim 5 Dev | Pemetaan awal sesuai PRD v1.0 & API Contract | **Aktif** |
| 2026-11-13 | Penyelesaian Sprint Minggu 3 (Escrow & WA Bot) | BE-2 | Integrasi Escrow state machine, Bot WA 1/0, Split-bill, & Group Radar (18 Unit Tests PASS) | **Selesai 100%** |
| 2026-11-13 | Penyelesaian Sprint Minggu 4 & Finalisasi Kontrak 24 Endpoint | BE-2 | Integrasi Paspor Digital Minang (Haversine Anti-Fake GPS <= 200m), Sertifikat Gubernur Sumbar & Analitik Dispar 19 Kab/Kota (22 Unit Tests PASS) | **Selesai 100% (Final)** |
| 2026-11-13 | Refactoring Clean Architecture & Gin Framework (BE-2) | BE-2 | Refactoring menyeluruh modul BE-2 ke Gin Framework v1.10.0 dengan 3-Layer Architecture (DTO, Repo, Service, Handler) terbagi dalam 8 modul vertikal terisolasi. 52 Unit Tests PASS 100%. | **Selesai 100% (Production-Ready)** |
| 2026-11-15 | Refactoring Menyeluruh Modul BE-1 ke Clean 3-Layer Gin (Tahap 1 - 8) | BE-1 & BE-2 | Eksekusi bertahap migrasi BE-1: Tahap 1 (Security/JWT/Rate-Limiter/Cache ETag), Tahap 2 (`destination`), Tahap 3 (`scenes360`), Tahap 4 (`spatial`/Shunlu/Hazard/SOS), Tahap 5 (`pungli`), Tahap 6 (`culture_ranking`/Gaode/Kato Nan Ampek), Tahap 7 (`system_core`/Benchmark SLA/Catalog), Tahap 8 (Pembersihan legacy `be1_core/` & migrasi DDL). 100% Unit Tests PASS di seluruh package (`go test ./...`) dan `go build ./...` Exit Code 0. | **Selesai 100% (Production-Ready)** |
| 2026-11-15 | Audit Menyeluruh Fitur Backend & Sinkronisasi Kontrak API Lengkap | Tim BE & FE | Pengujian komprehensif end-to-end seluruh 48 endpoint BE-1 dan BE-2. Menemukan dan menuntaskan 17 potensi ketidaksesuaian/bug (route alias kontrak, anti-fake GPS validator bug pada equator 0.0, perbaikan ID mapping, dan implementasi endpoint hilang seperti /nearby & /optimize-tsp). Seluruh unit test PASS 100% (0 errors). | **Selesai 100% (Verified)** |
| 2026-11-16 | Sentralisasi Database ke Supabase PostgreSQL + PostGIS Cloud & Strict Guard | Tim 5 Dev | Migrasi penuh seluruh 27 tabel BE-1 & BE-2 ke Supabase PostgreSQL Cloud terpusat (Singapore ap-southeast-1 Pooler). Implementasi PostgreSQL Repository Layer untuk seluruh modul BE-2 (`auth`, `booking_escrow`, `partner`, `itinerary`, `group`, `community`, `gamification`) dan modul utama BE-1 (`destination`). Menambahkan `DatabaseGuardMiddleware` strictly offline handler (HTTP 503 jika koneksi terputus, no phantom mock). `go build ./...` Exit Code 0 & 100% PASS Unit Test. | **Selesai 100% (Production-Ready)** |
| 2026-11-18 | Fondasi Auth WhatsApp OTP, In-Memory Session, & Profile Reactivity | BE-2 & FE-2 | Implementasi multi-agent teamwork fondasi autentikasi: (1) Backend Go normalisasi nomor Indonesia E.164 (`628...`), cryptographic random 4-digit OTP dengan TTL 300s & anti-replay, visual console banner `[AUTH OTP]`, bypass whitelist QA (`1234` & `2486`); (2) Flutter in-memory zero-dependency session (`ApiConfig.authNotifier` & `UserProfile`); (3) Integrasi UI `LoginScreen` & `OtpVerificationScreen` tap-to-autofill banner; (4) Surgical wrap reaktif di `SavedPlacesScreen._buildProfileView()` (Guest Mode vs Mode Terverifikasi tanpa reload). 100% PASS Unit & Widget Tests di backend dan mobile. | **Selesai 100% (Production-Ready)** |
| 2026-11-21 | Penerapan Skema DBML v2 Baru (Safe Evolutionary Migration) ke Supabase Cloud | BE-1 & BE-2 | Sukses menerapkan migrasi `000003_v2_new_schema.sql` ke Supabase Cloud: (1) Master `categories` terpusat (22 core categories seeded across 5 modules); (2) Ulasan terverifikasi GPS `destination_reviews` dengan integritas `stemp_visit_id`; (3) Sistem misi gamifikasi dinamis `challenges` & `challenge_destinations` & `user_challenge_rewards`; (4) Tabel offline `offline_bundles`, `api_telemetry_logs`, `emergency_contacts`, `notifikasi`, `visit_point`, `open_trips`, `new_tour`, `aturan_destinasi`, `indikator_medan`; (5) Backward-compatible penuh, 0 broken code di Go (100% PASS Unit Tests) dan 0 breaking changes untuk Frontend. Total 42 tabel terverifikasi di Supabase. | **Selesai 100% (Live on Supabase)** |
| 2026-11-21 | Eksekusi Fase 2: Migrasi Kueri Repositori Backend Go ke Tabel Baru v2 | BE-2 | Sukses mengalihkan kueri repositori backend Go ke tabel-tabel baru v2 di Supabase: (1) `community`: kueri dialihkan dari `community_places` ke `new_tour` (dengan JOIN `categories`) & `shared_trips` ke `open_trips`; (2) `gamification`: kueri dialihkan dari `digital_passports` ke `stemp_visit`; (3) `destination`: relasi dialihkan dari `medan_indicators` ke `indikator_medan` & `local_tips` ke `aturan_destinasi` (dengan JOIN `categories`); (4) Seeder destinasi menyinkronkan kedua versi tabel. Seluruh 22/22 unit tests PASS 100% dan `go build ./...` Exit Code 0. | **Selesai 100% (Production-Ready)** |
| 2026-11-21 | Eksekusi Fase 3: Contract & Cleanup Tabel Legacy di Supabase Cloud | BE-1 & BE-2 | Sukses mengeksekusi migrasi `000004_v2_contract_cleanup.sql` di Supabase Cloud: Menghapus 7 tabel legacy (`medan_indicators`, `local_tips`, `shunlu_pois`, `digital_passports`, `community_places`, `shared_trips`, `scenic_micro_maps`) secara bersih (CASCADE). Skema Supabase kini ramping, terstruktur rapi dengan 35 tabel aktif (26 tabel DBML baru + tabel relasi + klaster rombongan & escrow BE-2). Seluruh unit tests 100% PASS dan `go build ./...` Exit Code 0. | **Selesai 100% (Production-Clean)** |
| 2026-11-21 | Penyesuaian Scope Proyek: Penghapusan Klaster Rombongan & Escrow (Presisi 26 Tabel DBML) | Tim 5 Dev | Sesuai kesepakatan tim, Klaster Rombongan (`group_rooms`, `group_members`, `group_votes`), Itinerary (`itineraries`, `itinerary_items`), dan Escrow & Mitra (`partners`, `booking_escrows`) resmi ditiadakan dari scope proyek. Tabel di-drop dari Supabase dan rutenya dinonaktifkan di API. Database Supabase kini 100% presisi menyisakan 26 tabel murni DBML (+1 tabel sistem PostGIS). `go build ./...` Exit Code 0 & 100% PASS Unit Tests. | **Selesai 100% (Aligned 26 Tables)** |
| 2026-11-21 | Penggabungan (Merge) origin/dev ke Backend-2 & Penyelarasan Penuh ERD v2 | Tim 5 Dev | Berhasil menggabungkan branch `origin/dev` ke `Backend-2` (Commit `348e05b`). Menyelesaikan seluruh 8 titik merge conflict: (1) `auth` (DTO, Handler, Service dengan variadic options, support role tourist/vendor, dev bypass QA & anti-replay); (2) `destination` (resilient query indikator_medan & aturan_destinasi v2 dengan fallback); (3) `mobile` (UI Frosted Glassmorphism, Google Sign-In, OtpVerification, QrisPayment offline fallback, dan SavedPlaces multi-bahasa Minang dari FE). Verifikasi kompilasi `go build ./...` Exit Code 0 dan 100% Unit Tests PASS. | **Selesai 100% (Merged & Synchronized)** |
| 2026-11-21 | Peresmian Squad 8 Agen Terpadu BE-2 & Single File Ownership Matrix | BE-2 | Sukses mendefinisikan dan mengaktifkan protokol 8 Agen Terpadu BE-2 (PM Analyst, Architect, Logic Engineer, DB Specialist, Shadow FE, QA Bug Hunter, Security Guard, Tech Lead) dengan Single File Ownership Matrix dan Staged Wave Pipeline untuk menjamin Zero Merge Conflict & Zero Bug. Protokol tersimpan di `docs/BE2_Squad_8_Agents_Protocol.md`. | **Aktif & Siap Tempur** |
| 2026-11-22 | Penyelarasan Final Endpoint & Database (Scope Cleanup) | BE-2 & Tim | Konfirmasi resmi kesepakatan tim atas penghapusan 3 klaster fitur (Private Group Room, Smart Trip Planner 7 Hari, Mitra Nagari & Escrow). Merapikan router `backend/cmd/api/main.go` dan matriks dokumen BE-2: mengklasifikasikan secara tegas 10 Endpoint Aktif (Live di Supabase 26 tabel) vs 14 Endpoint Non-Aktif / Archived (kode Go utuh di internal/modules/ tetapi tabel di-drop via 000004_v2_contract_cleanup.sql). | **Selesai 100% (Terdokumentasi Rapi)** |
| 2026-11-22 | Integrasi Tahap 1: Autentikasi OTP WhatsApp & Sesi JWT Flutter ↔ Go | BE-2 & FE-2 | Eksekusi Squad Multi-Agen (VICTORY CONFIRMED): (1) `login_screen.dart` terhubung ke `ApiService.requestOtp()` dengan mode Strict Real-Only & anti-double-tap loading; (2) `otp_verification_screen.dart` terhubung ke `ApiService.verifyOtp()` dengan mode manual terminal log OTP, penyimpanan token JWT/profil ke `ApiConfig.setAuthSession()`, dan SnackBar sukses ke `SavedPlacesScreen`; (3) Zero boundary conflict (web-admin & be1_core 100% clean); (4) 100% PASS Go tests (16/16), Flutter analyze (0 issues), & Flutter tests (19/19). | **Selesai 100% (Production-Verified)** |
| 2026-11-23 | Perbaikan Alur Logout & Guest Mode Flutter (Anti-App-Termination di Windows Desktop) | BE-2 & FE-2 | Eksekusi Squad Multi-Agen: (1) Dialog konfirmasi 'Keluar' di `saved_places_screen.dart` memanggil `ApiService.logout()` secara atomik untuk membersihkan `ApiConfig.authToken` dan `currentUser`; (2) Menghilangkan navigasi destruktif `pushAndRemoveUntil(SplashScreen)` yang menyebabkan crash/exit pada desktop Windows; (3) State Profil beralih mulus ke Guest Mode (`_isGuestMode = true`) dengan menampilkan floating SnackBar sukses dan tombol 'Masuk ke Akun WISGO' menuju `LoginScreen`; (4) Menghilangkan 2 warning linter (`qris_payment_sheet.dart` & `destination_adapter.dart`), `flutter analyze` exit 0 (0 issues); (5) Verifikasi menyeluruh: 100% PASS Go backend build & tests, serta 22/22 Flutter tests lulus tanpa regresi. | **Selesai 100% (Production-Verified)** |
| 2026-11-23 | Pemetaan Kerja BE-1 & BE-2 Sinkron FE Terbaru (13 Catatan Revisi) | BE-1 & BE-2 | Perumusan dokumen teknis panduan resmi `docs/Pemetaan_Kerja_BE1_BE2_Sinkron_FE.md` yang menyinkronkan 13 Catatan Revisi dengan 4 Tab FE Flutter (`SavedPlacesScreen`), matriks kepemilikan tabel DBML v2 Supabase, kontrak sinergi data BE-1 ➔ BE-2, dan acceptance criteria terukur. 100% Zero Merge Conflict. | **Dokumen Resmi Aktif** |
| 2026-11-23 | Auth Guard Interaktif Flutter & Hardening Sesi Backend Go | BE-2 & FE-2 | Implementasi Auth Guard Interaktif (`AuthGuard.check()` bottom sheet khas Minangkabau radius 28px palet forest/cream/terracotta) pada 3 fitur kunci Flutter: (1) Paspor Minang (GPS check-in & Sertifikat Gubernur); (2) Usulan Destinasi (autofill nama/kontak & submit guard); (3) Saved Places (bookmark offline instant, notifikasi ajakan cloud sync, & reaktivitas sesi). Serta hardening backend Go (`/gamification/checkin`, `/users/saved`, `/destinations/hidden-gem`) menolak request tanpa `user_id` yang valid. Zero merge conflict, 15/15 Go test packages PASS, `flutter analyze` 0 issues, dan 28/28 Flutter tests PASS. | **Selesai 100% (VICTORY CONFIRMED)** |
| 2026-11-23 | Perbaikan Crash Fatal Siklus "Login -> Logout -> Re-Login" Flutter | BE-2 & FE-2 | Investigasi & perbaikan tuntas crash saat re-login: (1) Mengganti destruktif `pushAndRemoveUntil((route) => false)` di `otp_verification_screen.dart` dan `login_screen.dart` dengan alur pop gracefully `canPop() ? pop(true) : pushReplacement()`, menjaga integritas root navigation tree; (2) Menambahkan safety guard `if (!mounted) return;` pada callback async `DigitalPassportSheet` (`_verifyGpsCheckIn` & `_showDigitalCertificateModal`) dan `UsulDestinasiSheet` untuk mencegah `setState() called after dispose`; (3) Menjaga navigator context di `AuthGuardDialog`; (4) Menambahkan test suite `relogin_crash_test.dart` (3 cycles PASS). 100% PASS Go backend (15 pkgs), `flutter analyze` 0 issues, dan 31/31 Flutter tests PASS. | **Selesai 100% (Production-Verified)** |
| 2026-11-24 | Penyelesaian Siklus Penuh Open Trip (`GET`, `POST`, `JOIN`, `DELETE`) | BE-2 & FE-2 | Menambahkan endpoint `POST /api/v1/community/shared-trips/:id/join` (pengurangan `available_seats` atomik di PostgreSQL & in-memory mutex, validasi user_id/host/kuota) dan `DELETE /api/v1/community/shared-trips/:id` (penghapusan khusus host dengan validasi 400/403/404) beserta unit test lengkap di modul `community`. | **Selesai 100% (Verified)** |

---

## 03. Kepemilikan 12 Tabel Database PostgreSQL & Status Supabase v2

| No | Nama Tabel Asal | Status di Supabase Cloud v2 | Keterangan & Tindakan Arsitektural |
| :---: | :--- | :---: | :--- |
| 1 | `users` | ✅ **Aktif (Live)** | Tabel akun wisatawan, nomor HP, peran, dan kolom baru `jenis_input`. |
| 2 | `saved_places` | ✅ **Aktif (Live)** | Tabel destinasi favorit/bookmark wisatawan. |
| 3 | `community_places`| 🔄 **Berevolusi ke v2** | Digantikan oleh tabel PostGIS [`new_tour`](file:///d:/WISGO/backend/migrations/000003_v2_new_schema.sql) & `destination_reviews`. |
| 4 | `shared_trips` | 🔄 **Berevolusi ke v2** | Digantikan oleh tabel [`open_trips`](file:///d:/WISGO/backend/migrations/000003_v2_new_schema.sql) untuk papan cari barengan / tebengan. |
| 5 | `digital_passports`| 🔄 **Berevolusi ke v2** | Digantikan oleh tabel [`stemp_visit`](file:///d:/WISGO/backend/migrations/000003_v2_new_schema.sql), `challenges`, dan `user_challenge_rewards`. |
| 6 | `itineraries` | ❌ **Non-Aktif / Di-Drop** | Di-drop dari Supabase via `000004_v2_contract_cleanup.sql` per konsensus 26 tabel murni DBML. |
| 7 | `itinerary_items` | ❌ **Non-Aktif / Di-Drop** | Di-drop dari Supabase via `000004_v2_contract_cleanup.sql` per konsensus 26 tabel murni DBML. |
| 8 | `group_rooms` | ❌ **Non-Aktif / Di-Drop** | Di-drop dari Supabase via `000004_v2_contract_cleanup.sql` per konsensus 26 tabel murni DBML. |
| 9 | `group_members` | ❌ **Non-Aktif / Di-Drop** | Di-drop dari Supabase via `000004_v2_contract_cleanup.sql` per konsensus 26 tabel murni DBML. |
| 10 | `group_votes` | ❌ **Non-Aktif / Di-Drop** | Di-drop dari Supabase via `000004_v2_contract_cleanup.sql` per konsensus 26 tabel murni DBML. |
| 11 | `partners` | ❌ **Non-Aktif / Di-Drop** | Di-drop dari Supabase via `000004_v2_contract_cleanup.sql` per konsensus 26 tabel murni DBML. |
| 12 | `booking_escrows` | ❌ **Non-Aktif / Di-Drop** | Di-drop dari Supabase via `000004_v2_contract_cleanup.sql` per konsensus 26 tabel murni DBML. |

> **Catatan Integritas Data**: Seluruh kode Go DTO, repository, service, handler, dan unit test untuk ke-7 tabel yang di-drop tetap tersimpan utuh di [`backend/internal/modules/`](file:///d:/WISGO/backend/internal/modules/) untuk kemudahan reaktivasi jika scope diaktifkan kembali.

---

## 04. Matriks Status 24 Endpoint REST API (Kontrak Kerja BE-2)

### 🟢 KELOMPOK 1: ENDPOINT AKTIF (Live di Router `main.go` & Supabase Cloud)
*Seluruh endpoint ini berstatus produksi, aktif terdaftar di router Gin, dan terhubung langsung ke skema 26 tabel Supabase v2:*

#### A. Klaster Autentikasi & Simpan Tempat (Pilar 4 & 5 — Modul `auth`)
- [x] `POST /api/v1/auth/request-otp` — Normalisasi nomor E.164 (`628...`), cryptographic random 4-digit OTP dengan TTL 300s & anti-replay.
- [x] `POST /api/v1/auth/verify-otp` — Verifikasi kode OTP, pemusnahan kode, dan cetak JWT Bearer token (tourist/vendor).
- [x] `POST /api/v1/auth/refresh-token` — Perpanjang masa berlaku token autentikasi JWT wisatawan.
- [x] `GET /api/v1/auth/me` — Ambil profil lengkap wisatawan aktif dari tabel `users`.
- [x] `GET /api/v1/users/saved` — Ambil daftar destinasi tersimpan wisatawan dari tabel `saved_places`.
- [x] `POST /api/v1/users/saved` & `POST /api/v1/users/saved/:destination_id` — Toggle simpan/hapus tempat favorit.

#### B. Klaster Komunitas & Cari Barengan (Pilar 6 — Modul `community`)
- [x] `POST /api/v1/community/places` — Pengajuan tempat wisata baru / hidden gem ke tabel `new_tour` (PostGIS `geom_point` + sanitasi).
- [x] `GET /api/v1/community/places` — Ambil daftar tempat wisata komunitas terkurasi.
- [x] `POST /api/v1/shared-trips` (alias `/api/v1/community/shared-trips`) — Pasang ajakan tebengan armada ke tabel `open_trips`.
- [x] `GET /api/v1/shared-trips` (alias `/api/v1/community/shared-trips`) — Ambil feed tebengan armada aktif.

#### C. Klaster Gamifikasi Paspor Minang & Sertifikat (Pilar 6 — Modul `gamification`)
- [x] `GET /api/v1/gamification/spots` — Ambil daftar spot bersejarah untuk misi stempel Paspor Minang.
- [x] `POST /api/v1/gamification/check-in` — Validasi stempel check-in GPS $\le 200\text{ m}$ (Anti-Fake GPS) ke tabel `stemp_visit`.
- [x] `GET /api/v1/gamification/passport/:userId` — Rekapitulasi perolehan stempel digital paspor wisatawan.
- [x] `GET /api/v1/gamification/certificate/:userId` — Penerbitan dan klaim Sertifikat Digital Resmi Gubernur Sumbar.

#### D. Klaster Analitik Eksekutif Dispar (Pilar 8 — Modul `analytics`)
- [x] `GET /api/v1/analytics/dispar/heatmaps` (alias `/api/v1/analytics/dispar/summary`) — Agregasi metrik kepadatan wisatawan 19 Kab/Kota dan perputaran ekonomi UMKM.

---

### ⚪ KELOMPOK 2: ENDPOINT NON-AKTIF / ARCHIVED (Ditiadakan Mengikuti Kesepakatan Scope DBML v2)
*Seluruh logika Go telah selesai 100% dan lulus unit test di `backend/internal/modules/*`, namun rutenya sengaja dinonaktifkan di `main.go` karena tabel fisiknya di-drop dari Supabase Cloud untuk memenuhi kuota presisi 26 tabel murni:*

#### E. Klaster Private Group Room (Pilar 4 — Modul `group`) — Non-Aktif
*Tabel terkait (`group_rooms`, `group_members`, `group_votes`) telah di-drop via `000004_v2_contract_cleanup.sql`.*
- [ ] `POST /api/v1/groups` — Buat Group Room baru & terbitkan `room_code` tautan WhatsApp.
- [ ] `GET /api/v1/groups/{code}` — Ambil info rombongan, leader, dan anggota.
- [ ] `POST /api/v1/groups/{code}/join` — Gabung ke ruang rombongan via tautan link WA.
- [ ] `POST /api/v1/groups/{code}/vote` — Submit voting destinasi/homestay live.
- [ ] `GET /api/v1/groups/{code}/results` (alias `/votes`) — Rekapitulasi voting persentase real-time.
- [ ] `POST /api/v1/groups/{code}/split-bill` — Kalkulator bagi rata tagihan (homestay/sewa mobil).
- [ ] `POST & GET /api/v1/groups/{code}/radar` — Menerima ping lokasi koordinat anggota & monitor Group Radar.

#### F. Klaster Smart Trip Planner 7 Hari (Pilar 4 — Modul `itinerary`) — Non-Aktif
*Tabel terkait (`itineraries`, `itinerary_items`) telah di-drop via `000004_v2_contract_cleanup.sql`.*
- [ ] `POST /api/v1/itineraries/auto-generate` — Generator itinerary pintar sesuai preferensi rombongan.
- [ ] `GET /api/v1/itineraries` — Riwayat rencana trip pengguna.
- [ ] `POST /api/v1/itineraries` — Simpan rencana trip 7 hari manual.

#### G. Klaster Mitra Nagari, Quick Booking & Escrow (Pilar 5 — Modul `partner` & `booking_escrow`) — Non-Aktif
*Tabel terkait (`partners`, `booking_escrows`) telah di-drop via `000004_v2_contract_cleanup.sql`.*
- [ ] `GET /api/v1/partners` — Katalog mitra 5 kategori (+ level pedas kuliner).
- [ ] `GET /api/v1/partners/detail` (alias `/:id`) — Detail profil mitra & tarif resmi paket.
- [ ] `POST /api/v1/bookings/create` (alias `/api/v1/escrow/bookings`) — Booking via Quick Drawer 360° (Dana dikunci di Escrow).
- [ ] `POST /api/v1/bookings/wa-webhook` — Simulator respon WhatsApp mitra (`1` Terima, `0` Tolak).
- [ ] `GET /api/v1/bookings/{id}/ticket-qr` — Terbitkan QR E-Ticket setelah dikonfirmasi mitra.
- [ ] `POST /api/v1/escrow/scan-redeem` — Scan QR oleh mitra saat tamu tiba untuk pencairan dana.
- [ ] `GET /api/v1/escrow/currency/myr-rate` — Kurs konversi MYR ke IDR (Wisatawan Malaysia).

---

## 05. Checklist Roadmap Sprint 4 Minggu

### 🚀 MINGGU 1 (Fondasi & Auth) — Target Selesai 100%
- [x] Setup skrip DDL SQL untuk 12 tabel BE-2 (termasuk 4 tabel utama: `users`, `saved_places`, `itineraries`, `partners` di `backend/migrations/000002_be2_schema.sql`).
- [x] Buat data seeder untuk 5 kategori mitra nagari (Homestay, Kuliner, Transport, Baju Adat, Pokdarwis di `backend/migrations/000002_be2_seeders.sql`).
- [x] Implementasi service & handler fungsional `RequestOTP` & `VerifyOTP` (Lolos Unit Test).
- [x] Implementasi endpoint `GET /api/v1/partners` & `GET /api/v1/partners/detail` (Lolos Unit Test).
- [x] Implementasi endpoint `GET & POST /api/v1/users/saved` (Lolos Unit Test).

### 📦 MINGGU 2 (Itinerary & Private Group Room) — Target Selesai 100%
- [x] Implementasi algoritma `POST /api/v1/itineraries/auto-generate` (Lolos Unit Test).
- [x] Implementasi alur Group Room (`POST /api/v1/groups` & `GET /api/v1/groups/detail`) (Lolos Unit Test).
- [x] Implementasi live voting rombongan (`/vote` & `/results`) (Lolos Unit Test).
- [x] Implementasi `POST /api/v1/community/places` dengan algoritma masking koordinat sensitif (Lolos Unit Test).

### 💰 MINGGU 3 (Escrow, Bot WhatsApp 1/0 & Split-Bill) — Target Selesai 100%
- [x] Implementasi state machine Escrow: `PENDING_WA` $\to$ `CONFIRMED` $\to$ `ESCROW_LOCKED` $\to$ `REDEEMED` / `REFUNDED` (Lolos Unit Test).
- [x] Implementasi Webhook Bot WhatsApp (`1` Terima, `0` Tolak) (Lolos Unit Test).
- [x] Integrasi Scan QR E-Ticket untuk pencairan dana escrow (`scan-redeem`) (Lolos Unit Test).
- [x] Implementasi logika Split-Bill rombongan dan feed Group Live Radar (Lolos Unit Test).
- [x] Implementasi Papan Shared Trips & konversi kurs MYR/IDR (Lolos Unit Test).

### 🏆 MINGGU 4 (Paspor Digital $\le 200\text{ m}$, Sertifikat & Analitik Dispar) — Target Selesai 100% (Final)
- [x] Validasi formula Haversine geofence $\le 200\text{ m}$ pada `gamification/checkin` (Anti-Fake GPS) (Lolos Unit Test).
- [x] Logika penentuan kelulusan 10 stempel & penerbitan sertifikat digital resmi Gubernur Sumbar (Lolos Unit Test).
- [x] Agregasi kueri analitik Dispar (total transaksi UMKM, heatmap kepadatan 19 Kab/Kota, scan QR) (Lolos Unit Test).
- [x] Uji performa & penutupan sprint 4 Minggu (22/22 Unit Tests PASS, Go Build Exit Code 0).

---

## 06. Protokol Manajemen Perubahan (Bila Ada Penyesuaian Tim)

Jika rekan tim meminta perubahan:
1. **Perubahan Field/JSON**: Perbarui struct di `models.go`, lalu catat perubahannya di tabel **02. Log Perubahan Fitur**.
2. **Penambahan Endpoint Baru**: Tambahkan ke sub-bab **04. Matriks 24 Endpoint REST API** dengan label `[Baru - Permintaan FE-2/FS-1]`.
3. **Konflik Scope**: Rujuk kembali ke batasan modular di sub-bab **01**. Pastikan tidak menimpa logika BE-1 di `be1_core/`.

