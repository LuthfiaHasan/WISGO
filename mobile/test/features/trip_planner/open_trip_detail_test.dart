import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/core/models/user_profile.dart';
import 'package:rancakin_mobile/core/network/api_config.dart';
import 'package:rancakin_mobile/features/trip_planner/models/open_trip_model.dart';
import 'package:rancakin_mobile/features/trip_planner/presentation/widgets/open_trip_card.dart';
import 'package:rancakin_mobile/features/trip_planner/presentation/widgets/open_trip_detail_sheet.dart';

void main() {
  setUp(() {
    ApiConfig.clearAuth();
  });

  final testTrip = kMockOpenTrips.first.copyWith(
    id: 'st-176390001',
    userId: 'usr-host-01',
    destinationId: 'dest-001',
    title: 'Eksplor Lembah Harau Weekend',
    singleDestination: 'Lembah Harau & Sarasah Bunta',
    category: 'Wisata Alam & Pegunungan',
    departureDate: 'Sabtu, 28 Nov 2026 • 06.00 WIB',
    duration: '2 Hari 1 Malam',
    quotaMax: 8,
    quotaFilled: 6,
    pricePerPerson: 135000,
    contactWa: '081211111111',
  );

  group('Open Trip Detail & Management Tests (BE-2 Contract)', () {
    testWidgets('1. Mengetuk kartu Open Trip membuka Modal Detail dengan info lengkap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OpenTripCard(trip: testTrip),
            ),
          ),
        ),
      );

      // Verify card exists
      expect(find.byType(OpenTripCard), findsOneWidget);
      expect(find.text('Eksplor Lembah Harau Weekend'), findsOneWidget);

      // Tap card title to open modal bottom sheet
      await tester.tap(find.text('Eksplor Lembah Harau Weekend').first);
      await tester.pumpAndSettle();

      // Modal bottom sheet should be open
      expect(find.byType(OpenTripDetailSheet), findsOneWidget);

      // Verify complete details displayed inside sheet
      expect(find.text('Eksplor Lembah Harau Weekend'), findsWidgets);
      expect(find.text('Wisata Alam & Pegunungan'), findsWidgets);
      expect(find.text('Lembah Harau & Sarasah Bunta'), findsWidgets);
      expect(find.text('Sabtu, 28 Nov 2026 • 06.00 WIB'), findsWidgets);
      // expect(find.text('081211111111'), findsWidgets);
      expect(find.textContaining('135.000'), findsWidgets);
      expect(find.textContaining('Kursi Tersisa'), findsWidgets);
    });

    testWidgets('2. Host melihat daftar peserta, tombol Edit Open Trip, dan tombol Hapus Trip', (tester) async {
      // Authenticate as the host
      ApiConfig.setAuthSession(
        token: 'host-auth-token-999',
        user: const UserProfile(
          id: 'usr-host-01',
          phoneNumber: '628121111111',
          fullName: 'Rahmat Hidayat',
          role: 'organizer',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenTripDetailSheet(trip: testTrip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Host view requirements:
      // A. Tombol Edit Open Trip harus tampil
      expect(find.text('Edit Trip Go'), findsOneWidget);

      // B. Tombol Hapus Trip harus tampil
      expect(find.text('Hapus Trip'), findsOneWidget);

      // C. Daftar Peserta Bergabung harus tampil untuk Host
      expect(find.textContaining('Daftar Peserta Bergabung'), findsOneWidget);

      // D. Host TIDAK boleh melihat tombol Gabung Open Trip
      expect(find.text('Gabung Trip Go'), findsNothing);
    });

    testWidgets('3. Non-host / Tamu hanya melihat tombol Gabung (tanpa Edit dan tanpa Hapus)', (tester) async {
      // Unauthenticated (Guest)
      ApiConfig.clearAuth();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenTripDetailSheet(trip: testTrip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Non-host requirements:
      // A. Tombol Gabung Open Trip harus tampil
      expect(find.text('Gabung Trip Go'), findsOneWidget);

      // B. Tombol Edit TIDAK boleh tampil
      expect(find.text('Edit Trip Go'), findsNothing);

      // C. Tombol Hapus TIDAK boleh tampil
      expect(find.text('Hapus Trip'), findsNothing);

      // D. Daftar peserta private host TIDAK boleh tampil
      expect(find.textContaining('Daftar Peserta Bergabung'), findsNothing);
    });

    testWidgets('4. Non-host saat kuota kursi habis menampilkan badge Penuh', (tester) async {
      ApiConfig.clearAuth();

      final fullTrip = testTrip.copyWith(quotaFilled: 8, quotaMax: 8);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenTripDetailSheet(trip: fullTrip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display Penuh instead of Gabung
      expect(find.textContaining('Penuh'), findsWidgets);
      expect(find.text('Gabung Trip Go'), findsNothing);
    });

    testWidgets('5. Host mengetuk Edit Open Trip membuka form modal edit lengkap', (tester) async {
      ApiConfig.setAuthSession(
        token: 'host-auth-token-999',
        user: const UserProfile(
          id: 'usr-host-01',
          phoneNumber: '628121111111',
          fullName: 'Rahmat Hidayat',
          role: 'organizer',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenTripDetailSheet(trip: testTrip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit Open Trip
      await tester.tap(find.text('Edit Trip Go'));
      await tester.pumpAndSettle();

      // Verify edit form modal is shown with editable fields
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Judul Trip Go'), findsOneWidget);
      expect(find.text('Destinasi Utama (Katalog BE-1)'), findsOneWidget);
      expect(find.text('Sisa Kursi'), findsWidgets);
      expect(find.text('Biaya / Orang (Rp)'), findsOneWidget);
      expect(find.text('Nomor WhatsApp Host'), findsOneWidget);
    });
  });
}
