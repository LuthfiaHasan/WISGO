import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Item 9: Formulir Laporan Pungutan Liar dan Fasilitas Rusak
/// Unggah foto bukti disertai penandaan titik koordinat lokasi otomatis langsung dikirim ke petugas pengawasan.
class LaporPungliSheet extends StatefulWidget {
  final String initialTab; // 'pungli' or 'fasilitas'
  final Function(String ticketNumber)? onSubmitSuccess;

  const LaporPungliSheet({
    super.key,
    this.initialTab = 'pungli',
    this.onSubmitSuccess,
  });

  @override
  State<LaporPungliSheet> createState() => _LaporPungliSheetState();
}

class _LaporPungliSheetState extends State<LaporPungliSheet> {
  late String _activeTab;
  String _selectedLocation = 'Lembah Harau (Kab. 50 Kota)';
  final TextEditingController _amountController = TextEditingController(text: '20000');
  final TextEditingController _descController = TextEditingController();
  String _selectedFasilitas = 'Toilet Umum / Air Bersih Rusak';
  bool _photoAttached = false;

  final List<String> _locations = [
    'Lembah Harau (Kab. 50 Kota)',
    'Jam Gadang (Kota Bukittinggi)',
    'Air Terjun Nyarai (Padang Pariaman)',
    'Kapalo Banda Taram (Kab. 50 Kota)',
    'Kawasan Mandeh (Pesisir Selatan)',
    'Pantai Padang (Kota Padang)',
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
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
                        Text('Kembali', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
                const Flexible(
                  child: Text(
                    'LAPOR SATGAS SABER PUNGLI',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.terracotta,
                    ),
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
                // Switcher Tab
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.creamSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 'pungli'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _activeTab == 'pungli' ? AppColors.forest : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🚨 Pungutan Liar',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _activeTab == 'pungli' ? AppColors.cream : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 'fasilitas'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _activeTab == 'fasilitas' ? AppColors.forest : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🛠️ Fasilitas Rusak',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _activeTab == 'fasilitas' ? AppColors.cream : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // GPS Auto-Detection Verified Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.brush.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.gps_fixed_rounded, color: AppColors.brush, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Titik Koordinat Lokasi Terkunci Otomatis',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                            ),
                            Text(
                              '-0.9471° S, 100.4172° E • Akurasi ±3m (Siap Kirim ke Satgas)',
                              style: TextStyle(fontSize: 9.5, color: AppColors.brush),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Form Fields Card
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
                        'LOKASI KAWASAN WISATA:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLocation,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.sageBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _locations.map((loc) {
                          return DropdownMenuItem(
                            value: loc,
                            child: Text(loc, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedLocation = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      if (_activeTab == 'pungli') ...[
                        const Text(
                          'NOMINAL YANG DIMINTA DI LUAR PERDA:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            filled: true,
                            fillColor: AppColors.cream,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.sageBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'JENIS FASILITAS YANG RUSAK:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedFasilitas,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.cream,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.sageBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Toilet Umum / Air Bersih Rusak', child: Text('Toilet Umum / Air Bersih Rusak')),
                            DropdownMenuItem(value: 'Jembatan / Jalur Trekking Amblas', child: Text('Jembatan / Jalur Trekking Amblas')),
                            DropdownMenuItem(value: 'Lampu Penerangan Malam Mati', child: Text('Lampu Penerangan Malam Mati')),
                            DropdownMenuItem(value: 'Tempat Sampah Penuh / Rusak', child: Text('Tempat Sampah Penuh / Rusak')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFasilitas = val);
                          },
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Upload Photo Box
                      const Text(
                        'UNGGAH FOTO BUKTI KEJADIAN (GPS TAGGED):',
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
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _photoAttached ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                                color: _photoAttached ? AppColors.forest : AppColors.muted,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _photoAttached
                                    ? 'Foto_Bukti_Pungli_Terlampir.jpg (2.4 MB) ✅'
                                    : 'Ketuk untuk Ambil Foto Kamera / Galeri',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _photoAttached ? AppColors.forest : AppColors.ink,
                                ),
                              ),
                              const Text(
                                'Koordinat GPS otomatis tersemat di file',
                                style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'URAIAN KRONOLOGI SINGKAT:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Oknum memungut tarif parkir motor tanpa karcis resmi perda...',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                          filled: true,
                          fillColor: AppColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.sageBorder),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    final ticket = 'SABER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    Navigator.pop(context);
                    if (widget.onSubmitSuccess != null) {
                      widget.onSubmitSuccess!(ticket);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Kirim Laporan Resmi ke Satgas Saber Pungli',
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

