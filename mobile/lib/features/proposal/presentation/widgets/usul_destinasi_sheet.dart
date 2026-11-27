import 'package:flutter/material.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_facility_icon.dart';
import '../../../fair_price/data/models/fair_price_tariff_model.dart';

class _SubmittedLocationRecord {
  final String normalizedName;
  final String displayName;
  final String proposer;
  final String gpsKey;

  const _SubmittedLocationRecord({
    required this.normalizedName,
    required this.displayName,
    required this.proposer,
    required this.gpsKey,
  });
}

/// Formulir Usulan Destinasi Wisata Baru (Hidden Gem)
/// - Aturan 1 Lokasi = 1 Pengusul (anti-duplikasi nama / titik GPS)
/// - Atribusi penyedia resmi: Provided by WISGO
class UsulDestinasiSheet extends StatefulWidget {
  final Function(String name)? onSubmitSuccess;

  const UsulDestinasiSheet({super.key, this.onSubmitSuccess});

  /// Registry lokal lokasi yang sudah pernah diajukan (1 lokasi hanya boleh disubmit 1 orang)
  static final List<_SubmittedLocationRecord> _submittedLocations = [];

  static void clearSubmittedRegistryForTest() => _submittedLocations.clear();

  @override
  State<UsulDestinasiSheet> createState() => _UsulDestinasiSheetState();
}

class _UsulDestinasiSheetState extends State<UsulDestinasiSheet> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  late final TextEditingController _proposerController;
  final TextEditingController _ownerWhatsAppController =
      TextEditingController(text: '+62 812-7578-953');
  final TextEditingController _gpsController =
      TextEditingController(text: '-0.098412, 100.672195');
  final TextEditingController _feeInfoController = TextEditingController(
    text: 'Karcis Masuk: Rp 5.000 / orang, Parkir Motor: Rp 2.000, Mobil: Rp 5.000',
  );

  String? _duplicateError;

  @override
  void initState() {
    super.initState();
    final loggedName = ApiConfig.currentUser?.fullName.trim();
    _proposerController = TextEditingController(
      text: (loggedName != null && loggedName.isNotEmpty)
          ? loggedName
          : 'Wisatawan WISGO',
    );
  }

  String _selectedRegion = 'Kab. Lima Puluh Kota';
  String _selectedCategory = 'Air Terjun';
  bool _photo360Attached = false;

  final List<String> _regions = [
    'Kab. Lima Puluh Kota',
    'Kota Bukittinggi',
    'Kota Padang',
    'Kab. Tanah Datar',
    'Kab. Agam',
    'Kab. Pesisir Selatan',
    'Kab. Padang Pariaman',
    'Kab. Solok',
    'Kota Sawahlunto',
    'Kab. Pasaman Barat',
    'Kab. Kepulauan Mentawai',
  ];

  final List<String> _categories = [
    'Air Terjun',
    'Gunung / Bukit',
    'Sungai / Danau',
    'Pantai / Pulau',
    'Hutan / Goa',
  ];

  final Set<String> _selectedFacilities = {
    'Area Parkir',
    'Toilet Bersih',
    'Musholla',
    'Warung Kuliner',
  };

  final List<Map<String, dynamic>> _facilityOptions = [
    {'name': 'Area Parkir', 'icon': Icons.local_parking_rounded},
    {'name': 'Toilet Bersih', 'icon': Icons.wc_rounded},
    {'name': 'Musholla', 'icon': Icons.mosque_rounded},
    {'name': 'Warung Kuliner', 'icon': Icons.restaurant_rounded},
    {'name': 'Gazebo / Pondok', 'icon': Icons.deck_rounded},
    {'name': 'Jalur Trekking', 'icon': Icons.hiking_rounded},
    {'name': 'Pemandu Lokal', 'icon': Icons.support_agent_rounded},
    {'name': 'Spot Foto Alami', 'icon': Icons.camera_alt_rounded},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _proposerController.dispose();
    _ownerWhatsAppController.dispose();
    _gpsController.dispose();
    _feeInfoController.dispose();
    super.dispose();
  }

  void _detectCurrentGpsLocation() {
    setState(() {
      _gpsController.text = '-0.098412, 100.672195';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Titik GPS berhasil terdeteksi otomatis!',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _fillSampleNarrative() {
    setState(() {
      _descController.text =
          'Sarasah Murai merupakan air terjun bertingkat tujuh yang tersembunyi di kawasan hutan adat Harau. Dahulu riam airnya menjadi tempat berkumpul dan bersarangnya burung murai batu endemik Minangkabau. Airnya yang jernih bersumber dari pegunungan Bukit Barisan, menghadirkan kesegaran alami serta kearifan falsafah "Alam Takambang Jadi Guru".';
    });
  }

  String _normalizeLocationName(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeGpsKey(String input) {
    final parts = input.split(',');
    if (parts.length != 2) return input.trim();
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return input.trim();
    // Bulatkan ke 3 desimal (~110m radius) untuk deteksi duplikat titik lokasi yang sama
    return '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
  }

  String? _checkDuplicateLocation(String rawName, String rawGps) {
    final normName = _normalizeLocationName(rawName);
    final gpsKey = _normalizeGpsKey(rawGps);

    // 1. Cek terhadap katalog destinasi resmi WISGO
    for (final existing in kAllSumbarDestinations) {
      final catalogName = _normalizeLocationName(existing.title);
      if (catalogName == normName ||
          (normName.length >= 6 &&
              (catalogName.contains(normName) || normName.contains(catalogName)))) {
        return 'Lokasi "${existing.title}" sudah terdaftar resmi (Provided by WISGO). Satu lokasi hanya dapat diajukan 1 kali.';
      }
    }

    // 2. Cek terhadap usulan yang sudah pernah disubmit pengguna sebelumnya
    for (final submitted in UsulDestinasiSheet._submittedLocations) {
      if (submitted.normalizedName == normName ||
          (gpsKey.isNotEmpty && submitted.gpsKey == gpsKey)) {
        return 'Lokasi "${submitted.displayName}" sudah disubmit oleh ${submitted.proposer} (Provided by WISGO). Satu lokasi hanya dapat disubmit oleh 1 orang.';
      }
    }
    return null;
  }

  void _handleSubmitProposal() {
    final rawName = _nameController.text.trim();
    final name = rawName.isNotEmpty ? rawName : 'Sarasah Murai Indah';
    final gpsRaw = _gpsController.text.trim();
    final proposer = _proposerController.text.trim().isNotEmpty
        ? _proposerController.text.trim()
        : 'Wisatawan WISGO';

    final duplicateMessage = _checkDuplicateLocation(name, gpsRaw);
    if (duplicateMessage != null) {
      setState(() => _duplicateError = duplicateMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicateMessage,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.terracotta,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    UsulDestinasiSheet._submittedLocations.add(
      _SubmittedLocationRecord(
        normalizedName: _normalizeLocationName(name),
        displayName: name,
        proposer: proposer,
        gpsKey: _normalizeGpsKey(gpsRaw),
      ),
    );

    Navigator.pop(context);
    if (widget.onSubmitSuccess != null) {
      widget.onSubmitSuccess!('$name (Provided by WISGO)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Handle Bar
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Top Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(bottom: BorderSide(color: AppColors.warmBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.ink),
                        SizedBox(width: 4),
                        Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Flexible(
                  child: Text(
                    'USUL DESTINASI WISATA BARU',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                // Info Badge: Aturan 1 Lokasi = 1 Pengusul + Provided by WISGO
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.forest, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Provided by WISGO • 1 Lokasi = 1 Pengusul',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.forest,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Setiap titik wisata hanya dapat disubmit oleh 1 orang dan diverifikasi resmi oleh tim WISGO & Dinas Pariwisata Sumbar.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.ink,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_duplicateError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _duplicateError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sageBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Nama Tempat
                      _buildFieldHeader('Nama Tempat Wisata', Icons.place_rounded),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration('Contoh: Sarasah Murai Tingkat 7'),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),

                      // 2. Deskripsi & Cerita Sejarah
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildFieldHeader(
                              'Deskripsi & Cerita Sejarah',
                              Icons.menu_book_rounded,
                            ),
                          ),
                          GestureDetector(
                            onTap: _fillSampleNarrative,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Isi Contoh Narasi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Tuliskan keunikan alam, legenda rakyat, atau sejarah nagari untuk panduan wisatawan.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        minLines: 3,
                        decoration: _inputDecoration(
                          'Ceritakan daya tarik alam dan kearifan lokal tempat ini...',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // 3. Wilayah Kabupaten / Kota
                      _buildFieldHeader('Wilayah Kabupaten / Kota', Icons.map_rounded),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRegion,
                        decoration: _inputDecoration('Pilih Wilayah'),
                        items: _regions.map((reg) {
                          return DropdownMenuItem(
                            value: reg,
                            child: Text(
                              reg,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRegion = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. Nama Pengusul
                      _buildFieldHeader('Nama Pengusul', Icons.person_rounded),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _proposerController,
                        decoration: _inputDecoration('Nama Lengkap Pengusul / Komunitas'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),

                      // 5. Nomor WhatsApp Pengelola
                      _buildFieldHeader(
                        'Nomor WhatsApp Pengelola / Pokdarwis',
                        Icons.chat_bubble_outline_rounded,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Nomor pengelola resmi yang dapat dihubungi pengunjung untuk reservasi langsung.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _ownerWhatsAppController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Contoh: +62 812-7578-953'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),

                      // 6. Titik Koordinat GPS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildFieldHeader(
                              'Titik Koordinat GPS',
                              Icons.my_location_rounded,
                            ),
                          ),
                          GestureDetector(
                            onTap: _detectCurrentGpsLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successBorder,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gps_fixed_rounded, size: 11, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'Deteksi GPS Saat Ini',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Format Latitude, Longitude untuk akurasi peta.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _gpsController,
                        decoration: _inputDecoration('Contoh: -0.098412, 100.672195'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 7. Foto Panorama 360°
                      _buildFieldHeader(
                        'Foto Panorama 360° (Tur Virtual)',
                        Icons.threesixty_rounded,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Unggah foto panorama alam untuk pengalaman tur interaktif wisatawan.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _photo360Attached = !_photo360Attached);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: _photo360Attached ? AppColors.successBorder : AppColors.cream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _photo360Attached
                                  ? AppColors.success
                                  : AppColors.sageBorder,
                              width: _photo360Attached ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _photo360Attached
                                    ? Icons.check_circle_rounded
                                    : Icons.add_photo_alternate_rounded,
                                color: _photo360Attached
                                    ? AppColors.success
                                    : AppColors.forest,
                                size: 30,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _photo360Attached
                                    ? 'Foto Panorama 360° Terpilih (Sarasah_Murai.jpg)'
                                    : 'Ketuk untuk Unggah Foto Panorama 360°',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _photo360Attached
                                      ? AppColors.success
                                      : AppColors.forest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _photo360Attached
                                    ? 'Format Equirectangular 2:1 siap untuk render virtual'
                                    : 'Mendukung format JPG/PNG resolusi tinggi (rasio 2:1)',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 8. Kategori Wisata (Pil Frosted-Glass Lembut + Ikon 3D)
                      _buildFieldHeader('Kategori Wisata Alam', Icons.category_rounded),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _selectedCategory = cat),
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.sage.withValues(alpha: 0.9)
                                      : AppColors.cream,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.brush.withValues(alpha: 0.55)
                                        : AppColors.warmBorder,
                                    width: isSelected ? 1.2 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      resolveNatureCategoryAsset(cat),
                                      width: 18,
                                      height: 18,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.terrain_rounded,
                                        size: 14,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.forest
                                            : AppColors.ink,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppColors.brush,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // 9. Fasilitas yang Tersedia di Lokasi (8 Ikon 3D Clay + Pil Lembut Tanpa Tumpang Tindih)
                      _buildFieldHeader(
                        'Fasilitas yang Tersedia di Lokasi',
                        Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _facilityOptions.map((fac) {
                          final String facName = fac['name'] as String;
                          final IconData facIcon = fac['icon'] as IconData;
                          final bool isChecked = _selectedFacilities.contains(facName);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isChecked) {
                                    _selectedFacilities.remove(facName);
                                  } else {
                                    _selectedFacilities.add(facName);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? AppColors.sage.withValues(alpha: 0.9)
                                      : AppColors.cream,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isChecked
                                        ? AppColors.brush.withValues(alpha: 0.55)
                                        : AppColors.warmBorder,
                                    width: isChecked ? 1.2 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WisgoFacilityIcon(
                                      facilityName: facName,
                                      size: 19,
                                      fallbackIcon: facIcon,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      facName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isChecked
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isChecked
                                            ? AppColors.forest
                                            : AppColors.ink,
                                      ),
                                    ),
                                    if (isChecked) ...[
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppColors.brush,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      _buildFieldHeader(
                        'Informasi Tarif / Retribusi Tiket',
                        Icons.receipt_long_rounded,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Data tarif digunakan sebagai panduan transparansi harga bagi pengunjung.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _feeInfoController,
                        maxLines: 2,
                        minLines: 1,
                        decoration: _inputDecoration(
                          'Contoh: Karcis Rp 5.000 / orang, Parkir Motor Rp 2.000',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Atribusi Resmi Provider
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.forest),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Atribusi Pengelolaan Resmi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      Text(
                        'Provided by WISGO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tombol Kirim Usulan
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _handleSubmitProposal,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text(
                      'Kirimkan Usulan Destinasi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.cream,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    'Destinasi baru akan resmi dipublikasikan dengan label Provided by WISGO setelah divalidasi.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.forest),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.warmBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.warmBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
