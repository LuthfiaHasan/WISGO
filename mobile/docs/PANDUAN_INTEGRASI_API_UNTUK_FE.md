# 📖 PANDUAN INTEGRASI REST API WISGO (UNTUK REKAN TIM FRONTEND)

Dokumen ini adalah panduan praktis bagi rekan tim Frontend (**FE-1 & FE-2**) untuk memanggil data nyata dari Backend (Go + Supabase Cloud PostgreSQL) tanpa perlu mengkhawatirkan perbedaan format atau risiko *merge conflict*.

---

## 01. Prinsip Utama: Zero Breaking Changes & Zero Conflict
1. **Model UI Anda Tetap Utuh**: Model tampilan yang sudah Anda gunakan di widget (seperti `SavedDestinationModel`, `QuickBookingItem`, `PassportBadge`) **tidak kami ubah**. Anda tetap bisa mengakses `item.title`, `item.imageUrl`, `item.price`, dll seperti biasa.
2. **Pola Adaptor Cerdas**: Semua konversi antara format database backend (`snake_case`) dan model UI Anda ditangani secara otomatis oleh file adaptor di folder masing-masing:
   - `features/saved/data/destination_adapter.dart`
   - `features/booking/data/booking_adapter.dart`
3. **Single Source of Truth**: Anda cukup memanggil satu kelas terpadu:  
   `import 'package:rancakin_mobile/core/services/api_service.dart';`

---

## 02. Konfigurasi Lingkungan (Base URL)
Secara otomatis, `ApiConfig` sudah mengarah ke server lokal `http://localhost:8080/api/v1`.  
Jika Anda menggunakan emulator atau URL publik, cukup set di `main.dart` atau sebelum memanggil API:

```dart
import 'package:rancakin_mobile/core/network/api_config.dart';

// Untuk Android Emulator:
ApiConfig.useAndroidEmulator(); // http://10.0.2.2:8080/api/v1

// Untuk Cloudflare Tunnel / Ngrok:
ApiConfig.useCloudflareTunnel('wisgo-demo.trycloudflare.com');

// Set token setelah login:
ApiConfig.setAuthToken('jwt-token-wisatawan');
```

---

## 03. Contoh Pemanggilan API Sesuai Pilar Fitur

### A. Destinasi Wisata & Spasial (Pilar 2 & 3)
```dart
// Ambil 20 destinasi prioritas Sumbar (mendukung filter kategori & pencarian)
final response = await ApiService.getDestinations(
  category: 'Alam',      // opsional: 'Semua', 'Alam', 'Budaya', 'Kuliner'
  searchQuery: 'Harau',  // opsional
);

if (response.isSuccess) {
  final List rawList = response.data;
  // Ubah ke model UI Anda via DestinationAdapter:
  final places = rawList.map((json) => DestinationAdapter.fromJson(json)).toList();
} else {
  // Tangani error / mode luring
  print("Gagal memuat: ${response.message}");
}
```

### B. Mitra Nagari & Paket Layanan (Pilar 5)
```dart
// Ambil daftar mitra nagari (otomatis toleran bahasa UI: 'Penginapan', 'Transportasi', dll)
final res = await ApiService.getPartners(category: 'Penginapan');

if (res.isSuccess) {
  final List rawPartners = res.data;
  // Langsung konversi ke QuickBookingItem milik FE:
  final items = rawPartners.map((j) => BookingAdapter.fromBackendPartner(j)).toList();
}
```

### C. Transaksi Smart Escrow Booking (Pilar 5)
```dart
// Buat pesanan escrow (Dana ditahan aman sampai wisatawan scan QR di lokasi)
final payload = BookingAdapter.toEscrowPayload(
  selectedItem,
  userId: 'usr-001',
  quantity: 2,
);

final bookingRes = await ApiService.createBooking(payload);
if (bookingRes.isSuccess) {
  final bookingData = bookingRes.data;
  final qrTicket = bookingData['qr_code_ticket']; // Tampilkan di QrisPaymentSheet!
}
```

### D. Rombongan & Group Room (Pilar 4)
```dart
// Buat room rombongan baru
final roomRes = await ApiService.createGroup('Keluarga Liburan Harau', leaderId: 'usr-001');

// Gabung room via kode 6 digit
final joinRes = await ApiService.joinGroup('WG-8841', userId: 'usr-002');
```

### E. Gamifikasi & Paspor Minang (Pilar 8)
```dart
// Check-in stempel paspor (otomatis divalidasi radius GPS <= 200m di backend)
final stampRes = await ApiService.stampPassport(
  destinationId: 'lubuk-hitam-padang',
  userLat: -0.9542,
  userLng: 100.3541,
);
```

### F. Pelaporan Saber Pungli & Fasilitas Rusak (Pilar 3)
```dart
final laporRes = await ApiService.reportPungli({
  'destination_id': 'harau-01',
  'incident_category': 'parkir_liar',
  'charged_amount_idr': 20000,
  'description': 'Karcis tidak resmi di gerbang air terjun',
});
```

---

## 04. Format Respon Seragam (`ApiResponse`)
Setiap fungsi di `ApiService` mengembalikan objek `ApiResponse`:
```dart
class ApiResponse<T> {
  final bool isSuccess;    // true jika status code 200-299
  final String status;     // 'success' | 'error'
  final String message;    // Pesan ramah dalam Bahasa Indonesia
  final T? data;           // Payload data hasil query
  final int statusCode;    // HTTP status code
}
```

Jika ada pertanyaan atau butuh penambahan endpoint baru, tim BE-2 siap membantu kapan saja! Selamat berkolaborasi! 🚀
