import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/features/auth/services/auth_session.dart';
import 'package:rancakin_mobile/features/saved/presentation/screens/saved_places_screen.dart';
import 'package:rancakin_mobile/features/saved/services/destination_review_store.dart';

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
    expect(find.text('Panorama 360°'), findsWidgets);
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

    // 4. Tap 'Detail' on Lembah Harau to navigate directly to DestinationDetailScreen (no pop-up sheet)
    final detailButtonFinder = find.widgetWithText(ElevatedButton, 'Detail').first;
    await tester.ensureVisible(detailButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(detailButtonFinder);
    await tester.pumpAndSettle();

    // Verify we landed directly on clean tabbed full guide screen (no WA Vendor button)
    expect(find.text('Pesan via WhatsApp Vendor'), findsNothing);
    expect(find.text('Panduan'), findsOneWidget);
    expect(find.text('Tarif & Fasilitas'), findsOneWidget);
    expect(find.text('Kesiapan Medan Lapangan'), findsOneWidget);

    // Switch to Tarif & Fasilitas tab
    await tester.tap(find.text('Tarif & Fasilitas'));
    await tester.pumpAndSettle();
    expect(find.text('Rincian Biaya Resmi'), findsOneWidget);

    // Switch to Ulasan tab: verify locked before visit/Open Trip, then unlocked after Open Trip completion
    await tester.tap(find.textContaining('Ulasan ('));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ulasan Terkunci'), findsOneWidget);
    expect(find.text('Tambah Ulasan'), findsNothing);

    AuthSession.instance.setAuthenticatedUser(
      name: 'Wisatawan Uji',
      phone: '081234567890',
    );
    DestinationReviewStore.instance
        .unlockFromCompletedOpenTrip('Air Terjun Lubuk Hitam');
    await tester.pumpAndSettle();
    // Re-open Ulasan tab or rebuild to see unlocked state
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ulasan ('));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Ulasan'), findsOneWidget);

    await tester.tap(find.text('Tambah Ulasan'));
    await tester.pumpAndSettle();
    expect(find.text('Bagikan Pengalaman Anda'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Sangat asri dan tarif transparan!');
    await tester.tap(find.text('Kirim Ulasan'));
    await tester.pumpAndSettle();
    expect(find.text('"Sangat asri dan tarif transparan!"'), findsOneWidget);
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
