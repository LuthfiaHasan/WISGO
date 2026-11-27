# DOKUMEN MASTER IMPLEMENTATION PLAN
# FONDASI AUTENTIKASI PENGGUNA WISGO (RANCAK.IN)
## Integrasi WhatsApp OTP, Supabase Cloud PostgreSQL, & Koordinasi Multi-Agent (Teamwork)
### Iteration 2 Hardened Specification (Post-Verification Wave Consensus)

---

## DAFTAR ISI
1. [Ringkasan Eksekutif & Arsitektur Sistem](#1-ringkasan-eksekutif--arsitektur-sistem)
2. [Topologi Tim Multi-Agent & Pembagian Peran](#2-topologi-tim-multi-agent--pembagian-peran)
3. [Matriks Kepemilikan Berkas (Zero Merge Conflict Guardrails)](#3-matriks-kepemilikan-berkas-zero-merge-conflict-guardrails)
4. [Spesifikasi Teknis Rinci per Komponen (Hardened)](#4-spesifikasi-teknis-rinci-per-komponen-hardened)
   - [4.1 Backend Go Auth Foundation (BE-2)](#41-backend-go-auth-foundation-be-2)
     - A. Normalisasi Defensif Nomor Telepon (`phone.go`)
     - B. In-Memory OTP Cache TTL 300s & Cleanup Ticker (`repository.go`)
     - C. Generator Angka Acak Kriptografis 4 Digit & Console Logging
     - D. Dev Bypass Scoping & Anti-Account Takeover (`service.go`)
     - E. Perluasan DTO & Repository Interface (`dto.go` & `repository.go`)
   - [4.2 Flutter Core Session, State & Service](#42-flutter-core-session-state--service)
     - A. Model Data `UserProfile` (`user_profile.dart`)
     - B. State Sesi Reaktif & Atomik `ApiConfig` (`api_config.dart`)
     - C. Penyelarasan Rute & Helper `ApiService` (`api_service.dart`)
   - [4.3 Flutter Auth UI & Testing Banner](#43-flutter-auth-ui--testing-banner)
     - A. Integrasi `LoginScreen` dengan Sanitasi Defensif
     - B. Integrasi `OtpVerificationScreen` dengan Testing Banner Interaktif
   - [4.4 Flutter Profile Reactivity & Guest/Auth Mode (Surgical Wrap)](#44-flutter-profile-reactivity--guestauth-mode-surgical-wrap)
     - A. Arsitektur Pembungkusan Bedah (Surgical Profile Wrap)
     - B. Mode Tamu (Guest Mode)
     - C. Mode Terverifikasi (Authenticated Mode)
5. [Alur Eksekusi Bertahap (Phased Waves & Dependency Graph)](#5-alur-eksekusi-bertahap-phased-waves--dependency-graph)
6. [Protokol Serah Terima Antar-Agen (Handoff Protocol)](#6-protokol-serah-terima-antar-agen-handoff-protocol)
7. [Rencana Pengujian & Verifikasi Objektif (Hardened Test Plan)](#7-rencana-pengujian--verifikasi-objektif-hardened-test-plan)
   - [7.1 Automated Unit & Integration Tests](#71-automated-unit--integration-tests)
   - [7.2 Empirical Stress & Security Verification Suite (ST-1 s/d ST-10)](#72-empirical-stress--security-verification-suite-st-1-sd-st-10)
   - [7.3 Skenario Pengujian Fungsional End-to-End](#73-skenario-pengujian-fungsional-end-to-end)
8. [Matriks Mitigasi Risiko & Edge Cases (Consensus Hardened)](#8-matriks-mitigasi-risiko--edge-cases-consensus-hardened)

---

## 1. Ringkasan Eksekutif & Arsitektur Sistem

### 1.1 Latar Belakang & Evaluasi Gelombang Verifikasi
Ekosistem pariwisata cerdas Sumatera Barat **WISGO (Rancak.in)** memerlukan fondasi autentikasi pengguna yang aman, cepat, dan ramah wisatawan tanpa friksi kata sandi (*passwordless WhatsApp OTP*). Pada tinjauan verifikasi gelombang awal (*Challenger 1, Reviewers, Auditor*), ditemukan 5 kerentanan kritis dan inefisiensi arsitektural pada draf sebelumnya:
1. **Pintu Belakang Bypass Dev Tidak Terbatas (Dev Bypass Backdoor)**: Kode bypass pengujian `"1234"` dan `"2486"` dapat dieksploitasi untuk mengambil alih akun siapapun (*arbitrary account takeover*) tanpa memicu request OTP terlebih dahulu dan tanpa pembatasan lingkungan produksi.
2. **Kebocoran Memori & Replay Attack pada Cache OTP**: `otpStore` berbasis `map[string]string` tidak memiliki TTL kadaluarsa, tidak menghapus OTP pasca-verifikasi, dan tidak memiliki rutinitas pembersihan memori latar belakang (*memory leak & replay vulnerability*).
3. **Kegagalan Format Normalisasi Telepon Lintas-Lapisan**: Penggabungan `'62' + rawDigits` di Flutter menghasilkan prefiks `6208...` jika pengguna mengetik `0812...`, yang langsung ditolak oleh regex backend Go. Format internasional `0062...` juga gagal ditangani.
4. **Desinkronisasi State & Over-Rebuilding Flutter**: Pemanggilan `setAuthToken` terpisah dari `setCurrentUser` menyebabkan UI tertahan di Mode Tamu, dan pembungkusan `ValueListenableBuilder` pada tingkat terluar `Scaffold` memicu re-render boros pada tab berat (Peta dan Jelajah) saat status autentikasi berubah.
5. **Pergeseran Kontrak Rute Destinasi Tersimpan (Route Drift)**: `ApiService` memanggil `/saved-places` dan `/saved-places/toggle`, sementara rute backend yang terdaftar adalah `/users/saved` dan `/users/saved/:destination_id`, berakibat respon HTTP 404 Not Found.

Dokumen Iterasi 2 ini memuat mitigasi arsitektur definitif untuk menuntaskan kelima kelemahan tersebut secara menyeluruh sebelum instruksi eksekusi kode diberikan.

### 1.2 Sasaran Arsitektur (End-to-End Clean Architecture & Hardened Security)
Sistem autentikasi WISGO dirancang menggunakan arsitektur bersih multi-tier yang tangguh:
- **Presentation Layer (Flutter Mobile)**: Input nomor telepon tervalidasi dengan sanitasi ganda (penghapusan awalan `0` dan `62` redundan), testing notification banner interaktif dengan tap-to-autofill, kotak digit OTP dinamis dengan on-screen numpad & keyboard listener, serta reaktivitas profil bedah (*surgical wrap*) tanpa mengganggu viewport peta/jelajah.
- **Core / Network Layer (Flutter)**: Single source of truth sesi in-memory atomik melalui `ApiConfig.setAuthSession`, model `UserProfile` dengan fallback inisial avatar Minang, dan fasad `ApiService` yang sepenuhnya selaras dengan kontrak rute backend Go (`/users/saved`).
- **Service & Data Layer (Go Gin + Supabase Cloud)**: Modul auth mandiri di `backend/internal/modules/auth/` dengan generator angka acak kriptografis 4 digit (`crypto/rand`), normalisasi telepon toleran E.164, pembatasan dev bypass hanya pada lingkungan development dan nomor pengujian terdaftar (*whitelisted test numbers*), cache OTP thread-safe dengan metadata `OTPEntry { Code, ExpiresAt }`, pemusnahan OTP pasca-verifikasi (*replay protection*), dan ticker pembersihan memori otomatis.

### 1.3 Diagram Arsitektur & Alur Data Hardened

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                   FLUTTER MOBILE CLIENT                                │
│                                                                                        │
│   ┌──────────────────────────┐    devOtpCode     ┌──────────────────────────────────┐  │
│   │       LoginScreen        │ ────────────────> │      OtpVerificationScreen       │  │
│   │  - Sanitasi '62' & '0'   │                   │  - 4 Digit OTP Box + Key Listener│  │
│   │  - Validasi 9-12 digit   │                   │  - WA Testing Notification Banner│  │
│   │  - Passing canonical num │                   │  - Auto-fill Tap + Resend Timer  │  │
│   └────────────┬─────────────┘                   └────────────────┬─────────────────┘  │
│                │ ApiService.requestOtp()                          │                    │
│                │                                                  │ verifyOtp()        │
│                ▼                                                  ▼                    │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│   │                            FLUTTER CORE NETWORK LAYER                           │  │
│   │                                                                                 │  │
│   │   ┌──────────────────────────────────┐     ┌────────────────────────────────┐   │  │
│   │   │            ApiService            │     │           ApiConfig            │   │  │
│   │   │  - requestOtp(phoneNumber)       │     │  - authToken (in-memory JWT)   │   │  │
│   │   │  - verifyOtp(phone, otp, name)   │ ──> │  - currentUser (UserProfile)  │   │  │
│   │   │  - setAuthSession() [ATOMIC]     │     │  - authNotifier (ValueNotifier)│   │  │
│   │   │  - /users/saved Route Alignment  │     │  - Getters: id, phone, name    │   │  │
│   │   └──────────────────────────────────┘     └───────────────┬────────────────┘   │  │
│   └────────────────────────────────────────────────────────────┼────────────────────┘  │
│                                                                │ ValueNotifier         │
│                                                                ▼ (Surgical Scoped)     │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│   │                  SavedPlacesScreen (Profile & Shell Tab)                        │  │
│   │   ┌─────────────────────────────────────────────────────────────────────────┐   │  │
│   │   │ IndexedStack: [ ExploreView, OpenTripView, PetaView, _buildProfileView ]│   │  │
│   │   │ (Peta & Jelajah TIDAK di-rebuild saat status auth berubah)              │   │  │
│   │   └────────────────────────────────────┬────────────────────────────────────┘   │  │
│   │                                        ▼                                        │  │
│   │                     ┌──────────────────────────────────────┐                    │  │
│   │                     │  ValueListenableBuilder (BEDAH)      │                    │  │
│   │                     │  - Guest Mode (!isAuthenticated)     │                    │  │
│   │                     │  - Authenticated Mode (isAuth)       │                    │  │
│   │                     └──────────────────────────────────────┘                    │  │
│   └─────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────┬───────────────────────────────────────────────┘
                                         │ HTTP REST (JSON)
                                         ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND GO (GIN 3-LAYER SERVICE)                          │
│                                                                                        │
│   ┌────────────────────────────────────────────────────────────────────────────────┐   │
│   │  Router & HTTP Handlers:                                                       │   │
│   │  - POST /api/v1/auth/request-otp (Rate-limited, terminal banner logging)       │   │
│   │  - POST /api/v1/auth/verify-otp  (Single-use invalidation, anti-takeover)      │   │
│   │  - GET/POST /api/v1/users/saved (Aligned bookmark endpoints)                   │   │
│   └───────────────────────────────────────┬────────────────────────────────────────┘   │
│                                           │                                            │
│   ┌───────────────────────────────────────▼────────────────────────────────────────┐   │
│   │  Service Layer (`backend/internal/modules/auth/service.go`):                   │   │
│   │  - Normalisasi Telepon Toleran (`phone.go`: 0062..., 6208..., 08..., 8...)     │   │
│   │  - Generator OTP Kriptografis 4 Digit (`crypto/rand` 1000-9999)                │   │
│   │  - Terminal Banner Logging ke stdout (`[AUTH OTP]`)                            │   │
│   │  - Scoped Dev Bypass: allowDevBypass == true & nomor terdaftar di Whitelist   │   │
│   │  - Invalidation: panggil DeleteOTP() pasca verifikasi sukses (Anti-Replay)     │   │
│   └───────────────────────────────────────┬────────────────────────────────────────┘   │
│                                           │                                            │
│   ┌───────────────────────────────────────▼────────────────────────────────────────┐   │
│   │  Repository Layer (`backend/internal/modules/auth/repository.go`):             │   │
│   │  - In-Memory Cache: map[string]OTPEntry { Code, ExpiresAt }                    │   │
│   │  - TTL 300s Check di GetOTP() + DeleteOTP() eksplisit                          │   │
│   │  - Background Ticker Cleaner (Eviksi entri kadaluarsa tiap 5 menit)            │   │
│   │  - Supabase Cloud PostgreSQL Pooler (Tabel `users` & `saved_places`)           │   │
│   └────────────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Topologi Tim Multi-Agent & Pembagian Peran

Pekerjaan implementasi didistribusikan kepada **5 Agen Spesialis** dengan mandat dan berkas yang terisolasi ketat:

```
                               ┌─────────────────────────────────┐
                               │       PARENT ORCHESTRATOR       │
                               │ (b99c97ea-e710-4206-b046-24e0)  │
                               └───────────────┬─────────────────┘
                                               │
                ┌──────────────────────────────┼───────────────────────────────┐
                │ Wave 1 (Fondasi & Kontrak)    │ Wave 2 (UI & Reaktivitas)     │ Wave 3
                ▼                               ▼                               ▼
   ┌─────────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────────┐
   │         AGENT 1         │     │         AGENT 3         │     │         AGENT 5         │
   │ BE-2 Go Auth Specialist │     │  Flutter Auth UI Spec.  │     │  QA & Verification Spec │
   │  (be_auth_specialist)   │     │ (flutter_auth_ui_spec)  │     │ (qa_verification_spec)  │
   └─────────────────────────┘     └─────────────────────────┘     └─────────────────────────┘
                │                               ▲                               ▲
                │ Wave 1                        │                               │
                ▼                               │ Wave 2                        │
   ┌─────────────────────────┐                  │                               │
   │         AGENT 2         │ ─────────────────┘                               │
   │ Flutter Core Specialist │                                                  │
   │ (flutter_core_specialist│ ─────────────────────────────────────────────────┘
   └─────────────────────────┘      Wave 2:
                │                  ┌─────────────────────────┐
                └────────────────> │         AGENT 4         │
                                   │ Flutter Profile React.  │
                                   │(flutter_profile_special)│
                                   └─────────────────────────┘
```

### 2.1 Rincian Profil & Mandat 5 Agen Spesialis

#### 1. Agent 1: BE-2 Go Auth Specialist (`be_auth_specialist`)
- **Tanggung Jawab Utama**:
  - `phone.go`: Implementasi normalisasi telepon defensif menangani prefiks internasional `0062...` dan reduplikasi `6208...` $\to$ `628...`.
  - `repository.go` & `postgres_repository.go`: Implementasi cache OTP berbasis struct `OTPEntry { Code string, ExpiresAt time.Time }`, pengecekan TTL 300 detik pada `GetOTP`, method `DeleteOTP(phone string)` untuk invalidasi instan, dan background ticker pembersih entri kadaluarsa.
  - `service.go`: Implementasi generator aman `crypto/rand` 4 digit, pencetakan banner visual `[AUTH OTP]` ke terminal log konsol, pengamanan bypass dev via flag `allowDevBypass bool` dan whitelisting nomor uji coba (`628127578953`, `6281211112222`), serta pemanggilan `DeleteOTP` setelah verifikasi sukses.
  - `dto.go`: Menambahkan field opsional `FullName` pada `OTPVerifyRequest`.
  - `auth_test.go`: Menulis pengujian komprehensif untuk normalisasi defensif, kadaluarsa TTL, mitigasi replay attack, dan penolakan bypass pada nomor non-whitelist.
- **Keluaran**: Kompilasi backend bersih (`go build ./...`) dan unit test auth lulus 100% (`go test -v ./internal/modules/auth/...`).

#### 2. Agent 2: Flutter Core Specialist (`flutter_core_specialist`)
- **Tanggung Jawab Utama**:
  - `user_profile.dart`: Model data `UserProfile` lengkap dengan parsing aman `fromJson`, serialisasi `toJson`, dan getter inisial nama Minang (`initials`).
  - `api_config.dart`: Pengelolaan sesi atomik via method baru `setAuthSession({required String? token, UserProfile? user})` yang memperbarui `authToken`, `currentUser`, dan memicu `authNotifier.value` secara serentak tanpa desinkronisasi.
  - `api_service.dart`: Penyelarasan rute destinasi tersimpan ke `/users/saved` dan `/users/saved/:destination_id` (mengeliminasi 404 route drift dari `/saved-places`), sanitasi nomor telepon pada `verifyOtp`, dan integrasi penyimpanan sesi via `setAuthSession`.
  - `api_service_test.dart`: Pengujian unit untuk sinkronisasi state atomik, penanganan token, dan integritas pemanggilan API.
- **Keluaran**: Unit test core lulus (`flutter test test/core/api_service_test.dart`).

#### 3. Agent 3: Flutter Auth UI Specialist (`flutter_auth_ui_specialist`)
- **Tanggung Jawab Utama**:
  - `login_screen.dart`: Sanitasi defensif `rawDigits` dengan membuang awalan `62` atau `0` sebelum membubuhi prefiks `'62'`, validasi panjang digit 9–12 angka, indikator loading spinner, banner error ramah pengguna, pemanggilan `ApiService.requestOtp`, dan passing nomor telepon kanonikal ke layar OTP.
  - `otp_verification_screen.dart`: Menerima parameter `phoneNumber` yang sudah ternormalisasi, rendering WhatsApp Testing Banner interaktif dengan tap-to-autofill, integrasi keypad virtual dan listener keyboard fisik, countdown timer 60s kirim ulang OTP, pemanggilan `ApiService.verifyOtp`, dan feedback getar/merah jika verifikasi gagal.
- **Keluaran**: Alur login dan verifikasi OTP pada pengujian antarmuka berjalan mulus.

#### 4. Agent 4: Flutter Profile Reactivity Specialist (`flutter_profile_specialist`)
- **Tanggung Jawab Utama**:
  - `saved_places_screen.dart`: Menerapkan pola **Surgical Profile Wrap** di mana `ValueListenableBuilder<UserProfile?>` **HANYA** membungkus metode `_buildProfileView`, sedangkan root `build()` dan tab berat (`_buildExploreView`, `_buildOpenTripView`, `_buildPetaView`) tetap statis di dalam `IndexedStack` tanpa re-render yang merusak performa viewport.
  - Merancang antarmuka **Mode Tamu (Guest Mode)**: kartu sambutan Minang ramah, 3 pilar nilai manfaat (Cloud Sync Supabase, Paspor Digital Minang, Escrow Rombongan Nagari), dan tombol CTA "Masuk dengan WhatsApp".
  - Merancang antarmuka **Mode Terverifikasi (Authenticated Mode)**: avatar inisial dinamis dari `UserProfile.initials`, nama lengkap, nomor telepon, badge terverifikasi, dan tombol logout dengan dialog konfirmasi elegan.
- **Keluaran**: Reaktivitas profil terisolasi secara efisien, widget test saved places lulus tanpa frame drop.

#### 5. Agent 5: QA & Integration Specialist (`qa_integration_specialist`)
- **Tanggung Jawab Utama**:
  - Menjalankan test suite otomatis backend Go (`go test -v ./internal/modules/auth/...`, `go build ./...`).
  - Menjalankan test suite otomatis Flutter (`flutter test`).
  - Melakukan validasi empiris terhadap 10 skenario uji ketat (ST-1 s/d ST-10).
  - Melakukan audit forensik: memverifikasi bahwa tidak ada mock palsu, tidak ada bypass tidak berizin di produksi, dan kepatuhan penuh pada aturan GEMINI.md.
- **Keluaran**: Laporan verifikasi integrasi final dan ringkasan audit kualitas.

---

## 3. Matriks Kepemilikan Berkas (Zero Merge Conflict Guardrails)

| Agen Spesialis | Berkas Kepemilikan Eksklusif (Write Access) | Berkas Referensi (Read Only) | Berkas DILARANG (Strictly Forbidden) |
|---|---|---|---|
| **Agent 1: BE-2 Go Auth Specialist** | `backend/internal/modules/auth/phone.go`<br>`backend/internal/modules/auth/service.go`<br>`backend/internal/modules/auth/dto.go`<br>`backend/internal/modules/auth/handler.go`<br>`backend/internal/modules/auth/repository.go`<br>`backend/internal/modules/auth/postgres_repository.go`<br>`backend/internal/modules/auth/auth_test.go` | `backend/internal/models/models.go`<br>`backend/cmd/api/main.go`<br>`backend/migrations/*` | `backend/internal/be1_core/*`<br>`mobile/*`<br>`web-admin/*` |
| **Agent 2: Flutter Core Specialist** | `mobile/lib/core/models/user_profile.dart`<br>`mobile/lib/core/network/api_config.dart`<br>`mobile/lib/core/services/api_service.dart`<br>`mobile/test/core/api_service_test.dart` | `mobile/lib/core/network/api_client.dart`<br>`backend/internal/modules/auth/dto.go` | `mobile/lib/features/*`<br>`backend/*`<br>`web-admin/*` |
| **Agent 3: Flutter Auth UI Specialist** | `mobile/lib/features/auth/presentation/screens/login_screen.dart`<br>`mobile/lib/features/auth/presentation/screens/otp_verification_screen.dart`<br>`mobile/test/features/auth/*` | `mobile/lib/core/network/api_config.dart`<br>`mobile/lib/core/services/api_service.dart`<br>`mobile/lib/core/theme/*` | `mobile/lib/core/*` (Write)<br>`mobile/lib/features/saved/*`<br>`backend/*` |
| **Agent 4: Flutter Profile Reactivity Specialist** | `mobile/lib/features/saved/presentation/screens/saved_places_screen.dart`<br>`mobile/test/features/saved/profile_auth_reactivity_test.dart` | `mobile/lib/core/network/api_config.dart`<br>`mobile/lib/core/services/api_service.dart`<br>`mobile/lib/features/auth/presentation/screens/login_screen.dart` | `mobile/lib/features/auth/*` (Write)<br>`mobile/lib/core/*` (Write)<br>`backend/*` |
| **Agent 5: QA & Integration Specialist** | Skrip eksekusi pengujian & artefak laporan pengujian di folder state / docs | Seluruh berkas di `backend/` dan `mobile/` | Dilarang memodifikasi langsung berkas kode sumber aplikasi |

---

## 4. Spesifikasi Teknis Rinci per Komponen (Hardened)

### 4.1 Backend Go Auth Foundation (BE-2)

#### A. Normalisasi Defensif Nomor Telepon (`backend/internal/modules/auth/phone.go`)
Fungsi normalisasi telepon diperkuat untuk menangani kebiasaan input pengguna Indonesia (`+62 08...`), standar penulisan internasional (`0062...`), serta pembersihan spasi dan tanda hubung:

```go
package auth

import (
    "errors"
    "regexp"
    "strings"
)

var nonDigitRegex = regexp.MustCompile(`\D`)

// NormalizePhoneNumber mengonversi ragam format input ke format kanonikal E.164 (628xxx)
func NormalizePhoneNumber(raw string) (string, error) {
    cleaned := nonDigitRegex.ReplaceAllString(strings.TrimSpace(raw), "")

    // 1. Tangani standar internasional awalan 00 (misal: 0062812... -> 62812...)
    if strings.HasPrefix(cleaned, "00") {
        cleaned = cleaned[2:]
    }

    // 2. Tangani kebiasaan user mengetik +62 diikuti 08... (6208xxx -> 628xxx)
    if strings.HasPrefix(cleaned, "6208") {
        cleaned = "62" + cleaned[3:]
    } else if strings.HasPrefix(cleaned, "08") {
        cleaned = "62" + cleaned[1:]
    } else if strings.HasPrefix(cleaned, "8") {
        cleaned = "62" + cleaned
    } else if strings.HasPrefix(cleaned, "628") {
        // format kanonikal sudah tepat
    } else {
        return "", errors.New("nomor telepon harus menggunakan awalan 08, 8, atau 628")
    }

    // 3. Validasi rentang panjang digit numerik nasional (10 - 15 digit)
    if len(cleaned) < 10 || len(cleaned) > 15 {
        return "", errors.New("panjang nomor telepon tidak valid (harus 10-15 digit)")
    }

    return cleaned, nil
}
```

#### B. In-Memory OTP Cache TTL 300s & Cleanup Ticker (`backend/internal/modules/auth/repository.go`)
Mencegah *unbounded memory leak* dan menjamin masa aktif OTP tepat 300 detik:

```go
package auth

import (
    "sync"
    "time"
)

// OTPEntry menyimpan kode OTP beserta batas waktu kadaluarsa (TTL)
type OTPEntry struct {
    Code      string
    ExpiresAt time.Time
}

type inMemoryRepository struct {
    mu       sync.RWMutex
    otpStore map[string]OTPEntry // phone -> OTPEntry
    users    map[string]*User
    saved    map[string][]SavedPlace
}

func NewInMemoryRepository() Repository {
    repo := &inMemoryRepository{
        otpStore: make(map[string]OTPEntry),
        users:    make(map[string]*User),
        saved:    make(map[string][]SavedPlace),
    }

    // Rutinitas pembersihan otomatis setiap 5 menit untuk mencegah kebocoran memori
    go repo.startCleanupTicker(5 * time.Minute)

    return repo
}

func (r *inMemoryRepository) SaveOTP(phone, code string, ttl time.Duration) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    r.otpStore[phone] = OTPEntry{
        Code:      code,
        ExpiresAt: time.Now().Add(ttl),
    }
    return nil
}

func (r *inMemoryRepository) GetOTP(phone string) (string, bool) {
    r.mu.Lock()
    defer r.mu.Unlock()

    entry, exists := r.otpStore[phone]
    if !exists {
        return "", false
    }

    // Cek batas waktu kadaluarsa TTL 300 detik
    if time.Now().After(entry.ExpiresAt) {
        delete(r.otpStore, phone) // Hapus seketika jika kadaluarsa
        return "", false
    }

    return entry.Code, true
}

// DeleteOTP menghapus kode OTP seketika pasca-verifikasi untuk mencegah Replay Attacks
func (r *inMemoryRepository) DeleteOTP(phone string) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    delete(r.otpStore, phone)
    return nil
}

func (r *inMemoryRepository) startCleanupTicker(interval time.Duration) {
    ticker := time.NewTicker(interval)
    defer ticker.Stop()
    for range ticker.C {
        r.mu.Lock()
        now := time.Now()
        for phone, entry := range r.otpStore {
            if now.After(entry.ExpiresAt) {
                delete(r.otpStore, phone)
            }
        }
        r.mu.Unlock()
    }
}
```

#### C. Generator Angka Acak Kriptografis 4 Digit & Console Logging
```go
func generateSecureOTP() string {
    n, err := rand.Int(rand.Reader, big.NewInt(9000))
    if err != nil {
        return "1234" // Fallback aman jika entropi OS bermasalah
    }
    return fmt.Sprintf("%04d", n.Int64()+1000)
}
```
Banner visual pada konsol terminal backend dieksekusi pada `RequestOTP`:
```go
log.Printf("\n" +
    "======================================================================\n" +
    "[AUTH OTP] KODE VERIFIKASI WHATSAPP RESMI RANCAK.IN\n" +
    "  Target Nomor : %s\n" +
    "  KODE OTP     : >>> %s <<<\n" +
    "  Masa Berlaku : 300 Detik (5 Menit)\n" +
    "  Bypass QA    : 1234 / 2486 (Toleransi Khusus Whitelist Development)\n" +
    "======================================================================\n",
    normalizedPhone, otpCode,
)
```

#### D. Dev Bypass Scoping & Anti-Account Takeover (`backend/internal/modules/auth/service.go`)
Pencegahan pengambilalihan akun secara sepihak dan pembatasan bypass hanya pada nomor pengujian terdaftar:

```go
type authService struct {
    repo           Repository
    allowDevBypass bool                // Injected: true di dev/test, WAJIB false di production
    whitelistedDev map[string]struct{} // Daftar nomor telepon uji coba resmi
}

func NewAuthService(repo Repository, allowDevBypass bool) Service {
    whitelist := map[string]struct{}{
        "628127578953":  {}, // Nomor demo pengujian sistem
        "6281211112222": {}, // Nomor demo evaluator UI
    }
    return &authService{
        repo:           repo,
        allowDevBypass: allowDevBypass,
        whitelistedDev: whitelist,
    }
}

func (s *authService) VerifyOTP(phone, code, fullName string) (*User, string, error) {
    normalizedPhone, err := NormalizePhoneNumber(phone)
    if err != nil {
        return nil, "", err
    }

    isBypassCode := (code == "1234" || code == "2486")
    if isBypassCode {
        // 1. Tolak mutlak jika bypass dicoba pada lingkungan non-development
        if !s.allowDevBypass {
            return nil, "", errors.New("kode bypass pengujian dinonaktifkan di lingkungan produksi")
        }
        // 2. Cegah Arbitrary Account Takeover: batasi hanya nomor uji coba terdaftar
        if _, allowed := s.whitelistedDev[normalizedPhone]; !allowed {
            return nil, "", errors.New("kode bypass hanya diizinkan untuk nomor telepon pengujian terdaftar")
        }
    } else {
        // Verifikasi kode OTP reguler dari cache
        storedCode, exists := s.repo.GetOTP(normalizedPhone)
        if !exists || storedCode != code {
            return nil, "", errors.New("Kode OTP salah atau telah kadaluarsa")
        }
    }

    // PENTING: Invalidate OTP seketika setelah verifikasi berhasil untuk mencegah Replay Attack
    _ = s.repo.DeleteOTP(normalizedPhone)

    // Lanjutkan pencarian / pembuatan user dan penerbitan JWT Token...
    user, err := s.repo.GetOrCreateUser(normalizedPhone, fullName)
    if err != nil {
        return nil, "", err
    }

    token, err := s.generateJWT(user)
    if err != nil {
        return nil, "", err
    }

    return user, token, nil
}
```

#### E. Perluasan DTO & Repository Interface (`dto.go` & `repository.go`)
```go
// dto.go
type OTPVerifyRequest struct {
    PhoneNumber string `json:"phone_number" binding:"required"`
    OTPCode     string `json:"otp_code" binding:"required"`
    FullName    string `json:"full_name,omitempty"`
}

// repository.go interface
type Repository interface {
    SaveOTP(phone, code string, ttl time.Duration) error
    GetOTP(phone string) (string, bool)
    DeleteOTP(phone string) error
    GetOrCreateUser(phone, fullName string) (*User, error)
    GetUserByID(id string) (*User, error)
    GetSavedPlaces(userID string) ([]SavedPlace, error)
    SavePlace(userID, destinationID string) error
    RemovePlace(userID, destinationID string) error
}
```

---

### 4.2 Flutter Core Session, State & Service

#### A. Model Data `UserProfile` (`mobile/lib/core/models/user_profile.dart`)
```dart
class UserProfile {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.role = 'tourist',
    this.avatarUrl,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Wisatawan Ranah Minang',
      role: json['role']?.toString() ?? 'tourist',
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone_number': phoneNumber,
    'full_name': fullName,
    'role': role,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  /// Inisial kapital 1-2 huruf untuk avatar pengguna Minang
  String get initials {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'W';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
```

#### B. State Sesi Reaktif & Atomik `ApiConfig` (`mobile/lib/core/network/api_config.dart`)
Memastikan token, profil, dan notifier selalu sinkron secara atomik:

```dart
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class ApiConfig {
  static String baseUrl = 'http://localhost:8080/api/v1';
  static String? authToken;
  static UserProfile? currentUser;
  static const Duration timeout = Duration(seconds: 15);

  /// Notifier reaktif native untuk mendengarkan perubahan status sesi pengguna
  static final ValueNotifier<UserProfile?> authNotifier = ValueNotifier<UserProfile?>(null);

  /// Pembaruan sesi terpadu secara atomik untuk mencegah desinkronisasi UI
  static void setAuthSession({required String? token, UserProfile? user}) {
    authToken = token;
    currentUser = user;
    authNotifier.value = user;
  }

  static void setAuthToken(String? token) {
    authToken = token;
    // Sinkronkan notifier jika user ada
    if (authToken == null) {
      currentUser = null;
      authNotifier.value = null;
    }
  }

  static void setCurrentUser(dynamic user) {
    if (user == null) {
      currentUser = null;
    } else if (user is UserProfile) {
      currentUser = user;
    } else if (user is Map<String, dynamic>) {
      currentUser = UserProfile.fromJson(user);
    }
    authNotifier.value = currentUser;
  }

  static void clearAuth() {
    setAuthSession(token: null, user: null);
  }

  static bool get isAuthenticated => authToken != null && authToken!.isNotEmpty;

  static String get currentUserId => currentUser?.id.isNotEmpty == true ? currentUser!.id : 'usr-001';
  static String get currentUserPhone => currentUser?.phoneNumber ?? '';
  static String get currentUserName => currentUser?.fullName ?? 'Tamu (Guest)';
  static String get currentUserRole => currentUser?.role ?? 'tourist';
}
```

#### C. Penyelarasan Rute & Helper `ApiService` (`mobile/lib/core/services/api_service.dart`)
Menyelaraskan rute bookmark ke `/users/saved` dan mengisolasi logika sesi:

```dart
class ApiService {
  // 1. Request OTP
  static Future<ApiResponse<dynamic>> requestOtp(String phoneNumber) async {
    return await ApiClient.post('/auth/request-otp', body: {
      'phone_number': phoneNumber,
    });
  }

  // 2. Verify OTP dengan pembaruan sesi atomik
  static Future<ApiResponse<dynamic>> verifyOtp(
    String phoneNumber,
    String otpCode, {
    String? fullName,
  }) async {
    final response = await ApiClient.post('/auth/verify-otp', body: {
      'phone_number': phoneNumber,
      'otp_code': otpCode,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    });

    if (response.isSuccess && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token']?.toString();
      UserProfile? profile;
      if (data['user'] is Map<String, dynamic>) {
        profile = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      }
      // Eksekusi atomik
      ApiConfig.setAuthSession(token: token, user: profile);
    }
    return response;
  }

  // 3. Penyelarasan Rute Bookmark Sesuai Kontrak Backend (/users/saved)
  static Future<ApiResponse<dynamic>> getSavedPlaces() async {
    return await ApiClient.get('/users/saved');
  }

  static Future<ApiResponse<dynamic>> toggleSavedPlace(String destinationId) async {
    return await ApiClient.post('/users/saved/$destinationId');
  }

  // 4. Logout & Sesi
  static void logout() {
    ApiConfig.clearAuth();
  }

  static UserProfile? getProfile() => ApiConfig.currentUser;
  static bool isAuthenticated() => ApiConfig.isAuthenticated;
}
```

---

### 4.3 Flutter Auth UI & Testing Banner

#### A. Integrasi `LoginScreen` dengan Sanitasi Defensif (`mobile/lib/features/auth/presentation/screens/login_screen.dart`)
Mencegah bug awalan `6208...` melalui sanitasi angka sebelum pembubuhan prefiks `'62'`:

```dart
void _handleSendOtp() async {
  if (_isLoading) return;

  // Sanitasi Defensif: Hapus non-digit, lalu buang awalan 62 atau 0 berlebih
  var rawDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
  if (rawDigits.startsWith('62')) {
    rawDigits = rawDigits.substring(2);
  }
  if (rawDigits.startsWith('0')) {
    rawDigits = rawDigits.substring(1);
  }

  if (rawDigits.length < 9 || rawDigits.length > 12) {
    _showErrorSnackBar('Nomor WhatsApp harus terdiri dari 9-12 digit setelah kode negara.');
    return;
  }

  final fullCanonicalNumber = '62$rawDigits';

  setState(() => _isLoading = true);
  try {
    final response = await ApiService.requestOtp(fullCanonicalNumber);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.isSuccess) {
      String? devCode;
      if (response.data is Map<String, dynamic>) {
        devCode = response.data['otp_code_dev']?.toString();
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: fullCanonicalNumber, // Kirim nomor kanonikal bersih
            devOtpCode: devCode ?? '1234',
          ),
        ),
      );
    } else {
      _showErrorSnackBar(response.message.isNotEmpty ? response.message : 'Gagal mengirim kode OTP.');
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showErrorSnackBar('Terjadi gangguan koneksi: $e');
  }
}
```

#### B. Integrasi `OtpVerificationScreen` dengan Testing Banner Interaktif (`mobile/lib/features/auth/presentation/screens/otp_verification_screen.dart`)
- **Penerimaan Parameter**: Menggunakan `phoneNumber` kanonikal tanpa tanda plus/spasi acak.
- **WhatsApp Testing Banner**:
  - Banner hijau meluncur dari atas menampilkan kode OTP nyata dari server: `"Kode OTP Anda: ${widget.devOtpCode ?? '1234'}"`.
  - Mengetuk banner langsung memicu `_autoFillOtp(widget.devOtpCode ?? '1234')`.
- **Eksekusi Verifikasi API**:
  ```dart
  void _verifyOtpCode() async {
    if (_isVerifying) return;
    final code = _otpDigits.join();
    if (code.length < 4) return;

    setState(() => _isVerifying = true);
    final response = await ApiService.verifyOtp(widget.phoneNumber, code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (response.isSuccess) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SavedPlacesScreen(initialTabIndex: 3)),
        (route) => false,
      );
    } else {
      _triggerErrorFeedback(response.message);
    }
  }
  ```

---

### 4.4 Flutter Profile Reactivity & Guest/Auth Mode (Surgical Wrap)

#### A. Arsitektur Pembungkusan Bedah (Surgical Profile Wrap)
Untuk mencegah *performance bottleneck* akibat pembuangan cache tab peta (`PetaView`) dan feed jelajah (`ExploreView`), `ValueListenableBuilder` **DILARANG** membungkus `Scaffold` terluar. `ValueListenableBuilder` dipasang secara bedah **HANYA** di dalam metode `_buildProfileTab()`:

```dart
// mobile/lib/features/saved/presentation/screens/saved_places_screen.dart

@override
Widget build(BuildContext context) {
  // Root build tetap ringan dan mempertahankan render state Map & Explore
  return Scaffold(
    backgroundColor: AppColors.cream,
    body: IndexedStack(
      index: _currentTabIndex,
      children: [
        _buildExploreView(),
        _buildOpenTripView(),
        _buildPetaView(),
        _buildProfileTab(), // Terisolasi secara bedah
      ],
    ),
    bottomNavigationBar: _buildBottomNav(),
  );
}

Widget _buildProfileTab() {
  return ValueListenableBuilder<UserProfile?>(
    valueListenable: ApiConfig.authNotifier,
    builder: (context, user, _) {
      final isLoggedIn = user != null && ApiConfig.isAuthenticated;
      return isLoggedIn
          ? _buildAuthenticatedProfileView(user)
          : _buildGuestProfileView();
    },
  );
}
```

#### B. Mode Tamu (Guest Mode - `!isLoggedIn`)
1. **Header Card**:
   - Ilustrasi Rumah Gadang / Ikon Tamu dengan aksen `AppColors.sage`.
   - Judul: *"Jelajahi Ranah Minang Lebih Leluasa"*.
   - Subjudul: *"Masuk dengan nomor WhatsApp untuk menyimpan destinasi favorit dan mengumpulkan stempel Paspor Digital Minang."*
2. **3 Kartu Manfaat Utama (Value Proposition)**:
   - 🌟 **Sinkronisasi Cloud Supabase**: Destinasi favorit Anda tersimpan aman dan dapat diakses dari perangkat manapun.
   - 🛂 **Paspor Digital Minang**: Kumpulkan lencana nagari dan stempel geofence GPS di setiap kunjungan budaya.
   - 🛡️ **Pemesanan Rombongan Nagari**: Akses resmi paket open-trip dan transaksi aman via Escrow Dispar Sumbar.
3. **Tombol Aksi Utama (CTA)**:
   - Tombol besar berlatar `AppColors.forest` dengan teks putih dan ikon WhatsApp: `"Masuk dengan Nomor WhatsApp"`.
   - Mengetuk tombol membuka `LoginScreen()`.

#### C. Mode Terverifikasi (Authenticated Mode - `isLoggedIn`)
1. **Kartu Identitas Pengguna**:
   - Avatar lingkaran berlatar `AppColors.forest` dengan teks inisial putih tebal (`user.initials`).
   - Nama lengkap wisatawan: `user.fullName`.
   - Nomor WhatsApp: `user.phoneNumber`.
   - Pill status hijau: *"OTP WhatsApp Terverifikasi"*.
2. **Sesi Akun & Tombol Logout**:
   - Tombol berlatar `AppColors.coralTint` dengan teks merah bata `AppColors.terracotta`: `"Keluar dari Akun WISGO"`.
   - Mengetuk tombol memunculkan dialog konfirmasi elegan:
     - Judul: *"Keluar dari Akun?"*
     - Pesan: *"Sesi login Anda akan diakhiri dan aplikasi kembali ke Mode Tamu."*
     - Aksi: *"Batal"* dan *"Ya, Keluar"* (memanggil `ApiService.logout()`).

---

## 5. Alur Eksekusi Bertahap (Phased Waves & Dependency Graph)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        WAVE 1: CORE & BACKEND FOUNDATION               │
│                                                                        │
│   ┌──────────────────────────────┐    ┌────────────────────────────┐   │
│   │ Agent 1: BE-2 Go Auth Spec.  │    │ Agent 2: Flutter Core Spec │   │
│   │ - phone.go (defensif)        │    │ - UserProfile model        │   │
│   │ - repository.go (OTPEntry)   │    │ - setAuthSession() atomik  │   │
│   │ - service.go (anti-takeover) │    │ - /users/saved alignment   │   │
│   │ - auth_test.go (ST-1 s/d 8)  │    │ - api_service_test.dart    │   │
│   └──────────────┬───────────────┘    └─────────────┬──────────────┘   │
└──────────────────┼──────────────────────────────────┼──────────────────┘
                   │                                  │
                   │ Kontrak Backend & Core Siap      │
                   ▼                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        WAVE 2: UI & PROFILE INTEGRATION                │
│                                                                        │
│   ┌──────────────────────────────┐    ┌────────────────────────────┐   │
│   │ Agent 3: Flutter Auth UI Spec│    │ Agent 4: Profile Reactivity│   │
│   │ - login_screen.dart (sanitasi│    │ - saved_places_screen.dart │   │
│   │ - otp_verification_screen    │    │ - Surgical Profile Wrap    │   │
│   │ - WhatsApp Testing Banner    │    │ - Guest Mode & 3 VP        │   │
│   │ - Auto-fill & Resend Timer   │    │ - Authenticated View       │   │
│   └──────────────┬───────────────┘    └─────────────┬──────────────┘   │
└──────────────────┼──────────────────────────────────┼──────────────────┘
                   │                                  │
                   │ Seluruh Fitur Auth & UI Selesai  │
                   ▼                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        WAVE 3: QA & AUDIT FORENSIK                     │
│                                                                        │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Agent 5: QA & Integration Specialist                           │   │
│   │ - go test -v ./internal/modules/auth/...                       │   │
│   │ - go build ./...                                               │   │
│   │ - flutter test test/core/api_service_test.dart                 │   │
│   │ - flutter test                                                 │   │
│   │ - Verifikasi ST-1 s/d ST-10 & Forensic Integrity Audit         │   │
│   └────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

### 5.1 Rincian Gelombang 1 (Wave 1: Fondasi Backend & Core Flutter)
- **Tujuan**: Membangun kontrak data yang kokoh dan bebas celah keamanan di backend dan core mobile.
- **Gerbang Kelulusan (Gate 1)**:
  - `go test -v ./internal/modules/auth/...` lulus 100% (termasuk verifikasi TTL, replay protection, dan bypass whitelist).
  - `go build ./...` keluar dengan exit code 0.
  - `flutter test test/core/api_service_test.dart` lulus 100%.

### 5.2 Rincian Gelombang 2 (Wave 2: Integrasi UI Layar Auth & Reaktivitas Profil)
- **Tujuan**: Menghubungkan antarmuka visual Flutter dengan layanan inti yang telah lulus uji pada Wave 1.
- **Gerbang Kelulusan (Gate 2)**:
  - Kompilasi Flutter bersih tanpa error sintaksis.
  - Alur navigasi Login $\to$ OTP $\to$ Profile berjalan mulus pada widget test.
  - Render profiling mengonfirmasi tab Peta/Jelajah tidak di-rebuild saat login/logout.

### 5.3 Rincian Gelombang 3 (Wave 3: QA, Pengujian E2E, & Audit Forensik)
- **Tujuan**: Verifikasi menyeluruh end-to-end dan penjaminan mutu integritas.
- **Gerbang Kelulusan (Gate 3)**: Seluruh automated tests berstatus PASS, laporan handoff lengkap, kepatuhan GEMINI.md dan zero merge conflict terpenuhi 100%.

---

## 6. Protokol Serah Terima Antar-Agen (Handoff Protocol)

### 6.1 Kontrak Serah Terima Agent 1 $\to$ Agent 2 & 3
- **Request OTP**:
  ```json
  POST /api/v1/auth/request-otp
  Request Body: { "phone_number": "0812-7578-953" }
  Response 200 OK:
  {
    "status": "success",
    "message": "Kode OTP berhasil dikirim ke nomor WhatsApp Anda",
    "data": {
      "phone_number": "628127578953",
      "otp_code_dev": "1234",
      "expires_in": 300
    }
  }
  ```
- **Terminal Stdout Log Verification**:
  ```
  ======================================================================
  [AUTH OTP] KODE VERIFIKASI WHATSAPP RESMI RANCAK.IN
    Target Nomor : 628127578953
    KODE OTP     : >>> 1234 <<<
    Masa Berlaku : 300 Detik (5 Menit)
    Bypass QA    : 1234 / 2486 (Toleransi Khusus Whitelist Development)
  ======================================================================
  ```
- **Verify OTP**:
  ```json
  POST /api/v1/auth/verify-otp
  Request Body: { "phone_number": "628127578953", "otp_code": "2486", "full_name": "Ahmad Fauzi" }
  Response 200 OK:
  {
    "status": "success",
    "message": "Autentikasi berhasil",
    "data": {
      "token": "jwt-wisgo-eyJhbGciOi...",
      "user": {
        "id": "usr-001",
        "phone_number": "628127578953",
        "full_name": "Ahmad Fauzi",
        "role": "tourist",
        "created_at": "2026-11-18T00:00:00Z"
      }
    }
  }
  ```

### 6.2 Kontrak Serah Terima Agent 2 $\to$ Agent 3 & 4
- **Antarmuka Core yang Tersedia**:
  - `ApiConfig.authNotifier` (`ValueNotifier<UserProfile?>`)
  - `ApiConfig.setAuthSession({required String? token, UserProfile? user})`
  - `ApiConfig.isAuthenticated` (`bool`)
  - `ApiConfig.currentUserName`, `currentUserPhone`, `currentUserId`, `currentUserRole`
  - `ApiService.requestOtp(String phoneNumber)`
  - `ApiService.verifyOtp(String phoneNumber, String otpCode, {String? fullName})`
  - `ApiService.getSavedPlaces()` $\to$ Memanggil `/users/saved`
  - `ApiService.toggleSavedPlace(String destinationId)` $\to$ Memanggil `/users/saved/:destination_id`
  - `ApiService.logout()`

---

## 7. Rencana Pengujian & Verifikasi Objektif (Hardened Test Plan)

### 7.1 Automated Unit & Integration Tests

#### 1. Uji Backend Go Auth (`backend/`)
```powershell
cd d:\WISGO\backend
go test -v ./internal/modules/auth/...
go test ./...
go build ./...
```
*Kriteria Kelulusan*:
- Unit test memverifikasi normalisasi defensif (`08xx`, `+628xx`, `8xx`, `6208xx`, `0062xx`).
- Unit test memverifikasi masa berlaku OTP kadaluarsa setelah 300 detik.
- Unit test memverifikasi penghapusan OTP seketika pasca-verifikasi (mencegah replay attack).
- Unit test memverifikasi penolakan kode bypass pada nomor telepon di luar daftar whitelist.
- Banner konsol terminal `[AUTH OTP]` tercetak saat request OTP.
- Kompilasi `go build ./...` keluar dengan exit code 0.

#### 2. Uji Flutter Core & State (`mobile/`)
```powershell
cd d:\WISGO\mobile
flutter test test/core/api_service_test.dart
flutter test
```
*Kriteria Kelulusan*:
- `ApiConfig.setAuthSession` secara serentak memperbarui token, profil, dan memicu `authNotifier`.
- `ApiConfig.clearAuth` membersihkan seluruh state sesi.
- Pemanggilan `getSavedPlaces` dan `toggleSavedPlace` memanggil URL kanonikal `/users/saved`.
- Seluruh unit & widget tests yang ada tetap lulus tanpa regresi.

### 7.2 Empirical Stress & Security Verification Suite (ST-1 s/d ST-10)

| ID Uji | Skenario Uji | Verifikasi & Perilaku yang Diharapkan | Status Mitigasi |
|---|---|---|---|
| **ST-1** | Normalisasi `6208127578953` (`62$rawDigits`) | Otomatis diubah menjadi kanonikal `628127578953`, lolos validasi | **TERSELESAIKAN (Mitigasi 3)** |
| **ST-2** | Normalisasi `+62 0812 7578 953` | Dikonversi menjadi `628127578953` tanpa error | **TERSELESAIKAN (Mitigasi 3)** |
| **ST-3** | Normalisasi `00628127578953` (Standar Internasional) | Dikonversi menjadi `628127578953` tanpa error | **TERSELESAIKAN (Mitigasi 3)** |
| **ST-4** | Nomor Telepon Asing (`+60123456789`) | Diberikan pesan error yang jelas dan santun | **TERSELESAIKAN (Mitigasi 3)** |
| **ST-5** | Spam 1.000 Request OTP Bersamaan | Background ticker membersihkan entri kadaluarsa, tidak ada RAM leak | **TERSELESAIKAN (Mitigasi 2)** |
| **ST-6** | Kadaluarsa OTP setelah 300 Detik | Request OTP ditolak setelah 300s dengan error kadaluarsa | **TERSELESAIKAN (Mitigasi 2)** |
| **ST-7** | Replay Attack OTP yang Sama | OTP langsung terhapus setelah pemakaian pertama; pemakaian kedua ditolak | **TERSELESAIKAN (Mitigasi 2)** |
| **ST-8** | Percobaan Bypass pada Nomor Non-Whitelist | Ditolak dengan pesan kode bypass dinonaktifkan / tidak terdaftar | **TERSELESAIKAN (Mitigasi 1)** |
| **ST-9** | Sinkronisasi State Flutter `setAuthSession` | Token dan profil terisi serentak; `authNotifier` langsung terpicu | **TERSELESAIKAN (Mitigasi 4)** |
| **ST-10**| Surgical Rebuild Tab Profil | Tab Peta dan Jelajah TIDAK mengalami re-render saat user login/logout | **TERSELESAIKAN (Mitigasi 4)** |

### 7.3 Skenario Pengujian Fungsional End-to-End

| No | Skenario Pengujian | Langkah Pengujian | Hasil yang Diharapkan |
|---|---|---|---|
| **S1** | **Normalisasi Input Telepon** | Masukkan nomor `0812-7578-953` di `LoginScreen` lalu tekan Kirim OTP. | Backend menerima nomor ternormalisasi `628127578953`. Terminal mencetak banner `[AUTH OTP]`. |
| **S2** | **Validasi Digit Input** | Masukkan nomor kurang dari 9 digit (misal: `08123`) di `LoginScreen`. | Muncul pesan error validasi. Tombol tidak memicu network call. |
| **S3** | **Testing Banner Interaktif** | Setelah request OTP berhasil, buka `OtpVerificationScreen`. | Banner WhatsApp meluncur dari atas menampilkan kode OTP nyata dari server (`devOtpCode`). |
| **S4** | **Autofill Kode OTP** | Ketuk banner WhatsApp atau tombol *"Isi Otomatis"* pada numpad. | Ke-4 kotak digit OTP otomatis terisi angka tanpa jeda. |
| **S5** | **Bypass Whitelist Development** | Masukkan kode pengujian `"1234"` pada nomor demo terdaftar (`628127578953`). | Server merespons HTTP 200 OK, token JWT dan data user dikembalikan, sesi tersimpan atomik. |
| **S6** | **Pencegahan Bypass Non-Whitelist** | Coba masukkan kode `"1234"` pada nomor acak di luar whitelist. | Server merespons HTTP 401 Unauthorized dengan pesan keamanan yang tegas. |
| **S7** | **Pencegahan Replay Attack** | Coba kirim ulang verifikasi dengan kode OTP yang sama setelah sukses verifikasi. | Server menolak permintaan dengan pesan *"Kode OTP salah atau telah kadaluarsa"*. |
| **S8** | **Reaktivitas Mode Tamu** | Buka Tab Profil saat belum masuk akun (`ApiConfig.clearAuth()`). | Ditampilkan **Mode Tamu** dengan 3 kartu manfaat Minang dan tombol CTA *"Masuk dengan WhatsApp"*. |
| **S9** | **Reaktivitas Mode Terverifikasi** | Selesaikan login berhasil lalu periksa Tab Profil. | UI otomatis berganti ke **Mode Terverifikasi** tanpa me-rebuild tab Peta dan Jelajah. |
| **S10**| **Konfirmasi Logout Akun** | Ketuk tombol *"Keluar dari Akun"* pada Tab Profil. | Muncul dialog konfirmasi. Jika disetujui, token & profil dibersihkan atomik, UI kembali ke Mode Tamu. |

---

## 8. Matriks Mitigasi Risiko & Edge Cases (Consensus Hardened)

| Kategori Risiko | Kerentanan / Edge Case | Solusi & Strategi Mitigasi Terpilih (Hardened) |
|---|---|---|
| **Keamanan Autentikasi** | Pengambilalihan akun sembarang via kode bypass dev ("1234" & "2486") | Kunci bypass via flag `allowDevBypass` (wajib `false` di produksi). Batasi kode bypass secara eksklusif hanya untuk nomor telepon demo terdaftar (`628127578953`, `6281211112222`). |
| **Manajemen Memori Server** | Spam request OTP menyebabkan kebocoran memori pada `otpStore` | Gunakan struct `OTPEntry { Code, ExpiresAt }` dengan masa berlaku 300 detik. Jalankan background goroutine pembersih setiap 5 menit untuk menghapus entri kadaluarsa secara teratur. |
| **Replay Attacks** | Kode OTP disadap dan digunakan kembali setelah pengguna asli login | Hapus entri OTP dari cache seketika (`DeleteOTP`) saat verifikasi berhasil dieksekusi. |
| **Normalisasi Telepon** | Format telepon `6208...`, `0062...`, atau spasi/strip gagal divalidasi | Perkuat sanitasi ganda: Flutter memotong awalan `62` dan `0` sebelum membubuhi `'62'`, dan backend Go memproses awalan `00` dan `6208` secara toleran menjadi format kanonikal E.164 `628...`. |
| **Performa UI Flutter** | Tab Peta dan Jelajah ter-rebuild berulang kali saat status autentikasi berubah | Terapkan pola **Surgical Profile Wrap**: letakkan `ValueListenableBuilder` secara terisolasi hanya di dalam `_buildProfileTab`, menjaga viewport tab berat tetap statis di dalam `IndexedStack`. |
| **Sinkronisasi State Mobile**| Token tersimpan namun profil belum ter-update, UI tertahan di Mode Tamu | Gunakan mutator sesi atomik `ApiConfig.setAuthSession({token, user})` yang memperbarui token dan profil dalam satu siklus event loop. |
| **Integrasi Rute Destinasi** | Pemanggilan bookmark gagal HTTP 404 karena perbedaan nama rute | Selaraskan endpoint `ApiService.getSavedPlaces` dan `toggleSavedPlace` ke rute kanonikal backend `/users/saved` dan `/users/saved/:destination_id`. |
| **Ketahanan Supabase** | Koneksi cloud pooler Supabase terganggu | Sediakan fallback in-memory repository untuk menjaga kelancaran demonstrasi autentikasi (*graceful degradation*). |

---
*Dokumen ini disusun sebagai panduan operasional master bagi orkestrasi 5 agen pengembang WISGO (Rancak.in) dengan kepatuhan penuh pada GEMINI.md dan karpathy-guidelines.*
