import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/core/models/user_profile.dart';
import 'package:rancakin_mobile/core/network/api_config.dart';
import 'package:rancakin_mobile/core/services/api_service.dart';
import 'package:rancakin_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:rancakin_mobile/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:rancakin_mobile/features/saved/presentation/screens/saved_places_screen.dart';

void main() {
  setUp(() {
    ApiConfig.clearAuth();
  });

  group('Auth Flow UI & Session Reactivity Tests', () {
    testWidgets('LoginScreen should display title, phone input, and submit button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Masuk ke Akun WISGO'), findsNothing);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
      expect(find.text('Kirim Kode OTP 4 Digit'), findsOneWidget);
      expect(find.text('812-7578-953'), findsOneWidget);
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
      expect(find.text('Lanjutkan dengan Apple'), findsOneWidget);
    });

    testWidgets('OtpVerificationScreen displays devOtpCode banner and allows autofill', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(
            phoneNumber: '+62 812-7578-953',
            canonicalPhone: '628127578953',
            devOtpCode: '2486',
          ),
        ),
      );

      // Verify header and phone
      expect(find.text('Verifikasi Kode OTP'), findsOneWidget);
      expect(find.text('+62 812-7578-953'), findsOneWidget);

      // Tap 'Isi Otomatis' button
      final autoFillFinder = find.text('Isi Otomatis');
      expect(autoFillFinder, findsOneWidget);
      await tester.tap(autoFillFinder);
      await tester.pumpAndSettle();

      // After auto-fill, digits 2, 4, 8, 6 should be in slots
      expect(find.text('2'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(find.text('8'), findsWidgets);
      expect(find.text('6'), findsWidgets);
    });

    testWidgets('SavedPlacesScreen Profile tab reacts to ApiConfig auth state dynamically', (tester) async {
      // Start in Guest Mode
      ApiConfig.clearAuth();

      await tester.pumpWidget(
        const MaterialApp(
          home: SavedPlacesScreen(initialTabIndex: 4),
        ),
      );
      await tester.pumpAndSettle();

      // In Guest Mode:
      expect(find.text('MODE TAMU'), findsOneWidget);
      expect(find.text('Akun Tamu'), findsOneWidget);
      expect(find.text('Masuk untuk Fitur Penuh'), findsOneWidget);
      expect(find.text('Masuk dengan Nomor WhatsApp'), findsOneWidget);

      // Now authenticate atomically
      ApiConfig.setAuthSession(
        token: 'mock-jwt-token-12345',
        user: const UserProfile(
          id: 'usr-minang-007',
          phoneNumber: '628127578953',
          fullName: 'Bujang Ranah Minang',
          role: 'tourist',
        ),
      );
      await tester.pumpAndSettle();

      // Profile View should instantly react without page reload!
      expect(find.text('AKUN WISGO'), findsOneWidget);
      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('Bujang Ranah Minang'), findsOneWidget);
      expect(find.text('OTP WhatsApp Terverifikasi'), findsOneWidget);

      // Scroll down to reveal the logout button
      await tester.dragUntilVisible(
        find.text('Keluar dari Akun (Logout)'),
        find.byType(ListView).last,
        const Offset(0, -250),
      );
      expect(find.text('Keluar dari Akun (Logout)'), findsOneWidget);

      // Now logout via ApiService
      ApiService.logout();
      await tester.pumpAndSettle();

      // Scroll back up to verify Guest Mode banner
      await tester.dragUntilVisible(
        find.text('Masuk untuk Fitur Penuh'),
        find.byType(ListView).last,
        const Offset(0, 300),
      );
      expect(find.text('MODE TAMU'), findsOneWidget);
      expect(find.text('Akun Tamu'), findsOneWidget);
      expect(find.text('Masuk untuk Fitur Penuh'), findsOneWidget);
    });
  });
}
