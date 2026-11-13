import 'package:flutter/material.dart';

/// Widget Logo Resmi WISGO (Menggunakan Gambar Asli Resolusi Tinggi 100% Transparan)
/// - `assets/images/logo_primary.png` telah diekstrak dengan Color-to-Alpha Matting
///   dari gambar logo asli pengguna sehingga 100% tajam dan bebas kotak background.
class WisgoLogo extends StatelessWidget {
  final double width;
  final bool showTagline;
  final bool compact;
  final double strokeProgress;

  const WisgoLogo({
    super.key,
    this.width = 230,
    this.showTagline = true,
    this.compact = false,
    this.strokeProgress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = compact ? 108.0 : width;

    return Opacity(
      opacity: strokeProgress.clamp(0.0, 1.0),
      child: SizedBox(
        width: effectiveWidth,
        child: Image.asset(
          'assets/images/logo_primary.png',
          width: effectiveWidth,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
        ),
      ),
    );
  }
}
