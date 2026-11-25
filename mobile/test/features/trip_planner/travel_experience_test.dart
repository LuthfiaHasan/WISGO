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
    test('1. TravelExperience model stores Jejak WISGO metadata, checkpoints and badges', () {
      final exp = kSampleTravelExperiences.first;
      expect(exp.title, contains('Lembah Harau'));
      expect(exp.destinationName, 'Lembah Harau');
      expect(exp.cityRegency, contains('Lima Puluh Kota'));
      expect(exp.stampNumber, 4);
      expect(exp.levelTitle, 'Panjelajah Nagari');
      expect(exp.checkpoints.length, 4);
      expect(exp.completedCheckpointsCount, 4);
      expect(exp.achievements.isNotEmpty, true);
      expect(exp.promoQrUrl, isNotEmpty);
    });

    test('2. Kategori Perjalanan maps destinations into 5 standard clusters', () {
      expect(
        determineCategoryForDestination('Lembah Harau & Sarasah Bunta'),
        'Alam & Geopark',
      );
      expect(
        determineCategoryForDestination('Kawasan Mandeh Snorkeling & Pulau'),
        'Alam & Geopark',
      );
      expect(
        determineCategoryForDestination('Istano Basa Pagaruyung & Cagar Budaya'),
        'Budaya & Nagari',
      );
      expect(
        determineCategoryForDestination('Desa Wisata Pariangan & Tenun'),
        'Budaya & Nagari',
      );
      expect(
        determineCategoryForDestination('Pasar Kuliner Kapau & Kebun Teh'),
        'Kuliner',
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

    testWidgets('5. TravelShareCardSheet renders Jejak WISGO sticker and full card modes', (tester) async {
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

      expect(find.text('Jejak WISGO'), findsWidgets);
      expect(find.text('Stiker & Kartu'), findsOneWidget);
      expect(find.text('Feed Komunitas'), findsOneWidget);
      expect(find.text('Stiker Transparan (PNG)'), findsOneWidget);
      expect(find.text('Kartu Penuh'), findsOneWidget);
      expect(find.text('Ganti Foto Sendiri'), findsOneWidget);
      expect(find.text('DESTINASI'), findsOneWidget);
      expect(find.text('JEJAK SUMBAR'), findsOneWidget);
      expect(find.text('GELAR'), findsOneWidget);
      expect(find.text('WISGO'), findsOneWidget);
      expect(find.text('Dijelajahi bersama WISGO'), findsOneWidget);
      expect(find.text('IG Story'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('WhatsApp Status'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('6. TravelExperienceDetailSheet renders checkpoint timeline and Jejak WISGO info', (tester) async {
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

      expect(find.text('Jejak WISGO'), findsOneWidget);
      expect(find.text('Check Point Kunjungan'), findsOneWidget);
      expect(find.text('Gerbang Nagari & Pos Registrasi Pokdarwis Harau'), findsOneWidget);
      expect(find.text('Buka Stiker & Kartu Jejak WISGO'), findsOneWidget);
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
