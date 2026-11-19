import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Kontroler bahasa aplikasi global (Bahasa Indonesia 'id' & English 'en').
class AppLocale {
  AppLocale._();

  static final ValueNotifier<String> notifier = ValueNotifier<String>('id');

  static String get code => notifier.value;
  static bool get isEn => notifier.value == 'en';

  static void setLocale(String langCode) {
    final normalized = langCode == 'en' ? 'en' : 'id';
    if (notifier.value != normalized) {
      notifier.value = normalized;
    }
  }

  static void toggle() {
    setLocale(isEn ? 'id' : 'en');
  }

  /// Helper terjemahan ringkas ID / EN.
  static String tr(String idText, String enText) => isEn ? enText : idText;
}

/// Tombol pil pilihan bahasa ID | EN yang ringkas dan serasi dengan tema WISGO.
class LanguageTogglePill extends StatelessWidget {
  final bool compact;

  const LanguageTogglePill({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.notifier,
      builder: (context, lang, _) {
        final isEn = lang == 'en';
        return Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: AppColors.creamSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangSegment(
                label: 'ID',
                selected: !isEn,
                compact: compact,
                onTap: () => AppLocale.setLocale('id'),
              ),
              _LangSegment(
                label: 'EN',
                selected: isEn,
                compact: compact,
                onTap: () => AppLocale.setLocale('en'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _LangSegment({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 11,
          vertical: compact ? 4 : 5.5,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 10.5 : 11,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.cream : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
