import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/features/booking/data/booking_adapter.dart';

void main() {
  group('BookingAdapter Tests', () {
    test('Should adapt backend partner JSON to QuickBookingItem accurately', () {
      final sampleJson = {
        'id': 'partner-homestay-01',
        'name': 'Homestay Rumah Gadang Kayu Jati',
        'category': 'homestay',
        'whatsapp': '628123456789',
        'standard_fee': 175000,
        'nagari_name': 'Nagari Harau',
      };

      final item = BookingAdapter.fromBackendPartner(sampleJson);

      expect(item.id, equals('partner-homestay-01'));
      expect(item.name, equals('Homestay Rumah Gadang Kayu Jati'));
      expect(item.category, equals('Penginapan'));
      expect(item.price, equals(175000));
      expect(item.provider, equals('Mitra Nagari Harau'));
      expect(item.unit, equals('malam/kamar'));
      expect(item.icon, equals(Icons.holiday_village_rounded));
    });

    test('Should generate valid escrow booking payload', () {
      final sampleJson = {
        'id': 'partner-trans-02',
        'name': 'Shuttle Wisata Avanza 6 Penumpang',
        'category': 'transport',
        'standard_fee': 280000,
        'nagari_name': 'Nagari Bungus',
      };

      final item = BookingAdapter.fromBackendPartner(sampleJson);
      final payload = BookingAdapter.toEscrowPayload(item, userId: 'usr-demo-01', quantity: 2);

      expect(payload['partner_id'], equals('partner-trans-02'));
      expect(payload['user_id'], equals('usr-demo-01'));
      expect(payload['total_amount'], equals(560000));
      expect(payload['currency'], equals('IDR'));
      expect(payload['notes'], contains('Shuttle Wisata Avanza'));
    });
  });
}
