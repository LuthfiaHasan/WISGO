import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../passport/presentation/widgets/digital_passport_sheet.dart';

/// Item 8 & Use Case Diagram:
/// "Scan QR dengan metode check-in GPS" untuk "Tantangan Menaklukkan Destinasi"
/// Scan stempel lokasi saat wisatawan sudah tiba di kawasan wisata (<500m)
/// Memenuhi tantangan 10 destinasi yang di-input oleh Admin Dispar.
class QrScannerSheet extends StatefulWidget {
  final VoidCallback? onOpenSiteMap;

  const QrScannerSheet({super.key, this.onOpenSiteMap});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  bool _isFlashOn = false;
  bool _isPlayingAudio = false;
  bool _isScanning = false;
  bool _hasCheckedIn = false;
  String _selectedDestination = 'Jam Gadang & Ngarai Sianok';

  // 10 Destinasi Tantangan Resmi Input Admin Dispar
  final List<Map<String, String>> _challengeDestinations = [
    {
      'title': 'Jam Gadang & Ngarai Sianok',
      'region': 'Kota Bukittinggi',
      'code': 'CHL-BKT-01',
      'gpsDist': '35 m (Di Kawasan)',
      'narasi': 'Mesin Brixet Langka 1926 & Panorama Ngarai Sianok',
    },
    {
      'title': 'Lembah Harau & Sarasah Bunta',
      'region': 'Kab. Lima Puluh Kota',
      'code': 'CHL-HRU-02',
      'gpsDist': '120 m (Di Kawasan)',
      'narasi': 'Tebing Granit 100-500m & Hutan Lindung Tropis Harau',
    },
    {
      'title': 'Istano Basa Pagaruyung',
      'region': 'Kab. Tanah Datar',
      'code': 'CHL-PGR-03',
      'gpsDist': '75 m (Di Kawasan)',
      'narasi': 'Pusat Kebesaran Adat Minang & Mahakarya Rumah Gadang',
    },
    {
      'title': 'Danau Singkarak & Dermaga Ombilin',
      'region': 'Kab. Solok',
      'code': 'CHL-SNK-04',
      'gpsDist': '210 m (Di Kawasan)',
      'narasi': 'Danau Tektonik Terbesar Kedua & Warisan Kereta Tambang Ombilin',
    },
    {
      'title': 'Danau Maninjau & Puncak Lawang',
      'region': 'Kab. Agam',
      'code': 'CHL-MNJ-05',
      'gpsDist': '140 m (Di Kawasan)',
      'narasi': 'Legenda Bujang Sembilan & Jalur Legendaris Kelok 44',
    },
    {
      'title': 'Pantai Air Manis & Batu Malin',
      'region': 'Kota Padang',
      'code': 'CHL-PAM-06',
      'gpsDist': '50 m (Di Kawasan)',
      'narasi': 'Legenda Si Malin Kundang & Garis Pantai Samudera Hindia',
    },
    {
      'title': 'Kawasan Mandeh & Pulau Setan',
      'region': 'Kab. Pesisir Selatan',
      'code': 'CHL-MND-07',
      'gpsDist': '85 m (Di Kawasan)',
      'narasi': 'Surga Bahari Tropis & Gugusan Pulau Eksotis Pesisir Selatan',
    },
    {
      'title': 'Air Terjun Lembah Anai',
      'region': 'Kab. Tanah Datar',
      'code': 'CHL-LBA-08',
      'gpsDist': '25 m (Di Kawasan)',
      'narasi': 'Air Terjun Ikonik di Tepi Jalur Nasional Trans-Sumatera',
    },
    {
      'title': 'Nagari Tuo Pariangan',
      'region': 'Kab. Tanah Datar',
      'code': 'CHL-PRG-09',
      'gpsDist': '95 m (Di Kawasan)',
      'narasi': 'Nagari Tertua Asal Mula Suku Bangsa Minangkabau',
    },
    {
      'title': 'Air Terjun Lubuk Hitam (Cindakir)',
      'region': 'Kota Padang',
      'code': 'CHL-LBH-10',
      'gpsDist': '40 m (Di Kawasan)',
      'narasi': 'Air Terjun Alami 3 Tingkat Tersembunyi di Perbukitan Cindakir',
    },
  ];

  Map<String, String> get _currentDestinationData {
    return _challengeDestinations.firstWhere(
      (d) => d['title'] == _selectedDestination,
      orElse: () => _challengeDestinations.first,
    );
  }

  void _performCheckInScan() {
    setState(() {
      _isScanning = true;
      _hasCheckedIn = false;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _hasCheckedIn = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 CHECK-IN SUKSES! "${_currentDestinationData['title']}" Tertaklukkan! Stempel Paspor Digital Telah Tercatat.',
            ),
            backgroundColor: AppColors.forest,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _openPassport() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DigitalPassportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
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
                  child: Column(
                    children: [
                      Text(
                        'CHECK-IN GPS & SCAN TIBA DI LOKASI',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.forest,
                        ),
                      ),
                      Text(
                        'Tantangan Menaklukkan Destinasi (Input Admin)',
                        style: TextStyle(fontSize: 9, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isFlashOn ? const Color(0xFFC89242) : Colors.white,
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
                // Info Box: Penjelasan Alur Tantangan Sesuai Use Case
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC89242)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: Color(0xFFC89242), size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scan stempel saat Anda telah TIBA di lokasi wisata. GPS perangkat otomatis divalidasi (< 500m) untuk mencatat penaklukan destinasi di Paspor Digital Anda.',
                          style: TextStyle(fontSize: 11, color: AppColors.ink, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Simulated Camera Viewfinder
                Container(
                  height: 190,
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
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
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
                              child: Text(
                                _isScanning ? 'Memverifikasi Koordinat GPS...' : 'Arahkan ke QR Plang Lokasi',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _hasCheckedIn ? AppColors.forest : const Color(0xFFC89242),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _hasCheckedIn ? '✓ LOKASI TERKONFIRMASI' : 'GPS Radius < 500m OK',
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Laser animation line
                      if (_isScanning)
                        Positioned(
                          top: 85,
                          left: 40,
                          right: 40,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2B755),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFE2B755).withValues(alpha: 0.9), blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Destinasi Picker (10 Destinasi Tantangan Admin)
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
                            'PILIH DESTINASI TANTANGAN (ADMIN INPUT):',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brush),
                          ),
                          Text('10 Destinasi', style: TextStyle(fontSize: 9.5, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 54,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _challengeDestinations.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, idx) {
                            final dest = _challengeDestinations[idx];
                            final isSelected = dest['title'] == _selectedDestination;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDestination = dest['title']!;
                                  _hasCheckedIn = false;
                                  _isPlayingAudio = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.forest : AppColors.cream,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.forest : AppColors.warmBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dest['title']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      dest['region']!,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isSelected ? AppColors.sage : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card Info Lokasi Terpilih & Tombol Scan Check-in
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
                                  'TANTANGAN DESTINASI SUMBAR',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFC89242)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentDestinationData['title']!,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                                ),
                                Text(
                                  '${_currentDestinationData['region']} • ${_currentDestinationData['narasi']}',
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
                              _currentDestinationData['gpsDist']!,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tombol Scan Check-in Tiba di Lokasi
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _performCheckInScan,
                          icon: _isScanning
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(_hasCheckedIn ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded, size: 18),
                          label: Text(
                            _isScanning
                                ? 'Memvalidasi Jarak GPS & Kode Stempel...'
                                : (_hasCheckedIn ? 'Sudah Ditaklukkan (Scan Ulang)' : 'Scan Check-in Tiba di Lokasi Ini'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasCheckedIn ? const Color(0xFF2E6F40) : AppColors.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      if (_hasCheckedIn) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openPassport,
                            icon: const Icon(Icons.verified_rounded, size: 16, color: Color(0xFFC89242)),
                            label: const Text(
                              'Buka Paspor Digital & Pantau Tantangan 10 Destinasi',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFC89242)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC89242)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],

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
                                  'PANDUAN AUDIO HISTORIS TEMPAT',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                                ),
                                Text(
                                  _isPlayingAudio ? 'Sedang Memutar...' : 'Siap Diputar',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _isPlayingAudio = !_isPlayingAudio),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.forest,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: AppColors.cream,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _currentDestinationData['narasi']!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.ink),
                                  ),
                                ),
                              ],
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
