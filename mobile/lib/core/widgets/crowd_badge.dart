import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// CrowdBadge - Penanda Keramaian (Sepi, Sedang, Ramai)
enum CrowdLevel { sepi, sedang, ramai }

class CrowdBadge extends StatelessWidget {
  final CrowdLevel level;

  const CrowdBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (level) {
      case CrowdLevel.sepi:
        bg = AppColors.green500.withOpacity(0.15);
        fg = AppColors.green500;
        text = 'Sepi';
        break;
      case CrowdLevel.sedang:
        bg = AppColors.orange500.withOpacity(0.15);
        fg = AppColors.orange500;
        text = 'Sedang';
        break;
      case CrowdLevel.ramai:
        bg = AppColors.coral500.withOpacity(0.15);
        fg = AppColors.coral500;
        text = 'Ramai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

