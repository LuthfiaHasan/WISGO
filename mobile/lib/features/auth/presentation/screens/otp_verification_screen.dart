import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../fe1_visual_map/fe1_main_shell.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';

/// Layar 4: Verifikasi Kode OTP 4 Digit (Bahasa Indonesia Bersih, Tanpa Dekorasi Ikon Berlebih).
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<String> _otpDigits = ['', '', '', ''];
  int _activeOtpIndex = 0;
  bool _showWaBanner = false;
  bool _isVerifying = false;
  int _otpSecondsLeft = 57;
  Timer? _countdownTimer;
  Timer? _bannerDelayTimer;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startOtpCountdown();

    _bannerDelayTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showWaBanner = true);
      }
    });
  }

  void _startOtpCountdown() {
    _countdownTimer?.cancel();
    _otpSecondsLeft = 57;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpSecondsLeft > 0) {
        if (mounted) setState(() => _otpSecondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  void _triggerOtpNotification() {
    setState(() {
      _showWaBanner = true;
      _otpSecondsLeft = 57;
    });
  }

  void _focusOtpSlot(int index) {
    setState(() => _activeOtpIndex = index);
  }

  void _pressNumpad(String num) {
    setState(() {
      _otpDigits[_activeOtpIndex] = num;
      if (_activeOtpIndex < 3) {
        _activeOtpIndex++;
      }
    });
  }

  void _pressBackspace() {
    setState(() {
      if (_otpDigits[_activeOtpIndex].isNotEmpty) {
        _otpDigits[_activeOtpIndex] = '';
      } else if (_activeOtpIndex > 0) {
        _activeOtpIndex--;
        _otpDigits[_activeOtpIndex] = '';
      }
    });
  }

  void _autoFillOtp(String code) {
    final chars = code.split('');
    setState(() {
      for (int i = 0; i < 4; i++) {
        _otpDigits[i] = i < chars.length ? chars[i] : '';
      }
      _activeOtpIndex = 3;
      _showWaBanner = false;
    });
  }

  bool get _isComplete => _otpDigits.every((d) => d.isNotEmpty);

  void _verifyOtpAndFinish() {
    if (!_isComplete || _isVerifying) return;
    setState(() => _isVerifying = true);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const Fe1MainShell(),
          builder: (_) => const SavedPlacesScreen(),
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bannerDelayTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final label = event.logicalKey.keyLabel;
          if (RegExp(r'^[0-9]$').hasMatch(label)) {
            _pressNumpad(label);
          } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _pressBackspace();
          } else if (event.logicalKey == LogicalKeyboardKey.enter &&
              _isComplete) {
            _verifyOtpAndFinish();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Konten Utama
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 28,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Navigasi Atas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.sage,
                                  foregroundColor: AppColors.forest,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(
                                      color: AppColors.sageBorder,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Kembali',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Text(
                                'Verifikasi Kode OTP',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(width: 68),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Bagian Input Kode 4 Digit
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.coralTint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Pesan WhatsApp Terkirim',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.terracotta,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Masukkan Kode OTP 4 Digit',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Kode verifikasi telah dikirimkan melalui WhatsApp ke nomor',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Ubah Nomor',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.terracotta,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // 4 Kotak Digit OTP
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  final isFocused = index == _activeOtpIndex;
                                  final isFilled =
                                      _otpDigits[index].isNotEmpty;

                                  return GestureDetector(
                                    onTap: () => _focusOtpSlot(index),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 56,
                                      height: 56,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isFocused
                                              ? AppColors.forest
                                              : isFilled
                                                  ? AppColors.brush
                                                  : AppColors.sageBorder,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _otpDigits[index],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 16),

                              // Kirim Ulang Kode
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Belum menerima kode? ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _triggerOtpNotification,
                                    child: Text(
                                      'Kirim ulang ($_otpSecondsLeft detik)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.terracotta,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Tombol Verifikasi & Papan Angka
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isComplete
                                      ? _verifyOtpAndFinish
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.forest,
                                    foregroundColor: AppColors.cream,
                                    disabledBackgroundColor:
                                        AppColors.sageBorder,
                                    disabledForegroundColor: AppColors.muted,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _isVerifying
                                        ? 'Memverifikasi Kode...'
                                        : 'Verifikasi & Masuk Aplikasi',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Papan Angka Mobile Bersih
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.sage.withValues(alpha: 0.60),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.sageBorder,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildNumpadRow(['1', '2', '3']),
                                    const SizedBox(height: 8),
                                    _buildNumpadRow(['4', '5', '6']),
                                    const SizedBox(height: 8),
                                    _buildNumpadRow(['7', '8', '9']),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _autoFillOtp('2486'),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppColors.coralTint,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Isi Otomatis',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.terracotta,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildNumpadDigitButton('0'),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: InkWell(
                                            onTap: _pressBackspace,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Hapus',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.forest,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 2. Banner Notifikasi Pesan WhatsApp OTP
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                top: _showWaBanner ? 10 : -120,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _autoFillOtp('2486'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.brush),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'WhatsApp • Resmi WISGO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sage,
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: const TextSpan(
                                  text: 'Kode OTP Anda: ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '2486',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Gunakan Kode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      children: [
        Expanded(child: _buildNumpadDigitButton(digits[0])),
        const SizedBox(width: 8),
        Expanded(child: _buildNumpadDigitButton(digits[1])),
        const SizedBox(width: 8),
        Expanded(child: _buildNumpadDigitButton(digits[2])),
      ],
    );
  }

  Widget _buildNumpadDigitButton(String digit) {
    return InkWell(
      onTap: () => _pressNumpad(digit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
        ),
      ),
    );
  }
}
