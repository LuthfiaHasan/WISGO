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

    // 1. Initial Beranda shows clean header + showcase sections
    expect(find.text('Jelajah Sumbar'), findsOneWidget);
    expect(find.text('Kategori Layanan'), findsOneWidget);
    expect(find.text('Rekomendasi Terdekat'), findsOneWidget);
    expect(find.textContaining('Tiket: Rp'), findsNothing);

    // Scroll down to verify the destination cards & compact facility icons
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -850));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tempat Parkir Warga'), findsOneWidget);
    expect(find.text('360° & Denah'), findsWidgets);
    expect(find.text('Detail'), findsWidgets);

    // Scroll back up to Search Bar
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 850));
    await tester.pumpAndSettle();

    // Initial card must NOT have the fee list directly visible
    expect(find.text('RINCIAN BIAYA RESMI (VERTIKAL)'), findsNothing);

    // 2. Search Bar is present and functional
    final searchFinder = find.byType(TextField);
    expect(searchFinder, findsOneWidget);

    await tester.enterText(searchFinder, 'Harau');
    await tester.pumpAndSettle();

    expect(find.text('Lembah Harau & Air Terjun Sarasah Bunta'), findsOneWidget);

    // 3. Sort button opens bottom sheet and allows selecting Jarak Terdekat (GPS)
    expect(find.text('Urutkan'), findsOneWidget);
    await tester.tap(find.text('Urutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Jarak Terdekat (GPS)'), findsOneWidget);
    await tester.tap(find.text('Jarak Terdekat (GPS)'));
    await tester.pumpAndSettle();
    expect(find.text('Terdekat'), findsOneWidget);

    // 4. Tap 'Detail' on Lembah Harau to open detail modal
    final detailButtonFinder = find.widgetWithText(ElevatedButton, 'Detail').first;
    await tester.ensureVisible(detailButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(detailButtonFinder);
    await tester.pumpAndSettle();

    // Check if the modal title is visible
    expect(find.text('DETAIL & TIKET'), findsOneWidget);

    // Sticky Booking Button directs to WhatsApp Vendor
    expect(find.text('Pesan via WhatsApp Vendor'), findsOneWidget);

    // Facilities section is visible in modal
    expect(find.text('LINGKUP FASILITAS KAWASAN WISATA'), findsOneWidget);

    // Scroll down to see Reviews & Fees
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();

    // - Verified Reviews (REQUEST 1)
    expect(find.text('ULASAN WISATAWAN TERVERIFIKASI'), findsOneWidget);

    // Scroll down further to see Fees
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();

    // - Official Perda Fees (REQUEST 1 & 4)
    expect(find.text('RINCIAN BIAYA RESMI'), findsOneWidget);
  });

  testWidgets('Usul Wisata modal opens and renders without unbounded layout error', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      const MaterialApp(
        home: SavedPlacesScreen(
          initialTabIndex: 0,
          initialLoading: false,
          initialOfflineMode: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usul Wisata'), findsOneWidget);
    await tester.tap(find.text('Usul Wisata'));
    await tester.pumpAndSettle();

    expect(find.text('USUL DESTINASI WISATA BARU'), findsOneWidget);
    expect(find.text('Isi Contoh Narasi'), findsOneWidget);
  });
}
