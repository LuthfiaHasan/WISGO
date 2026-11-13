import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Item 13: Formulir Usulan Destinasi Wisata Baru
/// Formulir pengajuan destinasi wisata baru oleh wisatawan/komunitas
/// disertai kategori, fasilitas, koordinat, usulan tarif, dan foto lokasi.
class UsulDestinasiSheet extends StatefulWidget {
  final Function(String name)? onSubmitSuccess;

  const UsulDestinasiSheet({super.key, this.onSubmitSuccess});

  @override
  State<UsulDestinasiSheet> createState() => _UsulDestinasiSheetState();
}

class _UsulDestinasiSheetState extends State<UsulDestinasiSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  String _selectedRegion = 'Kab. Lima Puluh Kota';
  String _selectedCategory = 'Air Terjun';
  bool _photoAttached = false;

  final List<String> _regions = [
    'Kab. Lima Puluh Kota',
    'Kota Padang',
    'Kota Bukittinggi',
    'Kab. Tanah Datar',
    'Kab. Agam',
    'Kab. Pesisir Selatan',
    'Kab. Padang Pariaman',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Bar
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.forest),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NAMA TEMPAT WISATA BARU:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Sarasah Murai Tingkat 7',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                          filled: true,
                          fillColor: AppColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.sageBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'KABUPATEN / KOTA DI SUMATERA BARAT:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRegion,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.sageBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _regions.map((reg) {
                          return DropdownMenuItem(
                            value: reg,
                            child: Text(reg, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRegion = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'KATEGORI WISATA:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: ['Air Terjun', 'Puncak/Bukit', 'Danau/Sungai'].map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.sage : AppColors.cream,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.forest : AppColors.warmBorder,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? AppColors.forest : AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'USULAN TARIF RETRIBUSI RESMI (ATAU GRATIS):',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _feeController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Rp 5.000 / orang (Pengelola Pokdarwis)',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                          filled: true,
                          fillColor: AppColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.sageBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Upload Foto Box
                      const Text(
                        'FOTO LOKASI / KEINDAHAN ALAM:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() => _photoAttached = !_photoAttached);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _photoAttached ? AppColors.forest : AppColors.sageBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _photoAttached ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded,
                                color: _photoAttached ? AppColors.forest : AppColors.muted,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _photoAttached
                                    ? 'Foto_Sarasah_Murai_Terlampir.jpg ✅'
                                    : 'Ketuk untuk Unggah Foto Tempat',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _photoAttached ? AppColors.forest : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim().isNotEmpty
                        ? _nameController.text.trim()
                        : 'Sarasah Murai Indah';
                    Navigator.pop(context);
                    if (widget.onSubmitSuccess != null) {
                      widget.onSubmitSuccess!(name);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Kirimkan Usulan Destinasi ke Dispar Sumbar',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

