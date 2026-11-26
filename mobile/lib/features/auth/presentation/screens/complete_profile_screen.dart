import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_logo.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';
import '../../services/auth_session.dart';

/// Layar Lengkapi Profil Awal setelah OTP berhasil (Opsi 2 — Seimbang & Relevan WISGO)
/// Field: Nama Lengkap (wajib), Kota Asal/Domisili, Email (opsional), & Kontak Darurat (opsional).
/// Pengguna juga dapat memilih "Lewati dulu" dan melengkapinya sendiri di Tab Profil.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _originController = TextEditingController(
    text: 'Padang, Sumatera Barat',
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();

  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _emailController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Nama lengkap wajib diisi agar tampil di Profil & Trip Go.');
      return;
    }

    AuthSession.instance.updateProfile(
      name: name,
      phone: widget.phoneNumber,
      origin: _originController.text.trim().isEmpty
          ? 'Padang, Sumatera Barat'
          : _originController.text.trim(),
      email: _emailController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      isProfileComplete: true,
    );

    _goToHome();
  }

  void _skipForNow() {
    _goToHome();
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SavedPlacesScreen(isGuest: false),
      ),
      (route) => false,
    );
  }

  void _showInfoDialog({
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.forest,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mengerti',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar dengan tombol Lewati
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const WisgoLogo(width: 72),
                  TextButton(
                    onPressed: _skipForNow,
                    child: const Text(
                      'Lewati dulu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Header Ringkas + Tombol Info (Progressive Disclosure)
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LANGKAH TERAKHIR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.brush,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Lengkapi Profil',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showInfoDialog(
                      title: 'Kenapa Lengkapi Profil?',
                      body:
                          '• Nama & Kota Asal dipakai untuk koordinasi Trip Go dan ulasan destinasi.\n'
                          '• Email dipakai untuk menerima e-tiket & bukti transaksi.\n'
                          '• Kontak Darurat terhubung ke fitur Darurat SOS.\n\n'
                          'Kamu bisa mengubah semua data ini kapan saja di Tab Profil.',
                    ),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.forest,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    tooltip: 'Info kegunaan data profil',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Badge Nomor WhatsApp Terverifikasi (Ringkas 1 Baris)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.phoneNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const Text(
                      'WA Terverifikasi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Form Card (Ringkas & Muat 1 Layar)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nama Lengkap *'),
                    const SizedBox(height: 5),
                    _buildInput(
                      controller: _nameController,
                      hint: 'Contoh: Latifa Keysha',
                      icon: Icons.person_outline_rounded,
                      onChanged: (_) {
                        if (_errorText != null) setState(() => _errorText = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Kota Asal'),
                    const SizedBox(height: 5),
                    _buildInput(
                      controller: _originController,
                      hint: 'Padang, Sumatera Barat',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Email'),
                        const Text(
                          'Opsional',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _buildInput(
                      controller: _emailController,
                      hint: 'nama@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    const Divider(color: AppColors.warmBorder, height: 1),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_outlined,
                          size: 16,
                          color: AppColors.terracotta,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Kontak Darurat',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const Text(
                          'Opsional',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showInfoDialog(
                            title: 'Kontak Darurat SOS',
                            body:
                                'Nomor keluarga atau kerabat terdekat yang akan menjadi tujuan pesan koordinat GPS saat Anda menggunakan fitur Darurat SOS di lokasi blank spot.',
                          ),
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Info Kontak Darurat',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildInput(
                      controller: _emergencyNameController,
                      hint: 'Nama keluarga / kerabat',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _emergencyPhoneController,
                      hint: 'No. HP kontak darurat',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.coralTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracotta,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Simpan & Mulai Jelajah',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.forest),
        filled: true,
        fillColor: AppColors.cream.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sageBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sageBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
        ),
      ),
    );
  }
}
