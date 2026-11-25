import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Modern Button WISGO (Sesuai Palet Warna Resmi #1F4523 & #FDF3E3)
class PillButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isEnabled;
  final Widget? icon;
  final Widget? trailingIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double borderRadius;

  const PillButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isEnabled = true,
    this.icon,
    this.trailingIcon,
    this.backgroundColor,
    this.textColor,
    this.height = 54,
    this.borderRadius = 16,
  });

  /// Varian Primary Forest Green (#1F4523)
  factory PillButton.lime({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    Widget? icon,
    Widget? trailingIcon,
  }) {
    return PillButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
      trailingIcon: trailingIcon,
      backgroundColor: AppColors.green,
      textColor: Colors.white,
    );
  }

  /// Varian Soft Sage / Secondary
  factory PillButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    Widget? icon,
  }) {
    return PillButton(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: AppColors.sage,
      textColor: AppColors.greenDark,
    );
  }

  /// Varian Outlined
  factory PillButton.outlined({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    Widget? icon,
  }) {
    return PillButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isOutlined: true,
      icon: icon,
    );
  }

  /// Varian Coral (#EB6534)
  factory PillButton.coral({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
  }) {
    return PillButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.coral,
      textColor: Colors.white,
    );
  }

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool canPress =
        widget.isEnabled && !widget.isLoading && widget.onPressed != null;

    if (widget.isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: OutlinedButton(
          onPressed: canPress ? widget.onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green,
            backgroundColor: Colors.white.withValues(alpha: 0.6),
            side: BorderSide(
              color: AppColors.green.withValues(alpha: 0.25),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
          child: _buildChild(AppColors.green),
        ),
      );
    }

    final bgColor = !widget.isEnabled
        ? AppColors.disabledBg
        : (widget.backgroundColor ?? AppColors.green);
    final fgColor = !widget.isEnabled
        ? AppColors.disabledText
        : (widget.textColor ?? Colors.white);

    return GestureDetector(
      onTapDown: canPress ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: canPress ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: canPress ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: canPress ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: AppColors.disabledBg,
              disabledForegroundColor: AppColors.disabledText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
            child: _buildChild(fgColor),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(Color fgColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: fgColor,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          widget.trailingIcon!,
        ],
      ],
    );
  }
}
