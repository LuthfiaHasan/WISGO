import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../passport/presentation/widgets/digital_passport_sheet.dart';
import '../../../gamification/services/gamification_service.dart';
import '../../../gamification/widgets/level_up_dialog.dart';

/// Halaman Penuh Tab Check-In GPS & Scan QR Destinasi WISGO.
/// Mendukung mode tab penuh (`embedded: true`, menempel alami di Tab Bar tengah
/// tanpa pop-up) maupun mode modal fallback (`embedded: false`).
/// Dilengkapi warna progresif berurutan 5 tahap pada kartu Misi Tantangan Resmi Dispar
/// sesuai jumlah check point yang telah diselesaikan.
class QrScannerSheet extends StatefulWidget {
  final VoidCallback? onOpenSiteMap;
  final VoidCallback? onNavigateToProfile;
  final bool embedded;

  const QrScannerSheet({
    super.key,
    this.onOpenSiteMap,
    this.onNavigateToProfile,
    this.embedded = false,
  });

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  bool _isFlashOn = false;
  bool _isPlayingAudio = false;
  bool _isScanning = false;
  bool _hasCheckedIn = false;
  String _selectedDestination = 'Jam Gadang & Ngarai Sianok';

  // 10 Destinasi Tantangan Resmi Sumatera Barat
  final List<Map<String, String>> _challengeDestinations = [
    {
      'title': 'Jam Gadang & Ngarai Sianok',
      'region': 'Kota Bukittinggi',
      'code': 'CHL-BKT-01',
      'gpsDist': '35 m',
      'narasi': 'Mesin Brixet Langka 1926 & Panorama Ngarai Sianok',
    },
    {
      'title': 'Lembah Harau & Sarasah Bunta',
      'region': 'Kab. Lima Puluh Kota',
      'code': 'CHL-HRU-02',
      'gpsDist': '120 m',
      'narasi': 'Tebing Granit 100-500m & Hutan Lindung Tropis Harau',
    },
    {
      'title': 'Istano Basa Pagaruyung',
      'region': 'Kab. Tanah Datar',
      'code': 'CHL-PGR-03',
      'gpsDist': '75 m',
      'narasi': 'Pusat Kebesaran Adat Minang & Mahakarya Rumah Gadang',
    },
    {
      'title': 'Danau Singkarak & Dermaga Ombilin',
      'region': 'Kab. Solok',
      'code': 'CHL-SNK-04',
      'gpsDist': '210 m',
      'narasi': 'Danau Tektonik Terbesar Kedua & Warisan Kereta Tambang Ombilin',
    },
    {
      'title': 'Danau Maninjau & Puncak Lawang',
      'region': 'Kab. Agam',
      'code': 'CHL-MNJ-05',
      'gpsDist': '140 m',
      'narasi': 'Legenda Bujang Sembilan & Jalur Legendaris Kelok 44',
    },
    {
      'title': 'Pantai Air Manis & Batu Malin',
      'region': 'Kota Padang',
      'code': 'CHL-PAM-06',
      'gpsDist': '50 m',
      'narasi': 'Legenda Si Malin Kundang & Garis Pantai Samudera Hindia',
    },
    {
      'title': 'Kawasan Mandeh & Pulau Setan',
      'region': 'Kab. Pesisir Selatan',
      'code': 'CHL-MND-07',
      'gpsDist': '85 m',
      'narasi': 'Surga Bahari Tropis & Gugusan Pulau Eksotis Pesisir Selatan',
    },
    {
      'title': 'Air Terjun Lembah Anai',
      'region': 'Kab. Tanah Datar',
      'code': 'CHL-LBA-08',
      'gpsDist': '25 m',
      'narasi': 'Air Terjun Ikonik di Tepi Jalur Nasional Trans-Sumatera',
    },
    {
      'title': 'Nagari Tuo Pariangan',
      'region': 'Kab. Tanah Datar',
      'code': 'CHL-PRG-09',
      'gpsDist': '95 m',
      'narasi': 'Nagari Tertua Asal Mula Suku Bangsa Minangkabau',
    },
    {
      'title': 'Air Terjun Lubuk Hitam',
      'region': 'Kota Padang',
      'code': 'CHL-LBH-10',
      'gpsDist': '40 m',
      'narasi': 'Air Terjun Alami 3 Tingkat di Perbukitan Cindakir',
    },
  ];

  // 5 Tahap Warna Harmonis: Kuning Madu Hangat -> Zaitun -> Hijau Daun -> Hijau WISGO
  // Mengalir natural mengikuti persenan progres (0% -> 100%) agar selalu enak dipandang
  static const List<_MissionColorStage> _colorStages = [
    _MissionColorStage(
      label: 'Mulai',
      accent: Color(0xFFD49A2A),
      darkAccent: Color(0xFF8A5E14),
      bgStart: Color(0xFFFDF8E4),
      bgEnd: Color(0xFFFAF0CE),
    ),
    _MissionColorStage(
      label: 'Menjelajah',
      accent: Color(0xFFB59B2B),
      darkAccent: Color(0xFF6B5D15),
      bgStart: Color(0xFFFAF6E0),
      bgEnd: Color(0xFFF1EED2),
    ),
    _MissionColorStage(
      label: 'Setengah Jalan',
      accent: Color(0xFF6C9A3E),
      darkAccent: Color(0xFF3E611D),
      bgStart: Color(0xFFF3F7E6),
      bgEnd: Color(0xFFE7F1D8),
    ),
    _MissionColorStage(
      label: 'Hampir Tuntas',
      accent: Color(0xFF3B8548),
      darkAccent: Color(0xFF21582C),
      bgStart: Color(0xFFEDF6EE),
      bgEnd: Color(0xFFDDEFE1),
    ),
    _MissionColorStage(
      label: 'Tuntas',
      accent: AppColors.brush,
      darkAccent: AppColors.forest,
      bgStart: Color(0xFFE7F3EB),
      bgEnd: AppColors.sage,
    ),
  ];

  _MissionColorStage _stageForProgress(double ratio) {
    final clamped = ratio.clamp(0.0, 1.0);
    final scaled = clamped * (_colorStages.length - 1);
    final lowerIdx = scaled.floor().clamp(0, _colorStages.length - 1);
    final upperIdx = scaled.ceil().clamp(0, _colorStages.length - 1);
    final t = scaled - lowerIdx;

    final a = _colorStages[lowerIdx];
    final b = _colorStages[upperIdx];
    return _MissionColorStage(
      label: t < 0.5 ? a.label : b.label,
      accent: Color.lerp(a.accent, b.accent, t)!,
      darkAccent: Color.lerp(a.darkAccent, b.darkAccent, t)!,
      bgStart: Color.lerp(a.bgStart, b.bgStart, t)!,
      bgEnd: Color.lerp(a.bgEnd, b.bgEnd, t)!,
    );
  }

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

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final result = GamificationService.instance.performCheckIn(
        destinationTitle: _currentDestinationData['title']!,
        region: _currentDestinationData['region']!,
        xpBonus: 50,
        pointBonus: 100,
      );

      setState(() {
        _isScanning = false;
        _hasCheckedIn = true;
      });

      if (result.leveledUp) {
        LevelUpDialog.show(
          context: context,
          oldGrade: result.oldGrade,
          newGrade: result.newGrade,
          totalXp: GamificationService.instance.currentXp,
          onGoToProfile: () {
            if (!widget.embedded) Navigator.pop(context);
            widget.onNavigateToProfile?.call();
          },
        );
      } else {
        final challenge = GamificationService.instance.primaryChallenge;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check-in berhasil di ${_currentDestinationData['title']} (+50 XP • ${challenge.currentCheckpoints}/${challenge.targetCheckpoints} lokasi)',
            ),
            backgroundColor: AppColors.forest,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _openPassport() {
    if (!widget.embedded) Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DigitalPassportSheet(),
    );
  }

  void _goToProfile() {
    if (!widget.embedded) Navigator.pop(context);
    widget.onNavigateToProfile?.call();
  }

  Widget _buildFrostedCircleButton({
    required VoidCallback onTap,
    required Widget child,
    Color? fillColor,
    Color? borderColor,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: fillColor ?? Colors.white.withValues(alpha: 0.68),
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor ?? AppColors.warmBorder.withValues(alpha: 0.85),
                ),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (widget.embedded) {
      // Header Halaman Tab Penuh (serasi dengan Beranda, Trip Go, Peta, Profil)
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHECK-IN GPS & QR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.brush,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Check-In Lokasi',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            // Pintasan Paspor Digital
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openPassport,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.warmBorder.withValues(alpha: 0.9),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppColors.goldMinang,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Paspor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildFrostedCircleButton(
              onTap: () => setState(() => _isFlashOn = !_isFlashOn),
              fillColor: _isFlashOn
                  ? AppColors.warningBg.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.72),
              borderColor: _isFlashOn
                  ? AppColors.goldMinang.withValues(alpha: 0.65)
                  : AppColors.warmBorder.withValues(alpha: 0.9),
              child: Icon(
                _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                size: 18,
                color: _isFlashOn ? AppColors.warningDark : AppColors.ink,
              ),
            ),
          ],
        ),
      );
    }

    // Header fallback jika suatu saat dipanggil sebagai modal
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              _buildFrostedCircleButton(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
              const Expanded(
                child: Text(
                  'Check-In Lokasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _buildFrostedCircleButton(
                onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                fillColor: _isFlashOn
                    ? AppColors.warningBg.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.65),
                borderColor: _isFlashOn
                    ? AppColors.goldMinang.withValues(alpha: 0.6)
                    : AppColors.warmBorder.withValues(alpha: 0.85),
                child: Icon(
                  _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  size: 17,
                  color: _isFlashOn ? AppColors.warningDark : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        6,
        18,
        widget.embedded ? 116 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Kartu Misi Tantangan Resmi Dispar (Gradasi Harmonis Kuning Hangat -> Hijau)
          AnimatedBuilder(
            animation: GamificationService.instance,
            builder: (context, _) {
              final challenge = GamificationService.instance.primaryChallenge;
              final grade = GamificationService.instance.currentGrade;
              final ratio = challenge.progressRatio.clamp(0.0, 1.0);
              final stage = _stageForProgress(ratio);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      stage.bgStart.withValues(alpha: 0.92),
                      stage.bgEnd.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: stage.accent.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: stage.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.military_tech_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Misi Tantangan Resmi Dispar',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: stage.darkAccent,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: stage.accent.withValues(alpha: 0.38),
                            ),
                          ),
                          child: Text(
                            'Level ${grade.level} • ${GamificationService.instance.currentXp} XP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: stage.darkAccent,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${challenge.currentCheckpoints} dari ${challenge.targetCheckpoints} Check Point • ${stage.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${challenge.progressPercent}%',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: stage.darkAccent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar gradasi mulus Kuning Madu -> Zaitun -> Hijau Segar
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: stage.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          widthFactor: ratio,
                          heightFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFE0A938),
                                  stage.accent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan radius < 500 m untuk +50 XP & +100 GP otomatis ke profilmu.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // 2. Viewfinder QR Minimalis & Rapi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF233A29), Color(0xFF192B1E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _isScanning
                        ? 'Memverifikasi koordinat GPS...'
                        : 'Arahkan ke QR plang lokasi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ScannerCornerPainter(
                            color: _hasCheckedIn
                                ? AppColors.sage
                                : Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      Icon(
                        _hasCheckedIn
                            ? Icons.check_circle_outline_rounded
                            : Icons.qr_code_2_rounded,
                        size: 46,
                        color: Colors.white.withValues(
                          alpha: _hasCheckedIn ? 0.92 : 0.22,
                        ),
                      ),
                      if (_isScanning)
                        Positioned(
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.goldSoft.withValues(alpha: 0.85),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _hasCheckedIn
                        ? AppColors.success
                        : AppColors.warning.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasCheckedIn
                            ? Icons.check_rounded
                            : Icons.my_location_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _hasCheckedIn
                            ? 'Lokasi terkonfirmasi'
                            : 'GPS Radius < 500 m OK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Pemilih Lokasi (Pil Bulat Frosted-Glass langsung di kanvas)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih lokasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '10 destinasi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _challengeDestinations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final dest = _challengeDestinations[idx];
                final isSelected = dest['title'] == _selectedDestination;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDestination = dest['title']!;
                            _hasCheckedIn = false;
                            _isPlayingAudio = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.sage.withValues(alpha: 0.82)
                                : Colors.white.withValues(alpha: 0.56),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brush.withValues(alpha: 0.45)
                                  : AppColors.warmBorder.withValues(alpha: 0.85),
                              width: isSelected ? 1.2 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: AppColors.forest,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                dest['title']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.forest
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // 4. Kartu Detail Lokasi Terpilih + Audio + Tombol Check-In Pil Halus
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.64),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.warmBorder.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentDestinationData['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentDestinationData['region']!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sage.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: AppColors.forest,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentDestinationData['gpsDist']!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Strip Audio Cerita Ringkas
                    InkWell(
                      onTap: () =>
                          setState(() => _isPlayingAudio = !_isPlayingAudio),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.warmBorder.withValues(alpha: 0.75),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _isPlayingAudio
                                    ? AppColors.brush
                                    : AppColors.sage,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _isPlayingAudio
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: _isPlayingAudio
                                    ? AppColors.cream
                                    : AppColors.forest,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPlayingAudio
                                        ? 'Memutar audio cerita...'
                                        : 'Audio cerita lokasi',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    _currentDestinationData['narasi']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),

                    // Tombol Utama Pil Halus
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: _hasCheckedIn
                              ? const [AppColors.success, AppColors.brush]
                              : const [AppColors.brush, AppColors.forest],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forest.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isScanning ? null : _performCheckInScan,
                          borderRadius: BorderRadius.circular(999),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isScanning)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.cream,
                                    ),
                                  )
                                else
                                  Icon(
                                    _hasCheckedIn
                                        ? Icons.check_circle_rounded
                                        : Icons.qr_code_scanner_rounded,
                                    size: 18,
                                    color: AppColors.cream,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isScanning
                                      ? 'Memverifikasi GPS...'
                                      : (_hasCheckedIn
                                          ? 'Check-In Berhasil (+50 XP)'
                                          : 'Check-In Lokasi (+50 XP)'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_hasCheckedIn) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openPassport,
                              icon: const Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: AppColors.goldMinang,
                              ),
                              label: const Text(
                                'Paspor Digital',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.72),
                                side: const BorderSide(
                                  color: AppColors.warmBorder,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _goToProfile,
                              icon: const Icon(
                                Icons.person_outline_rounded,
                                size: 15,
                                color: AppColors.forest,
                              ),
                              label: const Text(
                                'Lihat Profil',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    AppColors.sage.withValues(alpha: 0.8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Mode Halaman Tab Penuh (menyatu langsung di Tab Check-In, bukan pop-up)
      return ColoredBox(
        color: AppColors.cream,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBodyContent()),
          ],
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.96,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBodyContent()),
          ],
        ),
      ),
    );
  }
}

class _MissionColorStage {
  const _MissionColorStage({
    required this.label,
    required this.accent,
    required this.darkAccent,
    required this.bgStart,
    required this.bgEnd,
  });

  final String label;
  final Color accent;
  final Color darkAccent;
  final Color bgStart;
  final Color bgEnd;
}

/// Menggambar 4 sudut bingkai QR scanner melengkung halus (tidak kotak kaku)
class _ScannerCornerPainter extends CustomPainter {
  const _ScannerCornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double len = 24;
    const double r = 14;

    // Kiri atas
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      paint,
    );

    // Kanan atas
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, len),
      paint,
    );

    // Kiri bawah
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(len, size.height),
      paint,
    );

    // Kanan bawah
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - r,
        )
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
