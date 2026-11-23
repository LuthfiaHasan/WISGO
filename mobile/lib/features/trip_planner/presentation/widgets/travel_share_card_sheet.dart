import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/travel_experience_model.dart';

/// Painter untuk Merender QR Code Promosi WISGO secara Tajam & Bersih (Offline)
class WisgoQrCodePainter extends CustomPainter {
  final Color darkColor;
  final Color lightColor;

  WisgoQrCodePainter({
    this.darkColor = const Color(0xFF193D22),
    this.lightColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = lightColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      bgPaint,
    );

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Grid 21x21 QR Code matrix representatif
    const int matrixSize = 21;
    final double moduleSize = (size.width - 16) / matrixSize;
    const double padding = 8.0;

    void drawFinderPattern(double startX, double startY) {
      // Kotak luar 7x7
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, startY, moduleSize * 7, moduleSize * 7),
          Radius.circular(moduleSize * 1.5),
        ),
        darkPaint,
      );
      // Kotak dalam 5x5 putih
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + moduleSize,
            startY + moduleSize,
            moduleSize * 5,
            moduleSize * 5,
          ),
          Radius.circular(moduleSize),
        ),
        bgPaint,
      );
      // Pusat 3x3 hitam
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + moduleSize * 2,
            startY + moduleSize * 2,
            moduleSize * 3,
            moduleSize * 3,
          ),
          Radius.circular(moduleSize * 0.7),
        ),
        darkPaint,
      );
    }

    // 3 Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    drawFinderPattern(padding, padding);
    drawFinderPattern(padding + moduleSize * 14, padding);
    drawFinderPattern(padding, padding + moduleSize * 14);

    // Timing & Data Matrix
    final pattern = [
      [8, 2], [8, 4], [8, 5], [9, 8], [11, 8], [13, 8],
      [15, 8], [17, 8], [19, 8], [2, 8], [4, 8], [5, 8],
      [9, 10], [10, 10], [11, 10], [12, 10], [10, 9], [10, 11],
      [14, 14], [15, 14], [16, 14], [14, 15], [16, 15], [15, 16],
      [18, 14], [19, 15], [20, 14], [14, 18], [15, 19], [14, 20],
      [9, 14], [10, 15], [11, 14], [12, 15], [13, 14],
      [14, 9], [15, 10], [14, 11], [15, 12], [14, 13],
      [9, 2], [9, 4], [11, 2], [11, 4], [12, 3], [13, 5],
      [2, 14], [3, 15], [4, 14], [5, 16], [2, 18], [4, 19],
    ];

    for (final dot in pattern) {
      final double x = padding + dot[0] * moduleSize;
      final double y = padding + dot[1] * moduleSize;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, moduleSize * 0.95, moduleSize * 0.95),
          Radius.circular(moduleSize * 0.3),
        ),
        darkPaint,
      );
    }

    // Logo 'W' kecil di tengah QR
    final centerW = size.width / 2;
    final centerH = size.height / 2;
    canvas.drawCircle(
      Offset(centerW, centerH),
      moduleSize * 2.2,
      Paint()..color = lightColor,
    );
    canvas.drawCircle(
      Offset(centerW, centerH),
      moduleSize * 1.8,
      Paint()..color = darkColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Modal Lembar Template Posting Berbagi Sosial Media (Gaya Post Instagram + Post di Aplikasi)
class TravelShareCardSheet extends StatefulWidget {
  final TravelExperience experience;

  const TravelShareCardSheet({
    super.key,
    required this.experience,
  });

  @override
  State<TravelShareCardSheet> createState() => _TravelShareCardSheetState();
}

class _TravelShareCardSheetState extends State<TravelShareCardSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedPhotoUrl;
  late String _captionText;
  bool _isLiked = false;
  late int _likesCount;
  bool _isSaved = false;
  bool _isCopied = false;
  bool _isDownloading = false;
  bool _hasPostedToApp = false;

  // Preset foto pemandangan petualangan Sumatera Barat untuk upload/ganti foto cepat
  final List<Map<String, String>> _availableAdventurePhotos = [
    {
      'title': 'Tebing Granit Harau & Kabut',
      'url':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Air Terjun Sarasah Murai',
      'url':
          'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Teluk Mandeh & Karang Bahari',
      'url':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Istano Basa Pagaruyung',
      'url':
          'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Danau Maninjau Sunset Kelok 44',
      'url':
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Ngarai Sianok & Jam Gadang',
      'url':
          'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedPhotoUrl = widget.experience.coverPhotoUrl;
    _captionText =
        'Menikmati keindahan alam Ranah Minang di ${widget.experience.destinationName}! Menuntaskan rute ${widget.experience.distanceKm} km dengan pemandangan spektakuler. Ayo jelajah Sumbar bersama WISGO! 🏔️✨\n\n#WisataSumbar #WISGO #JelajahRanahMinang #TravelExperience #ExploreSumbar';
    _likesCount = widget.experience.likesCount + 88;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Modal Upload / Ganti Gambar Pengalaman Perjalanan ---
  void _showImageUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final customUrlController = TextEditingController();
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.forest, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Unggah Foto Petualangan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih foto dari album petualangan Sumbar atau unggah foto dari perangkat Anda untuk template posting Instagram.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),

              // Opsi Upload Kamera & Galeri Cepat
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _pickFromGallerySimulation();
                      },
                      icon: const Icon(Icons.photo_library_rounded,
                          size: 18, color: AppColors.forest),
                      label: const Text(
                        'Pilih dari Galeri',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.sageBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _pickFromCameraSimulation();
                      },
                      icon: const Icon(Icons.camera_alt_rounded,
                          size: 18, color: AppColors.brush),
                      label: const Text(
                        'Ambil Foto Kamera',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brush),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.sageBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Preset Galeri Spot Wisata
              const Text(
                'PILIHAN FOTO SPOT DESTINASI',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableAdventurePhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final item = _availableAdventurePhotos[index];
                    final isSelected = item['url'] == _selectedPhotoUrl;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPhotoUrl = item['url']!;
                        });
                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.forest,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Foto "${item['title']}" berhasil dipasang!'),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.forest
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item['url']!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.forest.withValues(alpha: 0.2),
                                  child: const Icon(Icons.terrain_rounded,
                                      color: AppColors.forest),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 3),
                                  color: Colors.black.withValues(alpha: 0.6),
                                  child: Text(
                                    item['title']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Center(
                                  child: Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 24),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Input URL Kustom
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customUrlController,
                      decoration: InputDecoration(
                        hintText: 'Atau tempel URL gambar kustom...',
                        hintStyle:
                            const TextStyle(fontSize: 11, color: AppColors.muted),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.warmBorder),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final url = customUrlController.text.trim();
                      if (url.isNotEmpty) {
                        setState(() => _selectedPhotoUrl = url);
                        Navigator.pop(modalCtx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                    ),
                    child: const Text('Terapkan',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickFromGallerySimulation() {
    setState(() {
      _selectedPhotoUrl =
          'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Foto berhasil diunggah dari galeri perangkat!'),
          ],
        ),
      ),
    );
  }

  void _pickFromCameraSimulation() {
    setState(() {
      _selectedPhotoUrl =
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=1200&q=80';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.brush,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Foto baru dari kamera berhasil diunggah!'),
          ],
        ),
      ),
    );
  }

  // --- Modal Edit Caption Postingan ---
  void _showEditCaptionModal() {
    final captionController = TextEditingController(text: _captionText);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        color: AppColors.forest, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tulis Caption Postingan Instagram',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: captionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan pengalaman petualangan Anda...',
                    filled: true,
                    fillColor: AppColors.cream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.warmBorder),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(modalCtx),
                      child: const Text('Batal',
                          style: TextStyle(color: AppColors.muted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final newCaption = captionController.text.trim();
                        if (newCaption.isNotEmpty) {
                          setState(() => _captionText = newCaption);
                        }
                        Navigator.pop(modalCtx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Simpan Caption',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Aksi Post ke Feed Komunitas WISGO ---
  void _handlePostToAppFeed() {
    final newPost = CommunityPost(
      id: 'post-user-${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'Anda (Dunsanak)',
      username: 'dunsanak_petualang',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      destinationName: widget.experience.destinationName,
      photoUrl: _selectedPhotoUrl,
      caption: _captionText,
      distanceKm: widget.experience.distanceKm,
      durationFormatted: widget.experience.durationFormatted,
      elevationGainMeters: widget.experience.elevationGainMeters,
      caloriesBurned: widget.experience.caloriesBurned,
      likesCount: _likesCount,
      isLiked: true,
      commentsCount: 3,
      postedTime: 'Baru saja',
      tags: const ['#WisataSumbar', '#WISGO', '#StravaTravel', '#RanahMinang'],
      isSelfPost: true,
    );

    setState(() {
      kSampleCommunityPosts.insert(0, newPost);
      _hasPostedToApp = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '🎉 Berhasil diposting ke Feed Komunitas WISGO! Postingan Anda kini aktif dan dapat dilihat oleh penjelajah lain.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    // Otomatis pindah ke tab Feed Komunitas untuk melihat hasilnya
    _tabController.animateTo(1);
  }

  // --- Aksi Unduh Gambar Postingan ---
  void _handleDownloadImage() {
    setState(() => _isDownloading = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isDownloading = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.download_done_rounded,
                  color: Color(0xFF15803D), size: 24),
              SizedBox(width: 8),
              Text('Unduh Berhasil!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gambar template postingan gaya Instagram telah diunduh dan tersimpan di Galeri HP Anda.',
                style: TextStyle(fontSize: 12.5, color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        color: AppColors.forest, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dilengkapi QR Code promosi WISGO untuk langsung dibagikan ke Instagram Feed & WhatsApp Story!',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _handleCopyLink();
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Buka Medsos',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handleCopyLink() {
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Tautan postingan pengalaman berhasil disalin!',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Template Posting Sosial Media',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Bagikan pencapaian Strava-style & promosikan aplikasi WISGO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.ink.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab Navigation: [Buat Postingan (Instagram)] | [Feed Komunitas WISGO]
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.forest,
              unselectedLabelColor: AppColors.muted,
              indicator: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                const Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_back_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Gaya Instagram',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.dynamic_feed_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('Feed Komunitas',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                      if (_hasPostedToApp) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF16A34A), shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Isi Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInstagramPostCreatorTab(),
                _buildCommunityFeedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: INSTAGRAM POST CREATOR & PREVIEW =================
  Widget _buildInstagramPostCreatorTab() {
    final exp = widget.experience;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Toolbar: Upload Foto & Edit Caption
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showImageUploadModal,
                    icon: const Icon(Icons.add_a_photo_rounded, size: 15),
                    label: const Text('Upload Foto',
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showEditCaptionModal,
                    icon: const Icon(Icons.edit_note_rounded,
                        size: 16, color: AppColors.ink),
                    label: const Text('Edit Caption',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.warmBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // KARTU POSTINGAN INSTAGRAM LENGKAP DENGAN QR WISGO
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Instagram (Avatar, Username, Geotag, More)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Story Circle Avatar
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF193D22),
                              Color(0xFFD97706),
                              Color(0xFF15803D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.forest,
                            child: Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'dunsanak_petualang',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.verified_rounded,
                                    size: 14, color: Color(0xFF0284C7)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 11, color: Color(0xFFEA4335)),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    exp.destinationName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded,
                            size: 20, color: AppColors.muted),
                        onPressed: _showImageUploadModal,
                      ),
                    ],
                  ),
                ),

                // 2. Main Photo Container (Aspect Ratio 1:1 Instagram) dengan Overlay Strava
                ClipRRect(
                  child: AspectRatio(
                    aspectRatio: 1.05,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _selectedPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF142417),
                            child: const Center(
                              child: Icon(Icons.landscape_rounded,
                                  size: 48, color: Colors.white54),
                            ),
                          ),
                        ),

                        // Subtle Gradient Overlay at bottom for readable metrics
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 110,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Watermark WISGO Explorer di pojok kanan atas
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.60),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.explore_rounded,
                                    size: 12, color: Color(0xFF68D391)),
                                SizedBox(width: 4),
                                Text(
                                  'WISGO Explorer',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tombol Quick Upload Floating di pojok kiri atas
                        Positioned(
                          top: 12,
                          left: 12,
                          child: GestureDetector(
                            onTap: _showImageUploadModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.forest.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt_rounded,
                                      size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ganti Foto',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // FLOATING METRIK STRAVA IDENTITY DI ATAS FOTO
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.70),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInstagramMetric(
                                  label: 'Jarak',
                                  value: '${exp.distanceKm}',
                                  unit: 'km',
                                  icon: Icons.straighten_rounded,
                                ),
                                _buildMetricDivider(),
                                _buildInstagramMetric(
                                  label: 'Waktu',
                                  value: exp.durationFormatted,
                                  unit: '',
                                  icon: Icons.timer_rounded,
                                ),
                                _buildMetricDivider(),
                                _buildInstagramMetric(
                                  label: 'Elevasi',
                                  value: '+${exp.elevationGainMeters}',
                                  unit: 'm',
                                  icon: Icons.landscape_rounded,
                                ),
                                _buildMetricDivider(),
                                _buildInstagramMetric(
                                  label: 'Kalori',
                                  value: '${exp.caloriesBurned}',
                                  unit: 'kkal',
                                  icon: Icons.local_fire_department_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Instagram Action Bar (Like, Comment, Share, Save)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Like Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLiked = !_isLiked;
                            _likesCount += _isLiked ? 1 : -1;
                          });
                        },
                        child: Icon(
                          _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isLiked
                              ? const Color(0xFFEF4444)
                              : AppColors.ink,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Comment Button
                      GestureDetector(
                        onTap: _showEditCaptionModal,
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.ink,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Direct Message / Share Button
                      GestureDetector(
                        onTap: _handleCopyLink,
                        child: const Icon(
                          Icons.near_me_outlined,
                          color: AppColors.ink,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      // Save / Bookmark
                      GestureDetector(
                        onTap: () {
                          setState(() => _isSaved = !_isSaved);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.forest,
                              duration: const Duration(milliseconds: 1200),
                              content: Text(_isSaved
                                  ? 'Postingan disimpan ke koleksi favorit!'
                                  : 'Postingan dihapus dari koleksi'),
                            ),
                          );
                        },
                        child: Icon(
                          _isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color:
                              _isSaved ? AppColors.forest : AppColors.ink,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Likes Counter & Caption
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disukai oleh rangga_adventure dan $_likesCount lainnya',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.ink, height: 1.35),
                          children: [
                            const TextSpan(
                              text: 'dunsanak_petualang ',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            TextSpan(text: _captionText),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Checkpoint info chip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.forest.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${exp.completedCheckpointsCount}/${exp.checkpoints.length} Checkpoint Tuntas',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            exp.tripDate,
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 5. PROMOSI RESMI WISGO DENGAN QR CODE (Sesuai Aturan & Test Requirement)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B0F),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(19)),
                  ),
                  child: Row(
                    children: [
                      // QR Code Generator
                      CustomPaint(
                        size: const Size(64, 64),
                        painter: WisgoQrCodePainter(
                          darkColor: const Color(0xFF142417),
                          lightColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.qr_code_scanner_rounded,
                                    color: Color(0xFF68D391), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'PINDAI UNTUK MENGUNDUH',
                                  style: TextStyle(
                                    color: Color(0xFF68D391),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Aplikasi WISGO Sumatera Barat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jelajah rute wisata Sumbar, tarif Perda resmi, open trip berizin & pantau cuaca real-time.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 9,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ACTION BUTTONS: [Post ke Feed WISGO] & [Unduh Gambar]
          Row(
            children: [
              // Tombol Post di Aplikasi
              Expanded(
                flex: 6,
                child: ElevatedButton.icon(
                  onPressed: _handlePostToAppFeed,
                  icon: const Icon(Icons.send_rounded, size: 17),
                  label: const Text(
                    'Post ke Feed WISGO',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Unduh
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  onPressed: _isDownloading ? null : _handleDownloadImage,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.forest),
                        )
                      : const Icon(Icons.download_rounded, size: 17),
                  label: Text(
                    _isDownloading ? 'Mengunduh...' : 'Unduh Post',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.forest,
                    side: const BorderSide(color: AppColors.forest, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tombol Salin Tautan
          Center(
            child: TextButton.icon(
              onPressed: _handleCopyLink,
              icon: Icon(
                _isCopied ? Icons.check_rounded : Icons.link_rounded,
                size: 16,
                color: AppColors.muted,
              ),
              label: Text(
                _isCopied ? 'Tautan Tersalin' : 'Salin Tautan Pengalaman',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ================= TAB 2: IN-APP COMMUNITY FEED (POST DI APLIKASI) =================
  Widget _buildCommunityFeedTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: kSampleCommunityPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, index) {
        final post = kSampleCommunityPosts[index];
        return _buildFeedPostCard(post);
      },
    );
  }

  Widget _buildFeedPostCard(CommunityPost post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: post.isSelfPost
              ? AppColors.forest.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: post.isSelfPost ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Postingan Feed
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.forest.withValues(alpha: 0.15),
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0] : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.username,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          if (post.isSelfPost) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.forest.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Postingan Anda',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${post.destinationName} • ${post.postedTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 18, color: AppColors.muted),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Foto Postingan dengan Metrik Strava
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  post.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF142417),
                    child: const Center(
                      child: Icon(Icons.image_rounded,
                          size: 40, color: Colors.white54),
                    ),
                  ),
                ),
                // Floating Strava Strip
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInstagramMetric(
                          label: 'Jarak',
                          value: '${post.distanceKm}',
                          unit: 'km',
                          icon: Icons.straighten_rounded,
                        ),
                        _buildMetricDivider(),
                        _buildInstagramMetric(
                          label: 'Waktu',
                          value: post.durationFormatted,
                          unit: '',
                          icon: Icons.timer_rounded,
                        ),
                        _buildMetricDivider(),
                        _buildInstagramMetric(
                          label: 'Elevasi',
                          value: '+${post.elevationGainMeters}',
                          unit: 'm',
                          icon: Icons.landscape_rounded,
                        ),
                        _buildMetricDivider(),
                        _buildInstagramMetric(
                          label: 'Kalori',
                          value: '${post.caloriesBurned}',
                          unit: 'kkal',
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      post.isLiked = !post.isLiked;
                      post.likesCount += post.isLiked ? 1 : -1;
                    });
                  },
                  child: Icon(
                    post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: post.isLiked
                        ? const Color(0xFFEF4444)
                        : AppColors.ink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.ink, size: 22),
                const SizedBox(width: 14),
                const Icon(Icons.near_me_outlined,
                    color: AppColors.ink, size: 22),
                const Spacer(),
                const Icon(Icons.bookmark_border_rounded,
                    color: AppColors.ink, size: 24),
              ],
            ),
          ),

          // Likes & Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post.likesCount} suka',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.ink, height: 1.3),
                    children: [
                      TextSpan(
                        text: '${post.username} ',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lihat semua ${post.commentsCount} komentar...',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub-widgets untuk Metrik Strava ---
  Widget _buildInstagramMetric({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF68D391), size: 13),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 1),
              Text(
                unit,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.20),
    );
  }
}
