import 'package:flutter/material.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/wisgo_destination_image.dart';
import '../../../core/widgets/wisgo_facility_icon.dart';
import '../../../core/widgets/crowd_badge.dart';
import '../../fair_price/data/models/fair_price_tariff_model.dart';
import '../../fair_price/presentation/widgets/fair_price_barometer_table.dart';
import '../../trip_planner/models/weather_model.dart';
import '../../trip_planner/presentation/widgets/destination_weather_sheet.dart';
import '../models/destination_model.dart';
import '../virtual_tour_360/virtual_tour_360_screen.dart';

/// Halaman Panduan & Detail Lengkap Destinasi (FE-1)
/// Tampilan clean, terstruktur dalam 3 tab (Panduan, Tarif & Fasilitas, Ulasan)
/// agar informatif, visual, dan tidak monoton.
class DestinationDetailScreen extends StatefulWidget {
  final DestinationModel destination;
  final Widget? fe2FairPriceSlot;
  final SavedDestinationModel? fullData;
  final bool initialBookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onOpenBarometer;
  final VoidCallback? onOpenLeaderboard;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
    this.fe2FairPriceSlot,
    this.fullData,
    this.initialBookmarked = false,
    this.onToggleBookmark,
    this.onOpenBarometer,
    this.onOpenLeaderboard,
  });

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isSavedOffline = false;
  late bool _isBookmarked;
  int _selectedSection = 0; // 0: Panduan, 1: Tarif & Fasilitas, 2: Ulasan
  late DestinationWeather _weather;
  late SavedDestinationModel _matchedPlace;
  late List<UserReview> _reviews;
  int _extraReviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.initialBookmarked;
    _matchedPlace = widget.fullData ??
        kAllSumbarDestinations.firstWhere(
          (d) => d.title.toLowerCase().contains(
                widget.destination.name.toLowerCase().split(' ').first,
              ),
          orElse: () => kAllSumbarDestinations[1],
        );
    _reviews = List<UserReview>.from(_matchedPlace.reviews);
    _weather = DestinationWeather.getForDestination(widget.destination.name);
    _loadLiveWeather();
  }

  Future<void> _loadLiveWeather() async {
    final live = await DestinationWeather.fetchLiveFromWeatherApi(
      destinationName: widget.destination.name,
    );
    if (!mounted) return;
    setState(() => _weather = live);
  }

  IconData _getFacilityIcon(String facility) {
    final f = facility.toLowerCase();
    if (f.contains('parkir')) return Icons.local_parking_rounded;
    if (f.contains('toilet') || f.contains('bilas')) return Icons.wc_rounded;
    if (f.contains('musholla') || f.contains('musala') || f.contains('masjid')) {
      return Icons.mosque_rounded;
    }
    if (f.contains('warung') || f.contains('kuliner') || f.contains('umkm') || f.contains('kopi')) {
      return Icons.restaurant_rounded;
    }
    if (f.contains('tiket') || f.contains('loket') || f.contains('registrasi')) {
      return Icons.confirmation_number_rounded;
    }
    if (f.contains('air panas')) return Icons.hot_tub_rounded;
    if (f.contains('kapal') || f.contains('dermaga')) return Icons.directions_boat_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;
    final medan = dest.medanIndicator ??
        const MedanIndicatorModel(
          vehicleAccess: 'Mobil OK',
          trekkingLevel: 'Mudah (Datar)',
          cellularSignal: '4G Kuat',
          facilities: 'Ada Toilet & Musala',
          guideNeed: 'Bisa Mandiri',
        );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // 1. IMMERSIVE HERO HEADER (Foto Jernih Tanpa Overlay Hijau Pekat)
          SliverAppBar(
            expandedHeight: 256,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.forest,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: _buildHeroCircleAction(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Kembali',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              if (widget.onToggleBookmark != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Center(
                    child: _buildHeroCircleAction(
                      icon: _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      tooltip: _isBookmarked ? 'Tersimpan' : 'Simpan',
                      isActive: _isBookmarked,
                      onTap: () {
                        setState(() => _isBookmarked = !_isBookmarked);
                        widget.onToggleBookmark?.call();
                      },
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: _buildHeroCircleAction(
                    icon: _isSavedOffline
                        ? Icons.download_done_rounded
                        : Icons.download_for_offline_outlined,
                    tooltip: _isSavedOffline
                        ? 'Tersimpan Offline'
                        : 'Simpan Offline',
                    isActive: _isSavedOffline,
                    onTap: () {
                      setState(() => _isSavedOffline = !_isSavedOffline);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.forest,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Text(
                            _isSavedOffline
                                ? '${dest.name} disimpan ke Kantong Offline.'
                                : '${dest.name} dihapus dari Kantong Offline.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroPhoto(dest),
            ),
          ),

          // 2. BODY CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Action Pills (Tur 360°, Cuaca Live, Peringkat / Offline)
                  _buildQuickActionStrip(context, dest),
                  const SizedBox(height: 16),

                  // Segmented Switcher: Panduan | Tarif & Fasilitas | Ulasan
                  _buildSectionSwitcher(),
                  const SizedBox(height: 18),

                  // Dynamic Tab Body
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _selectedSection == 0
                        ? _buildPanduanSection(dest, medan)
                        : _selectedSection == 1
                            ? _buildTarifFasilitasSection()
                            : _buildUlasanSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCircleAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? AppColors.forest.withValues(alpha: 0.92)
            : AppColors.ink.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPhoto(DestinationModel dest) {
    final bool isCulture = dest.category.toLowerCase().contains('budaya');
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.forest),
        WisgoDestinationImage(
          source: dest.coverImage,
          destinationId: dest.id,
          destinationTitle: dest.name,
          fit: BoxFit.cover,
          cacheWidth: 1080,
          fallback: const ColoredBox(color: AppColors.forest),
        ),
        // Scrim natural hanya di tepi atas & bawah agar foto asli tetap jernih
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x55000000),
                Color(0x08000000),
                Color(0xB80F1E14),
              ],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCulture ? AppColors.goldMinang : AppColors.forest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dest.category} • Resmi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${_matchedPlace.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dest.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dest.cityRegency,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionStrip(BuildContext context, DestinationModel dest) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionPill(
            icon: Icons.view_in_ar_rounded,
            label: 'Tur 360°',
            accent: AppColors.forest,
            bg: AppColors.sage,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => VirtualTour360Screen(destination: dest),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionPill(
            icon: _weather.conditionIcon,
            label: '${_weather.currentTemp}°C Live',
            accent: AppColors.info,
            bg: AppColors.infoBg,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DestinationWeatherSheet(
                  destinationName: dest.name,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionPill(
            icon: widget.onOpenLeaderboard != null
                ? Icons.leaderboard_rounded
                : Icons.verified_outlined,
            label: widget.onOpenLeaderboard != null ? 'Peringkat' : 'Tarif Resmi',
            accent: AppColors.goldMinang,
            bg: AppColors.warningBg,
            onTap: widget.onOpenLeaderboard ??
                () => setState(() => _selectedSection = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionPill({
    required IconData icon,
    required String label,
    required Color accent,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionSwitcher() {
    final labels = [
      'Panduan',
      'Tarif & Fasilitas',
      'Ulasan (${_reviews.length})',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.creamSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = _selectedSection == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSection = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.cream : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PANDUAN & KESIAPAN MEDAN
  // ===========================================================================
  Widget _buildPanduanSection(
    DestinationModel dest,
    MedanIndicatorModel medan,
  ) {
    return Column(
      key: const ValueKey('tab-panduan'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ringkasan Destinasi & Catatan Medan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_stories_rounded, size: 16, color: AppColors.forest),
                  SizedBox(width: 6),
                  Text(
                    'Tentang Destinasi & Rute',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dest.description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.ink,
                ),
              ),
              if (_matchedPlace.terrainNote.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        size: 16,
                        color: AppColors.brush,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _matchedPlace.terrainNote,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Statistik Keputusan (Grid 2x2 Visual Tanpa Nomor Kaku)
        const Text(
          'Ringkasan Perjalanan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildFourStatsGrid(dest),
        const SizedBox(height: 18),

        // 5 Indikator Kesiapan Medan (Visual Grid Cards — Tidak Monoton)
        const Text(
          'Kesiapan Medan Lapangan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildFiveMedanGrid(medan),
        const SizedBox(height: 18),

        // Tips Menjaga Tempat Ini
        _buildTipsCard(dest.tips),
      ],
    );
  }

  String _formatEntryFeeDisplay(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'^Rp\s*(\d{4,})$', caseSensitive: false)
        .firstMatch(trimmed);
    if (match == null) return trimmed;
    final digits = match.group(1)!;
    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  Widget _buildFourStatsGrid(DestinationModel dest) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 80,
      ),
      children: [
        _buildStatTile(
          assetPath: 'assets/images/det_jarak.png',
          fallbackIcon: Icons.route_outlined,
          iconColor: AppColors.forest,
          iconBg: AppColors.sage,
          label: 'Jarak Tempuh',
          child: Text(
            dest.distanceKm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        _buildStatTile(
          assetPath: 'assets/images/det_waktu.png',
          fallbackIcon: Icons.schedule_rounded,
          iconColor: AppColors.info,
          iconBg: AppColors.infoBg,
          label: 'Estimasi Waktu',
          child: Text(
            dest.travelTime,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
        ),
        _buildStatTile(
          assetPath: 'assets/images/det_keramaian.png',
          fallbackIcon: Icons.people_alt_outlined,
          iconColor: AppColors.goldMinang,
          iconBg: AppColors.warningBg,
          label: 'Keramaian',
          child: CrowdBadge(level: dest.crowdLevelEnum),
        ),
        _buildStatTile(
          assetPath: 'assets/images/det_tiket.png',
          fallbackIcon: Icons.confirmation_number_outlined,
          iconColor: AppColors.forest,
          iconBg: AppColors.sage,
          label: 'Tiket Masuk',
          child: Text(
            _formatEntryFeeDisplay(dest.entryFee),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String assetPath,
    required IconData fallbackIcon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warmBorder.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              assetPath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, size: 18, color: iconColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveMedanGrid(MedanIndicatorModel medan) {
    final items = [
      (
        asset: 'assets/images/det_kendaraan.png',
        icon: Icons.directions_car_filled_outlined,
        title: 'Akses Kendaraan',
        value: medan.vehicleAccess,
        color: AppColors.forest,
      ),
      (
        asset: 'assets/images/fac_trekking.png',
        icon: Icons.nordic_walking_outlined,
        title: 'Trekking',
        value: medan.trekkingLevel,
        color: medan.trekkingLevel.contains('Ekstrem')
            ? AppColors.terracotta
            : AppColors.forest,
      ),
      (
        asset: 'assets/images/det_sinyal.png',
        icon: Icons.cell_tower_rounded,
        title: 'Sinyal Seluler',
        value: medan.cellularSignal,
        color: medan.cellularSignal.contains('Blank')
            ? AppColors.terracotta
            : AppColors.success,
      ),
      (
        asset: 'assets/images/fac_pemandu.png',
        icon: Icons.person_pin_circle_outlined,
        title: 'Pemandu',
        value: medan.guideNeed,
        color: medan.guideNeed.contains('Wajib')
            ? AppColors.warningDark
            : AppColors.forest,
      ),
    ];

    return Column(
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 82,
          ),
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.warmBorder.withValues(alpha: 0.85),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      item.asset,
                      width: 23,
                      height: 23,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) =>
                          Icon(item.icon, size: 17, color: item.color),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: item.color,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // Indikator ke-5 (Fasilitas Umum) full-width agar rapi dan simetris
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.warmBorder.withValues(alpha: 0.85),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/fac_toilet.png',
                  width: 23,
                  height: 23,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.wc_outlined,
                    size: 18,
                    color: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fasilitas Umum',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medan.facilities,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard(List<LocalTipModel> tips) {
    final displayTips = tips.isEmpty
        ? [
            LocalTipModel(
              id: 'default-1',
              destinationId: widget.destination.id,
              content: 'Bawa kembali sampah Anda dan jaga kebersihan alam sekitar.',
              isImportant: true,
            ),
            LocalTipModel(
              id: 'default-2',
              destinationId: widget.destination.id,
              content: 'Hormati adat istiadat dan tata krama Nagari setempat.',
              isImportant: false,
            ),
          ]
        : tips;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.forest, size: 18),
              SizedBox(width: 8),
              Text(
                'Tips Menjaga Tempat Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...displayTips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                        fontWeight:
                            t.isImportant ? FontWeight.w600 : FontWeight.normal,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: TARIF RESMI & FASILITAS LENGKAP
  // ===========================================================================
  void _openFairPriceBarometerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Barometer Tarif Wajar',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    FairPriceBarometerTable(
                      destinationData: _matchedPlace,
                      selectedCategory: 'ALL',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarifFasilitasSection() {
    return Column(
      key: const ValueKey('tab-tarif'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fasilitas Lengkap
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lingkup Fasilitas Kawasan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _matchedPlace.facilities.map((fac) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WisgoFacilityIcon(
                          facilityName: fac,
                          size: 18,
                          fallbackIcon: _getFacilityIcon(fac),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            fac,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Rincian Biaya Resmi Sesuai Perda
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Rincian Biaya Resmi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openFairPriceBarometerSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Barometer →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                _matchedPlace.perdaRef,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_matchedPlace.verticalFees.length, (idx) {
                final fee = _matchedPlace.verticalFees[idx];
                return Container(
                  padding: EdgeInsets.only(top: idx > 0 ? 10 : 0),
                  margin: EdgeInsets.only(top: idx > 0 ? 10 : 0),
                  decoration: idx > 0
                      ? const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.warmBorder),
                          ),
                        )
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fee.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              fee.sub,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        fee.price,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
                const SizedBox(height: 12),
                // Strip Ringkas Anti-Pungli & Pintasan Barometer Tarif Wajar (Tanpa Duplikasi Tabel/Foto)
                if (widget.fe2FairPriceSlot != null) ...[
                  const SizedBox(height: 4),
                  widget.fe2FairPriceSlot!,
                ] else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.brush.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 18,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Barometer Tarif Wajar (Anti-Pungli)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Bandingkan tarif resmi vs batas wajar & laporkan jika ada pungli.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: _openFairPriceBarometerSheet,
                            icon: const Icon(
                              Icons.balance_rounded,
                              size: 16,
                              color: AppColors.forest,
                            ),
                            label: const Text(
                              'Lihat Barometer Tarif Wajar',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.85),
                              side: BorderSide(
                                color: AppColors.brush.withValues(alpha: 0.35),
                              ),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: ULASAN WISATAWAN TERVERIFIKASI (+ TAMBAH ULASAN)
  // ===========================================================================
  void _openAddReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDestinationReviewModal(
        destination: _matchedPlace,
        onReviewSubmitted: (newReview) {
          setState(() {
            _reviews.insert(0, newReview);
            _extraReviewsCount++;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.forest,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.goldSoft, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ulasan terverifikasi berhasil ditambahkan!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewImage(String photoPath, {double height = 132}) {
    if (photoPath.startsWith('assets/')) {
      return Image.asset(
        photoPath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Image.network(
      photoPath,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildUlasanSection() {
    return Column(
      key: const ValueKey('tab-ulasan'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Summary Card + Tombol Tulis Ulasan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              '${_matchedPlace.rating}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_matchedPlace.reviewsCount + _extraReviewsCount} Ulasan',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ulasan Terverifikasi GPS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Ditulis oleh pengunjung yang benar-benar check-in di lokasi wisata.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openAddReviewSheet,
                  icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                  label: const Text(
                    'Tambah Ulasan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Daftar Ulasan Lengkap
        ..._reviews.map((rev) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.forest,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        rev.author.isNotEmpty ? rev.author.substring(0, 1) : 'U',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rev.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Terverifikasi • ${rev.date}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final starCount = rev.rating.round().clamp(1, 5);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < starCount
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 13,
                                  color: i < starCount
                                      ? Colors.amber
                                      : AppColors.warmBorder,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$starCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warningDark,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (rev.realLocation != null && rev.realLocation!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            rev.realLocation!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '"${rev.comment}"',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.ink,
                  ),
                ),
                if (rev.photoUrl != null && rev.photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildReviewImage(rev.photoUrl!),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Modal Bottom Sheet Tambah Ulasan Terverifikasi GPS
class _AddDestinationReviewModal extends StatefulWidget {
  final SavedDestinationModel destination;
  final ValueChanged<UserReview> onReviewSubmitted;

  const _AddDestinationReviewModal({
    required this.destination,
    required this.onReviewSubmitted,
  });

  @override
  State<_AddDestinationReviewModal> createState() =>
      _AddDestinationReviewModalState();
}

class _AddDestinationReviewModalState
    extends State<_AddDestinationReviewModal> {
  int _rating = 5;
  late String _photoPath;
  final _commentController = TextEditingController();
  late final List<Map<String, String>> _samplePhotos;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.destination.imageUrl;
    _samplePhotos = [
      {'label': 'Spot Utama', 'path': widget.destination.imageUrl},
      {'label': 'Lembah & Air Terjun', 'path': 'assets/images/activity_lembah_anai.jpg'},
      {'label': 'Panorama Nagari', 'path': 'assets/images/activity_pariangan.jpg'},
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int stars) {
    switch (stars) {
      case 5:
        return '5 Bintang • Sangat Memuaskan';
      case 4:
        return '4 Bintang • Bagus & Nyaman';
      case 3:
        return '3 Bintang • Cukup Baik';
      case 2:
        return '2 Bintang • Kurang Memuaskan';
      default:
        return '1 Bintang • Perlu Perbaikan';
    }
  }

  void _submit() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tulis ulasan pengalaman Anda terlebih dahulu.'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    final authorName =
        ApiConfig.currentUser?.fullName.trim().isNotEmpty == true
            ? ApiConfig.currentUser!.fullName
            : 'Penjelajah Ranah Minang';

    final newReview = UserReview(
      author: authorName,
      rating: _rating.toDouble(),
      date: 'Baru saja',
      comment: comment,
      photoUrl: _photoPath,
      realLocation: 'GPS Terverifikasi (${widget.destination.subRegion})',
      isGpsVerified: true,
    );

    Navigator.pop(context);
    widget.onReviewSubmitted(newReview);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.warmBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAMBAH ULASAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.brush,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bagikan Pengalaman Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.creamSubtle,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: const Icon(Icons.close_rounded, size: 17, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // GPS Verified Badge
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sageBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 18, color: AppColors.forest),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lokasi GPS Terverifikasi • ${widget.destination.subRegion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Rating Bintang
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(
                            star <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 32,
                            color: star <= _rating
                                ? Colors.amber
                                : AppColors.warmBorder,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingLabel(_rating),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Foto Kunjungan
            const Text(
              'Lampirkan Foto Kunjungan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _photoPath.startsWith('assets/')
                  ? Image.asset(
                      _photoPath,
                      height: 112,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _photoPath,
                      height: 112,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 112,
                        color: AppColors.creamSubtle,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined, color: AppColors.muted),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _samplePhotos.map((sample) {
                final selected = _photoPath == sample['path'];
                return ChoiceChip(
                  label: Text(sample['label']!),
                  selected: selected,
                  onSelected: (val) {
                    if (val) setState(() => _photoPath = sample['path']!);
                  },
                  selectedColor: AppColors.forest,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.cream : AppColors.ink,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected ? AppColors.forest : AppColors.warmBorder,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Input Ulasan
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: InputDecoration(
                hintText:
                    'Ceritakan kondisi destinasi, kebersihan fasilitas, atau kesesuaian tarif resmi…',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.warmBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.warmBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'Tarif resmi sesuai Perda',
                'Fasilitas bersih & rapi',
                'Pemandangan sangat indah',
                'Parkir aman & tertib',
              ].map((tag) {
                return GestureDetector(
                  onTap: () {
                    final cur = _commentController.text.trim();
                    _commentController.text = cur.isEmpty ? tag : '$cur. $tag';
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ $tag',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text(
                  'Kirim Ulasan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: AppColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
