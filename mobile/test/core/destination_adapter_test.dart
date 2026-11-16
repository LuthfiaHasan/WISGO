import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/features/saved/data/destination_adapter.dart';

void main() {
  group('DestinationAdapter Tests', () {
    test('Should adapt Supabase destination JSON correctly to SavedDestinationModel', () {
      final sampleJson = {
        'id': 'harau-granit-01',
        'name': 'Lembah Harau & Sarasah Bunta',
        'category': 'Alam',
        'city_regency': 'Kab. Lima Puluh Kota',
        'description': 'Ngarai granit menjulang tinggi dengan air terjun alami dan sawah hijau.',
        'cover_image': 'https://example.com/harau.jpg',
        'entry_fee': 15000,
        'medan_indicator': {
          'vehicle_access': 'Mobil & Bus Pariwisata',
          'trekking_level': 'Mudah (Jalan Aspal)',
          'cellular_signal': 'Kuat 4G',
          'facilities': 'Toilet, Musala, Parkir Luas, Homestay',
        },
        'tariffs': [
          {
            'item_name': 'Tiket Masuk Resmi Perda',
            'price': 15000,
            'unit': 'per orang',
            'regulation_ref': 'Perda Kab. 50 Kota No. 4/2024',
          },
          {
            'item_name': 'Parkir Resmi Motor',
            'price': 5000,
            'unit': 'per motor',
            'regulation_ref': 'Perda Kab. 50 Kota No. 4/2024',
          },
          {
            'item_name': 'Parkir Resmi Mobil/Bus',
            'price': 10000,
            'unit': 'per mobil',
            'regulation_ref': 'Perda Kab. 50 Kota No. 4/2024',
          },
        ]
      };

      final model = DestinationAdapter.fromJson(sampleJson, index: 1);

      expect(model.id, equals('harau-granit-01'));
      expect(model.title, equals('Lembah Harau & Sarasah Bunta'));
      expect(model.region, equals('Payakumbuh & 50 Kota'));
      expect(model.natureType, equals('Gunung & Lembah'));
      expect(model.perdaRef, equals('Perda Kab. 50 Kota No. 4/2024'));
      expect(model.calcRates.tiket, equals(15000));
      expect(model.calcRates.motor, equals(5000));
      expect(model.calcRates.mobil, equals(10000));
      expect(model.facilities.contains('Toilet'), isTrue);
      expect(model.tariffs.length, equals(3));
    });

    test('Should handle fallback values gracefully when fields are missing', () {
      final minimalJson = {
        'id': 'pantai-gandoriah',
        'name': 'Pantai Gandoriah Pariaman',
        'city_regency': 'Kota Pariaman',
      };

      final model = DestinationAdapter.fromJson(minimalJson, index: 2);

      expect(model.id, equals('pantai-gandoriah'));
      expect(model.natureType, equals('Pantai & Bahari'));
      expect(model.region, equals('Daerah Terpencil'));
      expect(model.calcRates.tiket, equals(10000)); // default fee
      expect(model.facilities.isNotEmpty, isTrue);
      expect(model.tariffs.isNotEmpty, isTrue);
    });
  });
}
