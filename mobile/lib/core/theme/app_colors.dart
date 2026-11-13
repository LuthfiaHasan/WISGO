import 'package:flutter/material.dart';

/// Palet Warna Presisi dari `wisgo_interactive_3d_prototype (1).html`
/// - cream:       #FAF3E6
/// - creamSubtle: #F3EBDC
/// - forest:      #193D22
/// - brush:       #2F663E
/// - sage:        #DFECE2
/// - sageBorder:  #D5E2D7
/// - warmBorder:  #E5DEC9
/// - terracotta:  #E65F2B
/// - coralTint:   #F9E4DC
/// - ink:         #142618
/// - muted:       #5A6B5D
class AppColors {
  AppColors._();

  // Core Colors dari wisgo_interactive_3d_prototype (1).html
  static const Color cream = Color(0xFFFAF3E6);
  static const Color creamSubtle = Color(0xFFF3EBDC);
  static const Color forest = Color(0xFF193D22);
  static const Color brush = Color(0xFF2F663E);
  static const Color sage = Color(0xFFDFECE2);
  static const Color sageBorder = Color(0xFFD5E2D7);
  static const Color warmBorder = Color(0xFFE5DEC9);
  static const Color terracotta = Color(0xFFE65F2B);
  static const Color coralTint = Color(0xFFF9E4DC);
  static const Color ink = Color(0xFF142618);
  static const Color muted = Color(0xFF5A6B5D);

  // Shimmer Colors (#EDE4D3 -> #F7F1E5 -> #EDE4D3)
  static const Color shimmerBase = Color(0xFFEDE4D3);
  static const Color shimmerHighlight = Color(0xFFF7F1E5);

  // Semantic Aliases
  static const Color background = cream;
  static const Color primaryDark = forest;
  static const Color primaryMain = brush;
  static const Color secondaryLight = sage;
  static const Color secondaryBorder = sageBorder;
  static const Color accent = terracotta;
  static const Color accentLight = coralTint;

  // Legacy Aliases untuk kompatibilitas seluruh proyek
  static const Color bg = cream;
  static const Color creamBg = cream;
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color green = forest;
  static const Color greenDark = forest;
  static const Color greenMedium = brush;
  static const Color forestDeep = forest;
  static const Color sageCard = sage;
  static const Color mintBadge = sage;
  static const Color coral = terracotta;
  static const Color peach = coralTint;
  static const Color emeraldAccent = brush;
  static const Color limeAccent = sage;
  static const Color limeSoft = sage;
  static const Color limeMid = sageBorder;

  static const Color textMuted = muted;
  static const Color borderLight = sageBorder;
  static const Color borderInput = sageBorder;
  static const Color inputFill = cream;
  static const Color disabledBg = sageBorder;
  static const Color disabledText = muted;
}
