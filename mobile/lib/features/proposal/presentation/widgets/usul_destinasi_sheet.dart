import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Formulir Usulan Destinasi Wisata Baru (Hidden Gem)
/// Desain bersih & rapi sesuai standar UI/UX WisGo
class UsulDestinasiSheet extends StatefulWidget {
  final Function(String name)? onSubmitSuccess;

  const UsulDestinasiSheet({super.key, this.onSubmitSuccess});

  @override
  State<UsulDestinasiSheet> createState() => _UsulDestinasiSheetState();
}

class _UsulDestinasiSheetState extends State<UsulDestinasiSheet> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _proposerController =
      TextEditingController(text: 'Ahmad Fauzi (Wisatawan)');
  final TextEditingController _ownerWhatsAppController =
      TextEditingController(text: '+62 812-7578-953');
  final TextEditingController _gpsController =
      TextEditingController(text: '-0.098412, 100.672195');
  final TextEditingController _feeInfoController = TextEditingController(
    text: 'Karcis Masuk: Rp 5.000 / orang, Parkir Motor: Rp 2.000, Mobil: Rp 5.000',
  );

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
                // Info Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.warningDark, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Usulan destinasi hidden gem akan diverifikasi oleh Dinas Pariwisata Sumbar sebelum resmi tampil di katalog umum.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warningDark,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

                      // 8. Kategori Wisata
                      _buildFieldHeader('Kategori Wisata Alam', Icons.category_rounded),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.forest,
                            backgroundColor: AppColors.cream,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.forest : AppColors.sageBorder,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCategory = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // 9. Fasilitas & Informasi Tiket
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

                          return FilterChip(
                            avatar: Icon(
                              facIcon,
                              size: 14,
                              color: isChecked ? Colors.white : AppColors.forest,
                            ),
                            label: Text(
                              facName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isChecked ? Colors.white : AppColors.ink,
                              ),
                            ),
                            selected: isChecked,
                            selectedColor: AppColors.forest,
                            backgroundColor: AppColors.cream,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: isChecked ? AppColors.forest : AppColors.sageBorder,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFacilities.add(facName);
                                } else {
                                  _selectedFacilities.remove(facName);
                                }
                              });
                            },
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

                // Tombol Kirim Usulan
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final name = _nameController.text.trim().isNotEmpty
                          ? _nameController.text.trim()
                          : 'Sarasah Murai Indah';
                      Navigator.pop(context);
                      if (widget.onSubmitSuccess != null) {
                        widget.onSubmitSuccess!(name);
                      }
                    },
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
                    'Destinasi baru akan resmi dipublikasikan setelah divalidasi oleh Tim Dispar.',
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
