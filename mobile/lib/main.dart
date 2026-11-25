import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WisgoApp());
}

/// Root Application WISGO - Sistem Wisata Pintar Sumatera Barat
/// Mengaktifkan tema global AppTheme.lightTheme (desain.md 06.1).
class WisgoApp extends StatelessWidget {
  const WisgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WISGO - Wisata Pintar Sumatera Barat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
