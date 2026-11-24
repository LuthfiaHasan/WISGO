import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../data/destination_repository.dart';
import '../destination_detail/destination_detail_screen.dart';

/// Modul FE-1: Mode Zero-Signal / Kantong Offline (Pilar 7)
/// Menyimpan paket data destinasi, peta mikro, dan panduan medan untuk area Blank Spot
class OfflinePocketScreen extends StatefulWidget {
  const OfflinePocketScreen({super.key});

  @override
  State<OfflinePocketScreen> createState() => _OfflinePocketScreenState();
}

class _OfflinePocketScreenState extends State<OfflinePocketScreen> {
  final DestinationRepository _repository = DestinationRepository();

  bool _isAirplaneModeSimulated = false;
  bool _isDownloadingAll = false;

  final List<Map<String, dynamic>> _offlineBundles = [
    {
      'id': 'dest-001',
      'name': 'Lembah Harau',
      'sizeMb': 4.2,
      'isDownloaded': true,
      'items': 'Peta Mikro + 5 Indikator Medan + Tarif Resmi Perda + Audio Pemandu',
      'syncedAt': 'Kemarin, 14:20',
    },
    {
      'id': 'dest-002',
      'name': 'Air Terjun Lubuk Nyarai',
      'sizeMb': 3.8,
      'isDownloaded': true,
      'items': 'Jalur Trekking Hutan Gamaran + Titik Posko Pokdarwis + Kontrak Tarif',
      'syncedAt': '3 hari lalu',
    },
    {
      'id': 'dest-003',
      'name': 'Geopark Nasional Silokek',
      'sizeMb': 5.1,
      'isDownloaded': false,
      'items': 'Peta Kawasan Ngalau + Panduan Batuan Purba Permian & Sinyal',
      'syncedAt': 'Belum diunduh',
    },
  ];

  double get _totalDownloadedMb {
    double sum = 0;
    for (final b in _offlineBundles) {
      if (b['isDownloaded'] == true) {
        sum += (b['sizeMb'] as double);
      }
    }
    return sum;
  }

  void _toggleDownload(int index) async {
    final bundle = _offlineBundles[index];
    final wasDownloaded = bundle['isDownloaded'] as bool;

    if (!wasDownloaded) {
      // Unduh bundle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green800,
          duration: const Duration(seconds: 2),
          content: Text('Mengunduh paket data offline ${bundle['name']}...'),
        ),
      );
      await _repository.getOfflineBundle(bundle['id'] as String);
    }

    setState(() {
      bundle['isDownloaded'] = !wasDownloaded;
      bundle['syncedAt'] = !wasDownloaded ? 'Baru saja' : 'Belum diunduh';
    });
  }

  void _downloadAll() async {
    setState(() => _isDownloadingAll = true);
    for (final b in _offlineBundles) {
      await _repository.getOfflineBundle(b['id'] as String);
      b['isDownloaded'] = true;
      b['syncedAt'] = 'Baru saja';
    }
    if (!mounted) return;
    setState(() => _isDownloadingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.green800,
        content: Text('Seluruh paket data destinasi Blank Spot berhasil disimpan di HP!'),
      ),
    );
  }

  void _openOfflineDestination(String id) async {
    final dest = await _repository.getDestinationById(id);
    if (!mounted || dest == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailScreen(destination: dest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Kantong Offline (Mode Zero-Signal)'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          // 1. BANNER ZERO-SIGNAL / AIRPLANE MODE
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _isAirplaneModeSimulated ? const Color(0xFFFDEEE9) : AppColors.sage100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isAirplaneModeSimulated
                    ? AppColors.coral500.withValues(alpha: 0.3)
                    : AppColors.green800.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isAirplaneModeSimulated
                          ? Icons.airplanemode_active_rounded
                          : Icons.signal_cellular_nodata_rounded,
                      color: _isAirplaneModeSimulated ? AppColors.coral500 : AppColors.green800,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isAirplaneModeSimulated
                          ? 'Simulasi Mode Pesawat (100% Luring Aktif)'
                          : 'Mode Zero-Signal (Area Blank Spot)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: _isAirplaneModeSimulated ? AppColors.coral500 : AppColors.ink900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isAirplaneModeSimulated
                      ? 'Koneksi internet dinonaktifkan. Aplikasi membaca data offline dari cache perangkat secara mulus.'
                      : 'Tetap berfungsi 100% tanpa internet di kawasan Blank Spot (Lembah Harau, Lubuk Nyarai, & Silokek).',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink900, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Uji Mode Pesawat:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isAirplaneModeSimulated ? AppColors.coral500 : AppColors.green800,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isAirplaneModeSimulated,
                      activeColor: AppColors.coral500,
                      onChanged: (val) {
                        setState(() => _isAirplaneModeSimulated = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: val ? AppColors.coral500 : AppColors.green800,
                            content: Text(
                              val
                                ? 'Mode Pesawat Aktif: Menguji keterbacaan data luring...'
                                : 'Kembali ke mode daring normal.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. KARTU STATISTIK PENYIMPANAN MEMORI HP
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.green800.withValues(alpha: 0.12),
                  child: const Icon(Icons.sd_storage_rounded, color: AppColors.green800, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Penyimpanan Offline Terpakai',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        '${_totalDownloadedMb.toStringAsFixed(1)} MB / 25.0 MB dialokasikan',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.ink900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 3. DAFTAR BUNDEL DESTINASI TERSIMPAN
          const Text(
            'Bundel Destinasi Tersimpan di Perangkat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),

          ..._offlineBundles.asMap().entries.map((entry) {
            final idx = entry.key;
            final b = entry.value;
            final isDownloaded = b['isDownloaded'] as bool;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDownloaded ? AppColors.green800.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
                  width: isDownloaded ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDownloaded ? Icons.check_circle : Icons.cloud_download_outlined,
                        color: isDownloaded ? AppColors.green500 : Colors.black45,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b['name'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.sage100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${b['sizeMb']} MB',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b['items'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sinkronisasi: ${b['syncedAt']}',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isDownloaded)
                        OutlinedButton.icon(
                          onPressed: () => _openOfflineDestination(b['id'] as String),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Buka Offline', style: TextStyle(fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green800,
                            side: const BorderSide(color: AppColors.green800),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => _toggleDownload(idx),
                        icon: Icon(
                          isDownloaded ? Icons.delete_outline : Icons.download_rounded,
                          size: 15,
                          color: isDownloaded ? Colors.red.shade600 : AppColors.green800,
                        ),
                        label: Text(
                          isDownloaded ? 'Hapus Cache' : 'Unduh Paket',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDownloaded ? Colors.red.shade600 : AppColors.green800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // 4. TOMBOL UNDUH SEMUA BUNDEL (52PX)
          PillButton(
            text: _isDownloadingAll ? 'Mengunduh Semua...' : 'Unduh Semua Bundel Area Blank Spot',
            icon: const Icon(
              Icons.download_for_offline_outlined,
              color: Colors.white,
              size: 20,
            ),
            height: 52,
            onPressed: _isDownloadingAll ? null : _downloadAll,
          ),
        ],
      ),
    );
  }
}
