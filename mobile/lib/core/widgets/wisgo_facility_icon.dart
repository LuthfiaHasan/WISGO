import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Auto-mapper terpusat: Nama Fasilitas -> Aset Ikon 3D Clay (`fac_*.png`).
/// Digunakan seragam di Kartu Destinasi Beranda, Form Usul Wisata,
/// Modal Detail Fasilitas, dan Halaman Detail Wisata.
String? resolveFacilityIconAsset(String facilityName) {
  final f = facilityName.toLowerCase();
  if (f.contains('parkir')) return 'assets/images/fac_parkir.png';
  if (f.contains('toilet') || f.contains('bilas') || f.contains('kamar ganti')) {
    return 'assets/images/fac_toilet.png';
  }
  if (f.contains('musholla') || f.contains('musala') || f.contains('masjid')) {
    return 'assets/images/fac_musholla.png';
  }
  if (f.contains('kuliner') ||
      f.contains('warung') ||
      f.contains('makan') ||
      f.contains('kopi') ||
      f.contains('umkm')) {
    return 'assets/images/fac_kuliner.png';
  }
  if (f.contains('gazebo') || f.contains('pondok') || f.contains('lesehan')) {
    return 'assets/images/fac_gazebo.png';
  }
  if (f.contains('trekking') ||
      f.contains('jalur') ||
      f.contains('hutan') ||
      f.contains('pendakian')) {
    return 'assets/images/fac_trekking.png';
  }
  if (f.contains('pemandu') || f.contains('guide')) {
    return 'assets/images/fac_pemandu.png';
  }
  if (f.contains('foto') ||
      f.contains('spot') ||
      f.contains('gardu') ||
      f.contains('pandang')) {
    return 'assets/images/fac_foto.png';
  }
  return null;
}

/// Auto-mapper kategori wisata alam (untuk chip Kategori di Form Usul Wisata)
String resolveNatureCategoryAsset(String categoryName) {
  final c = categoryName.toLowerCase();
  if (c.contains('air terjun') || c.contains('sungai') || c.contains('danau')) {
    return 'assets/images/pin_airterjun.png';
  }
  if (c.contains('pantai') || c.contains('pulau') || c.contains('bahari')) {
    return 'assets/images/pin_pantai.png';
  }
  return 'assets/images/pin_gunung.png';
}

/// Widget Ikon Fasilitas 3D Clay WISGO dengan fallback otomatis ke ikon Material
class WisgoFacilityIcon extends StatelessWidget {
  const WisgoFacilityIcon({
    super.key,
    required this.facilityName,
    this.size = 18,
    this.fallbackIcon,
    this.fallbackColor = AppColors.forest,
  });

  final String facilityName;
  final double size;
  final IconData? fallbackIcon;
  final Color fallbackColor;

  IconData _defaultFallback() {
    if (fallbackIcon != null) return fallbackIcon!;
    final f = facilityName.toLowerCase();
    if (f.contains('parkir')) return Icons.local_parking_rounded;
    if (f.contains('toilet') || f.contains('bilas')) return Icons.wc_rounded;
    if (f.contains('musholla') || f.contains('musala') || f.contains('masjid')) {
      return Icons.mosque_rounded;
    }
    if (f.contains('kuliner') || f.contains('warung') || f.contains('makan')) {
      return Icons.restaurant_rounded;
    }
    if (f.contains('gazebo') || f.contains('pondok')) return Icons.deck_rounded;
    if (f.contains('trekking') || f.contains('jalur')) {
      return Icons.hiking_rounded;
    }
    if (f.contains('pemandu') || f.contains('guide')) {
      return Icons.support_agent_rounded;
    }
    if (f.contains('foto') || f.contains('spot')) {
      return Icons.camera_alt_rounded;
    }
    if (f.contains('perahu') || f.contains('kapal') || f.contains('dermaga')) {
      return Icons.directions_boat_rounded;
    }
    if (f.contains('air panas')) return Icons.hot_tub_rounded;
    if (f.contains('tiket') || f.contains('loket')) {
      return Icons.confirmation_number_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final asset = resolveFacilityIconAsset(facilityName);
    if (asset == null) {
      return Icon(_defaultFallback(), size: size * 0.82, color: fallbackColor);
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          Icon(_defaultFallback(), size: size * 0.82, color: fallbackColor),
    );
  }
}
