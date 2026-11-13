import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';

/// Modul FE-1: Mode Zero-Signal / Offline Pocket (Pilar 7)
/// Menyimpan paket data destinasi, peta mikro, dan panduan medan untuk area Blank Spot
class OfflinePocketScreen extends StatelessWidget {
  const OfflinePocketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Kantong Offline (Mode Zero-Signal)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.sage100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.signal_cellular_nodata_rounded,
                  color: AppColors.green800,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tetap berfungsi 100% tanpa internet saat memasuki kawasan Blank Spot seperti Lembah Harau, Lubuk Nyarai, & Geopark Silokek.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ink900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Bundel Destinasi Tersimpan di Perangkat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),

          _buildBundleTile(
            title: 'Bundel Offline: Lembah Harau',
            subtitle: 'Peta Mikro + 5 Indikator Medan + Tarif Resmi Perda (4.2 MB)',
            isDownloaded: true,
          ),
          _buildBundleTile(
            title: 'Bundel Offline: Air Terjun Lubuk Nyarai',
            subtitle: 'Jalur Trekking Hutan Gamaran + Kontak Pokdarwis (3.8 MB)',
            isDownloaded: true,
          ),
          _buildBundleTile(
            title: 'Bundel Offline: Geopark Nasional Silokek',
            subtitle: 'Peta Kawasan Ngalau + Panduan Keselamatan (5.1 MB)',
            isDownloaded: false,
          ),
          const SizedBox(height: 16),

          PillButton(
            label: 'Unduh Semua Bundel Area Blank Spot',
            icon: Icons.download_for_offline_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.green800,
                  content: Text('Mengunduh bundel offline ke penyimpanan lokal...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBundleTile({
    required String title,
    required String subtitle,
    required bool isDownloaded,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(
            isDownloaded ? Icons.check_circle : Icons.cloud_download_outlined,
            color: isDownloaded ? AppColors.green500 : AppColors.green800,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

