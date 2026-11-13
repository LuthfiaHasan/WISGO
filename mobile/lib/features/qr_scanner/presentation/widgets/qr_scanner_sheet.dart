import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Item 8: Pemindaian Plang Kode QR Wisata
/// Pemindai kamera untuk membaca plang informasi wisata dan membuka panduan audio serta peta lokasi.
class QrScannerSheet extends StatefulWidget {
  final VoidCallback? onOpenSiteMap;

  const QrScannerSheet({super.key, this.onOpenSiteMap});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  bool _isFlashOn = false;
  bool _isPlayingAudio = false;
  String _selectedPlang = 'Jam Gadang Bukittinggi';

  final List<Map<String, String>> _samplePlangs = [
    {
      'title': 'Jam Gadang Bukittinggi',
      'sub': 'Pusat Kota Bukittinggi • Dibangun 1926 arsitek Yazin & Sutan Gigi Ameh',
      'caption': 'Narasi: Sejarah Mesin Brixet Langka (Hanya 2 di Dunia: London & Bukittinggi)',
      'code': 'PLANG-BKT-04',
    },
    {
      'title': 'Lembah Harau & Sarasah Bunta',
      'sub': 'Kec. Harau, Kab. 50 Kota • Tebing Granit Raksasa 100–500m',
      'caption': 'Narasi: Legenda Batang Harau & Ekosistem Hutan Lindung Tropis',
      'code': 'PLANG-HRU-01',
    },
    {
      'title': 'Istano Basa Pagaruyung',
      'sub': 'Kec. Tanjung Emas, Batusangkar • Mahakarya Rumah Gadang Luhak Nan Tuo',
      'caption': 'Narasi: Filosofi Ukiran Minang & Alam Takambang Jadi Guru',
      'code': 'PLANG-PGR-02',
    },
  ];

  Map<String, String> get _currentPlangData {
    return _samplePlangs.firstWhere(
      (p) => p['title'] == _selectedPlang,
      orElse: () => _samplePlangs.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(bottom: BorderSide(color: AppColors.warmBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.ink),
                        SizedBox(width: 4),
                        Text('Tutup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
                const Flexible(
                  child: Text(
                    'PEMINDAI PLANG SMART QR',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isFlashOn ? AppColors.terracotta : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      size: 14,
                      color: _isFlashOn ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Simulated Camera Viewfinder
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.forest, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder Frame
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Arahkan ke Plang QR',
                                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.forest.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Otomatis Terdeteksi',
                                style: TextStyle(color: AppColors.cream, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Laser animation line
                      Positioned(
                        top: 90,
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            boxShadow: [
                              BoxShadow(color: AppColors.terracotta.withValues(alpha: 0.8), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Simulation Plang Picker
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PILIH SIMULASI PLANG FISIK:',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brush),
                          ),
                          Text('Uji Coba Scan', style: TextStyle(fontSize: 9.5, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _samplePlangs.map((p) {
                          final isSelected = p['title'] == _selectedPlang;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPlang = p['title']!;
                                    _isPlayingAudio = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.sage : AppColors.cream,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.forest : AppColors.warmBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['title']!.split(' ').first,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? AppColors.forest : AppColors.ink,
                                        ),
                                      ),
                                      Text(
                                        p['code']!,
                                        style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Hasil Scan: Panduan Audio Storytelling & Peta Lokasi
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PLANG TERVERIFIKASI DISPAR SUMBAR',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentPlangData['title']!,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                                ),
                                Text(
                                  _currentPlangData['sub']!,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentPlangData['code']!,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Audio Guide Player Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.warmBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PANDUAN AUDIO SUARA BUDAYA',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                                ),
                                Text(
                                  '01:14 / 03:20',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _isPlayingAudio = !_isPlayingAudio),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: AppColors.forest,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: AppColors.cream,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: 0.38,
                                          backgroundColor: AppColors.sageBorder,
                                          valueColor: const AlwaysStoppedAnimation(AppColors.forest),
                                          minHeight: 5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentPlangData['caption']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Peta Lokasi Mikro
                      Container(
                        height: 90,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.creamSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pin_drop_rounded, size: 24, color: AppColors.terracotta),
                            SizedBox(height: 4),
                            Text(
                              'Posisi Anda: Depan Plang Fisik Gerbang Kawasan',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                            Text(
                              'Peta mikro & denah tapak siap dibuka',
                              style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

