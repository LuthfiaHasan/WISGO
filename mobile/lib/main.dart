import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_tokens.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/wisgo_button.dart';
import 'core/widgets/wisgo_card.dart';
import 'core/widgets/wisgo_badge.dart';
import 'core/widgets/crowd_badge.dart';

void main() {
  runApp(const RancakinApp());
}

class RancakinApp extends StatelessWidget {
  const RancakinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WISGO - Wisata Pintar Sumbar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreenPlaceholder(),
    );
  }
}

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('WISGO (Sumatera Barat)'),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Semantics(
              button: true,
              label: 'Pindai Smart QR Perda',
              child: SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.forest),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Selamat Datang
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: AppColors.sageBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppColors.forest, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Selamat datang di Ranah Minang! Jelajahi 19 Kab/Kota dengan 8 Pilar Smart Tourism.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Heading Seksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Destinasi Pilihan',
                  style: AppTypography.h1,
                ),
                WisgoBadge(
                  label: 'Terverifikasi Perda',
                  variant: WisgoBadgeVariant.success,
                  hasDot: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Kartu Destinasi Baku (WisgoCard)
            WisgoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Lembah Harau',
                          style: AppTypography.h2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CrowdBadge(level: CrowdLevel.sedang),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kabupaten Lima Puluh Kota',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
                  ),
                  const Divider(height: 24),

                  // Grid 4 Statistik Sederhana
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Jarak', '124 km'),
                      _buildStat('Waktu', '2j 45m'),
                      _buildStat('Sinyal', 'Blank Spot'),
                      _buildStat('Tiket', 'Rp 10.000'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // CTA Primer 52px Sesuai Standar desain.md
                  WisgoButton(
                    label: 'Jelajah Tur 360°',
                    icon: Icons.view_in_ar_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.tabular(
            AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
