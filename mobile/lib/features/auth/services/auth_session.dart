import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/api_config.dart';

/// Pengelola status sesi autentikasi pengguna WISGO (Singleton ChangeNotifier)
/// Tersinkronisasi atomik dengan ApiConfig.authNotifier agar Tab Profil & seluruh
/// fitur tidak pernah mengalami desinkronisasi antara Mode Tamu dan Pengguna Login.
class AuthSession extends ChangeNotifier {
  static final AuthSession _instance = AuthSession._internal();
  static AuthSession get instance => _instance;

  AuthSession._internal();

  bool _isGuest = true;
  String _userName = 'Wisatawan WISGO';
  String _userPhone = '';
  String _userEmail = '';
  String _userRole = 'Wisatawan Nusantara';
  String _userOrigin = 'Padang, Sumatera Barat';
  String _emergencyContactName = '';
  String _emergencyContactPhone = '';
  bool _isProfileComplete = false;

  bool get isGuest => _isGuest && !ApiConfig.isAuthenticated;
  String get userName => isGuest ? 'Tamu WISGO' : _userName;
  String get userPhone => isGuest ? '-' : _userPhone;
  String get userEmail => isGuest ? '' : _userEmail;
  String get userRole => isGuest ? 'Mode Tamu • Belum Masuk' : _userRole;
  String get userOrigin => isGuest ? 'Ranah Minang' : _userOrigin;
  String get emergencyContactName => isGuest ? '' : _emergencyContactName;
  String get emergencyContactPhone => isGuest ? '' : _emergencyContactPhone;
  bool get isProfileComplete => _isProfileComplete;

  /// Persentase kelengkapan profil (5 field Opsi 2: Nama, WA, Kota Asal, Email, Kontak Darurat)
  int get profileCompletionPercent {
    if (isGuest) return 0;
    int filled = 0;
    if (_userName.trim().isNotEmpty && _userName != 'Wisatawan WISGO') filled++;
    if (_userPhone.trim().isNotEmpty) filled++;
    if (_userOrigin.trim().isNotEmpty) filled++;
    if (_userEmail.trim().isNotEmpty) filled++;
    if (_emergencyContactName.trim().isNotEmpty &&
        _emergencyContactPhone.trim().isNotEmpty) {
      filled++;
    }
    return ((filled / 5) * 100).round();
  }

  String get userInitials {
    if (isGuest) return 'TM';
    final parts = _userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'WS';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void setGuestMode() {
    _isGuest = true;
    ApiConfig.clearAuth();
    notifyListeners();
  }

  void setAuthenticatedUser({
    String name = 'Wisatawan WISGO',
    String phone = '+62 812-7578-953',
    String email = '',
    String role = 'Wisatawan Nusantara',
    String origin = 'Padang, Sumatera Barat',
    String emergencyContactName = '',
    String emergencyContactPhone = '',
    bool isProfileComplete = false,
  }) {
    _isGuest = false;
    _userName = name.trim().isEmpty ? 'Wisatawan WISGO' : name.trim();
    _userPhone = phone.trim();
    _userEmail = email.trim();
    _userRole = role.trim().isEmpty ? 'Wisatawan Nusantara' : role.trim();
    _userOrigin = origin.trim().isEmpty ? 'Padang, Sumatera Barat' : origin.trim();
    _emergencyContactName = emergencyContactName.trim();
    _emergencyContactPhone = emergencyContactPhone.trim();
    _isProfileComplete = isProfileComplete;

    final canonicalPhone = _userPhone.replaceAll(RegExp(r'\D'), '');
    ApiConfig.setAuthSession(
      token: ApiConfig.authToken ?? 'wisgo-otp-session-${DateTime.now().millisecondsSinceEpoch}',
      user: UserProfile(
        id: ApiConfig.currentUser?.id.isNotEmpty == true
            ? ApiConfig.currentUser!.id
            : 'usr-${canonicalPhone.isNotEmpty ? canonicalPhone : 'wisgo'}',
        phoneNumber: _userPhone.isNotEmpty ? _userPhone : canonicalPhone,
        fullName: _userName,
        role: 'tourist',
      ),
    );
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? phone,
    String? email,
    String? role,
    String? origin,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isProfileComplete,
  }) {
    if (name != null && name.trim().isNotEmpty) _userName = name.trim();
    if (phone != null && phone.trim().isNotEmpty) _userPhone = phone.trim();
    if (email != null) _userEmail = email.trim();
    if (role != null && role.trim().isNotEmpty) _userRole = role.trim();
    if (origin != null && origin.trim().isNotEmpty) _userOrigin = origin.trim();
    if (emergencyContactName != null) {
      _emergencyContactName = emergencyContactName.trim();
    }
    if (emergencyContactPhone != null) {
      _emergencyContactPhone = emergencyContactPhone.trim();
    }
    if (isProfileComplete != null) {
      _isProfileComplete = isProfileComplete;
    }

    if (ApiConfig.isAuthenticated) {
      ApiConfig.setCurrentUser(
        UserProfile(
          id: ApiConfig.currentUser?.id ?? 'usr-wisgo',
          phoneNumber: _userPhone.isNotEmpty
              ? _userPhone
              : (ApiConfig.currentUser?.phoneNumber ?? ''),
          fullName: _userName,
          role: ApiConfig.currentUser?.role ?? 'tourist',
        ),
      );
    }
    notifyListeners();
  }
}
