import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// ==============================================================================
/// WISGO (Rancak.in) - KONFIGURASI PUSAT JEMBATAN REST API
/// Digunakan bersama oleh seluruh modul FE-1, FE-2, BE-1, dan BE-2.
/// ==============================================================================

class ApiConfig {
  // Base URL default untuk pengujian lokal di browser Web / Desktop Windows
  static String baseUrl = 'http://localhost:8080/api/v1';

  // Token JWT autentikasi wisatawan aktif
  static String? authToken;

  // Profil wisatawan terautentikasi aktif
  static UserProfile? currentUser;

  // Timeout standar pemanggilan API (15 detik)
  static const Duration timeout = Duration(seconds: 15);

  /// Notifier reaktif native untuk mendengarkan perubahan status sesi pengguna
  static final ValueNotifier<UserProfile?> authNotifier = ValueNotifier<UserProfile?>(null);

  /// Pembaruan sesi terpadu secara atomik untuk mencegah desinkronisasi UI
  static void setAuthSession({required String? token, UserProfile? user}) {
    authToken = token;
    currentUser = user;
    authNotifier.value = user;
  }

  /// Ubah Base URL secara dinamis ke server mana pun
  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api/v1')) {
      url = '$url/api/v1';
    }
    baseUrl = url;
  }

  /// Sakelar Cepat: Gunakan Server Lokal Laptop (Browser / Desktop)
  static void useLocalhost() {
    baseUrl = 'http://localhost:8080/api/v1';
  }

  /// Sakelar Cepat: Gunakan Android Emulator Resmi
  static void useAndroidEmulator() {
    baseUrl = 'http://10.0.2.2:8080/api/v1';
  }

  /// Sakelar Cepat: Gunakan Cloudflare Tunnel Publik (Akses dari HP Asli)
  static void useCloudflareTunnel(String domain) {
    setBaseUrl('https://$domain');
  }

  /// Sakelar Cepat: Gunakan Server Cloud Produksi (Render / Zeabur / VPS)
  static void useProduction(String domain) {
    setBaseUrl('https://$domain');
  }

  /// Simpan atau hapus Token JWT
  static void setAuthToken(String? token) {
    authToken = token;
    if (token == null) {
      currentUser = null;
      authNotifier.value = null;
    }
  }

  /// Simpan profil pengguna aktif
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

  /// Hapus sesi login wisatawan (kembali ke Guest Mode)
  static void clearAuth() {
    setAuthSession(token: null, user: null);
  }

  /// Cek apakah pengguna saat ini sudah terautentikasi
  static bool get isAuthenticated => authToken != null && authToken!.isNotEmpty;

  // Helper Getters untuk data wisatawan aktif
  static String get currentUserId => currentUser?.id.isNotEmpty == true ? currentUser!.id : 'usr-001';
  static String get currentUserPhone => currentUser?.phoneNumber ?? '';
  static String get currentUserName => currentUser?.fullName ?? 'Tamu (Guest)';
  static String get currentUserRole => currentUser?.role ?? 'tourist';
}
