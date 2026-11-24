import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'api_config.dart';

/// Guard autentikasi untuk memagari aksi yang memerlukan akun terverifikasi
class AuthGuard {
  /// Memeriksa status autentikasi pengguna saat ini.
  /// Jika sudah login, memanggil [onAuthenticated] dan mengembalikan true.
  /// Jika belum login (tamu/guest), menampilkan SnackBar ajakan masuk ke akun WISGO dan mengembalikan false.
  static bool check(BuildContext context, {VoidCallback? onAuthenticated}) {
    if (ApiConfig.isAuthenticated) {
      if (onAuthenticated != null) {
        onAuthenticated();
      }
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Silakan masuk terlebih dahulu untuk mengakses fitur ini.'),
        action: SnackBarAction(
          label: 'Masuk',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ),
    );
    return false;
  }
}
