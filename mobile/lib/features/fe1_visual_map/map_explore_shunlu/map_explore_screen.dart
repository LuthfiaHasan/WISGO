import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';

/// Layar 03 · Jelajah Peta Interaktif & Cari Searah Rute (Shunlu)
/// Pilar 2: Navigasi Cerdas & Algoritma Amap
class MapExploreShunluScreen extends StatefulWidget {
  const MapExploreShunluScreen({super.key});

  @override
  State<MapExploreShunluScreen> createState() => _MapExploreShunluScreenState();
}

class _MapExploreShunluScreenState extends State<MapExploreShunluScreen> {
  String _selectedShunluFilter = 'RM Padang';
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedPoi;

  // Daftar POI sepanjang koridor Lintas Tengah Sumbar
  static const List<Map<String, dynamic>> _shunluPois = [
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
      'detour': 'Detour: +3 menit (180 m)',
      'route': 'Dekat gerbang wisata nagari adat',
      'lat': -0.4710,
      'lng': 100.4150,
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

  // Garis Koridor Rute Padang -> Padang Panjang -> Bukittinggi -> Harau
  static const List<LatLng> _corridorPoints = [
    LatLng(-0.9500, 100.3540), // Padang
    LatLng(-0.6800, 100.3400), // Sicincin
    LatLng(-0.4635, 100.3988), // Padang Panjang
    LatLng(-0.3800, 100.3850), // Koto Baru
    LatLng(-0.3051, 100.3692), // Bukittinggi
    LatLng(-0.2100, 100.6300), // Payakumbuh
    LatLng(-0.1023, 100.6728), // Lembah Harau
  ];

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'RM Padang':
        return Icons.restaurant;
      case 'SPBU':
        return Icons.local_gas_station;
      case 'Masjid':
        return Icons.mosque;
      case 'ATM & Bengkel':
      default:
        return Icons.build_circle;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'RM Padang':
        return AppColors.coral500;
      case 'SPBU':
        return AppColors.orange500;
      case 'Masjid':
        return AppColors.green800;
      case 'ATM & Bengkel':
      default:
        return AppColors.indigo500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _shunluPois
        .where((p) => p['category'] == _selectedShunluFilter)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Jelajah Peta & Rute Shunlu'),
        actions: [
          IconButton(
            tooltip: 'Fokus ke Koridor',
            icon: const Icon(Icons.my_location, color: AppColors.green800),
            onPressed: () {
              _mapController.move(const LatLng(-0.3800, 100.4100), 10.5);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. KANVAS PETA INTERAKTIF OPENSTREETMAP (FLUTTER_MAP V8)
          SizedBox(
            height: 310,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(-0.3800, 100.4100), // Tengah Sumbar
                    initialZoom: 10.2,
                    minZoom: 8.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // Lapisan Tile OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wisgo.rancakin',
                    ),

                    // Garis Polyline Koridor Rute Aktif
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _corridorPoints,
                          color: AppColors.green800.withOpacity(0.85),
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),

                    // Marker POI Searah Rute
                    MarkerLayer(
                      markers: filtered.map((poi) {
                        final lat = poi['lat'] as double;
                        final lng = poi['lng'] as double;
                        final isSelected = _selectedPoi?['id'] == poi['id'];
                        final color = _categoryColor(poi['category'] as String);

                        return Marker(
                          point: LatLng(lat, lng),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedPoi = poi);
                              _mapController.move(LatLng(lat, lng), 12.5);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? color : Colors.white,
                                  width: isSelected ? 3.0 : 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _categoryIcon(poi['category'] as String),
                                color: isSelected ? color : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Badge Info Koridor Mengambang di Atas Peta
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.green800.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.alt_route, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Koridor: Padang → Padang Panjang → Bukittinggi → Harau',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Kartu Mengambang (Floating Card) saat Marker Ditekan
                if (_selectedPoi != null)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _categoryColor(
                              _selectedPoi!['category'] as String,
                            ),
                            child: Icon(
                              _categoryIcon(_selectedPoi!['category'] as String),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedPoi!['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.ink900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _selectedPoi!['detour'] as String,
                                  style: const TextStyle(
                                    color: AppColors.green500,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _selectedPoi = null),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. FILTER KATEGORI SEARAH RUTE (SHUNLU)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari Searah Rute (Algoritma Shunlu)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'RM Padang',
                      'SPBU',
                      'Masjid',
                      'ATM & Bengkel',
                    ].map((c) {
                      final selected = _selectedShunluFilter == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: AppColors.green800,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.ink900,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedShunluFilter = c;
                              _selectedPoi = null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 3. DAFTAR KARTU POI BESERTA LABEL DETOUR
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final poi = filtered[index];
                final color = _categoryColor(poi['category'] as String);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              poi['name'] as String,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green500.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              poi['detour'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.green500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        poi['route'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        poi['address'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: PillButton(
                              label: 'Tambahkan ke Rute',
                              icon: Icons.add_location_alt_outlined,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.green800,
                                    content: Text(
                                      '${poi['name']} ditambahkan sebagai singgahan koridor.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 52,
                            width: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                side: BorderSide(color: color),
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                setState(() => _selectedPoi = poi);
                                _mapController.move(
                                  LatLng(
                                    poi['lat'] as double,
                                    poi['lng'] as double,
                                  ),
                                  13.5,
                                );
                              },
                              child: Icon(Icons.location_searching, color: color),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
