import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Item 13: Formulir Usulan Destinasi Wisata Baru (Hidden Gem)
/// Berisi 8 komponen utama sesuai regulasi Dinas Pariwisata Sumbar:
/// 1. Nama Tempat
/// 2. Deskripsi & Narasi Sejarah (Voice Over AI Tur 360°)
/// 3. Wilayah (Kabupaten / Kota di Sumbar)
/// 4. Nama Pengusul (Wisatawan / Komunitas)
/// 5. Titik Koordinat GPS
/// 6. Foto Panorama Equirectangular 360°
/// 7. Kategori Wisata Alam
/// 8. Fasilitas & Informasi Tiket Masuk (Non-transaksi / Informasi saja)
///
/// Pasca submit: Status masuk ke "Menunggu Validasi Admin", baru akan tampil
/// di katalog aplikasi setelah diverifikasi oleh Admin Dispar.
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
  final TextEditingController _proposerController = TextEditingController(text: 'Ahmad Fauzi (Wisatawan)');
  final TextEditingController _gpsController = TextEditingController(text: '-0.098412, 100.672195');
  final TextEditingController _feeInfoController = TextEditingController(
    text: 'Karcis Masuk: Rp 5.000 / orang, Parkir Motor: Rp 2.000, Mobil: Rp 5.000 (Pokdarwis)',
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
    _gpsController.dispose();
    _feeInfoController.dispose();
    super.dispose();
  }

  void _detectCurrentGpsLocation() {
    setState(() {
      _gpsController.text = '-0.098412, 100.672195';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Koordinat GPS perangkat Anda berhasil terdeteksi!'),
        backgroundColor: AppColors.forest,
        duration: Duration(seconds: 2),
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
          // Top Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.ink),
                        SizedBox(width: 4),
                        Text('Batal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
                const Flexible(
                  child: Text(
                    'USUL DESTINASI WISATA BARU',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.forest),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),

          // Scrollable Body (Form with 8 Items)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Badge: Validasi Admin
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3D6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD97706).withOpacity(0.4)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Usulan destinasi hidden gem akan diverifikasi oleh Admin Dinas Pariwisata Sumbar terlebih dahulu sebelum resmi tampil di aplikasi wisata.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF78350F), height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sageBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. NAMA TEMPAT
                      _buildFieldHeader('1. NAMA TEMPAT WISATA:', Icons.place_rounded),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration('Contoh: Sarasah Murai Tingkat 7'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),

                      // 2. DESKRIPSI & NARASI SEJARAH (VOICE OVER AI)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldHeader('2. DESKRIPSI & SEJARAH (VOICE OVER):', Icons.record_voice_over_rounded),
                          GestureDetector(
                            onTap: _fillSampleNarrative,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Isi Contoh Narasi',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Deskripsi sejarah, legenda, atau keunikan alam ini akan dibacakan oleh Voice Over AI pada Tur Virtual 360°.',
                        style: TextStyle(fontSize: 9.5, color: AppColors.muted, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        minLines: 3,
                        decoration: _inputDecoration('Tuliskan sejarah, legenda, atau daya tarik nagari untuk diceritakan Voice Over...'),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      const SizedBox(height: 14),

                      // 3. WILAYAH (KABUPATEN / KOTA DI SUMBAR)
                      _buildFieldHeader('3. WILAYAH DI SUMATERA BARAT:', Icons.map_rounded),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRegion,
                        decoration: _inputDecoration('Pilih Wilayah'),
                        items: _regions.map((reg) {
                          return DropdownMenuItem(
                            value: reg,
                            child: Text(reg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRegion = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // 4. NAMA PENGUSUL
                      _buildFieldHeader('4. NAMA PENGUSUL:', Icons.person_rounded),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _proposerController,
                        decoration: _inputDecoration('Nama Lengkap Pengusul / Komunitas'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),

                      // 5. TITIK KOORDINAT GPS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldHeader('5. TITIK KOORDINAT GPS (SPASIAL):', Icons.my_location_rounded),
                          GestureDetector(
                            onTap: _detectCurrentGpsLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.gps_fixed_rounded, size: 10, color: Color(0xFF15803D)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ambil GPS Saat Ini',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Format Latitude, Longitude untuk penempatan pin di Peta Interaktif Sumbar.',
                        style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _gpsController,
                        decoration: _inputDecoration('Contoh: -0.098412, 100.672195'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 14),

                      // 6. FOTO TEMPAT UNTUK TUR 360 DERAJAT
                      _buildFieldHeader('6. FOTO TEMPAT UNTUK TUR PANORAMA 360°:', Icons.threesixty_rounded),
                      const SizedBox(height: 3),
                      const Text(
                        'Unggah foto equirectangular / panorama 360° keindahan tempat wisata untuk tur virtual.',
                        style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() => _photo360Attached = !_photo360Attached);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _photo360Attached ? const Color(0xFFDCFCE7) : AppColors.cream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _photo360Attached ? const Color(0xFF15803D) : AppColors.sageBorder,
                              width: _photo360Attached ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _photo360Attached ? Icons.check_circle_rounded : Icons.threesixty_rounded,
                                color: _photo360Attached ? const Color(0xFF15803D) : AppColors.forest,
                                size: 32,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _photo360Attached
                                    ? '✅ Foto_Panorama360_Sarasah_Murai.jpg (Terpilih)'
                                    : 'Ketuk untuk Unggah Foto Panorama 360°',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _photo360Attached ? const Color(0xFF15803D) : AppColors.forest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _photo360Attached
                                    ? 'Format Equirectangular 2:1 siap untuk render virtual tour'
                                    : 'Mendukung format JPG/PNG rasio 2:1 (Resolusi tinggi disarankan)',
                                style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 7. KATEGORI WISATA
                      _buildFieldHeader('7. KATEGORI WISATA ALAM:', Icons.category_rounded),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _categories.map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.forest,
                            backgroundColor: AppColors.cream,
                            side: BorderSide(
                              color: isSelected ? AppColors.forest : AppColors.sageBorder,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCategory = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 8. FASILITAS & INFORMASI TIKET MASUK (NON-TRANSAKSI)
                      _buildFieldHeader(
                        '8. FASILITAS & INFORMASI TIKET (NON-TRANSAKSI):',
                        Icons.info_rounded,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ℹ️ HANYA UNTUK INFORMASI TEMPAT • TIDAK ADA TRANSAKSI DI SISTEM',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.forest),
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'Fasilitas yang Tersedia di Lokasi:',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _facilityOptions.map((fac) {
                          final String facName = fac['name'] as String;
                          final IconData facIcon = fac['icon'] as IconData;
                          final bool isChecked = _selectedFacilities.contains(facName);

                          return FilterChip(
                            avatar: Icon(
                              facIcon,
                              size: 13,
                              color: isChecked ? Colors.white : AppColors.forest,
                            ),
                            label: Text(
                              facName,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isChecked ? Colors.white : AppColors.ink,
                              ),
                            ),
                            selected: isChecked,
                            selectedColor: AppColors.forest,
                            backgroundColor: AppColors.cream,
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
                      const SizedBox(height: 10),

                      const Text(
                        'Informasi Tarif / Retribusi Tiket Masuk:',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _feeInfoController,
                        maxLines: 2,
                        minLines: 1,
                        decoration: _inputDecoration('Contoh: Karcis Rp 5.000 / orang, Parkir Motor Rp 2.000'),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Kirim Usulan
                ElevatedButton.icon(
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
                    'Kirimkan Usulan Destinasi ke Dispar Sumbar',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    '💡 Destinasi baru akan resmi dipublikasikan setelah divalidasi oleh Admin Dispar.',
                    style: TextStyle(fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
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
        Icon(icon, size: 13, color: AppColors.forest),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.forest, letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
      filled: true,
      fillColor: AppColors.cream,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
