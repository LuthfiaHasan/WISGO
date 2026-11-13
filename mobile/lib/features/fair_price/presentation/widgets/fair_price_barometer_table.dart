import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/fair_price_tariff_model.dart';

/// Item 7: Komponen Tabel Fair-Price Barometer Vertikal + Kalkulator Simulasi Biaya Resmi
/// (1:1 dengan `wisgo_interactive_3d_prototype (1).html`).
///
/// Menampilkan:
/// - Visual Destination Banner dengan Foto, Badge Wilayah & Kategori Alam, Judul, Perda, dan Akses Medan
/// - Susunan Rincian Biaya Resmi Vertikal (1. Tiket Masuk & Retribusi Kawasan, 2. Retribusi Parkir Resmi Kendaraan, 3. Sewa Fasilitas, Pemandu & Lokal)
/// - Kalkulator Simulasi Biaya Resmi Vertikal dengan tombol stepper (+/-) untuk Pengunjung, Parkir Motor, dan Parkir Mobil
class FairPriceBarometerTable extends StatefulWidget {
  final SavedDestinationModel destinationData;
  final String selectedCategory; // 'ALL' | 'TIKET' | 'PARKIR' | 'FASILITAS'

  const FairPriceBarometerTable({
    super.key,
    required this.destinationData,
    this.selectedCategory = 'ALL',
  });

  @override
  State<FairPriceBarometerTable> createState() =>
      _FairPriceBarometerTableState();
}

class _FairPriceBarometerTableState extends State<FairPriceBarometerTable> {
  int _visitors = 2;
  int _motor = 0;
  int _mobil = 1;

  static const List<Map<String, String>> _groups = [
    {'key': 'TIKET', 'title': '1. Tiket Masuk & Retribusi Kawasan'},
    {'key': 'PARKIR', 'title': '2. Retribusi Parkir Resmi Kendaraan'},
    {'key': 'FASILITAS', 'title': '3. Sewa Fasilitas, Pemandu & Lokal'},
  ];

  String _formatRupiah(int number) {
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }

  void _adjustCalc(String field, int delta) {
    setState(() {
      if (field == 'visitors') {
        _visitors = (_visitors + delta).clamp(0, 99);
      } else if (field == 'motor') {
        _motor = (_motor + delta).clamp(0, 99);
      } else if (field == 'mobil') {
        _mobil = (_mobil + delta).clamp(0, 99);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destinationData;
    final activeGroups = widget.selectedCategory == 'ALL'
        ? _groups
        : _groups.where((g) => g['key'] == widget.selectedCategory).toList();

    final totalCost = (_visitors * dest.calcRates.tiket) +
        (_motor * dest.calcRates.motor) +
        (_mobil * dest.calcRates.mobil);

    final parts = <String>[];
    if (_visitors > 0) parts.add('$_visitors Tiket');
    if (_motor > 0) parts.add('$_motor Motor');
    if (_mobil > 0) parts.add('$_mobil Mobil');
    final breakdownText = parts.isNotEmpty
        ? parts.join(' + ')
        : 'Pilih jumlah pengunjung/kendaraan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Visual Destination Banner with Terrain Info
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 148,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppColors.forest),
                    Image.network(
                      dest.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: AppColors.forest),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.ink.withValues(alpha: 0.88),
                            AppColors.ink.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cream.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dest.region,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.forest.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dest.natureType,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dest.perdaRef,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.sage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  border: Border(
                    top: BorderSide(color: AppColors.warmBorder),
                  ),
                ),
                child: Text(
                  'Akses & Medan: ${dest.terrainNote}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Vertical Official Cost List (Susunan ke Bawah)
        ...activeGroups.map((group) {
          final rows = dest.tariffs
              .where((t) => t.cat == group['key'])
              .toList();
          if (rows.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sageBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.creamSubtle,
                      border: Border(
                        bottom: BorderSide(color: AppColors.warmBorder),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            group['title']!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        const Text(
                          'Susunan Vertikal',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.warmBorder,
                    ),
                    itemBuilder: (context, idx) {
                      final r = rows[idx];
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      r.note,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.cream,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: AppColors.warmBorder,
                                        ),
                                      ),
                                      child: Text(
                                        'Acuan: ${r.type} • Maks Wajar ${r.fairMax}',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brush,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'TARIF RESMI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  r.official,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),

        // 3. Interactive Vertical Calculator (Simulasi Biaya ke Bawah)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.warmBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalkulator Simulasi Biaya Resmi',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Susunan estimasi ke bawah sesuai jumlah rombongan & kendaraan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'Otomatis',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Baris 1: Pengunjung
              _buildStepperRow(
                title: 'Tiket Masuk Pengunjung',
                rateLabel: '${_formatRupiah(dest.calcRates.tiket)} / orang',
                value: _visitors,
                onDecrement: () => _adjustCalc('visitors', -1),
                onIncrement: () => _adjustCalc('visitors', 1),
              ),
              const Divider(height: 1, color: AppColors.warmBorder),

              // Baris 2: Parkir Motor
              _buildStepperRow(
                title: 'Retribusi Parkir Motor (Roda 2)',
                rateLabel: '${_formatRupiah(dest.calcRates.motor)} / unit',
                value: _motor,
                onDecrement: () => _adjustCalc('motor', -1),
                onIncrement: () => _adjustCalc('motor', 1),
              ),
              const Divider(height: 1, color: AppColors.warmBorder),

              // Baris 3: Parkir Mobil
              _buildStepperRow(
                title: 'Retribusi Parkir Mobil (Roda 4)',
                rateLabel: '${_formatRupiah(dest.calcRates.mobil)} / unit',
                value: _mobil,
                onDecrement: () => _adjustCalc('mobil', -1),
                onIncrement: () => _adjustCalc('mobil', 1),
              ),

              const SizedBox(height: 12),

              // Total Official Calculation Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Biaya Resmi Seharusnya',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sage,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            breakdownText,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.sage.withValues(alpha: 0.80),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRupiah(totalCost),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cream,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4. Tombol Lapor Ketidaksesuaian Tarif / Pungli (Sesuai Jobdesk Pilar 3)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.coralTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.terracotta.withValues(alpha: 0.30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diminta Bayar Melebihi Standar Tarif Perda?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Laporkan pungutan liar atau tarif parkir tidak wajar beserta titik lokasi ke pos pengawasan Dinas Pariwisata & Dishub.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showReportSheet(context, dest),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Laporkan Ketidaksesuaian Tarif di Lokasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportSheet(BuildContext context, SavedDestinationModel dest) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.sageBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Laporan Ketidaksesuaian Tarif Resmi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dest.title} (${dest.region})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: const Text(
                    'Laporan Anda tercatat beserta titik lokasi GPS dan acuan Perda terkait untuk ditindaklanjuti oleh petugas pengawasan setempat.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.ink,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: const Text(
                            'Laporan tarif berhasil dikirim ke pos pengawasan.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cream,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.cream,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kirim Laporan Sekarang',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepperRow({
    required String title,
    required String rateLabel,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rateLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
