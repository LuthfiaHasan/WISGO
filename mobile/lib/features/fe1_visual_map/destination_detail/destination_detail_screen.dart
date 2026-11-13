import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/crowd_badge.dart';
import '../../../core/widgets/pill_button.dart';
import '../../fair_price/data/models/fair_price_tariff_model.dart';
import '../../fair_price/presentation/widgets/fair_price_barometer_table.dart';
import '../models/destination_model.dart';
import '../virtual_tour_360/virtual_tour_360_screen.dart';

/// Layar 02 · Detail Tempat (FE-1)
/// Pilar 1 & 3: 4 Statistik, 5 Indikator Medan, Tips Menjaga Tempat & Fair-Price Barometer (FE-2)
class DestinationDetailScreen extends StatefulWidget {
  final DestinationModel destination;
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
            tooltip: _isSavedOffline ? 'Tersimpan Offline' : 'Simpan Offline',
            onPressed: () {
              setState(() => _isSavedOffline = !_isSavedOffline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.green800,
                  content: Text(
                    _isSavedOffline
                        ? '${dest.name} berhasil disimpan ke Kantong Offline.'
                        : '${dest.name} dihapus dari penyimpanan offline.',
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
            // 1. HERO BANNER FOTO ASLI + PRATINJAU 360°
            _buildHeroBanner(context, dest),
            const SizedBox(height: 16),

            // TOMBOL UTAMA CTA 52PX: JELAJAH TUR 360°
            PillButton(
              text: 'Jelajah Tur 360° (Drone & Darat)',
              icon: const Icon(
                Icons.view_in_ar_rounded,
                color: Colors.white,
                size: 20,
              ),
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

            // 2. GRID 4 STATISTIK KEPUTUSAN
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

            // 3. KARTU 5 INDIKATOR MEDAN LAPANGAN (PILAR 3)
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

            // 4. KARTU WAJIB: "TIPS MENJAGA TEMPAT INI" (#E4E9DA)
            _buildTipsCard(dest.tips),
            const SizedBox(height: 24),

            // 5. SLOT FAIR-PRICE BAROMETER (INTEGRASI TABEL RESMI DARI REKAN FE-2)
            const Text(
              'Fair-Price Barometer (Tarif Resmi Nagari & Perda)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 12),
            widget.fe2FairPriceSlot ??
                Builder(
                  builder: (_) {
                    final matched = kAllSumbarDestinations.firstWhere(
                      (d) => d.title.toLowerCase().contains(
                            dest.name.toLowerCase().split(' ').first,
                          ),
                      orElse: () => kAllSumbarDestinations[1],
                    );
                    return FairPriceBarometerTable(
                      destinationData: matched,
                      selectedCategory: 'ALL',
                    );
                  },
                ),
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
            color: Colors.black.withValues(alpha: 0.12),
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

          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A3A1B).withValues(
                      alpha: dest.coverImage.isNotEmpty ? 0.72 : 1.0,
                    ),
                    AppColors.green800.withValues(
                      alpha: dest.coverImage.isNotEmpty ? 0.90 : 1.0,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCategoryCulture ? AppColors.indigo500 : AppColors.green500,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
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
          icon: Icons.people_alt_outlined,
          label: '3. Keramaian Saat Ini',
          child: CrowdBadge(level: dest.crowdLevelEnum),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildFiveMedanCard(MedanIndicatorModel medan) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildMedanRow(
            icon: Icons.directions_car_filled_outlined,
            title: 'Akses Kendaraan',
            value: medan.vehicleAccess,
            color: AppColors.green800,
          ),
          const Divider(height: 18),
          _buildMedanRow(
            icon: Icons.nordic_walking_outlined,
            title: 'Tingkat Trekking',
            value: medan.trekkingLevel,
            color: medan.trekkingLevel.contains('Ekstrem')
                ? AppColors.coral500
                : AppColors.green800,
          ),
          const Divider(height: 18),
          _buildMedanRow(
            icon: Icons.cell_tower_rounded,
            title: 'Sinyal Seluler',
            value: medan.cellularSignal,
            color: medan.cellularSignal.contains('Blank')
                ? AppColors.coral500
                : AppColors.green500,
          ),
          const Divider(height: 18),
          _buildMedanRow(
            icon: Icons.wc_outlined,
            title: 'Fasilitas Umum',
            value: medan.facilities,
            color: AppColors.green800,
          ),
          const Divider(height: 18),
          _buildMedanRow(
            icon: Icons.person_pin_circle_outlined,
            title: 'Kebutuhan Pemandu',
            value: medan.guideNeed,
            color: medan.guideNeed.contains('Wajib')
                ? AppColors.orange500
                : AppColors.green800,
          ),
        ],
      ),
    );
  }

  Widget _buildMedanRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.ink900),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard(List<LocalTipModel> tips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sage100, // #E4E9DA Sesuai Desain Token
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green800.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.green800, size: 20),
              SizedBox(width: 8),
              Text(
                'Tips Menjaga Tempat Ini (Wajib)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tips.isEmpty)
            const Text(
              'Bawa kembali sampah Anda dan hormati adat istiadat Nagari setempat.',
              style: TextStyle(fontSize: 13, color: AppColors.ink900, height: 1.4),
            )
          else
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          t.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.ink900,
                            fontWeight: t.isImportant ? FontWeight.w600 : FontWeight.normal,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

