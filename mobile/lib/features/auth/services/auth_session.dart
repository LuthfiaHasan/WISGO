import 'package:flutter/material.dart';

/// Pengelola status sesi autentikasi pengguna WISGO (Singleton ChangeNotifier)
/// Mengatur apakah pengguna saat ini masuk sebagai Tamu (Guest Mode) atau Pengguna Terdaftar.
class AuthSession extends ChangeNotifier {
  static final AuthSession _instance = AuthSession._internal();
  static AuthSession get instance => _instance;

  AuthSession._internal();

  bool _isGuest = false;
  String _userName = 'Ahmad Fauzi';
  String _userPhone = '+62 812-7578-953';
  String _userRole = 'Wisatawan Nusantara';
  String _userOrigin = 'Padang, Sumatera Barat';

  bool get isGuest => _isGuest;
  String get userName => _isGuest ? 'Tamu WISGO' : _userName;
  String get userPhone => _isGuest ? '-' : _userPhone;
  String get userRole => _isGuest ? 'Mode Tamu • Belum Masuk' : _userRole;
  String get userOrigin => _isGuest ? 'Ranah Minang' : _userOrigin;
  String get userInitials => _isGuest
      ? 'TM'
      : _userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

  void setGuestMode() {
    _isGuest = true;
    notifyListeners();
  }

  void setAuthenticatedUser({
    String name = 'Ahmad Fauzi',
    String phone = '+62 812-7578-953',
    String role = 'Wisatawan Nusantara',
    String origin = 'Padang, Sumatera Barat',
  }) {
    _isGuest = false;
    _userName = name;
    _userPhone = phone;
    _userRole = role;
    _userOrigin = origin;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? phone,
    String? role,
    String? origin,
  }) {
    if (name != null && name.trim().isNotEmpty) _userName = name.trim();
    if (phone != null && phone.trim().isNotEmpty) _userPhone = phone.trim();
    if (role != null && role.trim().isNotEmpty) _userRole = role.trim();
    if (origin != null && origin.trim().isNotEmpty) _userOrigin = origin.trim();
    notifyListeners();
  }
}
