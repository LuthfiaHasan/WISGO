import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_logo.dart';
import 'location_onboarding_screen.dart';
import 'otp_verification_screen.dart';

/// Layar 3: Masuk ke Akun WISGO (Khusus WhatsApp OTP, Bahasa Indonesia Bersih).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController(text: '812-7578-953');
  final FocusNode _phoneFocus = FocusNode();
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _handlePhoneInput(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length > 12) digits = digits.substring(0, 12);

    String formatted = '';
    if (digits.isNotEmpty) {
      formatted += digits.substring(0, digits.length.clamp(0, 3));
    }
    if (digits.length > 3) {
      formatted += '-${digits.substring(3, digits.length.clamp(3, 7))}';
    }
    if (digits.length > 7) {
      formatted += '-${digits.substring(7, digits.length.clamp(7, 12))}';
    }

    if (_phoneController.text != formatted) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() => _showError = false);
  }

  void _fillDemoPhone() {
    _phoneController.text = '812-7578-953';
    setState(() => _showError = false);
  }

  void _clearPhoneInput() {
    _phoneController.clear();
    _phoneFocus.requestFocus();
    setState(() => _showError = false);
  }

  void _submitPhoneAndSendOtp() {
    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 8) {
      setState(() => _showError = true);
      return;
    }

    final formattedPhone = '+62 ${_phoneController.text.trim()}';
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, _, _) =>
            OtpVerificationScreen(phoneNumber: formattedPhone),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _phoneFocus.hasFocus;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Navigasi Atas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LocationOnboardingScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.sage,
                                foregroundColor: AppColors.forest,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.sageBorder),
                              ),
                              child: const Text(
                                'Langkah 2 dari 2',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 2. Identitas Logo WISGO
                        const Center(
                          child: WisgoLogo(compact: true),
                        ),

                        const SizedBox(height: 20),

                        // 3. Judul & Penjelasan
                        const Text(
                          'Masuk ke Akun WISGO',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Simpan destinasi favorit Sumatera Barat, cek standar tarif resmi Perda, dan nikmati perjalanan yang nyaman.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 4. Input Nomor WhatsApp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nomor WhatsApp Aktif',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
                              ),
                            ),
                            GestureDetector(
                              onTap: _fillDemoPhone,
                              child: const Text(
                                'Isi Nomor Contoh',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brush,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? AppColors.forest
                                  : AppColors.sageBorder,
                              width: 1.8,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.cream,
                                  border: Border(
                                    right: BorderSide(
                                      color: AppColors.sageBorder,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  '+62',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  keyboardType: TextInputType.number,
                                  cursorColor: AppColors.forest,
                                  onChanged: _handlePhoneInput,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                    letterSpacing: 0.4,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '812-xxxx-xxxx',
                                    hintStyle: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14.5,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) =>
                                      _submitPhoneAndSendOtp(),
                                ),
                              ),
                              if (_phoneController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: _clearPhoneInput,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'Hapus',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (_showError) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Masukkan minimal 9 digit nomor WhatsApp yang valid.',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // 5. Tombol Utama
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitPhoneAndSendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: AppColors.cream,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Kirim Kode OTP 4 Digit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 6. Keterangan Pengiriman WhatsApp Bersih
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.sage.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.sageBorder),
                          ),
                          child: const Text(
                            'Kode verifikasi 4 digit dikirimkan langsung melalui WhatsApp resmi WISGO tanpa biaya pulsa operator.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.forest,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 7. Catatan Keamanan Bawah
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Dilindungi sistem keamanan transaksi resmi WISGO Sumatera Barat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
