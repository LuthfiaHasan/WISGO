import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/features/trip_planner/models/open_trip_model.dart';
import 'package:rancakin_mobile/features/trip_planner/models/travel_experience_model.dart';
import 'package:rancakin_mobile/features/trip_planner/models/weather_model.dart';
import 'package:rancakin_mobile/features/trip_planner/models/ground_condition_model.dart';
import 'package:rancakin_mobile/features/trip_planner/presentation/widgets/travel_share_card_sheet.dart';
import 'package:rancakin_mobile/features/trip_planner/presentation/widgets/travel_experience_sheet.dart';
import 'package:rancakin_mobile/features/trip_planner/presentation/widgets/trip_planner_detail_sheet.dart';

void main() {
  group('Travel Experience & 5 Fitur Utama Tests', () {
    test('1. TravelExperience model stores Strava-like metrics, checkpoints and badges', () {
      final exp = kSampleTravelExperiences.first;
      expect(exp.title, contains('Lembah Harau'));
      expect(exp.distanceKm, 14.8);
      expect(exp.elevationGainMeters, 520);
      expect(exp.checkpoints.length, 4);
      expect(exp.completedCheckpointsCount, 4);
      expect(exp.achievements.isNotEmpty, true);
      expect(exp.promoQrUrl, isNotEmpty);
    });

    test('2. Kategori Perjalanan maps destinations into 5 standard clusters', () {
      expect(
        determineCategoryForDestination('Lembah Harau & Sarasah Bunta'),
        'Wisata Alam & Pegunungan',
      );
      expect(
        determineCategoryForDestination('Kawasan Mandeh Snorkeling & Pulau'),
        'Wisata Bahari & Pesisir',
      );
      expect(
        determineCategoryForDestination('Istano Basa Pagaruyung & Cagar Budaya'),
        'Sejarah & Warisan Minangkabau',
      );
      expect(
        determineCategoryForDestination('Desa Wisata Pariangan & Tenun'),
        'Nagari Adat & Edukasi Budaya',
      );
      expect(
        determineCategoryForDestination('Pasar Kuliner Kapau & Kebun Teh'),
        'Kuliner Otentik & Agrowisata',
      );
    });

    test('3. Informasi Cuaca returns real-time data and trip warnings for destinations', () {
      final weatherHarau = DestinationWeather.getForDestination('Lembah Harau');
      expect(weatherHarau.currentTemp, greaterThan(0));
      expect(weatherHarau.hourlyForecast.length, 4);
      expect(weatherHarau.tripAlert.practicalAdvice.isNotEmpty, true);

      final weatherMandeh = DestinationWeather.getForDestination('Kawasan Mandeh');
      expect(weatherMandeh.cityName, contains('Pesisir Selatan'));
      expect(weatherMandeh.currentCondition, isNotEmpty);
    });

    test('4. GroundCondition minimum character threshold is 30 characters', () {
      expect(kMinGroundReportChars, 30);
      const shortText = 'Air terjun bagus.';
      expect(shortText.length < kMinGroundReportChars, true);

      final sample = kSampleGroundReports.first;
      expect(sample.freeformContent.length >= kMinGroundReportChars, true);
      expect(sample.tags.isNotEmpty, true);
    });

    testWidgets('5. TravelShareCardSheet renders Strava metrics and WisgoQrCodePainter', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exp = kSampleTravelExperiences.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TravelShareCardSheet(experience: exp),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Template Posting Sosial Media'), findsOneWidget);
      expect(find.text('Gaya Instagram'), findsOneWidget);
      expect(find.text('Feed Komunitas'), findsOneWidget);
      expect(find.text('Upload Foto'), findsOneWidget);
      expect(find.text('Post ke Feed WISGO'), findsOneWidget);
      expect(find.text('Unduh Post'), findsOneWidget);
      expect(find.text('14.8'), findsWidgets);
      expect(find.text('+520'), findsWidgets);
      expect(find.byType(WisgoQrCodePainter), findsNothing); // painter used inside CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Aplikasi WISGO Sumatera Barat'), findsOneWidget);
    });

    testWidgets('6. TravelExperienceDetailSheet renders checkpoint timeline', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final exp = kSampleTravelExperiences.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TravelExperienceDetailSheet(experience: exp),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Perjalanan (Experience)'), findsOneWidget);
      expect(find.text('Check Point Perjalanan'), findsOneWidget);
      expect(find.text('Gerbang Nagari & Pos Registrasi Pokdarwis Harau'), findsOneWidget);
      expect(find.text('Bagikan Template Posting (QR Promosi)'), findsOneWidget);
    });

    testWidgets('7. TripPlannerDetailSheet renders manual rundown and add rundown button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final trip = kMockOpenTrips.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripPlannerDetailSheet(trip: trip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RUNDOWN PERJALANAN (MANUAL)'), findsOneWidget);
      expect(find.text('Tambah Jam & Kegiatan Rundown'), findsOneWidget);
      expect(find.text(trip.itinerary.first.activity), findsOneWidget);
    });
  });
}
