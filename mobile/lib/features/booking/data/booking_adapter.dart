import 'package:flutter/material.dart';
import '../presentation/widgets/quick_booking_panel.dart';

/// Lapisan Adaptor Booking Escrow & Mitra Nagari (Zero Merge Conflict).
/// Memetakan data REST API Supabase menjadi `QuickBookingItem` FE tanpa merusak struktur model rekan FE.
class BookingAdapter {
  /// Kamus pemetaan kategori Backend (snake_case) ke Label UI Frontend
  static const Map<String, String> backendToFrontendCategory = {
    'homestay': 'Penginapan',
    'transport': 'Transportasi',
    'pokdarwis': 'Atraksi',
    'pakaian_adat': 'Pakaian Adat',
    'baju_adat': 'Pakaian Adat',
    'kuliner': 'Kuliner',
  };

  /// Kamus pemetaan kategori Frontend ke Backend (untuk filter API)
  static const Map<String, String> frontendToBackendCategory = {
    'Penginapan': 'homestay',
    'Transportasi': 'transport',
    'Atraksi': 'pokdarwis',
    'Pakaian Adat': 'pakaian_adat',
    'Kuliner': 'kuliner',
  };

  /// Mengonversi satu entitas JSON Mitra Nagari dari Supabase menjadi `QuickBookingItem`
  static QuickBookingItem fromBackendPartner(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? 'partner-0';
    final name = json['name']?.toString() ?? 'Mitra Nagari Minang';
    final rawCat = (json['category']?.toString() ?? 'homestay').toLowerCase();
    final category = backendToFrontendCategory[rawCat] ?? 'Penginapan';

    final num? feeNum = json['standard_fee'] is num
        ? json['standard_fee'] as num
        : (json['standard_fee'] != null ? num.tryParse(json['standard_fee'].toString()) : null);
    final int price = (feeNum != null && feeNum > 0) ? feeNum.toInt() : 50000;

    final nagari = json['nagari_name']?.toString() ?? '';
    final provider = nagari.isNotEmpty ? 'Mitra $nagari' : 'Pokdarwis Lokal';

    // Unit default jika belum ditentukan di backend
    String unit = json['unit']?.toString() ?? '';
    if (unit.isEmpty) {
      switch (category) {
        case 'Penginapan':
          unit = 'malam/kamar';
          break;
        case 'Transportasi':
          unit = 'hari / trip';
          break;
        case 'Atraksi':
          unit = 'orang / karcis';
          break;
        case 'Pakaian Adat':
          unit = 'set busana / hari';
          break;
        case 'Kuliner':
          unit = 'porsi / paket';
          break;
        default:
          unit = 'paket';
      }
    }

    final IconData icon = getCategoryIcon(category);
    final desc = json['description']?.toString() ??
        'Layanan resmi terkurasi Pokdarwis Nagari Minangkabau. Transaksi aman via Escrow & QRIS Resmi.';

    return QuickBookingItem(
      id: id,
      category: category,
      name: name,
      provider: provider,
      price: price,
      unit: unit,
      icon: icon,
      description: desc,
    );
  }

  /// Memilih IconData sesuai kategori layanan
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Penginapan':
        return Icons.holiday_village_rounded;
      case 'Transportasi':
        return Icons.directions_car_rounded;
      case 'Atraksi':
        return Icons.confirmation_number_rounded;
      case 'Pakaian Adat':
        return Icons.checkroom_rounded;
      case 'Kuliner':
        return Icons.restaurant_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  /// Membuat payload request untuk endpoint `POST /api/v1/escrow/bookings`
  static Map<String, dynamic> toEscrowPayload(
    QuickBookingItem item, {
    String userId = 'usr-001',
    int quantity = 1,
    String? customNotes,
  }) {
    return {
      'partner_id': item.id,
      'user_id': userId,
      'total_amount': item.price * quantity,
      'currency': 'IDR',
      'notes': customNotes ?? 'Pemesanan ${item.name} ($quantity ${item.unit}) via WISGO Escrow',
    };
  }
}
