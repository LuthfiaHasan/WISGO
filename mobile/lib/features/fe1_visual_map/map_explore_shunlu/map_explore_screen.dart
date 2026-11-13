import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';

/// Layar 03 · Jelajah Peta & Cari Searah Rute (Shunlu)
/// Pilar 2: Navigasi Cerdas & Algoritma Amap
class MapExploreShunluScreen extends StatefulWidget {
  const MapExploreShunluScreen({super.key});

  @override
  State<MapExploreShunluScreen> createState() => _MapExploreShunluScreenState();
}

class _MapExploreShunluScreenState extends State<MapExploreShunluScreen> {
  String _selectedShunluFilter = 'RM Padang';

  static const List<Map<String, dynamic>> _shunluPois = [
    {
      'category': 'RM Padang',
      'name': 'RM Simpang Raya Bukittinggi',
      'detour': 'Detour: +4 menit (350 m)',
      'route': 'Searah koridor Padang → Lembah Harau',
    },
    {
      'category': 'SPBU',
      'name': 'SPBU Pertamina Padang Panjang',
      'detour': 'Detour: +2 menit (120 m)',
      'route': 'Tepat di sisi kiri jalur utama Lintas Tengah',
    },
    {
      'category': 'Masjid',
      'name': 'Masjid Raya Syekh Ahmad Khatib Al-Minangkabawi',
      'detour': 'Detour: +5 menit (600 m)',
      'route': 'Parkir luas & fasilitas wudu ramah rombongan',
    },
    {
      'category': 'ATM & Bengkel',
      'name': 'ATM Center Bank Nagari & Bengkel Siaga Kelok 9',
      'detour': 'Detour: +3 menit (250 m)',
      'route': 'Sebelum tanjakan jembatan layang Kelok 9',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _shunluPois
        .where((p) => p['category'] == _selectedShunluFilter)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Jelajah Peta & Rute Shunlu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Kanvas Pratinjau Peta Spasial
          Container(
            height: 230,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE7DC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.green800.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green800,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Koridor Aktif: Padang → Bukittinggi → Harau',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                const Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 54,
                    color: AppColors.green800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.alt_route_rounded, color: AppColors.green500),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Algoritma Shunlu (Along-the-Route): mencari tempat singgah tanpa memutar balik.',
                          style: TextStyle(fontSize: 12, color: AppColors.ink900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Cari Searah Rute (Shunlu Filter)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['RM Padang', 'SPBU', 'Masjid', 'ATM & Bengkel'].map((c) {
              final selected = _selectedShunluFilter == c;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.green800,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.ink900,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _selectedShunluFilter = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          ...filtered.map(
            (poi) => Container(
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
                            fontSize: 15,
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
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Tambahkan Singgahan ke Rute',
                    icon: Icons.add_location_alt_outlined,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

