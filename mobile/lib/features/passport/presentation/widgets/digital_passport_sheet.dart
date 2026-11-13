import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PassportBadge {
  final String id;
  final String destinationTitle;
  final String region;
  final String iconSymbol;
  final bool isUnlocked;
  final String? unlockDate;
  final int distanceMeters;
  final String culturalQuote;

  const PassportBadge({
    required this.id,
    required this.destinationTitle,
    required this.region,
    required this.iconSymbol,
    required this.isUnlocked,
    this.unlockDate,
    required this.distanceMeters,
    required this.culturalQuote,
  });
}

class DigitalPassportSheet extends StatefulWidget {
  final String currentDestination;

  const DigitalPassportSheet({
    super.key,
    this.currentDestination = 'Air Terjun Lubuk Hitam (Cindakir) 3 Tingkat',
  });

  @override
  State<DigitalPassportSheet> createState() => _DigitalPassportSheetState();
}

class _DigitalPassportSheetState extends State<DigitalPassportSheet> {
  final List<PassportBadge> _badges = [
    const PassportBadge(
      id: 'bdg-1',
      destinationTitle: 'Air Terjun Lubuk Hitam (Cindakir)',
      region: 'Kota Padang',
      iconSymbol: 'LUB-HITAM',
      isUnlocked: true,
      unlockDate: '13 Nov 2026 • 14:20 WIB',
      distanceMeters: 45,
      culturalQuote: 'Alam Takambang Jadi Guru - Tingkat 3 Kesegaran Alami',
    ),
    const PassportBadge(
      id: 'bdg-2',
      destinationTitle: 'Lembah Harau & Sarasah Bunta',
      region: 'Kab. Lima Puluh Kota',
      iconSymbol: 'HARAU-VALLEY',
      isUnlocked: true,
      unlockDate: '10 Nov 2026 • 11:15 WIB',
      distanceMeters: 120,
      culturalQuote: 'Tinggi Monolit, Dalam Ngarai - Keagungan Nagari',
    ),
    const PassportBadge(
      id: 'bdg-3',
      destinationTitle: 'Istano Basa Pagaruyung',
      region: 'Kab. Tanah Datar',
      iconSymbol: 'PAGARUYUNG',
      isUnlocked: false,
      unlockDate: null,
      distanceMeters: 14200,
      culturalQuote: 'Pusat Kebesaran Adat Minangkabau',
    ),
    const PassportBadge(
      id: 'bdg-4',
      destinationTitle: 'Danau Singkarak & Ombilin',
      region: 'Kab. Solok',
      iconSymbol: 'SINGKARAK',
      isUnlocked: false,
      unlockDate: null,
      distanceMeters: 38400,
      culturalQuote: 'Habitat Ikan Bilih & Warisan Dunia Tambang UNESCO',
    ),
  ];

  bool _isCheckingGps = false;

  int get _unlockedCount => _badges.where((b) => b.isUnlocked).length;

  void _verifyGpsCheckIn() {
    setState(() => _isCheckingGps = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isCheckingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi GPS Terverifikasi di Kawasan! Stempel Paspor Nagari Berhasil Diberikan.'),
            backgroundColor: AppColors.forest,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASPOR WISATA BUDAYA DIGITAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.brush,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Verifikasi Geofence Kunjungan Nagari',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.warmBorder),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Passport Cover Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.forest, Color(0xFF142618)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forest.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PASPOR DIGITAL WISGO',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.cream, letterSpacing: 1.2),
                            ),
                          ),
                          Text(
                            '$_unlockedCount / ${_badges.length} Lencana',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sage),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'PENGEMBARA RANAH MINANG',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cream,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Stempel resmi diberikan otomatis saat GPS perangkat berada di radius < 500m kawasan wisata.',
                        style: TextStyle(fontSize: 10.5, color: AppColors.sage, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _unlockedCount / _badges.length,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GPS Check-in verification button for current location
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingGps ? null : _verifyGpsCheckIn,
                    icon: _isCheckingGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                          )
                        : const Icon(Icons.pin_drop_rounded, size: 18),
                    label: Text(
                      _isCheckingGps ? 'Memvalidasi Koordinat GPS Kawasan...' : 'Verifikasi Jarak GPS di Lokasi Saat Ini',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'KOLEKSI STEMPEL & LENCANA RESMI',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.muted),
                ),
                const SizedBox(height: 10),

                // Grid of Stamps
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: _badges.length,
                  itemBuilder: (ctx, idx) {
                    final b = _badges[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: b.isUnlocked ? AppColors.forest : AppColors.sageBorder,
                          width: b.isUnlocked ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Stamp circle
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: b.isUnlocked ? const Color(0xFFDFECE2) : const Color(0xFFF3EBDC),
                              border: Border.all(
                                color: b.isUnlocked ? AppColors.terracotta : AppColors.muted,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              b.isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
                              size: 26,
                              color: b.isUnlocked ? AppColors.terracotta : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b.destinationTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: b.isUnlocked ? AppColors.ink : AppColors.muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.isUnlocked ? (b.unlockDate ?? 'Terverifikasi') : '${(b.distanceMeters / 1000).toStringAsFixed(1)} km lagi',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: b.isUnlocked ? AppColors.forest : AppColors.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
