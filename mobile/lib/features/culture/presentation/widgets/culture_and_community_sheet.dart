import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MinangMotif {
  final String name;
  final String meaning;
  final String philosophy;
  final IconData icon;

  const MinangMotif({
    required this.name,
    required this.meaning,
    required this.philosophy,
    required this.icon,
  });
}

class CommunityQuestion {
  final String author;
  final String question;
  final String? localAnswer;
  final String? answerAuthor;
  final String time;

  const CommunityQuestion({
    required this.author,
    required this.question,
    this.localAnswer,
    this.answerAuthor,
    required this.time,
  });
}

class CultureAndCommunitySheet extends StatefulWidget {
  final String destinationTitle;

  const CultureAndCommunitySheet({
    super.key,
    this.destinationTitle = 'Air Terjun Lubuk Hitam (Cindakir) 3 Tingkat',
  });

  @override
  State<CultureAndCommunitySheet> createState() => _CultureAndCommunitySheetState();
}

class _CultureAndCommunitySheetState extends State<CultureAndCommunitySheet> {
  String _activeTab = 'motif'; // 'motif' | 'sertifikat' | 'tanya_jawab'

  final List<MinangMotif> _motifs = [
    const MinangMotif(
      name: 'Kaluak Paku Kacang Balimbiang',
      meaning: 'Belajar dan menyesuaikan diri dengan alam sekitar',
      philosophy: 'Anak dipangku kemenakan dibimbing, urang kampuang dipatenggangkan.',
      icon: Icons.all_inclusive_rounded,
    ),
    const MinangMotif(
      name: 'Itik Pulang Patang',
      meaning: 'Kesepakatan bersama, kepatuhan dan keharmonisan hidup nagari',
      philosophy: 'Bararak salarik-larik, indak batindiak saeto jua, sapaham sajalan.',
      icon: Icons.groups_rounded,
    ),
    const MinangMotif(
      name: 'Pucuak Rabuang',
      meaning: 'Bermanfaat sepanjang usia mulai dari rebung hingga jadi bambu',
      philosophy: 'Kaciak baguno, gadang tapakai, tuo batungkek, mati bapusaro.',
      icon: Icons.eco_rounded,
    ),
    const MinangMotif(
      name: 'Siriah Gadang',
      meaning: 'Keramahan budi dan penghormatan dalam menyambut tamu',
      philosophy: 'Siriah sacabiak, pinang sagak, tando karajo bapokok pado adaik.',
      icon: Icons.volunteer_activism_rounded,
    ),
  ];

  final List<CommunityQuestion> _questions = [
    const CommunityQuestion(
      author: 'Rian Pratama',
      question: 'Apakah jalur menuju tingkat 3 licin kalau berkunjung pagi hari?',
      localAnswer: 'Pagi hari berembun dan agak lembab dunsanak, disarankan pakai sandal gunung atau sepatu trekking berpola grip kuat.',
      answerAuthor: 'Pak Etek (Pokdarwis Cindakir)',
      time: '2 jam lalu',
    ),
    const CommunityQuestion(
      author: 'Desi Marlina',
      question: 'Di pos registrasi apakah menerima pembayaran QRIS untuk parkir dan tiket?',
      localAnswer: 'Alhamdulillah sudah ada plang QRIS Wisgo resmi di loket masuk pos 1, jadi tidak perlu khawatir uang pas.',
      answerAuthor: 'Buyuang Hendra (Pengelola Nagari)',
      time: '1 hari lalu',
    ),
  ];

  final TextEditingController _questionCtrl = TextEditingController();
  bool _isDownloadingCertificate = false;

  void _downloadCertificate() {
    setState(() => _isDownloadingCertificate = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _isDownloadingCertificate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sertifikat Resmi Berhasil Diunduh (PDF Disimpan di Perangkat).'),
            backgroundColor: AppColors.forest,
          ),
        );
      }
    });
  }

  void _submitQuestion() {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _questions.insert(
        0,
        CommunityQuestion(
          author: 'Anda (Wisatawan)',
          question: text,
          localAnswer: 'Pertanyaan Anda sedang diteruskan ke Tetua Adat & Pengelola Nagari...',
          answerAuthor: 'Moderator Pokdarwis',
          time: 'Baru saja',
        ),
      );
      _questionCtrl.clear();
    });
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUDAYA, SERTIFIKAT & FORUM NAGARI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.brush,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.destinationTitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.warmBorder),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('motif', 'Motif Ukiran', Icons.auto_awesome_rounded),
                const SizedBox(width: 8),
                _buildTab('sertifikat', 'Sertifikat', Icons.workspace_premium_rounded),
                const SizedBox(width: 8),
                _buildTab('tanya_jawab', 'Forum Warga', Icons.forum_rounded),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 'motif'
                ? _buildMotifView()
                : _activeTab == 'sertifikat'
                    ? _buildCertificateView()
                    : _buildCommunityForumView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String key, String label, IconData icon) {
    final isSel = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.forest : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.forest : AppColors.sageBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSel ? AppColors.cream : AppColors.forest),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSel ? AppColors.cream : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotifView() {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: _motifs.length,
      itemBuilder: (ctx, idx) {
        final m = _motifs[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(m.icon, color: AppColors.forest, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        Text(
                          m.meaning,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '“${m.philosophy}”',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.forest, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertificateView() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Certificate Preview Box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.forest, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDFECE2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.forest, size: 28),
              ),
              const SizedBox(height: 8),
              const Text(
                'PIAGAM RESMI KUNJUNGAN NAGARI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.forest, letterSpacing: 1.1),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pemerintah Provinsi Sumatera Barat • Dinas Pariwisata',
                style: TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
              const Divider(height: 24),
              const Text(
                'Diberikan kepada Pengembara Budaya:',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              const Text(
                'Wisatawan Teladan Ranah Minang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Telah resmi mengunjungi dan mematuhi tata tertib kelestarian alam di ${widget.destinationTitle}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nomor Sertifikat:', style: TextStyle(fontSize: 9, color: AppColors.muted)),
                      Text(
                        '#WG-CERT-${DateTime.now().year}-08492',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Status Verifikasi:', style: TextStyle(fontSize: 9, color: AppColors.muted)),
                      const Text('Terkonfirmasi Pokdarwis', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.forest)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isDownloadingCertificate ? null : _downloadCertificate,
            icon: _isDownloadingCertificate
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(
              _isDownloadingCertificate ? 'Menyiapkan Berkas PDF Sertifikat...' : 'Unduh Sertifikat Kunjungan Resmi (PDF)',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityForumView() {
    return Column(
      children: [
        // Question list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: _questions.length,
            itemBuilder: (ctx, idx) {
              final q = _questions[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          q.author,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        Text(
                          q.time,
                          style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.question,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    if (q.localAnswer != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFECE2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded, size: 12, color: AppColors.forest),
                                const SizedBox(width: 4),
                                Text(
                                  q.answerAuthor ?? 'Warga Lokal Nagari',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              q.localAnswer!,
                              style: const TextStyle(fontSize: 11, color: AppColors.forest, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Input text bar for asking new questions
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.warmBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tanyakan sesuatu kepada warga lokal nagari...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.creamSubtle,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.warmBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submitQuestion,
                icon: const Icon(Icons.send_rounded, color: AppColors.forest),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
