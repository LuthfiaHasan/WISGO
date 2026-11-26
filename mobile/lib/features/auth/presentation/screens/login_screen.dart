import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_logo.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';
import '../../services/auth_session.dart';
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
  final TextEditingController _phoneController =
      TextEditingController(text: '812-7578-953');
  final FocusNode _phoneFocus = FocusNode();

  bool _rememberMe = true;
  bool _showError = false;
  String _errorMessage = '';
  bool _isButtonPressed = false;
  bool _isGoogleLoading = false;
  bool _isGoogleButtonPressed = false;
  bool _isAppleLoading = false;
  bool _isAppleButtonPressed = false;

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

  void _submitAuthAndSendOtp() {
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (rawPhone.length < 8) {
      setState(() {
        _showError = true;
        _errorMessage = 'Masukkan minimal 9 digit nomor WhatsApp yang aktif.';
      });
      return;
    }

    final formattedPhone = '+62 ${_phoneController.text.trim()}';
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => OtpVerificationScreen(
          phoneNumber: formattedPhone,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _handleGoogleSignIn() {
    if (_isGoogleLoading || _isAppleLoading) return;
    _showGoogleAccountPickerSheet();
  }

  void _handleAppleSignIn() {
    if (_isAppleLoading || _isGoogleLoading) return;
    _showAppleAccountPickerSheet();
  }

  void _showAppleAccountPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masuk dengan Apple ID',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Lanjutkan ke WISGO secara aman & privat',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.warmBorder),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Column(
                    children: [
                      _buildGoogleAccountTile(
                        name: 'Bagikan Email Apple ID',
                        email: 'wisatawan.sumbar@icloud.com',
                        initialLetter: 'A',
                        avatarColor: AppColors.ink,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _performAppleSignInProcess(
                            userName: 'Penjelajah Apple',
                            userEmail: 'wisatawan.sumbar@icloud.com',
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 64, color: AppColors.warmBorder),
                      _buildGoogleAccountTile(
                        name: 'Sembunyikan Email Saya',
                        email: 'private.relay@privaterelay.appleid.com',
                        initialLetter: 'P',
                        avatarColor: AppColors.forest,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _performAppleSignInProcess(
                            userName: 'Wisatawan WISGO',
                            userEmail: 'private.relay@privaterelay.appleid.com',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Apple ID melindungi privasi Anda dan memungkinkan Anda masuk ke WISGO tanpa membagikan kata sandi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
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

  void _performAppleSignInProcess({
    required String userName,
    required String userEmail,
  }) {
    setState(() => _isAppleLoading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
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
                'Masuk dengan Apple ID ($userName)…',
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
      setState(() => _isAppleLoading = false);
      AuthSession.instance.setAuthenticatedUser(
        name: userName,
        phone: '+62 812-7578-953',
        email: userEmail,
        isProfileComplete: true,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SavedPlacesScreen(isGuest: false),
        ),
        (route) => false,
      );
    });
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
                    const Expanded(
                      child: Text(
                        'Pilih akun untuk melanjutkan ke WISGO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
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
                    fontSize: 12,
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
                    fontWeight: FontWeight.w700,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
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
                'Masuk sebagai $userName ($userEmail)…',
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
      AuthSession.instance.setAuthenticatedUser(
        name: userName,
        phone: '+62 812-7578-953',
        email: userEmail,
        isProfileComplete: true,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SavedPlacesScreen(isGuest: false),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Lanskap Rumah Gadang & Gunung Marapi Full-Screen (sudah direstorasi mulus)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg_1.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // 2. Gradiasi Ivory Ambient Halus
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.cream.withValues(alpha: 0.22),
                    AppColors.cream.withValues(alpha: 0.42),
                    AppColors.cream.withValues(alpha: 0.62),
                  ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top Navigation Bar (Hanya tombol Kembali -> selalu kembali ke Beranda, tanpa tombol Lewati)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => SavedPlacesScreen(
                                  isGuest: AuthSession.instance.isGuest,
                                ),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
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
                                color: AppColors.ink.withValues(alpha: 0.08),
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
                                  fontSize: 13,
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
                  ],
                ),
              ),
            ),
          ),

          // 4. Kartu Glassmorphic Utama (Lebih Ringkas & Proporsional tanpa judul "Masuk ke Akun WISGO")
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(22, 56, 22, 24 + bottomInset),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
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
                            color: AppColors.ink.withValues(alpha: 0.06),
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
                              width: 96,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subjudul ringkas (tanpa judul besar agar card lebih pendek & elegan)
                          const Text(
                            'Masuk dengan nomor WhatsApp untuk mulai eksplorasi Sumatera Barat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Input Nomor WhatsApp Aktif
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
                                  color: AppColors.ink.withValues(alpha: 0.03),
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
                                          fontWeight: FontWeight.w700,
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Baris Opsi Tambahan (Isi Contoh & Ingat Saya)
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() => _rememberMe = !_rememberMe);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _rememberMe
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 18,
                                        color: _rememberMe
                                            ? AppColors.forest
                                            : AppColors.muted,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Ingat saya',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _fillDemoPhone,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Isi Nomor Contoh',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brush,
                                      decoration: TextDecoration.underline,
                                    ),
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
                                        AppColors.ink.withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.20),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Kirim Kode OTP 4 Digit',
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
                                    fontSize: 13,
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
                                        AppColors.ink.withValues(alpha: 0.06),
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
                                            const Text(
                                              'Lanjutkan dengan Google',
                                              style: TextStyle(
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

                          const SizedBox(height: 10),

                          // Tombol Masuk dengan Apple (Wajib Setara dengan Login Google)
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _isAppleButtonPressed = true),
                            onTapUp: (_) =>
                                setState(() => _isAppleButtonPressed = false),
                            onTapCancel: () =>
                                setState(() => _isAppleButtonPressed = false),
                            child: AnimatedScale(
                              scale: _isAppleButtonPressed ? 0.96 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeInOut,
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _handleAppleSignIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ink,
                                    foregroundColor: Colors.white,
                                    elevation: 1,
                                    shadowColor:
                                        AppColors.ink.withValues(alpha: 0.16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: _isAppleLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.apple,
                                              size: 22,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Lanjutkan dengan Apple',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 6. Opsi Jelajah sebagai Tamu
                          Center(
                            child: TextButton(
                              onPressed: () {
                                AuthSession.instance.setGuestMode();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const SavedPlacesScreen(isGuest: true),
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
                                  fontSize: 13,
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
                                      fontSize: 12,
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
