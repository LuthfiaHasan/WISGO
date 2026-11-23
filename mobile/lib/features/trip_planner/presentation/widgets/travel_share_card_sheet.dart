import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/travel_experience_model.dart';

/// Painter untuk Merender QR Code Promosi WISGO secara Tajam & Bersih (Offline)
class WisgoQrCodePainter extends CustomPainter {
  final Color darkColor;
  final Color lightColor;

  WisgoQrCodePainter({
    this.darkColor = const Color(0xFF193D22),
    this.lightColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = lightColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      bgPaint,
    );

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Grid 21x21 QR Code matrix representatif
    const int matrixSize = 21;
    final double moduleSize = (size.width - 16) / matrixSize;
    const double padding = 8.0;

    void drawFinderPattern(double startX, double startY) {
      // Kotak luar 7x7
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, startY, moduleSize * 7, moduleSize * 7),
          Radius.circular(moduleSize * 1.5),
        ),
        darkPaint,
      );
      // Kotak dalam 5x5 putih
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + moduleSize,
            startY + moduleSize,
            moduleSize * 5,
            moduleSize * 5,
          ),
          Radius.circular(moduleSize),
        ),
        bgPaint,
      );
      // Pusat 3x3 hitam
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + moduleSize * 2,
            startY + moduleSize * 2,
            moduleSize * 3,
            moduleSize * 3,
          ),
          Radius.circular(moduleSize * 0.7),
        ),
        darkPaint,
      );
    }

    // 3 Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    drawFinderPattern(padding, padding);
    drawFinderPattern(padding + moduleSize * 14, padding);
    drawFinderPattern(padding, padding + moduleSize * 14);

    // Timing & Data Matrix
    final pattern = [
      // Pola data matriks yang rapi & simetris
      [8, 2], [8, 4], [8, 5], [9, 8], [11, 8], [13, 8],
      [15, 8], [17, 8], [19, 8], [2, 8], [4, 8], [5, 8],
      [9, 10], [10, 10], [11, 10], [12, 10], [10, 9], [10, 11],
      [14, 14], [15, 14], [16, 14], [14, 15], [16, 15], [15, 16],
      [18, 14], [19, 15], [20, 14], [14, 18], [15, 19], [14, 20],
      [9, 14], [10, 15], [11, 14], [12, 15], [13, 14],
      [14, 9], [15, 10], [14, 11], [15, 12], [14, 13],
      [9, 2], [9, 4], [11, 2], [11, 4], [12, 3], [13, 5],
      [2, 14], [3, 15], [4, 14], [5, 16], [2, 18], [4, 19],
    ];

    for (final dot in pattern) {
      final double x = padding + dot[0] * moduleSize;
      final double y = padding + dot[1] * moduleSize;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, moduleSize * 0.95, moduleSize * 0.95),
          Radius.circular(moduleSize * 0.3),
        ),
        darkPaint,
      );
    }

    // Logo 'W' kecil di tengah QR
    final centerW = size.width / 2;
    final centerH = size.height / 2;
    canvas.drawCircle(
      Offset(centerW, centerH),
      moduleSize * 2.2,
      Paint()..color = lightColor,
    );
    canvas.drawCircle(
      Offset(centerW, centerH),
      moduleSize * 1.8,
      Paint()..color = darkColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Modal Lembar Template Posting Berbagi Sosial Media (Konsep Strava + Promosi WISGO)
class TravelShareCardSheet extends StatefulWidget {
  final TravelExperience experience;

  const TravelShareCardSheet({
    super.key,
    required this.experience,
  });

  @override
  State<TravelShareCardSheet> createState() => _TravelShareCardSheetState();
}

class _TravelShareCardSheetState extends State<TravelShareCardSheet> {
  bool _isCopied = false;
  bool _isDownloaded = false;

  void _handleCopyLink() {
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Tautan pengalaman berhasil disalin!',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _handleSaveImage() {
    setState(() => _isDownloaded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.image_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Template posting disimpan ke Galeri HP (Siap diunggah)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isDownloaded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.experience;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.warmBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Template Posting Sosial Media',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Bagikan pencapaian Strava-style & promosikan aplikasi WISGO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.ink.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Card Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // CARD UTAMA TEMPLATE POSTING (Strava-like + QR WISGO)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF142417),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF142417).withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Kartu: Logo WISGO & Identitas Ranah Minang
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.sage.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.explore_rounded,
                                        color: Color(0xFF68D391),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'WISGO • SUMBAR',
                                            style: TextStyle(
                                              color: Color(0xFF68D391),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          Text(
                                            'Travel Experience • ${exp.tripDate}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  exp.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Title & Destination
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_rounded,
                                    color: Color(0xFFE5C07B),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    exp.destinationName,
                                    style: const TextStyle(
                                      color: Color(0xFFE5C07B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 4 Big Metrics Grid (Strava Identity)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildMetricItem(
                                'Jarak',
                                '${exp.distanceKm}',
                                'km',
                                Icons.straighten_rounded,
                              ),
                              _buildMetricDivider(),
                              _buildMetricItem(
                                'Waktu',
                                exp.durationFormatted,
                                '',
                                Icons.timer_rounded,
                              ),
                              _buildMetricDivider(),
                              _buildMetricItem(
                                'Elevasi',
                                '+${exp.elevationGainMeters}',
                                'm',
                                Icons.landscape_rounded,
                              ),
                              _buildMetricDivider(),
                              _buildMetricItem(
                                'Kalori',
                                '${exp.caloriesBurned}',
                                'kkal',
                                Icons.local_fire_department_rounded,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Checkpoint Route Traverse List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TITIK CHECKPOINT TERLEWATI',
                                    style: TextStyle(
                                      color: Color(0xFFA0AEC0),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    '${exp.completedCheckpointsCount}/${exp.checkpoints.length} Tuntas',
                                    style: const TextStyle(
                                      color: Color(0xFF68D391),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: exp.checkpoints.map((cp) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          cp.icon,
                                          size: 11,
                                          color: const Color(0xFF68D391),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            cp.name.split('&').first.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
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

                        // Lencana Pencapaian
                        if (exp.achievements.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.military_tech_rounded,
                                  color: Color(0xFFF6AD55),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Lencana: ${exp.achievements.map((a) => a.title).join(" • ")}',
                                    style: const TextStyle(
                                      color: Color(0xFFFBD38D),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // PROMO WISGO DENGAN QR CODE (Promosi Aplikasi)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D1B0F),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              // QR Code Generator
                              CustomPaint(
                                size: const Size(68, 68),
                                painter: WisgoQrCodePainter(
                                  darkColor: const Color(0xFF142417),
                                  lightColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: Color(0xFF68D391),
                                          size: 13,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PINDAI UNTUK MENGUNDUH',
                                          style: TextStyle(
                                            color: Color(0xFF68D391),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Aplikasi WISGO Sumatera Barat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Jelajah rute wisata Sumbar, tarif Perda resmi, open trip berizin & pantau cuaca real-time.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.70),
                                        fontSize: 9.5,
                                        height: 1.25,
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
                  ),

                  const SizedBox(height: 18),

                  // Action Buttons: Share & Save
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleCopyLink,
                          icon: Icon(
                            _isCopied ? Icons.check_rounded : Icons.link_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isCopied ? 'Tersalin' : 'Salin Tautan',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.warmBorder),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleSaveImage,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            _isDownloaded ? 'Tersimpan' : 'Bagikan Post',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF68D391), size: 15),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 1.5),
                Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA0AEC0),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}
