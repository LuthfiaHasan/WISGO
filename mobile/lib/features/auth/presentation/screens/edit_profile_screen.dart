import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/auth_session.dart';

/// Halaman Penuh Ganti Profil Wisatawan WISGO
/// Tata letak minimalis & lega: avatar 3D di tengah, tautan ganti foto,
/// input underline bersih, pill bendera +62 dengan lencana Terverifikasi
/// pada Nomor HP, Email opsional, chip kategori pil frosted-glass, serta
/// tombol Simpan pil yang halus.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialName,
    this.initialPhone,
    this.initialOrigin,
    this.initialRole,
  });

  final String? initialName;
  final String? initialPhone;
  final String? initialOrigin;
  final String? initialRole;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneDigitsCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _originCtrl;
  late final TextEditingController _emergencyNameCtrl;
  late final TextEditingController _emergencyPhoneCtrl;

  late String _selectedAvatarMode;
  late String _selectedRole;
  bool _showExtraDetails = false;

  static const List<String> _roles = [
    'Wisatawan Nusantara',
    'Wisatawan Lokal Sumbar',
    'International Traveler',
  ];

  @override
  void initState() {
    super.initState();
    final session = AuthSession.instance;

    final rawName = ApiConfig.currentUser?.fullName.isNotEmpty == true
        ? ApiConfig.currentUser!.fullName
        : (widget.initialName?.trim().isNotEmpty == true
            ? widget.initialName!.trim()
            : session.userName);

    final rawPhone = ApiConfig.currentUser?.phoneNumber.isNotEmpty == true
        ? ApiConfig.currentUser!.phoneNumber
        : (widget.initialPhone?.trim().isNotEmpty == true
            ? widget.initialPhone!.trim()
            : session.userPhone);

    _nameCtrl = TextEditingController(text: rawName);
    _phoneDigitsCtrl = TextEditingController(
      text: _extractLocalIndonesianDigits(rawPhone),
    );
    _emailCtrl = TextEditingController(text: session.userEmail);
    _originCtrl = TextEditingController(
      text: widget.initialOrigin?.trim().isNotEmpty == true
          ? widget.initialOrigin!.trim()
          : session.userOrigin,
    );
    _emergencyNameCtrl = TextEditingController(
      text: session.emergencyContactName,
    );
    _emergencyPhoneCtrl = TextEditingController(
      text: session.emergencyContactPhone,
    );
    _selectedAvatarMode = session.avatarMode;
    final candidateRole = widget.initialRole?.trim().isNotEmpty == true
        ? widget.initialRole!.trim()
        : session.userRole;
    _selectedRole = _roles.contains(candidateRole) ? candidateRole : _roles.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneDigitsCtrl.dispose();
    _emailCtrl.dispose();
    _originCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  /// Mengambil angka lokal Indonesia tanpa prefiks `+62`, `62`, atau `0`.
  String _extractLocalIndonesianDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('62')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  String _formatSavedPhone(String localDigits) {
    final clean = localDigits.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '+62 812-7578-953';
    if (clean.length <= 3) return '+62 $clean';
    if (clean.length <= 7) {
      return '+62 ${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return '+62 ${clean.substring(0, 3)}-${clean.substring(3, 7)}-${clean.substring(7)}';
  }

  String get _previewInitials {
    final text = _nameCtrl.text.trim();
    if (text.isEmpty) return 'WS';
    final parts = text
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _phoneDigitsCtrl.text.trim().length >= 8;

  void _saveProfile() {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.tr(
              'Nama dan Nomor HP (minimal 8 digit) wajib diisi.',
              'Name and phone number (min. 8 digits) are required.',
            ),
          ),
          backgroundColor: AppColors.terracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nextName = _nameCtrl.text.trim();
    final nextPhone = _formatSavedPhone(_phoneDigitsCtrl.text.trim());
    final nextOrigin = _originCtrl.text.trim().isEmpty
        ? 'Padang, Sumatera Barat'
        : _originCtrl.text.trim();

    AuthSession.instance.updateProfile(
      name: nextName,
      phone: nextPhone,
      email: _emailCtrl.text.trim(),
      origin: nextOrigin,
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      role: _selectedRole,
      avatarMode: _selectedAvatarMode,
      isProfileComplete: true,
    );

    Navigator.pop(context, true);
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.brush,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocale.tr('Bantuan Profil', 'Profile Help'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocale.tr(
              'Nomor HP diverifikasi melalui OTP WhatsApp sebagai identitas utama akun WISGO dan keamanan SOS. Email bersifat opsional.',
              'Your phone number is verified via WhatsApp OTP for WISGO identity and SOS safety. Email is optional.',
            ),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocale.tr('Mengerti', 'Got it'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brush,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openAvatarPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        final options = <({String id, String label})>[
          (
            id: 'default_3d',
            label: AppLocale.tr('Avatar 3D Default', 'Default 3D Avatar'),
          ),
          (
            id: 'initials_forest',
            label: AppLocale.tr('Inisial Hijau Hutan', 'Forest Initials'),
          ),
          (
            id: 'initials_info',
            label: AppLocale.tr('Inisial Biru Samudra', 'Ocean Initials'),
          ),
          (
            id: 'initials_terracotta',
            label: AppLocale.tr('Inisial Terakota', 'Terracotta Initials'),
          ),
          (
            id: 'initials_gold',
            label: AppLocale.tr('Inisial Emas Minang', 'Minang Gold Initials'),
          ),
        ];

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocale.tr('Pilih Avatar Profil', 'Choose Profile Avatar'),
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map((opt) {
                  final active = _selectedAvatarMode == opt.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedAvatarMode = opt.id);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.sage.withValues(alpha: 0.72)
                              : Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: active
                                ? AppColors.brush.withValues(alpha: 0.45)
                                : AppColors.warmBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            WisgoProfileAvatar(
                              avatarMode: opt.id,
                              initials: _previewInitials,
                              size: 42,
                              borderRadius: 13,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt.label,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (active)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.brush,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _underlineDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.muted.withValues(alpha: 0.55),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.only(top: 6, bottom: 10),
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.warmBorder.withValues(alpha: 0.9),
          width: 1.1,
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.warmBorder.withValues(alpha: 0.9),
          width: 1.1,
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.brush, width: 1.6),
      ),
    );
  }

  Widget _buildFrostedRolePill(String role) {
    final active = _selectedRole == role;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedRole = role),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.sage.withValues(alpha: 0.80)
                    : Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? AppColors.brush.withValues(alpha: 0.48)
                      : AppColors.warmBorder.withValues(alpha: 0.85),
                  width: active ? 1.2 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (active) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? AppColors.forest : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: AppLocale.tr('Kembali', 'Back'),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
            size: 24,
          ),
        ),
        titleSpacing: 4,
        title: Text(
          AppLocale.tr('Ganti profil', 'Edit profile'),
          style: const TextStyle(
            fontSize: 19.5,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: _showHelpDialog,
              tooltip: AppLocale.tr('Bantuan', 'Help'),
              icon: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.sageBorder.withValues(alpha: 0.9),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.question_mark_rounded,
                  size: 15,
                  color: AppColors.forest,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Konten Form Bersih & Lega
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 108),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. AVATAR KOTAK MEMBULAT DI TENGAH + TAUTAN GANTI FOTO
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _openAvatarPickerSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forest.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: WisgoProfileAvatar(
                            avatarMode: _selectedAvatarMode,
                            initials: _previewInitials,
                            size: 86,
                            borderRadius: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _openAvatarPickerSheet,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            AppLocale.tr(
                              'Pasang/ganti foto profil',
                              'Add/change profile photo',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brush,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.brush,
                              decorationThickness: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 2. NAMA
                Text(
                  AppLocale.tr('Nama', 'Name'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                  decoration: _underlineDecoration(
                    hintText: AppLocale.tr(
                      'Masukkan nama lengkap',
                      'Enter your full name',
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // 3. NOMOR HP (PILL BENDERA +62 + INPUT + TERVERIFIKASI)
                Text(
                  AppLocale.tr('Nomor HP', 'Phone number'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Pill Bendera Merah Putih +62
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.warmBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2.5),
                              border: Border.all(
                                color: AppColors.warmBorder,
                                width: 0.6,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: const Column(
                              children: [
                                Expanded(
                                  child: ColoredBox(
                                    color: AppColors.danger,
                                    child: SizedBox.expand(),
                                  ),
                                ),
                                Expanded(
                                  child: ColoredBox(
                                    color: Colors.white,
                                    child: SizedBox.expand(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '+62',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneDigitsCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: 0.2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: _underlineDecoration(
                          hintText: '81234567890',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocale.tr('Terverifikasi', 'Verified'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brush,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 4. EMAIL (OPSIONAL — TANPA BADGE TERVERIFIKASI)
                Text(
                  AppLocale.tr('Email (Opsional)', 'Email (Optional)'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  decoration: _underlineDecoration(
                    hintText: AppLocale.tr(
                      'contoh@email.com',
                      'name@email.com',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocale.tr(
                    'Opsional — untuk bukti transaksi & keamanan akun.',
                    'Optional — for receipts & account security.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),

                const SizedBox(height: 26),

                // 5. DETAIL LAINNYA (RINGKAS, FROSTED-GLASS, BERSIH)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(
                          () => _showExtraDetails = !_showExtraDetails,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.warmBorder.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                size: 17,
                                color: AppColors.brush,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppLocale.tr(
                                    'Detail lainnya',
                                    'More details',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Icon(
                                _showExtraDetails
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.muted,
                                size: 21,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _showExtraDetails
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocale.tr('Kota Asal', 'Home City'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextField(
                          controller: _originCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          decoration: _underlineDecoration(
                            hintText: AppLocale.tr(
                              'Padang, Sumatera Barat',
                              'Padang, West Sumatra',
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          AppLocale.tr('Kategori Wisatawan', 'Traveler Type'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _roles.map(_buildFrostedRolePill).toList(),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          AppLocale.tr(
                            'Kontak Darurat SOS (Opsional)',
                            'Emergency SOS Contact (Optional)',
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextField(
                          controller: _emergencyNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          decoration: _underlineDecoration(
                            hintText: AppLocale.tr(
                              'Nama keluarga / kerabat',
                              'Family / relative name',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emergencyPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          decoration: _underlineDecoration(
                            hintText: AppLocale.tr(
                              'Nomor HP kontak darurat',
                              'Emergency contact phone',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6. TOMBOL SIMPAN PIL HALUS DI ATAS BAR FROSTED-GLASS
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.82),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.warmBorder.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: _canSave
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.brush,
                                    AppColors.forest,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: _canSave
                              ? null
                              : AppColors.muted.withValues(alpha: 0.35),
                          boxShadow: _canSave
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.forest.withValues(alpha: 0.22),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _saveProfile,
                            borderRadius: BorderRadius.circular(999),
                            child: Center(
                              child: Text(
                                AppLocale.tr('Simpan', 'Save'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cream,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
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

/// Widget Avatar Profil WISGO yang dipakai konsisten di halaman Ganti Profil
/// dan kartu profil utama. Menampilkan ikon 3D clay default (`avatar_default.png`)
/// saat pengguna belum memasang foto sendiri, atau inisial bergaya warna WISGO.
class WisgoProfileAvatar extends StatelessWidget {
  const WisgoProfileAvatar({
    super.key,
    required this.avatarMode,
    required this.initials,
    this.size = 56,
    this.borderRadius = 18,
  });

  final String avatarMode;
  final String initials;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (avatarMode == 'default_3d') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          color: AppColors.sage,
          child: Image.asset(
            AuthSession.defaultAvatarAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _buildFallback3DSilhouette(),
          ),
        ),
      );
    }

    final List<Color> gradientColors;
    switch (avatarMode) {
      case 'initials_info':
        gradientColors = const [AppColors.info, Color(0xFF154360)];
        break;
      case 'initials_terracotta':
        gradientColors = const [AppColors.terracotta, Color(0xFFC24A1C)];
        break;
      case 'initials_gold':
        gradientColors = const [AppColors.goldMinang, Color(0xFF9C6D27)];
        break;
      case 'initials_forest':
      default:
        gradientColors = const [AppColors.forest, Color(0xFF214D2E)];
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: AppColors.cream,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFallback3DSilhouette() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sage, Color(0xFFCDE1D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Icon(
        Icons.person_rounded,
        size: size * 0.72,
        color: AppColors.forest,
      ),
    );
  }
}
