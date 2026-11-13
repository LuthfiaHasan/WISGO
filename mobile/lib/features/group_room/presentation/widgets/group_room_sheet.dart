import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Item 11: Ruang Rombongan Pribadi & Tautan Undangan melalui WhatsApp
/// Ruang grup rombongan, bagikan link undangan WA, daftar peserta aktif,
/// serta live voting destinasi wisata bersama.
class GroupRoomSheet extends StatefulWidget {
  final VoidCallback? onInviteWhatsApp;

  const GroupRoomSheet({super.key, this.onInviteWhatsApp});

  @override
  State<GroupRoomSheet> createState() => _GroupRoomSheetState();
}

class _GroupRoomSheetState extends State<GroupRoomSheet> {
  int _kapaloVotes = 4;
  int _harauVotes = 5;

  final List<Map<String, String>> _members = [
    {'name': 'Luthfia Hasan', 'role': 'Ketua Rombongan', 'initial': 'LH'},
    {'name': 'Dina Fitriani', 'role': 'Terkonfirmasi', 'initial': 'DF'},
    {'name': 'Rian Pratama', 'role': 'Terkonfirmasi', 'initial': 'RP'},
    {'name': 'Fauzan Akbar', 'role': 'Terkonfirmasi', 'initial': 'FA'},
    {'name': 'Siti Rahma', 'role': 'Terkonfirmasi', 'initial': 'SR'},
  ];

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
                        Text('Tutup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
                const Flexible(
                  child: Text(
                    'RUANG ROMBONGAN PRIBADI',
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
                // Group Room Hero Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NAMA GRUP TRIP', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.sage)),
                              SizedBox(height: 2),
                              Text('Jelajah Ranah Minang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('5 Anggota', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.cream)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kode Undangan: WISGO-MINANG-88',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cream),
                            ),
                            Icon(Icons.copy_rounded, size: 14, color: AppColors.sage),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tombol WhatsApp Invite Link (Item 11)
                      ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onInviteWhatsApp != null) {
                            widget.onInviteWhatsApp!();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tautan WhatsApp berhasil disalin & siap dibagikan!'),
                              backgroundColor: AppColors.forest,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Undang Anggota via WhatsApp', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Members List Card
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
                        'PESERTA ROMBONGAN AKTIF (5 ORANG):',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_members.length, (idx) {
                        final m = _members[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: idx == 0 ? AppColors.forest : AppColors.sage,
                                    child: Text(
                                      m['initial']!,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: idx == 0 ? AppColors.cream : AppColors.forest,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    m['name']!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: idx == 0 ? FontWeight.w800 : FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: idx == 0 ? AppColors.sage : AppColors.cream,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  m['role']!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: idx == 0 ? AppColors.forest : AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Live Voting Destinasi Rombongan
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '🗳️ LIVE VOTING DESTINASI ROMBONGAN:',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                          ),
                          Text('Bebas Pilih', style: TextStyle(fontSize: 9.5, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildVoteItem(
                        title: 'Kapalo Banda Taram (Rakit Bambu)',
                        votes: _kapaloVotes,
                        onVote: () => setState(() => _kapaloVotes++),
                      ),
                      const SizedBox(height: 8),
                      _buildVoteItem(
                        title: 'Lembah Harau & Sarasah Bunta',
                        votes: _harauVotes,
                        isWinner: true,
                        onVote: () => setState(() => _harauVotes++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteItem({
    required String title,
    required int votes,
    bool isWinner = false,
    required VoidCallback onVote,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWinner ? AppColors.forest : AppColors.warmBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Text(
                  '$votes Suara ${isWinner ? "• Terpilih Favorit Rombongan!" : "Setuju"}',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isWinner ? AppColors.forest : AppColors.muted),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onVote,
            style: ElevatedButton.styleFrom(
              backgroundColor: isWinner ? AppColors.forest : Colors.white,
              foregroundColor: isWinner ? Colors.white : AppColors.forest,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('+ Vote', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

