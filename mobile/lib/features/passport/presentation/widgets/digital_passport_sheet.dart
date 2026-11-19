import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Model Lencana Tantangan Menaklukkan Destinasi (10 Wisata Sumbar Input Admin)
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

  PassportBadge copyWith({
    bool? isUnlocked,
    String? unlockDate,
    int? distanceMeters,
  }) {
    return PassportBadge(
      id: id,
      destinationTitle: destinationTitle,
      region: region,
      iconSymbol: iconSymbol,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockDate: unlockDate ?? this.unlockDate,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      culturalQuote: culturalQuote,
    );
  }
}

/// Item 18 & Use Case Diagram:
/// Tantangan Menaklukkan Destinasi (Input Admin)
/// -> Scan QR dengan metode check-in GPS (<500m)
/// -> Koleksi Stempel & Lencana di Paspor Digital
/// -> Geode ranking (Papan Peringkat Spasial Wisatawan)
/// -> Full 10/10: Terbuka Sertifikat Digital & Notifikasi Reward dari Admin Dispar
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
  // 10 Destinasi Resmi Tantangan Input Admin Dispar
  late List<PassportBadge> _badges;
  bool _isCheckingGps = false;
  bool _isRecalculatingGeode = false;

  @override
  void initState() {
    super.initState();
    _badges = [
      const PassportBadge(
        id: 'bdg-1',
        destinationTitle: 'Air Terjun Lubuk Hitam (Cindakir)',
        region: 'Kota Padang',
        iconSymbol: 'LUB-HITAM',
        isUnlocked: true,
        unlockDate: '17 Nov 2026 • 10:15 WIB',
        distanceMeters: 45,
        culturalQuote: 'Tingkat 3 Kesegaran Alami - Alam Takambang Jadi Guru',
      ),
      const PassportBadge(
        id: 'bdg-2',
        destinationTitle: 'Lembah Harau & Sarasah Bunta',
        region: 'Kab. Lima Puluh Kota',
        iconSymbol: 'HARAU-VALLEY',
        isUnlocked: true,
        unlockDate: '16 Nov 2026 • 14:20 WIB',
        distanceMeters: 120,
        culturalQuote: 'Tinggi Monolit Tebing Granit - Keagungan Luhak',
      ),
      const PassportBadge(
        id: 'bdg-3',
        destinationTitle: 'Istano Basa Pagaruyung',
        region: 'Kab. Tanah Datar',
        iconSymbol: 'PAGARUYUNG',
        isUnlocked: true,
        unlockDate: '15 Nov 2026 • 11:30 WIB',
        distanceMeters: 250,
        culturalQuote: 'Pusat Falsafah Luhak Nan Tuo & Arsitektur Rangkiang',
      ),
      const PassportBadge(
        id: 'bdg-4',
        destinationTitle: 'Jam Gadang & Ngarai Sianok',
        region: 'Kota Bukittinggi',
        iconSymbol: 'JAM-GADANG',
        isUnlocked: true,
        unlockDate: '14 Nov 2026 • 16:45 WIB',
        distanceMeters: 180,
        culturalQuote: 'Ikon Ranah Minang dengan Mesin Jam Brixet Langka',
      ),
      const PassportBadge(
        id: 'bdg-5',
        destinationTitle: 'Danau Singkarak & Dermaga Ombilin',
        region: 'Kab. Solok',
        iconSymbol: 'SINGKARAK',
        isUnlocked: true,
        unlockDate: '13 Nov 2026 • 09:10 WIB',
        distanceMeters: 310,
        culturalQuote: 'Habitat Ikan Bilih Asli & Warisan Kereta Ombilin UNESCO',
      ),
      const PassportBadge(
        id: 'bdg-6',
        destinationTitle: 'Danau Maninjau & Puncak Lawang',
        region: 'Kab. Agam',
        iconSymbol: 'MANINJAU',
        isUnlocked: true,
        unlockDate: '12 Nov 2026 • 15:00 WIB',
        distanceMeters: 220,
        culturalQuote: 'Panorama Kelok 44 nan Melegenda & Angin Danau Kaldera',
      ),
      const PassportBadge(
        id: 'bdg-7',
        destinationTitle: 'Pantai Air Manis & Batu Malin',
        region: 'Kota Padang',
        iconSymbol: 'AIR-MANIS',
        isUnlocked: true,
        unlockDate: '11 Nov 2026 • 17:10 WIB',
        distanceMeters: 90,
        culturalQuote: 'Falsafah Budi & Pesan Moral Sang Legenda Samudera',
      ),
      const PassportBadge(
        id: 'bdg-8',
        destinationTitle: 'Kawasan Mandeh & Pulau Setan',
        region: 'Kab. Pesisir Selatan',
        iconSymbol: 'MANDEH',
        isUnlocked: true,
        unlockDate: '10 Nov 2026 • 13:40 WIB',
        distanceMeters: 150,
        culturalQuote: 'Surga Bahari Raja Ampat-nya Sumatera Barat',
      ),
      const PassportBadge(
        id: 'bdg-9',
        destinationTitle: 'Air Terjun Lembah Anai',
        region: 'Kab. Tanah Datar',
        iconSymbol: 'LMB-ANAI',
        isUnlocked: true,
        unlockDate: '09 Nov 2026 • 08:30 WIB',
        distanceMeters: 60,
        culturalQuote: 'Gemuruh Aliran Air Alami Gerbang Jalur Padang-Bukittinggi',
      ),
      const PassportBadge(
        id: 'bdg-10',
        destinationTitle: 'Nagari Tuo Pariangan',
        region: 'Kab. Tanah Datar',
        iconSymbol: 'PARIANGAN',
        isUnlocked: false,
        unlockDate: null,
        distanceMeters: 14200,
        culturalQuote: 'Nagari Tertua Asal Mula Suku Bangsa Minangkabau',
      ),
    ];
  }

  int get _unlockedCount => _badges.where((b) => b.isUnlocked).length;
  bool get _isChallengeCompleted => _unlockedCount == _badges.length;

  void _verifyGpsCheckIn() {
    setState(() => _isCheckingGps = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isCheckingGps = false;
          // Unlock remaining destination (Nagari Tuo Pariangan)
          final idx = _badges.indexWhere((b) => !b.isUnlocked);
          if (idx != -1) {
            _badges[idx] = _badges[idx].copyWith(
              isUnlocked: true,
              unlockDate: 'Hari ini • Baru Saja',
              distanceMeters: 35,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Koordinat GPS Terverifikasi (<500m)! Stempel & Lencana Resmi Berhasil Ditambahkan.'),
            backgroundColor: AppColors.forest,
          ),
        );

        if (_isChallengeCompleted) {
          _showRewardFromAdminNotification();
        }
      }
    });
  }

  void _openGeodeRankingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.leaderboard_rounded, color: AppColors.forest, size: 24),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GEODE RANKING PENJELAJAH',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.forest, letterSpacing: 0.8),
                            ),
                            Text(
                              'Peringkat Spasial Wisatawan Minang',
                              style: TextStyle(fontSize: 10, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 6),

                // User's Geode Status Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.forest, Color(0xFF142618)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('POSISI ANDA SAAT INI', style: TextStyle(fontSize: 9.5, color: AppColors.sage, fontWeight: FontWeight.w800)),
                              Text('Peringkat #3 Se-Sumbar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC89242),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Tier Geode Platinum', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('${_unlockedCount * 250 + 250} GP', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFE2B755))),
                              const Text('Skor Geode', style: TextStyle(fontSize: 9.5, color: AppColors.sage)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white24),
                          Column(
                            children: [
                              Text('$_unlockedCount/10', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                              const Text('Ditaklukkan', style: TextStyle(fontSize: 9.5, color: AppColors.sage)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white24),
                          Column(
                            children: [
                              Text('${(_unlockedCount * 46.5).toStringAsFixed(1)} km', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                              const Text('Jarak Geodesik', style: TextStyle(fontSize: 9.5, color: AppColors.sage)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Button: Rekalkulasi Geode Ranking
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRecalculatingGeode
                        ? null
                        : () {
                            final messenger = ScaffoldMessenger.of(context);
                            setSheetState(() => _isRecalculatingGeode = true);
                            Future.delayed(const Duration(milliseconds: 900), () {
                              if (mounted) {
                                setSheetState(() => _isRecalculatingGeode = false);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Rekalkulasi Geode Ranking Berhasil! Data titik spasial GPS terbaru telah disinkronkan oleh Admin Dispar.'),
                                    backgroundColor: AppColors.forest,
                                  ),
                                );
                              }
                            });
                          },
                    icon: _isRecalculatingGeode
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_rounded, size: 16, color: AppColors.forest),
                    label: Text(
                      _isRecalculatingGeode ? 'Merekalkulasi Skor Geode Spasial...' : 'Rekalkulasi Geode Ranking Saya',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forest),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.forest),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'LEADERBOARD PENJELAJAH SPASIAL (TOP 5):',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1),
                ),
                const SizedBox(height: 8),

                // Leaderboard List
                Expanded(
                  child: ListView(
                    children: [
                      _buildLeaderboardItem(1, 'Rangkayo Sutan', '10/10 Destinasi', '520.4 km', '2.950 GP', 'Diamond', true),
                      _buildLeaderboardItem(2, 'Pendekar Marapulai', '10/10 Destinasi', '498.1 km', '2.750 GP', 'Diamond', false),
                      _buildLeaderboardItem(3, 'Anda (Wisatawan Teladan)', '$_unlockedCount/10 Destinasi', '${(_unlockedCount * 46.5).toStringAsFixed(1)} km', '${_unlockedCount * 250 + 250} GP', 'Platinum', false, isMe: true),
                      _buildLeaderboardItem(4, 'Bundo Penjelajah', '8/10 Destinasi', '412.0 km', '2.200 GP', 'Gold', false),
                      _buildLeaderboardItem(5, 'Petualang Singkarak', '7/10 Destinasi', '385.5 km', '1.950 GP', 'Gold', false),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, String dest, String dist, String score, String tier, bool isLeader, {bool isMe = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFBF4E4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? const Color(0xFFC89242) : AppColors.sageBorder,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank == 1
                  ? const Color(0xFFE2B755)
                  : rank == 2
                      ? const Color(0xFFB0B7BD)
                      : rank == 3
                          ? const Color(0xFFCD7F32)
                          : AppColors.cream,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: rank <= 3 ? Colors.white : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                          color: isMe ? const Color(0xFF8C5C1E) : AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC89242),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Saya', style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text('$dest • $dist', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.forest)),
              Text('Tier $tier', style: const TextStyle(fontSize: 8.5, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  void _showRewardFromAdminNotification() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFFC89242), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'NOTIFIKASI REWARD RESMI ADMIN DISPAR',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.forest),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4E4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC89242)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFC89242), size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Selamat! Anda telah MENAKLUKKAN 10 DESTINASI SUMBAR yang ditentukan oleh Admin Dispar!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '🎁 Hadiah Resmi dari Dinas Pariwisata Prov. Sumbar:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            const Text(
              '• 1x Plakat Emas Miniatur Rumah Gadang Penjelajah\n'
              '• Sertifikat Digital Berbarcode Resmi Kepala Dispar\n'
              '• Voucher Cinderamata Kerajinan Tenun Pandai Sikek\n'
              '• Bebas Biaya Retribusi 1 Tahun di Kawasan Perda Prov.',
              style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Kode Klaim Reward: REWARD-DISPAR-10SUMBAR-2026',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.forest),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lihat Sertifikat Digital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showDigitalCertificateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFC89242), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'SERTIFIKAT DIGITAL RESMI',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.forest),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  // Certificate Border Frame
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC89242), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC89242).withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        const Text(
                          'PEMERINTAH PROVINSI SUMATERA BARAT',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.muted),
                        ),
                        const Text(
                          'DINAS PARIWISATA',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.forest),
                        ),
                        const SizedBox(height: 8),
                        Container(height: 2, width: 80, color: const Color(0xFFC89242)),
                        const SizedBox(height: 14),
                        const Text(
                          'PIAGAM PENGHARGAAN',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFC89242), letterSpacing: 1),
                        ),
                        const Text(
                          'PENAKLUK 10 DESTINASI UNGGULAN RANAH MINANG',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Diberikan kepada wisatawan terhormat:',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.muted),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Wisatawan Teladan WisGo',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Telah berhasil menyelesaikan Tantangan Menaklukkan 10 Destinasi Unggulan Sumatera Barat dengan verifikasi scan check-in GPS resmi di seluruh kawasan wisata binaan Dispar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        // Signature & Hologram Stamp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('No. Reg: 2026/DSP-CHL/0988', style: TextStyle(fontSize: 9, color: AppColors.muted)),
                                const Text('Verifikasi: GPS Geofence Valid', style: TextStyle(fontSize: 9, color: AppColors.forest, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.warmBorder),
                                  ),
                                  child: const Text('Hologram Valid', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFC89242))),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Kepala Dinas Pariwisata', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.ink)),
                                const SizedBox(height: 25),
                                Container(height: 1, width: 110, color: Colors.black45),
                                const SizedBox(height: 2),
                                const Text('Provinsi Sumatera Barat', style: TextStyle(fontSize: 8.5, color: AppColors.muted)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sertifikat Digital berhasil diunduh ke galeri!'),
                          backgroundColor: AppColors.forest,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Unduh Sertifikat PDF / Gambar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TANTANGAN RESMI DARI ADMIN DISPAR',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFFC89242),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tantangan Menaklukkan 10 Destinasi',
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
                // Passport Cover Card with Challenge Progress
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
                              'PASPOR DIGITAL WISATAWAN',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.cream, letterSpacing: 1.2),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isChallengeCompleted ? const Color(0xFFC89242) : Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$_unlockedCount / ${_badges.length} Ditaklukkan',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
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
                        'Selesaikan tantangan dari Admin dengan tiba di lokasi wisata dan melakukan scan check-in GPS. Penuhi 10/10 stempel untuk membuka Sertifikat Digital & Reward Resmi Dispar!',
                        style: TextStyle(fontSize: 10.5, color: AppColors.sage, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _unlockedCount / _badges.length,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isChallengeCompleted ? const Color(0xFFE2B755) : AppColors.sage,
                          ),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: Geode Ranking & GPS Check-in
                Row(
                  children: [
                    // Geode Ranking Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openGeodeRankingModal,
                        icon: const Icon(Icons.leaderboard_rounded, size: 16, color: Color(0xFFC89242)),
                        label: const Text(
                          'Geode Ranking',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFC89242)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC89242), width: 1.5),
                          backgroundColor: const Color(0xFFFBF4E4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Check-in GPS Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingGps ? null : _verifyGpsCheckIn,
                        icon: _isCheckingGps
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.pin_drop_rounded, size: 16),
                        label: Text(
                          _isChallengeCompleted ? 'Semua Tuntas (10/10)' : 'Check-in Lokasi Tiba',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // UNLOCKED CERTIFICATE & REWARD BANNER (Only when 10/10)
                if (_isChallengeCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4E4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC89242), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.military_tech_rounded, color: Color(0xFFC89242), size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'TANTANGAN 10/10 TUNTAS: SERTIFIKAT TERBUKA!',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF8C5C1E)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Anda berhak memperoleh Sertifikat Digital Penjelajah Minang & Notifikasi Reward Resmi dari Admin Dispar.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showDigitalCertificateModal,
                                icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                                label: const Text('Buka Sertifikat Digital', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC89242),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _showRewardFromAdminNotification,
                              icon: const Icon(Icons.notifications_active_rounded, size: 16, color: AppColors.forest),
                              label: const Text('Info Reward', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forest)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.forest),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'KOLEKSI 10 STEMPEL & LENCANA RESMI DISPAR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.muted),
                ),
                const SizedBox(height: 10),

                // Grid of Stamps (All 10 Destinations)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: _badges.length,
                  itemBuilder: (ctx, idx) {
                    final b = _badges[idx];
                    return Container(
                      padding: const EdgeInsets.all(10),
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
                            width: 52,
                            height: 52,
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
                              size: 24,
                              color: b.isUnlocked ? AppColors.terracotta : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b.destinationTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
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
                              fontSize: 9,
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
