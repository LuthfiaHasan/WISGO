import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/features/saved/presentation/screens/saved_places_screen.dart';

void main() {
  testWidgets('SavedPlacesScreen displays facilities on initial card without fee table', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      const MaterialApp(
        home: SavedPlacesScreen(
          initialTabIndex: 0, // Explore feed
          initialLoading: false,
          initialOfflineMode: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial card must show title and facilities chips
    expect(find.text('Jelajah Daerah Sumbar'), findsOneWidget);
    expect(find.text('FASILITAS LINGKUNGAN:'), findsWidgets);
    expect(find.text('360° & Denah'), findsWidgets);
    expect(find.text('Detail & Pesan'), findsWidgets);

    // Initial card must NOT have the fee list directly visible
    expect(find.text('RINCIAN BIAYA RESMI (VERTIKAL)'), findsNothing);

    // 2. Search Bar is present and functional
    final searchFinder = find.byType(TextField);
    expect(searchFinder, findsOneWidget);

    await tester.enterText(searchFinder, 'Harau');
    await tester.pumpAndSettle();

    expect(find.text('Lembah Harau & Air Terjun Sarasah Bunta'), findsOneWidget);

    // 3. Distance sort chip is present
    expect(find.text('Jarak Terdekat (GPS)'), findsOneWidget);
    await tester.tap(find.text('Jarak Terdekat (GPS)'));
    await tester.pumpAndSettle();

    // 4. Tap 'Detail & Pesan' on Lembah Harau to open detail modal
    final detailButtonFinder = find.widgetWithText(ElevatedButton, 'Detail & Pesan').first;
    await tester.ensureVisible(detailButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(detailButtonFinder);
    await tester.pumpAndSettle();

    // Check if the modal title is visible
    expect(find.text('DETAIL & TIKET'), findsOneWidget);

    // Sticky Booking Button (REQUEST 4)
    expect(find.text('Pesan Tiket & Parkir Resmi'), findsOneWidget);

    // Facilities section is visible in modal
    expect(find.text('LINGKUP FASILITAS KAWASAN WISATA'), findsOneWidget);

    // Scroll down to see Reviews & Fees
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();

    // - Verified Reviews (REQUEST 1)
    expect(find.text('ULASAN WISATAWAN TERVERIFIKASI'), findsOneWidget);

    // Scroll down further to see Fees
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    // - Official Perda Fees (REQUEST 1 & 4)
    expect(find.text('RINCIAN BIAYA RESMI'), findsOneWidget);
  });
}
