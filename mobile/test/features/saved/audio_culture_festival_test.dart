import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/features/saved/presentation/screens/saved_places_screen.dart';

void main() {
  testWidgets('Open Trip does not show Kalender Event duplicate, while Kalender Budaya shows it with full features', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      const MaterialApp(
        home: SavedPlacesScreen(
          initialTabIndex: 1, // Open Trip
          initialLoading: false,
          initialOfflineMode: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. In Open Trip: Verify "Kalender Event & Festival Budaya" is NOT present
    expect(find.text('Trip Go Sumbar'), findsOneWidget);
    expect(find.text('Kalender Event & Festival Budaya'), findsNothing);

    // 2. Switch to Beranda tab and open Kamus Minang from Kategori Layanan card
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kamus').first);
    await tester.pumpAndSettle();

    // 3. Switch to Kalender Budaya tab
    expect(find.text('Kalender Budaya'), findsOneWidget);
    await tester.tap(find.text('Kalender Budaya'));
    await tester.pumpAndSettle();

    // 4. Verify Kalender Event & Festival Budaya card is now present in Kalender Budaya
    expect(find.text('Kalender Event & Festival Budaya'), findsOneWidget);
    expect(find.text('Agenda & Event'), findsOneWidget);
    expect(find.text('Buka Kalender Event'), findsOneWidget);

    // 5. Verify Festival cards are displayed
    expect(find.text('Festival Pasa Harau 2026'), findsOneWidget);
    expect(find.text('Pacu Jawi Tradisional Luhak Nan Tuo'), findsOneWidget);

    // 6. Tap on Festival card to open detail modal
    await tester.tap(find.text('Festival Pasa Harau 2026'));
    await tester.pumpAndSettle();

    // Verify detail modal opened
    expect(find.text('Detail Acara Budaya'), findsOneWidget);
    expect(find.text('Arahkan ke Lokasi GPS'), findsOneWidget);
    expect(find.text('Tentang Acara & Nilai Budaya'), findsOneWidget);
    expect(find.textContaining('Pengingat'), findsWidgets);
  });
}
