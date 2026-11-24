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
/// - 4 Kotak Input Responsif: Kursor aktif, auto-advance, auto-backspace, auto-paste
/// - Keyboard Angka Bawaan HP otomatis muncul di HP Android/iOS
/// - Bisa langsung diketik via keyboard laptop/PC saat dijalankan di Chrome
/// - Simulasi Notifikasi Banner WhatsApp Resmi dengan shortcut [Gunakan Kode]
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? userName;
  final String? canonicalPhone;
  final String? devOtpCode;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.userName,
    this.canonicalPhone,
    this.devOtpCode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _showWaBanner = false;
  bool _isVerifying = false;
  int _otpSecondsLeft = 57;
  Timer? _countdownTimer;
  Timer? _bannerDelayTimer;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _startOtpCountdown();

    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (index) {
      final node = FocusNode();
      node.addListener(() {
        if (mounted) setState(() {});
      });
      node.onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[index].text.isEmpty &&
            index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
          setState(() {});
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
      return node;
    });

    // Auto-focus pada kotak pertama saat layar dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });

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
    _startOtpCountdown();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Tangani kasus copy-paste lebih dari 1 digit (misal paste "2486")
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 4; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      if (digits.length >= 4) {
        _focusNodes.last.unfocus();
        setState(() {});
        _verifyOtpAndFinish();
        return;
      } else {
        final nextIndex = digits.length.clamp(0, 3);
        _focusNodes[nextIndex].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    setState(() {});

    if (_isComplete) {
      _verifyOtpAndFinish();
    }
  }

  void _autoFillOtp(String code) {
    final chars = code.split('');
    for (int i = 0; i < 4; i++) {
      _controllers[i].text = i < chars.length ? chars[i] : '';
    }
    _focusNodes.last.unfocus();
    setState(() {
      _showWaBanner = false;
    });
  }

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  void _verifyOtpAndFinish() {
    if (!_isComplete || _isVerifying) return;
    setState(() => _isVerifying = true);

    for (final f in _focusNodes) {
      f.unfocus();
    }

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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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

          // 4. Konten Utama: Kartu Glassmorphic OTP
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                child: ClipRRect(
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

                          // Judul
                          const Text(
                            'Verifikasi Kode OTP',
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
                          const Text(
                            'Kode verifikasi 4 digit telah dikirimkan melalui WhatsApp resmi ke nomor',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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

                          // 4 Kotak Input Digit OTP Interaktif dengan Kursor Asli & Keyboard Support
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFocused = _focusNodes[index].hasFocus;
                              final isFilled =
                                  _controllers[index].text.isNotEmpty;

                              return AnimatedScale(
                                scale: isFocused ? 1.05 : 1.0,
                                duration: const Duration(milliseconds: 140),
                                child: Container(
                                  width: 58,
                                  height: 60,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
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
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (_controllers[index].text.isNotEmpty)
                                          Offstage(
                                            offstage: true,
                                            child: Text(_controllers[index].text),
                                          ),
                                        TextFormField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          cursorColor: AppColors.forest,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.forest,
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
                                          onChanged: (val) =>
                                              _onDigitChanged(index, val),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          if (widget.devOtpCode != null) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _autoFillOtp(widget.devOtpCode!),
                                icon: const Icon(Icons.flash_on_rounded, size: 16),
                                label: const Text('Isi Otomatis'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.forest,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

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
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 20),

                          // Tombol Verifikasi
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
                                    disabledBackgroundColor: AppColors.forest
                                        .withValues(alpha: 0.35),
                                    foregroundColor: Colors.white,
                                    elevation: _isComplete ? 3 : 0,
                                    shadowColor:
                                        Colors.black.withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
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
    );
  }
}
