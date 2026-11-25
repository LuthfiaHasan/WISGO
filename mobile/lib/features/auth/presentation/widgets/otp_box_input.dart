import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// 4-Digit OTP Box Input Component Resmi WISGO
/// - 4 kotak ukuran 60x64px, rounded 18px
/// - Latar Putih Bersih, Border #E2D9C8, Fokus Border Hijau Hutan #1F4523
/// - Efek sedikit membesar (scale) saat aktif diketik
class OtpBoxInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final TextEditingController? masterController;

  const OtpBoxInput({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.masterController,
  });

  @override
  State<OtpBoxInput> createState() => OtpBoxInputState();
}

class OtpBoxInputState extends State<OtpBoxInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) {
      final node = FocusNode();
      node.addListener(() {
        if (mounted) setState(() {});
      });
      return node;
    });

    widget.masterController?.addListener(_syncFromMaster);
  }

  void _syncFromMaster() {
    final text = widget.masterController?.text ?? '';
    for (int i = 0; i < widget.length; i++) {
      if (i < text.length) {
        _controllers[i].text = text[i];
      } else {
        _controllers[i].clear();
      }
    }
    if (mounted) setState(() {});
  }

  void setOtp(String code) {
    for (int i = 0; i < widget.length; i++) {
      if (i < code.length) {
        _controllers[i].text = code[i];
      } else {
        _controllers[i].clear();
      }
    }
    _focusNodes.last.unfocus();
    if (mounted) setState(() {});
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  void dispose() {
    widget.masterController?.removeListener(_syncFromMaster);
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    setState(() {});
    final code = _otpCode;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final isFilled = _controllers[index].text.isNotEmpty;

        return AnimatedScale(
          scale: isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Container(
            width: 60,
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isFocused
                    ? AppColors.green
                    : isFilled
                        ? AppColors.green.withValues(alpha: 0.45)
                        : AppColors.borderLight,
                width: isFocused ? 2.0 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isFocused
                      ? AppColors.green.withValues(alpha: 0.12)
                      : AppColors.greenDark.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                cursorColor: AppColors.green,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onChanged: (val) => _onDigitChanged(index, val),
              ),
            ),
          ),
        );
      }),
    );
  }
}
