import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';

/// Layar 4: Verifikasi Kode OTP 4 Digit via WhatsApp
/// - Desain Modern Frosted Glassmorphic Card (Selaras dengan Gambar 3 & Splashscreen)
/// - Background Lanskap Alam Minangkabau HD dengan Gradiasi Ivory
/// - Tipografi & Tombol Hijau Resmi WISGO (AppColors.forest #193D22)
/// - Simulasi Notifikasi Banner WhatsApp Resmi dengan shortcut [Gunakan Kode]
/// - Numpad modern yang responsif dan empuk
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? userName;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.userName,
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
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _startOtpCountdown();

    // Munculkan simulasi banner pesan WhatsApp resmi setelah 600ms
    _bannerDelayTimer = Timer(const Duration(milliseconds: 600), () {
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Lanskap Alam HD
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_bg_1.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),

            // 2. Gradiasi Ivory Ambient Transparan
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.cream.withValues(alpha: 0.35),
                      AppColors.cream.withValues(alpha: 0.65),
                      AppColors.cream.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Tombol Kembali di Pojok Kiri Atas
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.sageBorder.withValues(alpha: 0.9),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 13,
                            color: AppColors.forest,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Konten Utama: Kartu Glassmorphic + Numpad
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Kartu Glassmorphic OTP
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.84),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.90),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.forest.withValues(alpha: 0.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Badge WhatsApp
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.sage,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.sageBorder),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 14,
                                          color: AppColors.forest,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Pesan WhatsApp Terkirim',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Judul (FONT SAMA PERSIS DENGAN SPLASHSCREEN)
                                const Text(
                                  'Masukkan Kode OTP',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.forest,
                                    letterSpacing: -0.4,
                                    height: 1.20,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Subjudul
                                Text(
                                  'Kode verifikasi 4 digit telah dikirimkan melalui WhatsApp resmi ke nomor',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.muted,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.phoneNumber,
                                      style: const TextStyle(
                                        fontSize: 14,
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
                                          color: AppColors.brush,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // 4 Kotak Input Digit OTP
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
                                        width: 58,
                                        height: 60,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isFocused
                                                ? AppColors.forest
                                                : isFilled
                                                    ? AppColors.forest
                                                    : AppColors.sageBorder,
                                            width: isFocused ? 2.2 : 1.5,
                                          ),
                                          boxShadow: isFocused
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.forest
                                                        .withValues(alpha: 0.18),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.04),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            _otpDigits[index],
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.forest,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                const SizedBox(height: 14),

                                // Countdown Kirim Ulang
                                Center(
                                  child: _otpSecondsLeft > 0
                                      ? Text(
                                          'Belum menerima kode? Kirim ulang ($_otpSecondsLeft detik)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: _triggerOtpNotification,
                                          child: const Text(
                                            'Kirim Ulang Kode WhatsApp',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.forest,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                ),

                                const SizedBox(height: 20),

                                // Tombol Verifikasi (HIJAU RESMI WISGO DENGAN BENTUK PILL SAMA PERSIS)
                                GestureDetector(
                                  onTapDown: (_) =>
                                      setState(() => _isButtonPressed = true),
                                  onTapUp: (_) =>
                                      setState(() => _isButtonPressed = false),
                                  onTapCancel: () =>
                                      setState(() => _isButtonPressed = false),
                                  child: AnimatedScale(
                                    scale: _isButtonPressed ? 0.96 : 1.0,
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeInOut,
                                    child: SizedBox(
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _isComplete && !_isVerifying
                                            ? _verifyOtpAndFinish
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.forest,
                                          disabledBackgroundColor:
                                              AppColors.forest.withValues(alpha: 0.35),
                                          foregroundColor: Colors.white,
                                          elevation: _isComplete ? 3 : 0,
                                          shadowColor:
                                              Colors.black.withValues(alpha: 0.35),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            side: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.20),
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                        child: _isVerifying
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Verifikasi & Masuk Aplikasi',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Numpad Modern Glassmorphic (Di Bawah Kartu)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.70),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildNumpadRow(['1', '2', '3']),
                            const SizedBox(height: 6),
                            _buildNumpadRow(['4', '5', '6']),
                            const SizedBox(height: 6),
                            _buildNumpadRow(['7', '8', '9']),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumpadAction(
                                    'Isi Otomatis',
                                    onTap: () => _autoFillOtp('2486'),
                                    isSpecial: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumpadButton('0'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumpadAction(
                                    'Hapus',
                                    onTap: _pressBackspace,
                                    isIcon: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Simulasi Pesan Masuk WhatsApp Resmi (Slide Down Animation)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              top: _showWaBanner ? 16 : -120,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(18),
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  color: AppColors.forest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WhatsApp • Resmi WISGO',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Kode OTP Anda: 2486',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _autoFillOtp('2486'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cream,
                            foregroundColor: AppColors.forest,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Gunakan Kode',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> items) {
    return Row(
      children: items.map((digit) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNumpadButton(digit),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadButton(String digit) {
    return Material(
      color: Colors.white.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => _pressNumpad(digit),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadAction(
    String label, {
    required VoidCallback onTap,
    bool isSpecial = false,
    bool isIcon = false,
  }) {
    return Material(
      color: isSpecial
          ? AppColors.sage
          : Colors.white.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: isIcon
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 19,
                  color: AppColors.forest,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                ),
        ),
      ),
    );
  }
}
