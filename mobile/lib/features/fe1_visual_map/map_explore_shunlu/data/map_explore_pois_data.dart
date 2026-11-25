import 'package:latlong2/latlong.dart';

/// Data POI Searah Rute (Shunlu) & Peta Mikro Kawasan Pejalan Kaki (Lembah Harau)
class MapExplorePoisData {
  MapExplorePoisData._();

  static const List<Map<String, dynamic>> shunluPois = [
    {
      'id': 'poi-rm-1',
      'category': 'RM Padang',
      'name': 'RM Simpang Raya Bukittinggi',
      'detour': 'Detour: +4 menit (350 m)',
      'route': 'Searah koridor Padang → Lembah Harau',
      'lat': -0.3055,
      'lng': 100.3695,
      'address': 'Jl. Sudirman No. 8, Bukittinggi',
    },
    {
      'id': 'poi-rm-2',
      'category': 'RM Padang',
      'name': 'Rumah Makan Pak Dt. Padang Panjang',
      'detour': 'Detour: +1 menit (80 m)',
      'route': 'Jalur Lintas Padang - Bukittinggi',
      'lat': -0.4635,
      'lng': 100.3988,
      'address': 'Jl. Sutan Syahrir No. 45, Padang Panjang',
    },
    {
      'id': 'poi-spbu-1',
      'category': 'SPBU',
      'name': 'SPBU Pertamina 14.271.536 Padang Panjang',
      'detour': 'Detour: +2 menit (120 m)',
      'route': 'Tepat di sisi kiri jalur utama Lintas Tengah',
      'lat': -0.4580,
      'lng': 100.4020,
      'address': 'Jl. Raya Padang - Bukittinggi Km 6',
    },
    {
      'id': 'poi-spbu-2',
      'category': 'SPBU',
      'name': 'SPBU Koto Baru Lembah Harau',
      'detour': 'Detour: +3 menit (200 m)',
      'route': 'Pintu masuk kawasan lembah',
      'lat': -0.1180,
      'lng': 100.6550,
      'address': 'Jl. Raya Harau Km 2',
    },
    {
      'id': 'poi-masjid-1',
      'category': 'Masjid',
      'name': 'Masjid Raya Syekh Ahmad Khatib Al-Minangkabawi',
      'detour': 'Detour: +5 menit (600 m)',
      'route': 'Parkir luas & fasilitas wudu ramah rombongan',
      'lat': -0.9250,
      'lng': 100.3620,
      'address': 'Kec. Padang Utara, Kota Padang',
    },
    {
      'id': 'poi-masjid-2',
      'category': 'Masjid',
      'name': 'Masjid Asasi Sigando Padang Panjang (Tertua)',
      'detour': 'Detour: +2 menit (150 m)',
      'route': 'Bangunan bersejarah kayu surau Minang',
      'lat': -0.4700,
      'lng': 100.4100,
      'address': 'Nagari Gunuang, Padang Panjang',
    },
    {
      'id': 'poi-atm-1',
      'category': 'ATM & Bengkel',
      'name': 'ATM Center Bank Nagari & Bengkel Siaga Kelok 9',
      'detour': 'Detour: +3 menit (250 m)',
      'route': 'Sebelum tanjakan jembatan layang Kelok 9',
      'lat': -0.0750,
      'lng': 100.7020,
      'address': 'Jalur Lintas Riau - Sumbar Km 32',
    },
    {
      'id': 'poi-atm-2',
      'category': 'ATM & Bengkel',
      'name': 'Posko Siaga Mobil & Motor Koto Baru',
      'detour': 'Detour: +2 menit (110 m)',
      'route': 'Rest area pasar Koto Baru',
      'lat': -0.3800,
      'lng': 100.3850,
      'address': 'Jl. Raya Bukittinggi - Padang',
    },
  ];

  static const List<LatLng> corridorPoints = [
    LatLng(-0.9500, 100.3540),
    LatLng(-0.6800, 100.3400),
    LatLng(-0.4635, 100.3988),
    LatLng(-0.3800, 100.3850),
    LatLng(-0.3051, 100.3692),
    LatLng(-0.2100, 100.6300),
    LatLng(-0.1023, 100.6728),
  ];

  static const List<LatLng> microMapPoints = [
    LatLng(-0.1030, 100.6710),
    LatLng(-0.1025, 100.6725),
    LatLng(-0.1018, 100.6738),
    LatLng(-0.1012, 100.6746),
    LatLng(-0.1008, 100.6755),
  ];

  static const List<Map<String, dynamic>> microMapPois = [
    {
      'id': 'micro-1',
      'category': 'Gerbang & Loket',
      'name': 'Pintu Gerbang & Loket Karcis Resmi',
      'detour': 'Akses Pejalan Kaki & E-Tiket',
      'route': 'Sesuai Perda No. 4/2023 · Rp 10.000/org',
      'lat': -0.1030,
      'lng': 100.6710,
      'address': 'Kawasan Nagari Harau, Kab. 50 Kota',
      'hasAudio': false,
    },
    {
      'id': 'micro-2',
      'category': 'Budaya & Audio',
      'name': 'Pondok Saluang & Suvenir Nagari Harau',
      'detour': 'Zona Narasi Suara Spasial (≤ 15m)',
      'route': 'Kisah legenda Sarasah & irama Saluang Minang',
      'lat': -0.1025,
      'lng': 100.6725,
      'address': 'Jalur Setapak Bambu Km 0.4',
      'hasAudio': true,
    },
    {
      'id': 'micro-3',
      'category': 'Air Terjun',
      'name': 'Sarasah Bunta (Air Terjun Utama)',
      'detour': 'Kolam Alami & Swafoto',
      'route': 'Tebing granit 200m & kolam air alami pegunungan',
      'lat': -0.1018,
      'lng': 100.6738,
      'address': 'Titik Tengah Lembah Harau',
      'hasAudio': true,
    },
    {
      'id': 'micro-4',
      'category': 'Eco-Trek',
      'name': 'Spot Tebing Granit & Posko Pemandu Nagari',
      'detour': 'Jalur Trekking Berpemandu Pokdarwis',
      'route': 'Wajib registrasi posko pemandu untuk keselamatan',
      'lat': -0.1008,
      'lng': 100.6755,
      'address': 'Kaki Tebing Granit Harau',
      'hasAudio': false,
    },
  ];
}
