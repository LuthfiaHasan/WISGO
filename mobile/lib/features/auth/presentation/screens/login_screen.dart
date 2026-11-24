import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_logo.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';
import 'location_onboarding_screen.dart';
import 'otp_verification_screen.dart';

/// Layar 3: Masuk (Sign In) & Daftar (Sign Up) Akun WISGO
/// - Desain Modern Frosted Glassmorphic Card (Terinspirasi Referensi Gambar 3)
/// - Background Pemandangan Alam Sumatera Barat HD
/// - Tipografi & Tombol Hijau Selaras dengan Splashscreen (AppColors.forest #193D22)
/// - Mendukung Sign In & Sign Up dengan verifikasi Kode OTP via WhatsApp
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Mode autentikasi: false = Sign In (Masuk), true = Sign Up (Daftar)
  bool _isSignUp = false;

  final TextEditingController _phoneController =
      TextEditingController(text: '812-7578-953');
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();

  bool _rememberMe = true;
  bool _agreeTerms = true;
  bool _showError = false;
  String _errorMessage = '';
  bool _isButtonPressed = false;
  bool _isGoogleLoading = false;
  bool _isGoogleButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _nameFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
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
    if (_isSignUp && _nameController.text.isEmpty) {
      _nameController.text = 'Sutan Rangkayo';
    }
    setState(() => _showError = false);
  }

  void _clearPhoneInput() {
    _phoneController.clear();
    _phoneFocus.requestFocus();
    setState(() => _showError = false);
  }

  void _submitAuthAndSendOtp() {
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (_isSignUp && _nameController.text.trim().isEmpty) {
      setState(() {
        _showError = true;
        _errorMessage = 'Silakan masukkan nama lengkap Anda.';
      });
      return;
    }

    if (rawPhone.length < 8) {
      setState(() {
        _showError = true;
        _errorMessage = 'Masukkan minimal 9 digit nomor WhatsApp yang aktif.';
      });
      return;
    }

    if (_isSignUp && !_agreeTerms) {
      setState(() {
        _showError = true;
        _errorMessage = 'Harap setujui syarat & ketentuan layanan WISGO.';
      });
      return;
    }

    final formattedPhone = '+62 ${_phoneController.text.trim()}';
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => OtpVerificationScreen(
          phoneNumber: formattedPhone,
          userName: _isSignUp ? _nameController.text.trim() : null,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _handleGoogleSignIn() {
    if (_isGoogleLoading) return;
    _showGoogleAccountPickerSheet();
  }

  void _showGoogleAccountPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Google Brand Header
                Row(
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isSignUp
                            ? 'Daftar ke WISGO dengan Google'
                            : 'Pilih akun untuk melanjutkan ke WISGO',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 6),

                // Akun Google 1: Akun Pengguna Utama
                _buildGoogleAccountTile(
                  name: 'Luthfia Hasan',
                  email: 'luthfia.hasan@gmail.com',
                  initialLetter: 'L',
                  avatarColor: const Color(0xFF1976D2),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _performGoogleSignInProcess(
                      userName: 'Luthfia Hasan',
                      userEmail: 'luthfia.hasan@gmail.com',
                    );
                  },
                ),

                // Akun Google 2: Akun Wisatawan
                _buildGoogleAccountTile(
                  name: 'WISGO Traveler',
                  email: 'wisgo.traveler@gmail.com',
                  initialLetter: 'W',
                  avatarColor: AppColors.forest,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _performGoogleSignInProcess(
                      userName: 'WISGO Traveler',
                      userEmail: 'wisgo.traveler@gmail.com',
                    );
                  },
                ),

                // Opsi Gunakan Akun Lain
                InkWell(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _performGoogleSignInProcess(
                      userName: 'Penjelajah Minang',
                      userEmail: 'explorer.minang@gmail.com',
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF3F4F6),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 20,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Gunakan akun lain',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),

                // Catatan Kebijakan Privasi Akun Google
                Text(
                  'Untuk melanjutkan, Google akan membagikan nama, alamat email, dan foto profil Anda dengan WISGO. Sebelum menggunakan aplikasi, tinjau Kebijakan Privasi dan Ketentuan Layanan WISGO.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoogleAccountTile({
    required String name,
    required String email,
    required String initialLetter,
    required Color avatarColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initialLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _performGoogleSignInProcess({
    required String userName,
    required String userEmail,
  }) {
    setState(() => _isGoogleLoading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Masuk sebagai $userName ($userEmail)...',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );

    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SavedPlacesScreen(),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Photographic Scenic Background (Minangkabau Landscape HD)
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

          // 3. Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Kembali (Pill Glassmorphic Seragam)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LocationOnboardingScreen(),
                          ),
                        );
                      },
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

                    // Tombol Lewati / Tamu
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const SavedPlacesScreen(),
                          ),
                          (route) => false,
                        );
                      },
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
                        child: const Text(
                          'Lewati',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Kartu Glassmorphic Utama (Sesuai Referensi Gambar 3)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 60, 22, 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
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
                          // Identitas Logo WISGO Kompak
                          const Center(
                            child: WisgoLogo(
                              width: 105,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Judul & Subjudul (FONT SAMA PERSIS DENGAN SPLASHSCREEN)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: Column(
                              key: ValueKey<bool>(_isSignUp),
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUp ? 'Daftar Akun Baru' : 'Masuk ke Akun WISGO',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.forest,
                                    letterSpacing: -0.4,
                                    height: 1.20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSignUp
                                      ? 'Lengkapi data untuk mulai eksplorasi wisata Ranah Minang.'
                                      : 'Selamat datang kembali, nikmati perjalanan nyaman di Sumatera Barat.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.muted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Input Nama Lengkap (Khusus Mode Sign Up)
                          if (_isSignUp) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _nameFocus.hasFocus
                                      ? AppColors.forest
                                      : AppColors.sageBorder,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.forest,
                                    size: 21,
                                  ),
                                  hintText: 'Nama Lengkap Anda',
                                  hintStyle: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Input Nomor WhatsApp Aktif (Sign In & Sign Up)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _phoneFocus.hasFocus
                                    ? AppColors.forest
                                    : AppColors.sageBorder,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.sage,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      bottomLeft: Radius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 16,
                                        color: AppColors.forest,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '+62',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                    ],
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
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                    ),
                                    onFieldSubmitted: (_) =>
                                        _submitAuthAndSendOtp(),
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

                          // Baris Opsi Tambahan (Isi Contoh & Remember Me / Checkbox)
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_isSignUp) {
                                      _agreeTerms = !_agreeTerms;
                                    } else {
                                      _rememberMe = !_rememberMe;
                                    }
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (_isSignUp ? _agreeTerms : _rememberMe)
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 18,
                                      color: (_isSignUp ? _agreeTerms : _rememberMe)
                                          ? AppColors.forest
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isSignUp ? 'Setujui syarat & ketentuan' : 'Ingat saya',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ],
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

                          if (_showError) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coralTint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.terracotta,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          // 5. Tombol Aksi Utama (HIJAU RESMI WISGO, BENTUK PILL SAMA PERSIS)
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
                                  onPressed: _submitAuthAndSendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.forest,
                                    foregroundColor: AppColors.cream,
                                    elevation: 3,
                                    shadowColor:
                                        Colors.black.withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.20),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _isSignUp
                                        ? 'Daftar & Kirim Kode OTP'
                                        : 'Kirim Kode OTP 4 Digit',
                                    style: const TextStyle(
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

                          const SizedBox(height: 18),

                          // Pembatas Atau
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.sageBorder.withValues(alpha: 0.8),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'atau',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.sageBorder.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Tombol Masuk / Daftar dengan Google (Pill Seragam & Modern)
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _isGoogleButtonPressed = true),
                            onTapUp: (_) =>
                                setState(() => _isGoogleButtonPressed = false),
                            onTapCancel: () =>
                                setState(() => _isGoogleButtonPressed = false),
                            child: AnimatedScale(
                              scale: _isGoogleButtonPressed ? 0.96 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeInOut,
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.95),
                                    foregroundColor: AppColors.forest,
                                    elevation: 1,
                                    shadowColor:
                                        Colors.black.withValues(alpha: 0.06),
                                    side: BorderSide(
                                      color: AppColors.sageBorder
                                          .withValues(alpha: 0.9),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: _isGoogleLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.forest,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/google_logo.png',
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _isSignUp
                                                  ? 'Daftar dengan Google'
                                                  : 'Lanjutkan dengan Google',
                                              style: const TextStyle(
                                                fontSize: 15,
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

                          const SizedBox(height: 18),

                          // 6. Pengalih Sign In <-> Sign Up (Sesuai Referensi Gambar 3)
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  _showError = false;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted,
                                      fontFamily: 'Inter',
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _isSignUp
                                            ? 'Sudah punya akun? '
                                            : 'Belum punya akun? ',
                                      ),
                                      TextSpan(
                                        text: _isSignUp
                                            ? 'Masuk Sekarang'
                                            : 'Daftar Baru',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.forest,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 7. Opsi Jelajah sebagai Tamu
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const SavedPlacesScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text(
                                'Jelajah Langsung sebagai Tamu',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 8. Info Keamanan WhatsApp Resmi
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.sageBorder.withValues(alpha: 0.8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 16,
                                  color: AppColors.forest,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Kode verifikasi 4 digit dikirimkan langsung melalui WhatsApp resmi WISGO.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.forest,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
