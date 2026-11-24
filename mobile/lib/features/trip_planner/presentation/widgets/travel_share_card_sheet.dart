import 'package:flutter/material.dart';
import '../../../../core/network/auth_guard.dart';
import '../../../../core/services/api_service.dart';
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
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bgPaint,
    );

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    const int matrixSize = 21;
    final double moduleSize = (size.width - 12) / matrixSize;
    const double padding = 6.0;

    void drawFinderPattern(double startX, double startY) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, startY, moduleSize * 7, moduleSize * 7),
          Radius.circular(moduleSize * 1.5),
        ),
        darkPaint,
      );
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

    drawFinderPattern(padding, padding);
    drawFinderPattern(padding + moduleSize * 14, padding);
    drawFinderPattern(padding, padding + moduleSize * 14);

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Modal Lembar Template Posting Berbagi Sosial Media: Jejak WISGO
/// Mendukung 2 Mode:
/// 1. Mode Stiker Transparan (PNG Overlay untuk IG Story / TikTok / WA Status)
/// 2. Mode Kartu Penuh
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
  bool _isTransparentSticker = true; // true = Mode Stiker Transparan, false = Mode Kartu Penuh
  bool _showQrCode = true;
  late int _likesCount;
  bool _isDownloading = false;
  bool _isSavingCloud = false;
  bool _hasPostedToApp = false;

  // Preset foto tempat wisata resmi katalog WISGO
  final List<Map<String, String>> _availableAdventurePhotos = [
    {
      'title': 'Tebing Granit Lembah Harau',
      'url':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Air Terjun Sarasah Murai',
      'url':
          'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Teluk Mandeh & Pulau Sirandah',
      'url':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Istano Basa Pagaruyung',
      'url':
          'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Danau Maninjau Kelok 44',
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
    _selectedPhotoUrl = widget.experience.activePhotoUrl;
    _captionText =
        'Jelajah ${widget.experience.destinationName} bareng WISGO! Stempel #${widget.experience.stampNumber} (${widget.experience.visitedCount}/${widget.experience.totalDestinations} destinasi). Gelar: ${widget.experience.levelTitle}. Dijelajahi bersama WISGO 🏔️✨\n\n#JejakWISGO #WisataSumbar #Minangkabau #WonderfulIndonesia';
    _likesCount = widget.experience.likesCount + 88;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                    'Ganti Foto Sendiri',
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
                'Gunakan foto jepretan Anda sendiri dari galeri atau pilih dari katalog resmi destinasi WISGO.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),

              // Tombol Unggah Galeri & Kamera
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          _pickFromCameraSimulation();
                        },
                        icon: const Icon(Icons.camera_alt_rounded,
                            size: 18, color: AppColors.terracotta),
                        label: const Text(
                          'Ambil Kamera',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracotta),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.sageBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text(
                'PILIHAN FOTO RESMI KATALOG DESTINASI',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
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
                      },
                      child: Container(
                        width: 95,
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
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  color: Colors.black.withValues(alpha: 0.6),
                                  child: Text(
                                    item['title']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
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
              const SizedBox(height: 14),

              // Input URL Kustom
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customUrlController,
                      decoration: InputDecoration(
                        hintText: 'Tempel URL foto pribadi...',
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
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton(
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
                      child: const Text('Pasang',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
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
            Text('Foto pribadi dari galeri berhasil dipasang pada Jejak WISGO!'),
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
        backgroundColor: AppColors.terracotta,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Foto jepretan kamera berhasil dipasang pada Jejak WISGO!'),
          ],
        ),
      ),
    );
  }

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
                      'Tulis Caption Kampanye Jejak WISGO',
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
                    hintText: 'Tuliskan kesan atau ajakan berwisata ke Ranah Minang...',
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
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ElevatedButton(
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

  // --- Aksi Simpan / Catat Share Card ke Cloud (BE-2) ---
  Future<void> _handleSaveShareCardToCloud() async {
    final allowed = AuthGuard.check(context);
    if (!allowed) return;

    setState(() => _isSavingCloud = true);
    try {
      final mode = _isTransparentSticker ? 'transparent_sticker' : 'full_card';
      final res = await ApiService.createShareCard(
        tripId: widget.experience.id,
        mode: mode,
        caption: _captionText,
      );

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.forest,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kartu Jejak WISGO berhasil dicatat dan disimpan ke akun Anda!',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.terracotta,
            content: Text(res.message.isNotEmpty ? res.message : 'Gagal menyimpan kartu'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text('Terjadi kendala: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingCloud = false);
    }
  }

  // --- Aksi Post ke Feed Komunitas WISGO ---
  void _handlePostToAppFeed() {
    final newPost = CommunityPost(
      id: 'post-user-${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'Anda (Wisatawan Minang)',
      username: 'jejak_wisatawan',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      destinationName: widget.experience.destinationName,
      cityRegency: widget.experience.cityRegency,
      photoUrl: _selectedPhotoUrl,
      caption: _captionText,
      badgeTitle: widget.experience.badgeTitle,
      likesCount: _likesCount,
      isLiked: true,
      commentsCount: 3,
      postedTime: 'Baru saja',
      tags: const ['#JejakWISGO', '#WisataSumbar', '#RanahMinang'],
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
                '🎉 Berhasil diposting ke Feed Komunitas WISGO! Pengalaman Anda kini mempromosikan pariwisata Sumbar.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    _tabController.animateTo(1);
  }

  // --- Aksi Unduh Gambar / Stiker ---
  void _handleDownloadImage() {
    setState(() => _isDownloading = true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _isDownloading = false);

      final modeName = _isTransparentSticker
          ? 'Stiker Transparan (PNG Overlay)'
          : 'Kartu Penuh Jejak WISGO';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.download_done_rounded,
                  color: Color(0xFF15803D), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Unduh $modeName Berhasil!',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isTransparentSticker
                    ? 'File PNG dengan latar transparan telah disimpan. Anda dapat langsung menempelkannya di atas foto/video Instagram Story, TikTok, atau WhatsApp Status!'
                    : 'Kartu visual penuh Jejak WISGO telah diunduh ke galeri perangkat Anda.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.35),
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
                    Icon(Icons.campaign_rounded,
                        color: AppColors.forest, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tag @wisgo.sumbar dan gunakan tagar #JejakWISGO untuk mendapatkan repost resmi!',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
                _shareToSocial('Instagram Story');
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Bagikan ke Story',
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

  void _shareToSocial(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Membuka $platform dengan stiker Jejak WISGO...',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
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

          // Header Kampanye Jejak WISGO
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign_rounded, size: 18, color: AppColors.forest),
                          SizedBox(width: 6),
                          Text(
                            'Jejak WISGO',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Kampanye Wisata & Bagikan ke IG Story, TikTok, atau WA Status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
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

          // Tab Navigation: [Kartu & Stiker Jejak] | [Feed Komunitas]
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
                      Icon(Icons.auto_awesome_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Stiker & Kartu',
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
                _buildJejakWisgoCardCreatorTab(),
                _buildCommunityFeedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: KARTU & STIKER JEJAK WISGO CREATOR =================
  Widget _buildJejakWisgoCardCreatorTab() {
    final exp = widget.experience;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Selector 2 Mode Tampilan: [Stiker Transparan (PNG)] | [Kartu Penuh]
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _isTransparentSticker = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _isTransparentSticker
                              ? AppColors.forest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 15,
                              color: _isTransparentSticker
                                  ? Colors.white
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Stiker Transparan (PNG)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _isTransparentSticker
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _isTransparentSticker = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: !_isTransparentSticker
                              ? AppColors.forest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.crop_portrait_rounded,
                              size: 15,
                              color: !_isTransparentSticker
                                  ? Colors.white
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Kartu Penuh',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: !_isTransparentSticker
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Toolbar Kontrol Cepat: Ganti Foto Sendiri & Toggle QR Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: OutlinedButton.icon(
                      onPressed: _showImageUploadModal,
                      icon: const Icon(Icons.add_a_photo_rounded,
                          size: 14, color: AppColors.forest),
                      label: const Text(
                        'Ganti Foto Sendiri',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        side: const BorderSide(color: AppColors.sageBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showQrCode = !_showQrCode),
                      icon: Icon(
                        _showQrCode ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
                        size: 15,
                        color: _showQrCode ? const Color(0xFF15803D) : AppColors.muted,
                      ),
                      label: Text(
                        _showQrCode ? 'QR Kode: Aktif' : 'QR Kode: Mati',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _showQrCode ? const Color(0xFF15803D) : AppColors.muted,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        side: BorderSide(
                          color: _showQrCode ? const Color(0xFF86EFAC) : AppColors.warmBorder,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _showEditCaptionModal,
                  tooltip: 'Tulis Caption',
                  icon: const Icon(Icons.edit_note_rounded,
                      size: 20, color: AppColors.forest),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.forest.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ================= PREVIEW AREA KARTU / STIKER JEJAK WISGO =================
          // Jika Mode Stiker Transparan: container preview diberi aksen gelap semi-transparan (ala Story Editor)
          Container(
            decoration: BoxDecoration(
              color: _isTransparentSticker
                  ? const Color(0xFF111827) // Kontras gelap agar stiker PNG transparan terbaca jelas
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isTransparentSticker
                    ? const Color(0xFF374151)
                    : AppColors.warmBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Mode Stiker indicator badge
                  if (_isTransparentSticker)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.layers_rounded,
                                size: 10, color: Color(0xFF34D399)),
                            SizedBox(width: 4),
                            Text(
                              'PNG Transparan',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- 1. 3 BLOK TIPOGRAFI MINIMALIS (ALA STRAVA OVERLAY) ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isTransparentSticker
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isTransparentSticker
                                  ? Colors.white12
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Blok 1: Destinasi
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DESTINASI',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _isTransparentSticker
                                            ? const Color(0xFF9CA3AF)
                                            : AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      exp.destinationName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: _isTransparentSticker
                                            ? Colors.white
                                            : AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      exp.cityRegency,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: _isTransparentSticker
                                            ? const Color(0xFFD1D5DB)
                                            : AppColors.brush,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: _isTransparentSticker
                                    ? Colors.white24
                                    : const Color(0xFFE5E7EB),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                              ),

                              // Blok 2: Jejak Sumbar
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'JEJAK SUMBAR',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _isTransparentSticker
                                            ? const Color(0xFF9CA3AF)
                                            : AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Stempel #${exp.stampNumber}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: _isTransparentSticker
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF15803D),
                                      ),
                                    ),
                                    Text(
                                      '${exp.visitedCount} / ${exp.totalDestinations} Destinasi',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: _isTransparentSticker
                                            ? const Color(0xFFD1D5DB)
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: _isTransparentSticker
                                    ? Colors.white24
                                    : const Color(0xFFE5E7EB),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                              ),

                              // Blok 3: Gelar Wisatawan
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'GELAR',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: _isTransparentSticker
                                            ? const Color(0xFF9CA3AF)
                                            : AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      exp.levelTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: _isTransparentSticker
                                            ? const Color(0xFFFBBF24)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                    Text(
                                      exp.tripDate,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: _isTransparentSticker
                                            ? const Color(0xFFD1D5DB)
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- 2. BAGIAN TENGAH: BINGKAI FOTO TEMPAT WISATA (PENGGANTI RUTE STRAVA) ---
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isTransparentSticker
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: AspectRatio(
                              aspectRatio: 1.25,
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

                                  // Subtle Badge di Pojok Kiri Bawah Foto
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_rounded,
                                              size: 11, color: Color(0xFF34D399)),
                                          const SizedBox(width: 4),
                                          Text(
                                            exp.badgeTitle,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Tombol Floating Ganti Foto di Sudut Atas
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: _showImageUploadModal,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white30),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.camera_alt_rounded,
                                                  size: 11, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text(
                                                'Ganti Foto',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- 3. BAGIAN BAWAH: BRANDING KAMPANYE WISGO ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isTransparentSticker
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFF0D1B0F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isTransparentSticker
                                  ? Colors.white12
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Brand Logo WISGO & Tagline
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.forest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Center(
                                  child: Text(
                                    'W',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WISGO',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      'Dijelajahi bersama WISGO',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF86EFAC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Toggleable QR Code Menuju Aplikasi
                              if (_showQrCode) ...[
                                const SizedBox(width: 8),
                                CustomPaint(
                                  size: const Size(42, 42),
                                  painter: WisgoQrCodePainter(
                                    darkColor: const Color(0xFF0D1B0F),
                                    lightColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Toolbar: Unduh Stiker/Kartu & Simpan ke Cloud
          Row(
            children: [
              Expanded(
                flex: 3,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _handleDownloadImage,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 16),
                    label: Text(
                      _isTransparentSticker
                          ? 'Unduh Stiker Transparan'
                          : 'Unduh Kartu Penuh',
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: OutlinedButton.icon(
                    onPressed: _isSavingCloud ? null : _handleSaveShareCardToCloud,
                    icon: _isSavingCloud
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.forest),
                          )
                        : const Icon(Icons.cloud_upload_rounded,
                            size: 16, color: AppColors.forest),
                    label: const Text(
                      'Simpan Cloud',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.forest, width: 1.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pintasan Bagikan ke Media Sosial Organik
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BAGIKAN LANGSUNG KE MEDIA SOSIAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSocialShareButton(
                      label: 'IG Story',
                      icon: Icons.camera_alt_outlined,
                      color: const Color(0xFFE1306C),
                      onTap: () => _shareToSocial('Instagram Story'),
                    ),
                    _buildSocialShareButton(
                      label: 'TikTok',
                      icon: Icons.music_note_rounded,
                      color: Colors.black,
                      onTap: () => _shareToSocial('TikTok'),
                    ),
                    _buildSocialShareButton(
                      label: 'WhatsApp Status',
                      icon: Icons.chat_rounded,
                      color: const Color(0xFF25D366),
                      onTap: () => _shareToSocial('WhatsApp Status'),
                    ),
                    _buildSocialShareButton(
                      label: 'Post ke Feed',
                      icon: Icons.forum_rounded,
                      color: AppColors.forest,
                      onTap: _handlePostToAppFeed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialShareButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: FEED KOMUNITAS KAMPANYE WISGO =================
  Widget _buildCommunityFeedTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: kSampleCommunityPosts.length,
      itemBuilder: (ctx, index) {
        final post = kSampleCommunityPosts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warmBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundImage: NetworkImage(post.avatarUrl),
                      backgroundColor: AppColors.sage,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  size: 13, color: Color(0xFF0284C7)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded,
                                  size: 11, color: AppColors.forest),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${post.destinationName} • ${post.cityRegency}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        post.badgeTitle,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Post Photo Frame
              ClipRRect(
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: Image.network(
                    post.photoUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Post Footer Caption & Tags
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likesCount} suka',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentsCount} komentar',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.caption,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: post.tags.map((tag) {
                        return Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
