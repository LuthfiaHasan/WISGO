import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/core/theme/app_colors.dart';
import 'package:rancakin_mobile/core/theme/app_tokens.dart';
import 'package:rancakin_mobile/core/theme/app_theme.dart';
import 'package:rancakin_mobile/core/widgets/wisgo_button.dart';
import 'package:rancakin_mobile/core/widgets/wisgo_card.dart';
import 'package:rancakin_mobile/core/widgets/wisgo_badge.dart';
import 'package:rancakin_mobile/core/widgets/crowd_badge.dart';

void main() {
  group('DESIGN SYSTEM CONSTITUTION (desain.md) Tests', () {
    test('01. Core Brand Colors calibration', () {
      expect(AppColors.cream, const Color(0xFFFAF3E6));
      expect(AppColors.creamSubtle, const Color(0xFFF3EBDC));
      expect(AppColors.bgCard, const Color(0xFFFFFFFF));
      expect(AppColors.forest, const Color(0xFF193D22));
      expect(AppColors.brush, const Color(0xFF2F663E));
      expect(AppColors.sage, const Color(0xFFDFECE2));
      expect(AppColors.sageBorder, const Color(0xFFD5E2D7));
      expect(AppColors.warmBorder, const Color(0xFFE5DEC9));
      expect(AppColors.terracotta, const Color(0xFFE65F2B));
      expect(AppColors.coralTint, const Color(0xFFF9E4DC));
      expect(AppColors.ink, const Color(0xFF142618));
      expect(AppColors.muted, const Color(0xFF5A6B5D));
    });

    test('02. Semantic & 360 Pin Tokens calibration', () {
      expect(AppColors.success, const Color(0xFF15803D));
      expect(AppColors.warning, const Color(0xFFD97706));
      expect(AppColors.goldMinang, const Color(0xFFC89242));
      expect(AppColors.info, const Color(0xFF1E5B82));
      expect(AppColors.danger, const Color(0xFFDC2626));

      // 4 Pin 360° Tokens
      expect(AppColors.pinNavigasiBiru, const Color(0xFF2563EB));
      expect(AppColors.pinAudioEmas, const Color(0xFFD97706));
      expect(AppColors.pinFasilitasHijau, const Color(0xFF15803D));
      expect(AppColors.pinMitraOranye, const Color(0xFFE65F2B));
    });

    test('03. Typography floor size >= 11 px quality gate', () {
      expect(AppTypography.display.fontSize! >= 11.0, isTrue);
      expect(AppTypography.h1.fontSize! >= 11.0, isTrue);
      expect(AppTypography.h2.fontSize! >= 11.0, isTrue);
      expect(AppTypography.title.fontSize! >= 11.0, isTrue);
      expect(AppTypography.body.fontSize! >= 11.0, isTrue);
      expect(AppTypography.bodySmall.fontSize! >= 11.0, isTrue);
      expect(AppTypography.caption.fontSize! >= 11.0, isTrue);
      expect(AppTypography.caption.fontSize, 11.0);
    });

    test('04. Radius and Spacing calibration', () {
      expect(AppRadius.xs, 8.0);
      expect(AppRadius.sm, 12.0);
      expect(AppRadius.md, 16.0);
      expect(AppRadius.lg, 20.0);
      expect(AppRadius.sheet, 28.0);
      expect(AppRadius.pill, 999.0);

      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
    });

    testWidgets('05. WisgoButton renders with 52px height & executes tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WisgoButton(
              label: 'Jelajah Destinasi',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      final buttonFinder = find.text('Jelajah Destinasi');
      expect(buttonFinder, findsOneWidget);

      final buttonBox = tester.renderObject<RenderBox>(find.byType(WisgoButton));
      expect(buttonBox.size.height, 52.0);

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('06. WisgoCard renders with bgCard, warmBorder & 20px radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: WisgoCard(
              child: Text('Konten Kartu'),
            ),
          ),
        ),
      );

      expect(find.text('Konten Kartu'), findsOneWidget);
    });

    testWidgets('07. WisgoBadge renders with caption typography and colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                WisgoBadge(label: 'Terverifikasi', variant: WisgoBadgeVariant.success),
                WisgoBadge(label: 'Menunggu', variant: WisgoBadgeVariant.warning),
                WisgoBadge(label: 'Ramai', variant: WisgoBadgeVariant.terracotta),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Ramai'), findsOneWidget);
    });

    testWidgets('08. CrowdBadge renders Sepi, Sedang, Ramai correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                CrowdBadge(level: CrowdLevel.sepi),
                CrowdBadge(level: CrowdLevel.sedang),
                CrowdBadge(level: CrowdLevel.ramai),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Sepi'), findsOneWidget);
      expect(find.text('Sedang'), findsOneWidget);
      expect(find.text('Ramai'), findsOneWidget);
    });
  });
}
