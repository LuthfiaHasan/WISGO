import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/ground_condition_model.dart';

/// Modal Input & Feed Pengalaman & Kondisi Nyata di Lokasi (Crowdsourced Wisatawan)
/// Persyaratan: Manual tanpa template khusus, batas minimal 30 karakter agar informatif.
class GroundConditionSheet extends StatefulWidget {
  final String destinationName;

  const GroundConditionSheet({
    super.key,
    required this.destinationName,
  });

  @override
  State<GroundConditionSheet> createState() => _GroundConditionSheetState();
}

class _GroundConditionSheetState extends State<GroundConditionSheet> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isWritingMode = false;
  late List<GroundConditionReport> _reports;

  final List<String> _suggestedTags = [
    'Jalur Aman & Kering',
    'Jalur Licin / Berlumpur',
    'Debit Air Deras',
    'Debit Air Pas',
    'Parkiran Longgar',
    'Pengunjung Padat',
    'Tiket Sesuai Perda',
    'Cuaca Cerah Sejuk',
  ];

  @override
  void initState() {
    super.initState();
    _reports = List<GroundConditionReport>.from(kSampleGroundReports);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _submitReport() {
    final text = _textController.text.trim();
    if (text.length < kMinGroundReportChars) return;

    final newReport = GroundConditionReport(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      destinationName: widget.destinationName,
      authorName: 'Rian Pratama (Anda)',
      authorBadge: 'Wisatawan Terverifikasi',
      timeAgo: 'Baru saja',
      freeformContent: text,
      tags: List<String>.from(_selectedTags),
      helpfulCount: 1,
      isVerifiedTourist: true,
    );

    setState(() {
      _reports.insert(0, newReport);
      _textController.clear();
      _selectedTags.clear();
      _isWritingMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Terima kasih! Informasi kondisi nyata lokasi Anda sangat membantu wisatawan lain.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = _textController.text.trim().length;
    final isLengthValid = currentLength >= kMinGroundReportChars;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.warmBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.visibility_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kondisi Nyata di Lokasi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          widget.destinationName,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ink.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Main View (Form vs Feed)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Penjelasan Sumber Ulasan Nyata di Lokasi (Item 4 Spesifikasi Trip Go)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.success,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ulasan Pengunjung Riil di Lokasi',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Review yang ditampilkan di bawah ini murni merupakan gambaran kondisi nyata berdasarkan pengalaman wisatawan yang sudah pernah mengunjungi tempat wisata ini langsung, bukan dari peserta Trip Go yang belum pernah ke lokasi.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF14532D),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Banner Edukasi: Bebas tanpa template, minimal 30 karakter
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.infoBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ceritakan kondisi riil yang Anda temui secara bebas tanpa template. Cukup penuhi minimal $kMinGroundReportChars karakter agar informatif bagi sesama wisatawan.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.info,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Button Toggle Write Mode
                  if (!_isWritingMode)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isWritingMode = true),
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        label: const Text(
                          'Tulis Laporan Kondisi Terkini',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                  // Form Input Manual Bebas (Tampil jika _isWritingMode = true)
                  if (_isWritingMode) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.warmBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Laporan Pengalaman Bebas',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isWritingMode = false),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _textController,
                            maxLines: 4,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.ink,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Tulis kondisi langsung di lapangan (cth: jalur dari gerbang basah dan agak licin, debit air terjun deras jernih, parkir mobil masih aman, tarif loket pas Rp10.000)...',
                              hintStyle: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.ink.withValues(alpha: 0.4),
                              ),
                              filled: true,
                              fillColor: AppColors.cream,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Live Character Count Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isLengthValid
                                      ? AppColors.successBorder
                                      : AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLengthValid
                                          ? Icons.check_circle_rounded
                                          : Icons.warning_amber_rounded,
                                      size: 12,
                                      color: isLengthValid
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isLengthValid
                                          ? 'Karakter memenuhi syarat ($currentLength/$kMinGroundReportChars)'
                                          : 'Minimal $kMinGroundReportChars karakter (kurang ${kMinGroundReportChars - currentLength} lagi)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isLengthValid
                                          ? AppColors.success
                                          : AppColors.warningDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$currentLength kar.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Tag Tambahan Opsional
                          const Text(
                            'Pilih Tag Situasi (Opsional):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _suggestedTags.map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return InkWell(
                                onTap: () => _toggleTag(tag),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.forest
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.forest
                                          : AppColors.warmBorder,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.ink,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 14),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isLengthValid ? _submitReport : null,
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text(
                                'Kirim Laporan Lapangan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forest,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.shade300,
                                disabledForegroundColor:
                                    Colors.grey.shade600,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Feed Laporan Terkini dari Wisatawan Lain
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Laporan Terkini di Lokasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${_reports.length} update',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.ink.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._reports.map((report) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.forest.withValues(alpha: 0.15),
                                child: Text(
                                  report.authorName.substring(0, 1),
                                  style: const TextStyle(
                                    color: AppColors.forest,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.authorName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      '${report.authorBadge} • ${report.timeAgo}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.ink.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.freeformContent,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                              height: 1.35,
                            ),
                          ),
                          if (report.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: report.tags.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.warmBorder,
                                    ),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
