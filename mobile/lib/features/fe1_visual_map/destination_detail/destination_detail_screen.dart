import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/crowd_badge.dart';
import '../../../core/widgets/pill_button.dart';
import '../models/destination_model.dart';
import '../virtual_tour_360/virtual_tour_360_screen.dart';

/// Layar 02 · Detail Tempat (Minggu 1 Wajib FE-1)
/// Mencakup:
/// 1. Hero Destinasi + Tombol PillButton 52px "Jelajah Tur 360°"
/// 2. Grid 4 Statistik Keputusan (Jarak, Waktu Tempuh, Tingkat Keramaian, Biaya Masuk)
/// 3. Kartu 5 Indikator Medan (Akses Kendaraan, Trekking, Sinyal, Fasilitas, Pemandu)
/// 4. Kartu Wajib "Tips Menjaga Tempat Ini" (Latar --sage-100 #E4E9DA)
/// 5. Slot / Pratinjau Fair-Price Barometer (Titik temu dengan FE-2)
class DestinationDetailScreen extends StatefulWidget {
  final DestinationModel destination;

  /// Slot opsional agar FE-2 bisa menyuntikkan widget Fair-Price Barometer & Lapor Pungli
  final Widget? fe2FairPriceSlot;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
    this.fe2FairPriceSlot,
  });

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isSavedOffline = false;
  bool _isFavorite = false;

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
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: Text(dest.name),
        actions: [
          IconButton(
            tooltip: 'Simpan Favorit',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.coral500 : AppColors.ink900,
            ),
          ),
          IconButton(
            tooltip: 'Simpan Paket Offline (Zero-Signal)',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () {
              setState(() => _isSavedOffline = !_isSavedOffline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.green800,
                  content: Text(
                    _isSavedOffline
                        ? 'Paket Offline "${dest.name}" berhasil disimpan untuk Mode Zero-Signal.'
                        : 'Paket Offline dihapus dari penyimpanan lokal.',
                  ),
                ),
              );
            },
            icon: Icon(
              _isSavedOffline
                  ? Icons.download_done_rounded
                  : Icons.download_for_offline_outlined,
              color: _isSavedOffline ? AppColors.green500 : AppColors.green800,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO CARD + PRATINJAU 360°
            _buildHeroBanner(context, dest),
            const SizedBox(height: 16),

            // TOMBOL UTAMA CTA 52PX: JELAJAH TUR 360°
            PillButton(
              label: 'Jelajah Tur 360° (Drone & Darat)',
              icon: Icons.view_in_ar_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => VirtualTour360Screen(destination: dest),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. GRID 4 STATISTIK KEPUTUSAN (Paruh Atas Layar Detail Tempat)
            const Text(
              '4 Statistik Keputusan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 12),
            _buildFourStatsGrid(dest),
            const SizedBox(height: 24),

            // 3. KARTU 5 INDIKATOR MEDAN LAPANGAN
            const Text(
              'Kesiapan Medan (5 Indikator Lapangan)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 12),
            _buildFiveMedanCard(medan),
            const SizedBox(height: 24),

            // 4. KARTU WAJIB: "TIPS MENJAGA TEMPAT INI" (--sage-100 #E4E9DA)
            _buildTipsCard(dest.tips),
            const SizedBox(height: 24),

            // 5. SLOT FAIR-PRICE BAROMETER (Integrasi FE-2 / Tarif Resmi Perda)
            widget.fe2FairPriceSlot ?? _buildFairPriceSection(dest.tariffs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, DestinationModel dest) {
    final bool isCategoryCulture =
        dest.category.toLowerCase().contains('budaya');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A1B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Foto Cover Destinasi
          if (dest.coverImage.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                dest.coverImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // Gradient Overlay agar kontras teks tetap optimal
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A3A1B).withOpacity(
                      dest.coverImage.isNotEmpty ? 0.75 : 1.0,
                    ),
                    AppColors.green800.withOpacity(
                      dest.coverImage.isNotEmpty ? 0.90 : 1.0,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Konten Teks & Badges di atas Foto
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isCategoryCulture
                            ? AppColors.indigo500
                            : AppColors.green500,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${dest.category} · Terverifikasi Nagari',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.threesixty, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '360° Ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  dest.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dest.cityRegency,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dest.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grid 4 Statistik sesuai `docs/Desain_System_Token.md` §04:
  /// 1. Jarak, 2. Waktu Tempuh, 3. Tingkat Keramaian (CrowdBadge), 4. Biaya Masuk
  Widget _buildFourStatsGrid(DestinationModel dest) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.05,
      children: [
        _buildStatTile(
          icon: Icons.route_outlined,
          label: '1. Jarak',
          child: Text(
            dest.distanceKm,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
        ),
        _buildStatTile(
          icon: Icons.schedule_rounded,
          label: '2. Waktu Tempuh',
          child: Text(
            dest.travelTime,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
        ),
        _buildStatTile(
          icon: Icons.groups_outlined,
          label: '3. Tingkat Keramaian',
          child: Align(
            alignment: Alignment.centerLeft,
            child: CrowdBadge(level: dest.crowdLevelEnum),
          ),
        ),
        _buildStatTile(
          icon: Icons.confirmation_number_outlined,
          label: '4. Biaya Masuk',
          child: Text(
            dest.entryFee,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.green800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.green800),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  /// Kartu 5 Indikator Medan sesuai `docs/Desain_System_Token.md` §04
  Widget _buildFiveMedanCard(MedanIndicatorModel medan) {
    final bool isBlankSpot =
        medan.cellularSignal.toLowerCase().contains('blank');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _buildMedanRow(
            icon: Icons.directions_car_filled_outlined,
            title: '1. Akses Kendaraan',
            value: medan.vehicleAccess,
          ),
          const Divider(height: 20),
          _buildMedanRow(
            icon: Icons.hiking_rounded,
            title: '2. Tingkat Trekking',
            value: medan.trekkingLevel,
          ),
          const Divider(height: 20),
          _buildMedanRow(
            icon: isBlankSpot
                ? Icons.signal_cellular_off_rounded
                : Icons.signal_cellular_alt_rounded,
            title: '3. Kekuatan Sinyal',
            value: medan.cellularSignal,
            isWarning: isBlankSpot,
          ),
          const Divider(height: 20),
          _buildMedanRow(
            icon: Icons.mosque_outlined,
            title: '4. Fasilitas Dasar',
            value: medan.facilities,
          ),
          const Divider(height: 20),
          _buildMedanRow(
            icon: Icons.badge_outlined,
            title: '5. Kebutuhan Pemandu',
            value: medan.guideNeed,
            isWarning: medan.guideNeed.toLowerCase().contains('wajib'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedanRow({
    required IconData icon,
    required String title,
    required String value,
    bool isWarning = false,
  }) {
    final Color badgeColor =
        isWarning ? AppColors.coral500 : AppColors.green800;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: badgeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.ink900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu Wajib "Tips Menjaga Tempat Ini" menggunakan token `--sage-100` (`#E4E9DA`)
  Widget _buildTipsCard(List<LocalTipModel> tips) {
    final displayTips = tips.isNotEmpty
        ? tips
        : const [
            LocalTipModel(
              id: 'default-tip',
              destinationId: '',
              content:
                  'Hormati adat basandi syarak di kawasan Nagari, bawa kembali sampah plastik, dan jaga keasrian sumber air.',
              isImportant: true,
            ),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sage100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green800.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.green800, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tips Menjaga Tempat Ini (Etika Wisata Nagari)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tip.isImportant
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppColors.green800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink900,
                        height: 1.4,
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

  /// Slot Fair-Price Barometer (Tarif Resmi Perda/Nagari)
  Widget _buildFairPriceSection(List<OfficialTariffModel> tariffs) {
    return Container(
      width: double.infinity,
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
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.green500,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Standar Tarif Resmi Perda / Nagari',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green500.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Anti-Pungli',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tariffs.isEmpty)
            const Text(
              'Data tarif resmi Perda sedang disinkronkan.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            )
          else
            ...tariffs.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.itemName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                          Text(
                            '${t.unit} · ${t.regulationRef}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      t.price == 0
                          ? 'Gratis'
                          : 'Rp ${t.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green800,
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
}

