import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/features/fe1_visual_map/models/destination_model.dart';
import 'package:rancakin_mobile/features/fe1_visual_map/virtual_tour_360/virtual_tour_360_screen.dart';

void main() {
  const testDest = DestinationModel(
    id: 'dest-lubuk-hitam',
    name: 'Air Terjun Lubuk Hitam (Cindakir) 3 Tingkat',
    category: 'Alam',
    cityRegency: 'Kota Padang',
    description:
        'Air terjun bertingkat alami di kawasan Teluk Kabung dengan panorama asri.',
    latitude: -1.0245,
    longitude: 100.4123,
    coverImage: 'https://images.unsplash.com/photo-1518709268805',
    crowdLevel: 'Tenang',
    scenes360: [
      Scene360Model(
        id: 'scn-lubuk-aerial',
        destinationId: 'dest-lubuk-hitam',
        title: 'Panorama Lubuk Hitam',
        type: 'aerial',
        panoramaUrl: 'https://images.unsplash.com/photo-1518709268805',
        hotspots: [
          Hotspot360Model(
            id: 'hs-fasilitas-blocked',
            sceneId: 'scn-lubuk-aerial',
            type: 'fasilitas',
            pitch: 0,
            yaw: 70,
            title: 'Musala & Toilet',
          ),
          Hotspot360Model(
            id: 'hs-kuliner-blocked',
            sceneId: 'scn-lubuk-aerial',
            type: 'kuliner',
            pitch: 0,
            yaw: -70,
            title: 'Warung Kuliner',
          ),
        ],
      ),
    ],
  );

  Widget createWidget() {
    return const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(412, 915)),
        child: VirtualTour360Screen(destination: testDest),
      ),
    );
  }

  group('VirtualTour360Screen - Pure Panorama View 360°', () {
    testWidgets('1. Tidak menampilkan ikon hotspot mengambang atau tombol Denah', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Fasilitas'), findsNothing);
      expect(find.text('Kuliner'), findsNothing);
      expect(find.text('Audio'), findsNothing);
      expect(find.text('Darat'), findsNothing);
      expect(find.text('Denah'), findsNothing);
      expect(find.text('Musala & Toilet'), findsNothing);
      expect(find.text('Warung Kuliner'), findsNothing);
    });

    testWidgets('2. Menampilkan judul destinasi dan petunjuk geser panorama 360°', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Air Terjun Lubuk Hitam (Cindakir) 3 Tingkat'), findsOneWidget);
      expect(find.text('Geser layar untuk melihat panorama 360° destinasi'), findsOneWidget);
    });

    testWidgets('3. Toggle tampilan Panorama Luas dan Dekat berfungsi', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Panorama Luas'), findsOneWidget);
      expect(find.text('Dekat'), findsOneWidget);

      await tester.tap(find.text('Dekat'));
      await tester.pump();

      await tester.tap(find.text('Panorama Luas'));
      await tester.pump();
    });

    testWidgets('4. Toggle Mode VR menampilkan tampilan stereoscopic', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('LEFT EYE'), findsNothing);
      await tester.tap(find.byIcon(Icons.vrpano_rounded));
      await tester.pump();

      expect(find.text('LEFT EYE'), findsOneWidget);
      expect(find.text('RIGHT EYE'), findsOneWidget);
    });
  });
}
