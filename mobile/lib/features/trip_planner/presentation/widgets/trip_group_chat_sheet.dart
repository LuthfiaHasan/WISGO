import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../models/open_trip_model.dart';

/// Ruang Komunikasi / Grup Chat Resmi In-App Trip Go (100% Tanpa WhatsApp)
/// Mengikuti aturan desain.md: Warm Cream, Forest, BgCard, radius 28 px,
/// fontSize >= 11 px, SafeArea + keyboard inset, dan kursor klik.
class TripGroupChatSheet extends StatefulWidget {
  final OpenTripItem trip;

  const TripGroupChatSheet({
    super.key,
    required this.trip,
  });

  @override
  State<TripGroupChatSheet> createState() => _TripGroupChatSheetState();
}

class _TripGroupChatSheetState extends State<TripGroupChatSheet> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickReplies = [
    'Saya sudah di titik kumpul',
    'Sedang menuju lokasi',
    'Bagaimana kondisi cuaca sekarang?',
  ];

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetText]) {
    final text = (presetText ?? _chatController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      widget.trip.messages.add(
        TripChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'Saya (Peserta)',
          senderRole: 'Peserta',
          message: text,
          timestamp: 'Baru saja',
        ),
      );
      if (presetText == null) {
        _chatController.clear();
      }
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final pinnedNotices =
        widget.trip.messages.where((m) => m.isPinnedNotice).toList();
    final chatMessages =
        widget.trip.messages.where((m) => !m.isPinnedNotice).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              // 1. Header Ruang Grup Chat In-App
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
                decoration: const BoxDecoration(
                  color: AppColors.bgCard,
                  border: Border(
                    bottom: BorderSide(color: AppColors.warmBorder),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle baku 40x4 px
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warmBorder,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            color: AppColors.forest,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grup Chat • ${widget.trip.singleDestination}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      '${widget.trip.quotaFilled} Anggota Aktif • Komunikasi Resmi In-App WISGO',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
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
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.ink,
                              size: 22,
                            ),
                            tooltip: 'Tutup Grup Chat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Pengumuman Penting Host (Pinned)
              if (pinnedNotices.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.goldMinang.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: AppColors.warningDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pinnedNotices.first.senderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pinnedNotices.first.timestamp,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pinnedNotices.first.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Daftar Pesan Grup Chat
              Expanded(
                child: chatMessages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppColors.sage,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 28,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada percakapan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Sapa Host dan peserta lain langsung di sini tanpa perlu pindah ke WhatsApp.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: chatMessages.length,
                        itemBuilder: (ctx, index) {
                          final msg = chatMessages[index];
                          final isMe = msg.senderRole == 'Peserta' &&
                              msg.senderName.contains('Saya');
                          final isHost = msg.senderRole == 'Host';

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.80,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.forest
                                    : isHost
                                        ? AppColors.sage
                                        : AppColors.bgCard,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe
                                      ? const Radius.circular(16)
                                      : const Radius.circular(4),
                                  bottomRight: isMe
                                      ? const Radius.circular(4)
                                      : const Radius.circular(16),
                                ),
                                border: Border.all(
                                  color: isMe
                                      ? AppColors.forest
                                      : isHost
                                          ? AppColors.sageBorder
                                          : AppColors.warmBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          msg.senderName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isMe
                                                ? AppColors.sage
                                                : isHost
                                                    ? AppColors.forest
                                                    : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      if (isHost) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.forest,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'HOST',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.cream,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isMe ? Colors.white : AppColors.ink,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.timestamp,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe
                                          ? AppColors.cream
                                              .withValues(alpha: 0.78)
                                          : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 4. Quick Reply Chips (1-Tap Koordinasi)
              Container(
                width: double.infinity,
                color: AppColors.bgCard,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickReplies.map((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            reply,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                          backgroundColor: AppColors.creamSubtle,
                          side: const BorderSide(color: AppColors.sageBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          onPressed: () => _sendMessage(reply),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 5. Input Bar Pesan
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                decoration: const BoxDecoration(
                  color: AppColors.bgCard,
                  border: Border(top: BorderSide(color: AppColors.warmBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Tulis pesan ke grup trip...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 11),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _sendMessage(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: AppColors.cream,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(Icons.send_rounded, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
