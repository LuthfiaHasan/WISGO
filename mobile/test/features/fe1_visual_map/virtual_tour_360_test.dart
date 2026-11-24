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
        title: 'Drone Udara Lubuk Hitam (150m)',
        type: 'aerial',
        panoramaUrl: 'https://images.unsplash.com/photo-1518709268805',
        hotspots: [
          Hotspot360Model(
            id: 'hs-1',
            sceneId: 'scn-lubuk-aerial',
            type: 'navigasi',
            pitch: -15,
            yaw: 10,
            title: 'Turun ke Titik Darat',
          ),
          Hotspot360Model(
            id: 'hs-2',
            sceneId: 'scn-lubuk-aerial',
            type: 'narasi',
            pitch: 5,
            yaw: -30,
            title: 'Narasi Sejarah Lubuk Hitam',
          ),
          Hotspot360Model(
            id: 'hs-3',
            sceneId: 'scn-lubuk-aerial',
            type: 'musik',
            pitch: -5,
            yaw: 40,
            title: 'Musik Tradisional Minang',
          ),
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

  group('VirtualTour360Screen - Clean 360 View, Narasi Sejarah & Musik Minang', () {
    testWidgets('1. Menghapus pin fasilitas dan kuliner dari tampilan 360', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Fasilitas and Kuliner pins MUST NOT be rendered
      expect(find.text('Fasilitas'), findsNothing);
      expect(find.text('Kuliner'), findsNothing);
      expect(find.text('Musala & Toilet'), findsNothing);
      expect(find.text('Warung Kuliner'), findsNothing);

      // Only 360 viewpoint (Darat), Narasi Sejarah, and Musik Minang are shown
      expect(find.text('Darat'), findsWidgets);
      expect(find.text('Narasi Sejarah'), findsWidgets);
      expect(find.text('Musik Minang'), findsWidgets);
    });

    testWidgets('2. Mengetuk Narasi Sejarah memicu pemutaran audio sejarah', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Tap 'Narasi Sejarah' pin or dock button
      final narasiFinder = find.text('Narasi Sejarah').first;
      await tester.tap(narasiFinder);
      await tester.pump();

      // Floating AI Historical Narration bar should appear
      expect(find.text('NARASI SUARA AI SEJARAH'), findsOneWidget);
    });

    testWidgets('3. Mengetuk Musik Minang memicu pemutaran musik tradisional Minang', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Tap 'Musik Minang' button
      final musikFinder = find.text('Musik Minang').first;
      await tester.tap(musikFinder);
      await tester.pump();

      // Floating Traditional Minang Music bar should appear
      expect(find.text('MUSIK TRADISIONAL MINANGKABAU'), findsOneWidget);
    });

    testWidgets('4. Toggle sudut pandang Drone Udara dan Titik Darat', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Initially aerial mode is true
      expect(find.text('Titik Darat'), findsOneWidget);

      // Tap Titik Darat chip
      await tester.tap(find.text('Titik Darat'));
      await tester.pump();

      // Ground mode selected, bottom dock shows Drone
      expect(find.text('Drone'), findsWidgets);
    });
  });
}
