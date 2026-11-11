import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/pill_button.dart';
import 'core/widgets/crowd_badge.dart';

void main() {
  runApp(const RancakinApp());
}

class RancakinApp extends StatelessWidget {
  const RancakinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rancak.in - Wisata Pintar Sumbar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreenPlaceholder(),
    );
  }
}

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rancak.in (Sumatera Barat)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.green800),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Selamat Datang
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sage100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco, color: AppColors.green800, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selamat datang di Ranah Minang! Jelajahi 19 Kab/Kota dengan 8 Pilar Smart Tourism.',
                      style: TextStyle(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contoh Kartu Destinasi (4 Statistik & 5 Indikator)
            Text(
              'Destinasi Pilihan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.black.withOpacity(0.06)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lembah Harau',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                        CrowdBadge(level: CrowdLevel.sedang),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kabupaten Lima Puluh Kota',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    // Grid 4 Statistik Sederhana
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Jarak', '124 km'),
                        _buildStat('Waktu', '2j 45m'),
                        _buildStat('Sinyal', 'Blank Spot'),
                        _buildStat('Tiket', 'Rp 10.000'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pill Button CTA Primer 52px
                    PillButton(
                      label: 'Jelajah Tur 360°',
                      icon: Icons.view_in_ar,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }
}

