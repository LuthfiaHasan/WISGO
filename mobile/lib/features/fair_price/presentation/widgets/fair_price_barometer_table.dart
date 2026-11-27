import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_destination_image.dart';
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


  static const List<Map<String, String>> _groups = [
    {'key': 'TIKET', 'title': '1. Tiket Masuk & Retribusi Kawasan'},
    {'key': 'PARKIR', 'title': '2. Retribusi Parkir Resmi Kendaraan'},
    {'key': 'FASILITAS', 'title': '3. Sewa Fasilitas, Pemandu & Lokal'},
  ];



  @override
  Widget build(BuildContext context) {
    final dest = widget.destinationData;
    final activeGroups = widget.selectedCategory == 'ALL'
        ? _groups
        : _groups.where((g) => g['key'] == widget.selectedCategory).toList();



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
                    WisgoDestinationImage(
                      source: dest.imageUrl,
                      destinationId: dest.id,
                      destinationTitle: dest.title,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      fallback: const ColoredBox(color: AppColors.forest),
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
                    separatorBuilder: (_, __) => const Divider(
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
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedType = 'Tiket Masuk';
    String? errorMsg;

    const tariffTypes = [
      'Tiket Masuk',
      'Parkir Motor',
      'Parkir Mobil',
      'Pemandu / Fasilitas',
      'Lainnya',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(modalCtx).bottom,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.warmBorder,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Laporan Ketidaksesuaian Tarif Resmi',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${dest.title} (${dest.region})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Pilih jenis tarif yang bermasalah
                      const Text(
                        'Jenis Tarif yang Dilaporkan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: tariffTypes.map((type) {
                          final active = selectedType == type;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  setModalState(() => selectedType = type),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.sage.withValues(alpha: 0.9)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.brush.withValues(alpha: 0.55)
                                        : AppColors.warmBorder,
                                    width: active ? 1.2 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: active
                                        ? AppColors.forest
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 2. Input Nominal yang Diminta di Lokasi
                      const Text(
                        'Nominal yang Diminta di Lokasi (Opsional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                          hintText: 'Contoh: 25000',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted.withValues(alpha: 0.6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.warmBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.warmBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.brush,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Input Keterangan / Kronologi Laporan (Bisa Diketikan Langsung)
                      const Text(
                        'Keterangan / Detail Kejadian',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteCtrl,
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) {
                          if (errorMsg != null) {
                            setModalState(() => errorMsg = null);
                          }
                        },
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText:
                              'Tuliskan ketidaksesuaian tarif yang dialami (misal: diminta parkir Rp 20.000 tanpa karcis resmi)...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted.withValues(alpha: 0.65),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.warmBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: errorMsg != null
                                  ? AppColors.danger
                                  : AppColors.warmBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.brush,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (errorMsg != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          errorMsg!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            size: 14,
                            color: AppColors.brush,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Titik GPS & acuan ${dest.perdaRef} otomatis terlampir.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tombol Pil Kirim Laporan
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [AppColors.brush, AppColors.forest],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.forest.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              final note = noteCtrl.text.trim();
                              if (note.isEmpty) {
                                setModalState(() {
                                  errorMsg =
                                      'Mohon tuliskan keterangan ketidaksesuaian tarif terlebih dahulu.';
                                });
                                return;
                              }
                              final rawAmt = amountCtrl.text.trim();
                              final amtSuffix =
                                  rawAmt.isNotEmpty ? ' (Rp $rawAmt)' : '';
                              Navigator.of(sheetContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.forest,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: Text(
                                    'Laporan $selectedType$amtSuffix berhasil dikirim ke pos pengawasan.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cream,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: const Center(
                              child: Text(
                                'Kirim Laporan Sekarang',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cream,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}
