import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Painter Latar Belakang Garis Orbit & Jalur Rute Wisata Minang
/// Sesuai prototipe wisgo_modern_mobile_ui_prototype.html
class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Soft Sage Ambient Aura Glow di Tengah
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.sage.withValues(alpha: 0.65),
          AppColors.sage.withValues(alpha: 0.35),
          AppColors.bg.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 170));
    canvas.drawCircle(center, 170, auraPaint);

    // 2. Lingkaran Orbit Putus-Putus (Dashed Orbit Circle) r = 126
    _drawDashedCircle(
      canvas: canvas,
      center: center,
      radius: 126,
      dashCount: 44,
      dashLengthRatio: 0.45,
      color: AppColors.green.withValues(alpha: 0.15),
      strokeWidth: 1.1,
    );

    // Lingkaran Luar Tipis r = 168
    _drawDashedCircle(
      canvas: canvas,
      center: center,
      radius: 168,
      dashCount: 56,
      dashLengthRatio: 0.25,
      color: AppColors.green.withValues(alpha: 0.09),
      strokeWidth: 0.9,
    );

    // 3. Titik Penanda Kecil pada Orbit
    // Titik Coral di Atas (cx=180, cy=54 -> offset y = -126)
    final coralDotPaint = Paint()
      ..color = AppColors.coral.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - 126), 3.5, coralDotPaint);

    // Titik Hijau di Kanan (cx=306, cy=180 -> offset x = +126)
    final greenDotPaint = Paint()
      ..color = AppColors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + 126, center.dy), 3.0, greenDotPaint);

    // 4. Jalur Rute Wisata Bergelombang Putus-Putus (Route Dash Paths)
    final topRoutePaint = Paint()
      ..color = AppColors.green.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final topPath = Path()
      ..moveTo(-20, size.height * 0.21)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.17,
        size.width * 0.35,
        size.height * 0.31,
        size.width * 0.62,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.25,
        size.width * 0.90,
        size.height * 0.14,
        size.width + 25,
        size.height * 0.16,
      );
    _drawDashedPath(canvas, topPath, topRoutePaint, 5, 7);

    // Jalur Rute Bawah Koral
    final bottomRoutePaint = Paint()
      ..color = AppColors.coral.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final bottomPath = Path()
      ..moveTo(-15, size.height * 0.79)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.83,
        size.width * 0.38,
        size.height * 0.69,
        size.width * 0.65,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.75,
        size.width * 0.92,
        size.height * 0.84,
        size.width + 20,
        size.height * 0.80,
      );
    _drawDashedPath(canvas, bottomPath, bottomRoutePaint, 5, 7);
  }

  void _drawDashedCircle({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required int dashCount,
    required double dashLengthRatio,
    required Color color,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final step = (2 * math.pi) / dashCount;
    final sweep = step * dashLengthRatio;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

