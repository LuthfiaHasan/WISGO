import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Helper terpusat untuk merender foto destinasi wisata Sumatera Barat.
///
/// Memprioritaskan foto asli lokal di `assets/images/gambar_asli/` (instan &
/// tetap tampil di Mode Offline) berdasarkan ID/nama destinasi, dan otomatis
/// fallback ke `Image.network` bila ada destinasi baru/dinamis dari backend
/// atau FE-2 — tanpa perlu mengubah struktur data `SavedDestinationModel`.
class WisgoDestinationImage extends StatelessWidget {
  final String? source;
  final String? destinationId;
  final String? destinationTitle;
  final BoxFit fit;
  final Alignment alignment;
  final int? cacheWidth;
  final FilterQuality filterQuality;
  final Widget? fallback;

  const WisgoDestinationImage({
    super.key,
    this.source,
    this.destinationId,
    this.destinationTitle,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.filterQuality = FilterQuality.medium,
    this.fallback,
  });

  /// Memetakan ID / nama destinasi ke file foto asli lokal di `assets/images/gambar_asli/`.
  static String? resolveLocalAsset({
    String? id,
    String? title,
    String? source,
  }) {
    if (source != null && source.startsWith('assets/')) {
      return source;
    }

    final key = '${id ?? ''} ${title ?? ''}'.toLowerCase();
    if (key.trim().isEmpty) return null;

    if (key.contains('lubuk-hitam') ||
        key.contains('lubuk hitam') ||
        key.contains('cindakir')) {
      return 'assets/images/gambar_asli/01_air_terjun_lubuk_hitam.jpg';
    }
    if (key.contains('kota-tua') ||
        key.contains('kota tua') ||
        key.contains('jembatan siti nurbaya')) {
      return 'assets/images/gambar_asli/17_kota_tua_jembatan_siti_nurbaya.jpg';
    }
    if (key.contains('gunung-padang') ||
        key.contains('gunung padang') ||
        key.contains('siti nurbaya')) {
      return 'assets/images/gambar_asli/02_gunung_padang_siti_nurbaya.jpg';
    }
    if (key.contains('lembah-harau') ||
        key.contains('dest-001') ||
        key.contains('harau') ||
        key.contains('sarasah bunta')) {
      return 'assets/images/gambar_asli/03_lembah_harau_sarasah_bunta.jpg';
    }
    if (key.contains('kapalo-banda') ||
        key.contains('kapalo banda') ||
        key.contains('taram')) {
      return 'assets/images/gambar_asli/04_kapalo_banda_taram.jpg';
    }
    if (key.contains('jam-gadang') ||
        key.contains('dest-004') ||
        key.contains('jam gadang') ||
        key.contains('ngarai sianok')) {
      return 'assets/images/gambar_asli/05_jam_gadang_ngarai_sianok.jpg';
    }
    if (key.contains('nyarai') ||
        key.contains('dest-002') ||
        key.contains('gamaran')) {
      return 'assets/images/gambar_asli/06_air_terjun_nyarai.jpg';
    }
    if (key.contains('pariangan')) {
      return 'assets/images/gambar_asli/07_nagari_tuo_pariangan.jpg';
    }
    if (key.contains('mandeh') ||
        key.contains('dest-006') ||
        key.contains('sironjong') ||
        key.contains('puncak paku')) {
      return 'assets/images/gambar_asli/08_kawasan_mandeh.jpg';
    }
    if (key.contains('pagaruyung') || key.contains('istano basa')) {
      return 'assets/images/gambar_asli/09_istano_basa_pagaruyung.jpg';
    }
    if (key.contains('maninjau') || key.contains('kelok 44')) {
      return 'assets/images/gambar_asli/10_danau_maninjau_kelok_44.jpg';
    }
    if (key.contains('silokek') || key.contains('dest-003')) {
      return 'assets/images/gambar_asli/11_geopark_silokek.jpg';
    }
    if (key.contains('sarugo') ||
        key.contains('dest-005') ||
        key.contains('saribu gonjong')) {
      return 'assets/images/gambar_asli/12_kampung_adat_sarugo.jpg';
    }
    if (key.contains('nasi kapau') ||
        key.contains('los lambuang') ||
        key.contains('dest-007')) {
      return 'assets/images/gambar_asli/13_nasi_kapau_los_lambuang.jpg';
    }
    if (key.contains('masjid-raya') ||
        key.contains('masjid raya') ||
        key.contains('dest-021') ||
        key.contains('ahmad khatib')) {
      return 'assets/images/gambar_asli/14_masjid_raya_sumbar.jpg';
    }
    if (key.contains('air-manis') ||
        key.contains('air manis') ||
        key.contains('malin kundang')) {
      return 'assets/images/gambar_asli/15_pantai_air_manis.jpg';
    }
    if (key.contains('taplau') || key.contains('pantai padang')) {
      return 'assets/images/gambar_asli/16_taplau_pantai_padang.jpg';
    }
    if (key.contains('pasumpahan')) {
      return 'assets/images/gambar_asli/18_pulau_pasumpahan.jpg';
    }
    if (key.contains('adityawarman')) {
      return 'assets/images/gambar_asli/19_museum_adityawarman.jpg';
    }

    return null;
  }

  /// Mengembalikan `ImageProvider` siap `precacheImage` (lokal jika tersedia).
  static ImageProvider? resolveProvider({
    String? id,
    String? title,
    String? source,
    int? cacheWidth,
  }) {
    final local = resolveLocalAsset(id: id, title: title, source: source);
    if (local != null) {
      return ResizeImage.resizeIfNeeded(cacheWidth, null, AssetImage(local));
    }
    if (source != null && source.startsWith('http')) {
      return ResizeImage.resizeIfNeeded(cacheWidth, null, NetworkImage(source));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallback ?? const ColoredBox(color: AppColors.forest);
    final local = resolveLocalAsset(
      id: destinationId,
      title: destinationTitle,
      source: source,
    );

    if (local != null) {
      return Image.asset(
        local,
        fit: fit,
        alignment: alignment,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        filterQuality: filterQuality,
        errorBuilder: (_, __, ___) {
          if (source != null && source!.startsWith('http')) {
            return Image.network(
              source!,
              fit: fit,
              alignment: alignment,
              cacheWidth: cacheWidth,
              gaplessPlayback: true,
              filterQuality: filterQuality,
              errorBuilder: (_, __, ___) => defaultFallback,
            );
          }
          return defaultFallback;
        },
      );
    }

    if (source != null && source!.startsWith('http')) {
      return Image.network(
        source!,
        fit: fit,
        alignment: alignment,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        filterQuality: filterQuality,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    return defaultFallback;
  }
}
