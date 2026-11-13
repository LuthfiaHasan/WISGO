import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';

/// Modul FE-1: Peringatan Dini Jalur Rawan & Tombol Darurat SOS GPS (Pilar 7)
/// Memantau Sitinjau Lauik, Lembah Anai, dan Kelok 9
class HazardSosScreen extends StatelessWidget {
  const HazardSosScreen({super.key});

  static const List<Map<String, String>> _corridors = [
    {
      'location': 'Jalur Sitinjau Lauik (Padang – Solok)',
      'severity': 'Waspada Kabut & Hujan',
      'message':
          'Jarak pandang 40 meter di Tikungan Panorama 1. Gunakan gigi rendah dan jaga jarak aman.',
      'detour': 'Rute Alternatif: Padang Panjang – Danau Singkarak – Solok',
    },
    {
      'location': 'Jalur Lembah Anai (Padang – Bukittinggi)',
      'severity': 'Buka Terbatas (Buka-Tutup)',
      'message':
          'Perbaikan bahu jalan pasca-banjir bandang. Ikuti arahan petugas di lapangan.',
      'detour': 'Rute Alternatif: Jalur Malalak (Khusus Kendaraan Kecil)',
    },
    {
      'location': 'Jembatan Layang Kelok 9 (Lima Puluh Kota)',
      'severity': 'Aman & Lancar',
      'message': 'Arus lalu lintas lancar dua arah, cuaca cerah berawan.',
      'detour': 'Tidak diperlukan rute pengalihan',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Mitigasi Jalur Rawan & SOS GPS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tombol Darurat SOS GPS
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.coral500.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.emergency_share_rounded,
                      color: AppColors.coral500,
                      size: 26,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sinyal Darurat SOS GPS (SAR & Pokdarwis)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mengirim titik koordinat GPS terakhir Anda ke Posko BPBD Sumbar & Pokdarwis Nagari terdekat.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                PillButton(
                  label: 'Kirim Sinyal Darurat SOS GPS',
                  icon: Icons.sos_rounded,
                  backgroundColor: AppColors.coral500,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.coral500,
                        content: Text(
                          'Simulasi SOS: Koordinat GPS (-0.1023, 100.6728) siap dikirim ke Posko SAR.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Status 3 Koridor Rawan Sumatera Barat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),

          ..._corridors.map((item) {
            final isSafe = item['severity']!.contains('Aman');
            final badgeColor = isSafe ? AppColors.green500 : AppColors.orange500;

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
                          item['location']!,
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
                          color: badgeColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item['severity']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['message']!,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sage100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alt_route,
                          size: 16,
                          color: AppColors.green800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['detour']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

