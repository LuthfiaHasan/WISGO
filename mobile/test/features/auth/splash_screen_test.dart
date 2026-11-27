import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/core/widgets/wisgo_logo.dart';
import 'package:rancakin_mobile/features/auth/presentation/screens/location_onboarding_screen.dart';
import 'package:rancakin_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:rancakin_mobile/features/saved/presentation/screens/saved_places_screen.dart';

void main() {
  testWidgets('SplashScreen displays 3 scenic slides, real Wisgo logo, and navigates correctly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();

    // 1. Verify Real WISGO Logo is displayed
    expect(find.byType(WisgoLogo), findsOneWidget);

    // 2. Verify Slide 1 contents
    expect(find.text('Jelajahi\nSumatera Barat'), findsOneWidget);
    expect(find.text('Temukan keindahan tersembunyi negeri Minang yang menakjubkan'), findsOneWidget);
    expect(find.text('Mulai Jelajah'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);

    // 3. Tap 'Mulai Jelajah' button to advance to Slide 2
    await tester.tap(find.text('Mulai Jelajah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Slide 2 contents
    expect(find.text('Wisata Autentik\nMinang'), findsOneWidget);
    expect(find.text('Nikmati budaya, kuliner, dan alam Sumatera Barat dalam genggamanmu'), findsOneWidget);
    expect(find.text('Eksplorasi Sekarang'), findsOneWidget);

    // 4. Tap 'Eksplorasi Sekarang' to advance to Slide 3
    await tester.tap(find.text('Eksplorasi Sekarang'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Slide 3 contents
    expect(find.text('Perjalanan Tak\nTerlupakan'), findsOneWidget);
    expect(find.text('Tarif resmi, rute akurat, dan pengalaman wisata terbaik bersamamu'), findsOneWidget);
    expect(find.text('Ayo Mulai'), findsOneWidget);

    // 5. Tap 'Ayo Mulai' to transition to LocationOnboardingScreen
    await tester.tap(find.text('Ayo Mulai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LocationOnboardingScreen), findsOneWidget);
    // 6. Verify 'Lewati' button exists on LocationOnboardingScreen and skips to Beranda
    expect(find.text('Lewati'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SavedPlacesScreen), findsOneWidget);
  });

  testWidgets('SplashScreen Lewati button navigates directly to SavedPlacesScreen as Guest without login', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();

    // Tap 'Lewati' button immediately on Slide 1 -> langsung masuk sebagai tamu ke SavedPlacesScreen
    await tester.tap(find.text('Lewati'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SavedPlacesScreen), findsOneWidget);
  });
}
