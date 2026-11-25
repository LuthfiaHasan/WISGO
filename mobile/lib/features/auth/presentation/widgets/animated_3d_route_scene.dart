import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive 3D Rumah Gadang Diorama Stage (1:1 dari `wisgo_interactive_3d_prototype.html`)
/// Merender secara 3D (dengan proyeksi perspektif 3D sejati):
/// - Pulau Silinder 3D Sumatera Barat (`#8EB897`) & Bukit Belakang (`#A8CBB0`, `#96BEA0`)
/// - Jalan Krem (`#FAF3E6`) menuju Rumah Gadang
/// - 8 Tiang Panggung (`#193D22`), Badan Krem (`#FAF3E6`), Pintu Terracotta (`#E65F2B`), Jendela (`#193D22`)
/// - Atap Gonjong 3D Melengkung (`#193D22`) dengan Anjuang Tengah & Tanduk Gonjong Terracotta (`#E65F2B`)
/// - Pin Lokasi 3D Melayang (`#E65F2B`) & Awan 3D (`#FAF3E6`)
/// - Mendukung:
///   1. Geser/drag horizontal 360° dengan jari/mouse untuk memutar Rumah Gadang 3D!
///   2. Rotasi otomatis halus + `spinBoost` saat mengunci GPS
///   3. Tombol Switcher Mode 3D: "Rute Sumbar 3D" vs "Sudut Pandang Atas" (mengubah sudut kamera vertikal secara mulus!)
class Animated3DRouteScene extends StatefulWidget {
  final double spinBoost;

  const Animated3DRouteScene({
    super.key,
    this.spinBoost = 0.0,
  });

  @override
  State<Animated3DRouteScene> createState() => _Animated3DRouteSceneState();
}

class _Animated3DRouteSceneState extends State<Animated3DRouteScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _rotationY = 0.35;
  double _cameraY = 3.8;
  double _targetCameraY = 3.8;
  bool _isDragging = false;
  double _clockTime = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(_onTick)
      ..repeat();
  }

  void _onTick() {
    _clockTime += 0.035;
    if (!_isDragging) {
      _rotationY += (0.008 + widget.spinBoost);
    }
    _cameraY += (_targetCameraY - _cameraY) * 0.12;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => _isDragging = true,
      onPanUpdate: (details) {
        setState(() {
          _rotationY += details.delta.dx * 0.014;
          _targetCameraY =
              (_targetCameraY + details.delta.dy * 0.035).clamp(2.2, 8.2);
        });
      },
      onPanEnd: (_) => _isDragging = false,
      onPanCancel: () => _isDragging = false,
      child: Container(
        width: 268,
        height: 268,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.sage.withValues(alpha: 0.85),
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.10),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Kanvas 3D Rumah Gadang Diorama (Bisa digeser 360° bebas)
              CustomPaint(
                painter: _Diorama3DPainter(
                  rotationY: _rotationY,
                  cameraY: _cameraY,
                  clockTime: _clockTime,
                ),
              ),

              // Inner Subtle Ring Border (#C5DBD0)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sageBorder,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vec3 {
  final double x;
  final double y;
  final double z;
  const _Vec3(this.x, this.y, this.z);
}

class _Poly3D {
  final List<Offset> points2D;
  final double depth;
  final Color color;
  final Color? strokeColor;
  final double strokeWidth;

  _Poly3D({
    required this.points2D,
    required this.depth,
    required this.color,
    this.strokeColor,
    this.strokeWidth = 0.0,
  });
}

/// CustomPainter 3D Engine untuk merender Diorama 3D Rumah Gadang dengan rotasi penuh 360°
class _Diorama3DPainter extends CustomPainter {
  final double rotationY;
  final double cameraY;
  final double clockTime;

  _Diorama3DPainter({
    required this.rotationY,
    required this.cameraY,
    required this.clockTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;

    // 1. Latar Belakang Sage (#DFECE2)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.sage,
    );

    // Sudut Pitch Kamera dari cameraY (3.8 -> ~0.34 rad, 7.8 -> ~0.64 rad)
    final pitch = math.atan2(cameraY - 0.2, 10.2);
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    const fovScale = 44.0;
    const cameraDist = 11.0;

    // Proyeksi titik 3D (x, y, z) ke layar 2D + kedalaman z
    ({Offset pt, double z}) project(_Vec3 v) {
      // Rotasi sekitar sumbu Y
      final rx = v.x * cosY + v.z * sinY;
      final rz0 = -v.x * sinY + v.z * cosY;
      final ry0 = v.y;

      // Rotasi pitch kamera (sumbu X)
      final ry = ry0 * cosP - rz0 * sinP;
      final rz = ry0 * sinP + rz0 * cosP;

      final perspective = cameraDist / (cameraDist - rz).clamp(2.5, 25.0);
      final sx = cx + rx * fovScale * perspective;
      final sy = cy - ry * fovScale * perspective;
      return (pt: Offset(sx, sy), z: rz);
    }

    final List<_Poly3D>renderQueue = [];

    void addQuad(
      _Vec3 a,
      _Vec3 b,
      _Vec3 c,
      _Vec3 d,
      Color color, {
      Color? stroke,
      double strokeW = 0.5,
    }) {
      final pa = project(a);
      final pb = project(b);
      final pc = project(c);
      final pd = project(d);
      final avgZ = (pa.z + pb.z + pc.z + pd.z) * 0.25;
      renderQueue.add(
        _Poly3D(
          points2D: [pa.pt, pb.pt, pc.pt, pd.pt],
          depth: avgZ,
          color: color,
          strokeColor: stroke ?? color,
          strokeWidth: strokeW,
        ),
      );
    }

    void addTri(
      _Vec3 a,
      _Vec3 b,
      _Vec3 c,
      Color color, {
      Color? stroke,
      double strokeW = 0.5,
    }) {
      final pa = project(a);
      final pb = project(b);
      final pc = project(c);
      final avgZ = (pa.z + pb.z + pc.z) / 3.0;
      renderQueue.add(
        _Poly3D(
          points2D: [pa.pt, pb.pt, pc.pt],
          depth: avgZ,
          color: color,
          strokeColor: stroke ?? color,
          strokeWidth: strokeW,
        ),
      );
    }

    void addBox(
      double x,
      double y,
      double z,
      double dx,
      double dy,
      double dz,
      Color topCol,
      Color frontCol,
      Color sideCol,
    ) {
      final hx = dx * 0.5;
      final hy = dy * 0.5;
      final hz = dz * 0.5;

      final v000 = _Vec3(x - hx, y - hy, z - hz);
      final v100 = _Vec3(x + hx, y - hy, z - hz);
      final v101 = _Vec3(x + hx, y - hy, z + hz);
      final v001 = _Vec3(x - hx, y - hy, z + hz);

      final v010 = _Vec3(x - hx, y + hy, z - hz);
      final v110 = _Vec3(x + hx, y + hy, z - hz);
      final v111 = _Vec3(x + hx, y + hy, z + hz);
      final v011 = _Vec3(x - hx, y + hy, z + hz);

      // Top
      addQuad(v010, v110, v111, v011, topCol);
      // Front (+z)
      addQuad(v001, v101, v111, v011, frontCol);
      // Back (-z)
      addQuad(v100, v000, v010, v110, frontCol);
      // Left (-x)
      addQuad(v000, v001, v011, v010, sideCol);
      // Right (+x)
      addQuad(v101, v100, v110, v111, sideCol);
    }

    // --- 1. PULAU SILINDER 3D (Island Base) ---
    const int segs = 28;
    const double rTop = 3.15;
    const double rBot = 2.85;
    const double yTop = -0.80;
    const double yBot = -1.45;

    final List<Offset> topRing2D = [];
    double topRingZ = 0;

    for (int i = 0; i < segs; i++) {
      final a1 = (i / segs) * 2 * math.pi;
      final a2 = ((i + 1) / segs) * 2 * math.pi;

      final t1 = _Vec3(math.cos(a1) * rTop, yTop, math.sin(a1) * rTop);
      final t2 = _Vec3(math.cos(a2) * rTop, yTop, math.sin(a2) * rTop);
      final b2 = _Vec3(math.cos(a2) * rBot, yBot, math.sin(a2) * rBot);
      final b1 = _Vec3(math.cos(a1) * rBot, yBot, math.sin(a1) * rBot);

      addQuad(
        t1,
        t2,
        b2,
        b1,
        const Color(0xFF739E7C),
      );

      final ptTop = project(t1);
      topRing2D.add(ptTop.pt);
      topRingZ += ptTop.z;
    }

    renderQueue.add(
      _Poly3D(
        points2D: topRing2D,
        depth: (topRingZ / segs) - 0.1,
        color: const Color(0xFF8EB897),
      ),
    );

    // --- 2. BUKIT BELAKANG (Rolling Hills) ---
    addBox(-1.05, -0.58, -1.05, 1.8, 0.44, 1.1, const Color(0xFFA8CBB0),
        const Color(0xFF96BEA0), const Color(0xFF85B08F));
    addBox(1.10, -0.62, -0.90, 1.6, 0.38, 1.0, const Color(0xFF96BEA0),
        const Color(0xFF88B292), const Color(0xFF7CA686));

    // --- 3. JALAN KREM MENUJU RUMAH GADANG (#FAF3E6) ---
    addBox(0.0, -0.76, 1.35, 0.95, 0.08, 2.5, const Color(0xFFFAF3E6),
        const Color(0xFFE8DEC8), const Color(0xFFDCD1BA));

    // --- 4. TIANG PANGGUNG RUMAH GADANG (#193D22) ---
    const stiltX = [-1.15, -0.40, 0.40, 1.15];
    const stiltZ = [-0.32, 0.32];
    for (final sx in stiltX) {
      for (final sz in stiltZ) {
        addBox(sx, -0.52, sz - 0.12, 0.12, 0.52, 0.12, AppColors.forest,
            AppColors.forest, const Color(0xFF112A17));
      }
    }

    // --- 5. BADAN RUMAH GADANG (#FAF3E6) & LIST HIJAU HUTAN (#193D22) ---
    // Trim Bawah
    addBox(0.0, -0.24, -0.12, 2.75, 0.09, 1.10, AppColors.forest,
        AppColors.forest, const Color(0xFF112A17));
    // Badan Utama Krem
    addBox(0.0, 0.14, -0.12, 2.66, 0.68, 1.02, const Color(0xFFFAF3E6),
        const Color(0xFFFAF3E6), const Color(0xFFEBE1CE));

    // Pintu Tengah Terracotta (#E65F2B) di Depan & Belakang
    addBox(0.0, 0.08, 0.41, 0.38, 0.46, 0.05, AppColors.terracotta,
        AppColors.terracotta, const Color(0xFFC94E1F));
    addBox(0.0, 0.08, -0.65, 0.38, 0.46, 0.05, AppColors.terracotta,
        AppColors.terracotta, const Color(0xFFC94E1F));

    // Jendela Kiri & Kanan (#193D22)
    for (final wx in [-0.78, 0.78]) {
      addBox(wx, 0.15, 0.41, 0.34, 0.28, 0.05, AppColors.forest,
          AppColors.forest, AppColors.forest);
      addBox(wx, 0.15, -0.65, 0.34, 0.28, 0.05, AppColors.forest,
          AppColors.forest, AppColors.forest);
    }

    // --- 6. ATAP GONJONG 3D MELENGKUNG KHAS MINANGKABAU (#193D22 & #E65F2B) ---
    // Kita bangun segmen kurva Gonjong 3D dari kiri (-1.95) ke kanan (+1.95)
    double roofCurveY(double x) {
      final ax = x.abs();
      if (ax < 0.85) {
        // Lembah tengah naik ke gonjong dalam
        return 0.56 + 0.52 * math.pow(ax / 0.85, 1.7);
      } else {
        // Dari lembah luar naik tajam ke tanduk gonjong ujung
        final t = (ax - 0.85) / 1.10;
        return 0.72 + 0.82 * math.pow(t, 1.6);
      }
    }

    const int roofSteps = 16;
    const double xMin = -1.95;
    const double xMax = 1.95;
    const double zFront = 0.48;
    const double zBack = -0.72;
    const double yEave = 0.46;

    for (int i = 0; i < roofSteps; i++) {
      final x1 = xMin + (xMax - xMin) * (i / roofSteps);
      final x2 = xMin + (xMax - xMin) * ((i + 1) / roofSteps);
      final ry1 = roofCurveY(x1);
      final ry2 = roofCurveY(x2);

      // Eave X sedikit lebih sempit daripada ujung tanduk
      final ex1 = x1 * 0.76;
      final ex2 = x2 * 0.76;

      final rF1 = _Vec3(x1, ry1, zFront * 0.35);
      final rF2 = _Vec3(x2, ry2, zFront * 0.35);
      final rB1 = _Vec3(x1, ry1, zBack * 0.45);
      final rB2 = _Vec3(x2, ry2, zBack * 0.45);

      final eF1 = _Vec3(ex1, yEave, zFront);
      final eF2 = _Vec3(ex2, yEave, zFront);
      final eB1 = _Vec3(ex1, yEave, zBack);
      final eB2 = _Vec3(ex2, yEave, zBack);

      // Lereng Depan Atap Gonjong
      addQuad(eF1, eF2, rF2, rF1, AppColors.forest,
          stroke: const Color(0xFF14331C), strokeW: 0.6);
      // Lereng Belakang Atap Gonjong
      addQuad(rB1, rB2, eB2, eB1, const Color(0xFF14331C),
          stroke: const Color(0xFF0F2615), strokeW: 0.6);
      // Punggung Atap (Ridge Terracotta #E65F2B)
      addQuad(rF1, rF2, rB2, rB1, AppColors.terracotta,
          stroke: AppColors.terracotta, strokeW: 0.8);
    }

    // Tanduk Gonjong Kiri & Kanan (Terracotta #E65F2B)
    final leftTip = _Vec3(-2.05, 1.66, -0.12);
    addTri(
      _Vec3(-1.72, 1.22, 0.12),
      _Vec3(-1.72, 1.22, -0.36),
      leftTip,
      AppColors.terracotta,
    );
    final rightTip = _Vec3(2.05, 1.66, -0.12);
    addTri(
      _Vec3(1.72, 1.22, -0.36),
      _Vec3(1.72, 1.22, 0.12),
      rightTip,
      AppColors.terracotta,
    );

    // Gonjong Anjuang Depan Tengah (Piramida Terracotta #E65F2B)
    final spireTop = _Vec3(0.0, 1.36, 0.34);
    final sFL = _Vec3(-0.34, 0.52, 0.64);
    final sFR = _Vec3(0.34, 0.52, 0.64);
    final sBL = _Vec3(-0.34, 0.52, 0.04);
    final sBR = _Vec3(0.34, 0.52, 0.04);
    addTri(sFL, sFR, spireTop, AppColors.terracotta);
    addTri(sFR, sBR, spireTop, const Color(0xFFD15120));
    addTri(sBL, sFL, spireTop, const Color(0xFFD15120));

    // --- 7. URUTKAN POLIGON BERDASARKAN KEDALAMAN Z (Painter's Algorithm) ---
    renderQueue.sort((a, b) => a.depth.compareTo(b.depth));

    for (final poly in renderQueue) {
      final path = Path()..addPolygon(poly.points2D, true);
      canvas.drawPath(
        path,
        Paint()
          ..color = poly.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      if (poly.strokeColor != null && poly.strokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = poly.strokeColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = poly.strokeWidth
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true,
        );
      }
    }

    // --- 8. AWAN 3D MENGAPUNG (#FAF3E6) ---
    final cloudPaint = Paint()..color = AppColors.cream;
    final c1 = project(_Vec3(-1.65, 1.55, -0.95));
    canvas.drawCircle(c1.pt, 12, cloudPaint);
    canvas.drawCircle(c1.pt.translate(10, 2), 9, cloudPaint);
    canvas.drawCircle(c1.pt.translate(-9, 2), 8, cloudPaint);

    final c2 = project(_Vec3(1.75, 1.35, -0.75));
    canvas.drawCircle(c2.pt, 10, cloudPaint);
    canvas.drawCircle(c2.pt.translate(8, 2), 7.5, cloudPaint);
    canvas.drawCircle(c2.pt.translate(-8, 2), 7, cloudPaint);

    // --- 9. PIN LOKASI 3D MELAYANG DI ATAS RUMAH GADANG (#E65F2B) ---
    final pinBobY = 2.05 + math.sin(clockTime * 1.6) * 0.14;
    final pinTip3D = project(_Vec3(0, pinBobY - 0.35, 0));
    final pinHead3D = project(_Vec3(0, pinBobY + 0.12, 0));

    final pinTip = pinTip3D.pt;
    final pinHead = pinHead3D.pt;

    final conePath = Path()
      ..moveTo(pinTip.dx, pinTip.dy)
      ..lineTo(pinHead.dx - 11.5, pinHead.dy + 2)
      ..lineTo(pinHead.dx + 11.5, pinHead.dy + 2)
      ..close();

    canvas.drawPath(conePath, Paint()..color = AppColors.terracotta);
    canvas.drawCircle(pinHead, 12.0, Paint()..color = AppColors.terracotta);
    canvas.drawCircle(pinHead, 5.2, Paint()..color = AppColors.cream);
  }

  @override
  bool shouldRepaint(covariant _Diorama3DPainter oldDelegate) {
    return oldDelegate.rotationY != rotationY ||
        oldDelegate.cameraY != cameraY ||
        oldDelegate.clockTime != clockTime;
  }
}
