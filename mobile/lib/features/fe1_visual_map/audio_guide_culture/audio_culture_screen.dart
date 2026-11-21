import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/localization/app_locale.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';
import '../map_explore_shunlu/map_explore_screen.dart';

/// Modul FE-1: Kamus Saku Audio Minang & Kalender Budaya (Pilar 1)
class AudioCultureScreen extends StatefulWidget {
  final bool embedded;
  final Set<String>? remindedFestivalIds;
  final void Function(Map<String, dynamic> festival)? onToggleReminder;
  final void Function(Map<String, dynamic> festival)? onNavigateToGps;
  final List<Map<String, dynamic>>? festivals;

  const AudioCultureScreen({
    super.key,
    this.embedded = false,
    this.remindedFestivalIds,
    this.onToggleReminder,
    this.onNavigateToGps,
    this.festivals,
  });

  @override
  State<AudioCultureScreen> createState() => _AudioCultureScreenState();
}
class _AudioCultureScreenState extends State<AudioCultureScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _internalRemindedFestivalIds = {'ev_harau'};
  Set<String> get _remindedIds => widget.remindedFestivalIds ?? _internalRemindedFestivalIds;
  List<Map<String, dynamic>> get _festivalList => widget.festivals ?? _defaultFestivals;

  static final List<Map<String, dynamic>> _defaultFestivals = [
    {
      'id': 'ev_harau',
      'title': 'Festival Pasa Harau 2026',
      'date': '18 – 20 Desember 2026',
      'time': '08:00 – 22:00 WIB',
      'location': 'Lembah Harau, Kab. Lima Puluh Kota',
      'venue': 'Area Terbuka Tebing Granit Lembah Harau',
      'desc': 'Pagelaran akbar seni adat, randai tradisional, musik saluang, & kuliner nagari di bawah tebing granit.',
      'badge': 'Festival Adat Resmi',
      'badgeColor': 0xFF5A3E85,
      'badgeBg': 0xFFF3EDFA,
      'lat': -0.1008,
      'lng': 100.6728,
      'gpsCoordinate': '-0.1008, 100.6728',
      'imageUrl': 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?w=800',
      'longDesc': 'Festival Pasa Harau adalah perayaan kebudayaan tahunan Minangkabau terbesar di Lembah Harau. Diapit tebing granit raksasa setinggi 100-300 meter, festival ini menampilkan teater tradisional Randai, pertunjukan musik Saluang & Gandang Tambua, pameran kuliner legendaris 50 Kota, serta pergelaran busana tenun songket khas Luak Limopuluah.',
      'rundown': [
        'Hari 1: Pawai Budaya Adat 100 Gandang & Pembukaan Resmi Nagari',
        'Hari 2: Randai Semalam Suntuk, Pacu Terbang Itiak & Tari Piring Kolosal',
        'Hari 3: Pasar Kuliner Tradisional Bajamba & Penutupan Obor Silat Minang'
      ],
      'tips': 'Gunakan pakaian sopan (baju kuruang/koko direkomendasikan). Bawalah payung/jas hujan ringan dan uang tunai untuk membeli kuliner nagari di tenda UMKM masyarakat adat.',
    },
    {
      'id': 'ev_pacu_jawi',
      'title': 'Pacu Jawi Tradisional Luhak Nan Tuo',
      'date': '24 – 25 Januari 2027',
      'time': '09:00 – 16:30 WIB',
      'location': 'Nagari Pariangan & Sungai Tarab, Kab. Tanah Datar',
      'venue': 'Sawah Basah Luhak Nan Tuo',
      'desc': 'Atraksi balapan sapi di sawah berlumpur khas Minang yang telah mendunia, sarat tradisi pascapanen.',
      'badge': 'Kearifan Lokal',
      'badgeColor': 0xFF15803D,
      'badgeBg': 0xFFDCFCE7,
      'lat': -0.4578,
      'lng': 100.5694,
      'gpsCoordinate': '-0.4578, 100.5694',
      'imageUrl': 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800',
      'longDesc': 'Pacu Jawi adalah pesta rakyat warisan leluhur Luhak Nan Tuo yang diselenggarakan di sawah basah setelah panen padi. Sepasang jawi (sapi) dipacu joki yang berpijak pada bajak kayu bambu. Selain menguji ketangkasan joki, acara ini menjadi simbol rasa syukur panen nagari dan sarana silaturahmi antar-desa.',
      'rundown': [
        '09:00 WIB: Ritual Doa Tolak Bala & Arak-arakan Jawi Hias Nagari',
        '10:30 WIB: Babak Pacuan Sawah Berlumpur Sesi Pagi',
        '12:30 WIB: Istirahat Makan Bajamba di Dangau Sawah',
        '14:00 WIB: Babak Final Pacu Cepat & Penjurian Nilai Sapi Terbaik'
      ],
      'tips': 'Gunakan sepatu boots anti-lumpur atau sandal gunung yang kuat. Jaga jarak aman minimal 3 meter dari bibir pematang sawah saat sapi sedang dipacu.',
    },
    {
      'id': 'ev_maninjau',
      'title': 'Festival Pesona Danau Maninjau 2026',
      'date': '12 – 14 November 2026',
      'time': '08:30 – 21:00 WIB',
      'location': 'Tanjung Raya, Kab. Agam (Kelok 44)',
      'venue': 'Tepian Danau Maninjau & Puncak Lawang',
      'desc': 'Paragliding internasional Puncak Lawang, lomba selancar sampan dayung tradisional, dan kuliner rinuak.',
      'badge': 'Pariwisata Danau',
      'badgeColor': 0xFF0284C7,
      'badgeBg': 0xFFE0F2FE,
      'lat': -0.3134,
      'lng': 100.1887,
      'gpsCoordinate': '-0.3134, 100.1887',
      'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      'longDesc': 'Festival Pesona Danau Maninjau mengintegrasikan keindahan kaldera vulkanik Danau Maninjau dengan atraksi dirgantara dan kearifan lokal nelayan selingkar danau. Acara meliputi paralayang dari Puncak Lawang mendarat di Danau, parade biduak tradisional, serta festival masakan rinuak khas Maninjau.',
      'rundown': [
        'Hari 1: Lepas Landas Paralayang Puncak Lawang & Pameran Ikan Rinuak',
        'Hari 2: Lomba Biduak (Sampan Dayung) Tradisional se-Selingkar Danau',
        'Hari 3: Pentas Musik Akustik Tradisional Dermaga & Pelepasan Bibit Ikan Endemik'
      ],
      'tips': 'Waktu terbaik melihat pemandangan danau bebas kabut adalah pukul 08:30-11:00 WIB. Bagi penderita mabuk kendaraan, siapkan obat sebelum melintasi jalur Kelok 44.',
    },
    {
      'id': 'ev_tabuik',
      'title': 'Pesta Budaya Tabuik Pariaman',
      'date': '05 – 16 Juli 2026',
      'time': '07:00 – 18:30 WIB',
      'location': 'Pantai Gandoriah & Pusat Kota Pariaman',
      'venue': 'Plaza Tabuik & Pantai Gandoriah',
      'desc': 'Puncak perayaan adat marasai dan pembuangan menara Tabuik setinggi 12 meter ke laut lepas saat senja.',
      'badge': 'Warisan Budaya Nasional',
      'badgeColor': 0xFFD97706,
      'badgeBg': 0xFFFEF3C7,
      'lat': -0.6272,
      'lng': 100.1177,
      'gpsCoordinate': '-0.6272, 100.1177',
      'imageUrl': 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800',
      'longDesc': 'Pesta Budaya Tabuik merupakan perhelatan kolosal masyarakat pesisir Pariaman yang telah diakui sebagai Warisan Budaya Takbenda Nasional. Dua menara Tabuik (Pasa dan Subarang) diarak oleh ribuan warga dengan tabuhan gendang tassa yang membahana, sebelum diakhiri dengan prosesi sakral pelarungan ke Samudera Hindia menjelang matahari terbenam.',
      'rundown': [
        '07:00 WIB: Prosesi Tabuik Naik Pangkek di Rumah Gadang Masing-masing Luhak',
        '10:30 WIB: Arak-arakan Tabuik Pasa & Subarang Menuju Lapangan Merdeka',
        '14:00 WIB: Atraksi Perang Gendang Tassa & Goyang Tabuik di Tepi Pantai',
        '17:30 WIB: Puncak Pelarungan Menara Tabuik ke Tengah Samudera Hindia'
      ],
      'tips': 'Kerumunan penonton sangat padat di Pantai Gandoriah saat matahari terbenam. Amankan barang berharga dan gunakan transportasi kereta api bandara/Pariaman Ekspres untuk menghindari kemacetan total jalur darat.',
    },
    {
      'id': 'ev_batagak',
      'title': 'Batagak Panghulu & Alek Nagari',
      'date': '03 – 05 Oktober 2026',
      'time': '09:00 – 17:00 WIB',
      'location': 'Nagari Sumpur, Tepian Danau Singkarak',
      'venue': 'Kompleks Rumah Gadang Sumpur',
      'desc': 'Upacara sakral pengangkatan datuk / penghulu kaum adat dengan jamuan bajamba adat 50 nampan kuningan.',
      'badge': 'Upacara Adat Sakral',
      'badgeColor': 0xFF7C3AED,
      'badgeBg': 0xFFF5F3FF,
      'lat': -0.5361,
      'lng': 100.5283,
      'gpsCoordinate': '-0.5361, 100.5283',
      'imageUrl': 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800',
      'longDesc': 'Batagak Panghulu adalah alek nagari (pesta adat desa) sakral penobatan pemimpin kaum/suku adat Minangkabau. Diselenggarakan di pelataran Rumah Gadang beratap gonjong berusia ratusan tahun, tamu kehormatan disambut dengan tari gelombang, carano sirih pinang, dan tradisi makan bajamba dengan tata cara adat Minang yang otentik.',
      'rundown': [
        '09:00 WIB: Pasambahan Adat Sirih Carano & Penyambutan Ninik Mamak Luhak',
        '11:00 WIB: Pemasangan Saluk & Keris Pusaka Pengukuhan Gala Datuk',
        '12:30 WIB: Jamuan Makan Bajamba Sepanjang Selasar Rumah Gadang',
        '15:00 WIB: Pagelaran Seni Silat Tradisional & Pidato Petatah-Petitih Adat'
      ],
      'tips': 'Wajib melepas alas kaki saat menaiki tangga Rumah Gadang. Ikuti aba-aba protokol adat ninik mamak sebelum mencicipi hidangan jamba.',
    },
  ];

  void _handleToggleReminder(Map<String, dynamic> ev, [StateSetter? setModalState]) {
    final id = ev['id'] as String;
    final currentlyActive = _remindedIds.contains(id);

    if (widget.onToggleReminder != null) {
      widget.onToggleReminder!(ev);
    } else {
      setState(() {
        if (currentlyActive) {
          _internalRemindedFestivalIds.remove(id);
        } else {
          _internalRemindedFestivalIds.add(id);
        }
      });
      final activeNow = _internalRemindedFestivalIds.contains(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activeNow
                ? 'Pengingat aktif! Notifikasi pengingat untuk ${ev["title"]} telah dijadwalkan.'
                : 'Pengingat untuk ${ev["title"]} telah dinonaktifkan.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          backgroundColor: activeNow ? const Color(0xFF193D22) : const Color(0xFF142618),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (setModalState != null) {
      setModalState(() {});
    }
    setState(() {});
  }

  void _handleNavigateToGps(Map<String, dynamic> ev) {
    if (widget.onNavigateToGps != null) {
      widget.onNavigateToGps!(ev);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5DEC9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF193D22).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.near_me_rounded, size: 20, color: Color(0xFF193D22)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navigasi Langsung ke GPS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF142618),
                          ),
                        ),
                        Text(
                          ev['location'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5A6B5D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EBDC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5DEC9)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Titik Koordinat GPS:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5A6B5D)),
                        ),
                        Text(
                          ev['gpsCoordinate'] as String,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: Color(0xFF193D22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Target Acara:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5A6B5D)),
                        ),
                        Expanded(
                          child: Text(
                            ev['title'] as String,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF142618)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapExploreShunluScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text(
                    'Buka Peta WisGo (Jelajah Interaktif)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF193D22),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ev['gpsCoordinate'] as String));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Koordinat GPS ${ev["gpsCoordinate"]} berhasil disalin ke clipboard!',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFF142618),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF142618)),
                  label: const Text(
                    'Salin Koordinat GPS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF142618)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5DEC9)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openKalenderBudayaModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final festivals = _festivalList;

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF3E6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DEC9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WARISAN & PERAYAAN NAGARI',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Color(0xFF5A3E85),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kalender Acara Budaya Minang',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF142618),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF5A6B5D)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5DEC9)),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: festivals.length,
                      itemBuilder: (context, idx) {
                        final ev = festivals[idx];
                        final isReminded = _remindedIds.contains(ev['id']);
                        final badgeColor = Color(ev['badgeColor'] as int? ?? 0xFF5A3E85);
                        final badgeBg = Color(ev['badgeBg'] as int? ?? 0xFFF3EDFA);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isReminded ? const Color(0xFF193D22).withValues(alpha: 0.6) : const Color(0xFFD5E2D7),
                              width: isReminded ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF142618).withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                _openFestivalDetailModal(ev);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ev['badge'] as String,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            if (isReminded) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.notifications_active_rounded, size: 10, color: Color(0xFF15803D)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Pengingat Aktif',
                                                      style: TextStyle(
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFF15803D),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF5A6B5D)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  ev['date'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF193D22),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ev['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF142618),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF2F663E)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            ev['location'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF5A6B5D),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ev['desc'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF5A6B5D),
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3EBDC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE5DEC9)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF193D22)),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'GPS: ${ev["gpsCoordinate"]}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF193D22),
                                              ),
                                            ),
                                          ),
                                          const Text(
                                            'Lihat Detail & Rute',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF142618),
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF142618)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFestivalDetailModal(Map<String, dynamic> ev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (detailCtx, setDetailState) {
            final isReminded = _remindedIds.contains(ev['id']);
            final badgeColor = Color(ev['badgeColor'] as int? ?? 0xFF5A3E85);
            final badgeBg = Color(ev['badgeBg'] as int? ?? 0xFFF3EDFA);
            final rundown = ev['rundown'] as List<String>? ?? [];

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DEC9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ev['badge'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Detail Acara Budaya',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5A6B5D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF5A6B5D)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5DEC9)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      children: [
                        Text(
                          ev['title'] as String,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF142618),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EBDC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5DEC9)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF193D22)),
                                  const SizedBox(width: 5),
                                  Text(
                                    ev['date'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF193D22),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EBDC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5DEC9)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF5A6B5D)),
                                  const SizedBox(width: 5),
                                  Text(
                                    ev['time'] as String? ?? '08:00 WIB',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF142618),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBF8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF193D22).withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF193D22),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ev['location'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF142618),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          ev['venue'] as String? ?? 'Sumatera Barat',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5A6B5D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFD5E2D7)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.my_location_rounded, size: 13, color: Color(0xFF193D22)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Titik GPS: ${ev["gpsCoordinate"]}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          color: Color(0xFF193D22),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _handleNavigateToGps(ev);
                                  },
                                  icon: const Icon(Icons.near_me_rounded, size: 16),
                                  label: const Text(
                                    'Arahkan ke Lokasi GPS',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF193D22),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tentang Acara & Nilai Budaya',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF142618),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ev['longDesc'] as String? ?? ev['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF142618),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (rundown.isNotEmpty) ...[
                          const Text(
                            'Rangkaian Acara Utama',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF142618),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...rundown.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(top: 6, right: 8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2F663E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF142618),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 14),
                        ],
                        if (ev['tips'] != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tata Krama & Tips Kunjungan Nagari',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        ev['tips'] as String,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF78350F),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EBDC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5DEC9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isReminded ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                    size: 18,
                                    color: isReminded ? const Color(0xFF15803D) : const Color(0xFF142618),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isReminded ? 'Pengingat Festival Aktif' : 'Pasang Pengingat Acara',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: isReminded ? const Color(0xFF15803D) : const Color(0xFF142618),
                                          ),
                                        ),
                                        Text(
                                          isReminded
                                              ? 'Anda akan menerima notifikasi otomatis di hari acara.'
                                              : 'Dapatkan pemberitahuan otomatis saat mendekati jadwal festival.',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF5A6B5D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _handleToggleReminder(ev, setDetailState);
                                  },
                                  icon: Icon(
                                    isReminded ? Icons.check_circle_rounded : Icons.add_alert_rounded,
                                    size: 16,
                                    color: isReminded ? const Color(0xFF15803D) : const Color(0xFF193D22),
                                  ),
                                  label: Text(
                                    isReminded ? 'Pengingat Aktif (Ketuk untuk Batalkan)' : 'Aktifkan Pengingat Acara',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isReminded ? const Color(0xFF15803D) : const Color(0xFF193D22),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isReminded ? const Color(0xFF15803D) : const Color(0xFF193D22),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
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
            );
          },
        );
      },
    );
  }

  final DestinationRepository _repository = DestinationRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  late TabController _tabController;

  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;
  Duration _currentDuration = Duration.zero;

  static const Set<String> _bundledAudioIds = {
    'phr-1',
    'phr-2',
    'phr-3',
    'phr-4',
    'phr-5',
    'phr-6',
    'phr-7',
    'phr-8',
  };

  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String? _currentlyPlayingId;
  bool _isAudioPlaying = false;
  double _playbackProgress = 0.0;

  List<MinangPhraseModel> _phrases = [];
  List<CulturalEventModel> _culturalEvents = [];
  bool _isLoading = true;

  static const List<String> _phraseCategories = [
    'Semua',
    'Kuliner',
    'Pasar & Belanja',
    'Sapaan Nagari',
    'Arah & Navigasi',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initAudioPlayer();
    _initTts();
    _loadCultureData();
  }

  void _initAudioPlayer() {
    try {
      _durationSub = _audioPlayer.onDurationChanged.listen((d) {
        if (!mounted) return;
        _currentDuration = d;
      });
      _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
        if (!mounted || !_isAudioPlaying) return;
        final totalMs = _currentDuration.inMilliseconds;
        if (totalMs > 0) {
          setState(() {
            _playbackProgress = (pos.inMilliseconds / totalMs).clamp(0.05, 1.0);
          });
        }
      });
      _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _isAudioPlaying = false;
          _currentlyPlayingId = null;
          _playbackProgress = 0.0;
        });
      });
    } on MissingPluginException {
      // Aman saat widget test
    } catch (_) {}
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
    } on MissingPluginException {
      // Aman saat dijalankan di environment widget test tanpa channel native
    } catch (_) {}
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    try {
      _audioPlayer.dispose();
    } catch (_) {}
    try {
      _flutterTts.stop();
    } catch (_) {}
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCultureData() async {
    setState(() => _isLoading = true);
    final phrases = await _repository.getCulturePhrases();
    final events = await _repository.getCulturalEvents();

    if (!mounted) return;
    setState(() {
      _phrases = phrases;
      _culturalEvents = events;
      _isLoading = false;
    });
  }

  String _prepareSpeechText(MinangPhraseModel phrase) {
    return phrase.minangText
        .replaceAll('/', ' atau ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _playPhrase(MinangPhraseModel phrase) async {
    final isStoppingSame = _currentlyPlayingId == phrase.id && _isAudioPlaying;

    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}

    if (isStoppingSame) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
        _currentlyPlayingId = null;
        _playbackProgress = 0.0;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _currentlyPlayingId = phrase.id;
      _isAudioPlaying = true;
      _playbackProgress = 0.12;
      _currentDuration = Duration.zero;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.green800,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.pinAudioEmas),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memutar Suara: "${phrase.minangText}"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Lafal: ${phrase.phoneticGuide} (${phrase.dialectNote})',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 1. Utamakan memutar file audio MP3 asli via rootBundle + BytesSource
    // (100% kompatibel lintas platform: Web Chrome/Edge, Windows, Android & iOS)
    if (_bundledAudioIds.contains(phrase.id)) {
      try {
        final byteData = await rootBundle.load('assets/audio/${phrase.id}.mp3');
        final bytes = byteData.buffer.asUint8List();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.play(
          BytesSource(bytes, mimeType: 'audio/mpeg'),
        );
        return;
      } on MissingPluginException catch (e) {
        debugPrint('[KamusAudio] Plugin audioplayers belum terdaftar (perlu restart penuh flutter run): $e');
      } catch (e) {
        debugPrint('[KamusAudio] Gagal memutar MP3 lokal ${phrase.id}: $e');
      }
    }

    // 2. Fallback: TTS sistem perangkat untuk frasa dinamis tambahan
    final speechText = _prepareSpeechText(phrase);
    var spokeNatively = false;
    try {
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.speak(speechText);
      spokeNatively = true;
    } on MissingPluginException {
      spokeNatively = false;
    } catch (_) {
      spokeNatively = false;
    }

    if (!spokeNatively) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _currentlyPlayingId == phrase.id) {
          setState(() {
            _isAudioPlaying = false;
            _currentlyPlayingId = null;
            _playbackProgress = 0.0;
          });
        }
      });
    } else if (mounted && _currentlyPlayingId == phrase.id) {
      setState(() {
        _isAudioPlaying = false;
        _currentlyPlayingId = null;
        _playbackProgress = 0.0;
      });
    }
  }

  String _categoryLabel(String cat) {
    if (!AppLocale.isEn) return cat;
    switch (cat) {
      case 'Semua':
        return 'All';
      case 'Kuliner':
        return 'Culinary';
      case 'Pasar & Belanja':
        return 'Market & Shopping';
      case 'Sapaan Nagari':
        return 'Greetings';
      case 'Arah & Navigasi':
        return 'Directions';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.notifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.cream100,
          appBar: AppBar(
            automaticallyImplyLeading: !widget.embedded,
            title: Text(
              widget.embedded
                  ? AppLocale.tr(
                      'Kamus Minang & Budaya',
                      'Minang Dictionary & Culture',
                    )
                  : AppLocale.tr(
                      'Kamus Saku Audio & Budaya Minang',
                      'Minang Pocket Audio & Culture',
                    ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: LanguageTogglePill(compact: true)),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.green800,
              indicatorWeight: 3,
              labelColor: AppColors.green800,
              unselectedLabelColor: Colors.black54,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  text: AppLocale.tr(
                    'Kamus Audio Minang',
                    'Minang Audio Dictionary',
                  ),
                ),
                Tab(
                  text: AppLocale.tr('Kalender Budaya', 'Culture Calendar'),
                ),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.green800),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildKamusAudioTab(),
                    _buildKalenderBudayaTab(),
                  ],
                ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 1: KAMUS SAKU AUDIO MINANG
  // ===========================================================================
  Widget _buildKamusAudioTab() {
    final filteredPhrases = _phrases.where((p) {
      final matchCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          p.minangText.toLowerCase().contains(q) ||
          p.indonesianText.toLowerCase().contains(q) ||
          p.englishText.toLowerCase().contains(q) ||
          p.usageContextTip.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, widget.embedded ? 124 : 32),
      children: [
        // BANNER INTRODUKSI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.indigo500.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: AppColors.indigo500,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.tr(
                        'Pemandu Bahasa Minang Asli',
                        'Authentic Minang Phrase Guide',
                      ),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr(
                        'Lafal frasa otentik dengan prinsip Kato Nan Ampek (Adat Basandi Syarak).',
                        'Authentic local phrases with audio, ID & EN meanings for speaking with locals.',
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // PENCARIAN FRASA
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: AppLocale.tr(
                'Cari kata Minang, Indonesia, atau English...',
                'Search Minang, Indonesian, or English phrases...',
              ),
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: const Icon(Icons.search, color: AppColors.green800),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // FILTER KATEGORI CHIP
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _phraseCategories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_categoryLabel(cat)),
                  selected: isSelected,
                  selectedColor: AppColors.green800,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink900,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // HEADER SECTION KAMUS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppLocale.tr(
                  'Daftar Frasa Budaya & Pasar',
                  'Cultural & Market Phrases',
                ),
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocale.tr(
                '${filteredPhrases.length} frasa',
                '${filteredPhrases.length} phrases',
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // DAFTAR KARTU AUDIO
        ...filteredPhrases.map((phrase) {
          final isPlaying = _currentlyPlayingId == phrase.id && _isAudioPlaying;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isPlaying ? AppColors.green800 : Colors.black.withValues(alpha: 0.06),
                width: isPlaying ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPlaying
                      ? AppColors.green800.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: isPlaying ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Kategori & Badges Kato Nan Ampek
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sage100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phrase.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phrase.politenessLevel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Teks Minang & Tombol Putar Audio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phrase.minangText,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${AppLocale.tr('Lafal:', 'Pronunciation:')} [ ${phrase.phoneticGuide} ]',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Putar Interaktif
                    GestureDetector(
                      onTap: () => _playPhrase(phrase),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPlaying ? AppColors.green800 : AppColors.sage100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isPlaying ? Colors.white : AppColors.green800,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                // Visual Soundwave Bar jika sedang diputar
                if (isPlaying) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _playbackProgress,
                      backgroundColor: AppColors.sage100,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green800),
                      minHeight: 4,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Arti Bahasa Indonesia & Bahasa Inggris (Bilingual ID & EN)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sage100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'ID',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '"${phrase.indonesianText}"',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (phrase.englishText.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1F8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'EN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E5B82),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '"${phrase.englishText}"',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E4A68),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 12, color: AppColors.orange500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phrase.usageContextTip,
                        style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: KALENDER BUDAYA & HARI PAKAN NAGARI
  // ===========================================================================
  Widget _buildKalenderBudayaTab() {
    final festivals = _festivalList;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, widget.embedded ? 124 : 32),
      children: [
        // =====================================================================
        // KARTU 1: BANNER FITUR KALENDER EVENT & FESTIVAL BUDAYA (PERSIS DARI OPEN TRIP)
        // =====================================================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6A3EA1).withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A3EA1).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDFA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF6A3EA1)),
                        SizedBox(width: 4),
                        Text(
                          'Agenda & Event',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6A3EA1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.calendar_month_outlined, color: Color(0xFF6A3EA1), size: 22),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Kalender Event & Festival Budaya',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF142618),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lihat jadwal festival budaya, pertunjukan kesenian randai, pacu jawi, dan agenda wisata tahunan resmi di Sumatera Barat.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5A6B5D),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _openKalenderBudayaModal(context),
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text(
                    'Buka Kalender Event',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3E85),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // =====================================================================
        // SECTION 2: AGENDA FESTIVAL TAHUNAN RESMI (LIST INTERAKTIF LENGKAP)
        // =====================================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'AGENDA FESTIVAL TAHUNAN RESMI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Color(0xFF5A3E85),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${festivals.length} Festival',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5A3E85),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List Festival Cards
        ...festivals.map((ev) {
          final isReminded = _remindedIds.contains(ev['id']);
          final badgeColor = Color(ev['badgeColor'] as int? ?? 0xFF5A3E85);
          final badgeBg = Color(ev['badgeBg'] as int? ?? 0xFFF3EDFA);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isReminded ? const Color(0xFF193D22).withValues(alpha: 0.6) : const Color(0xFFD5E2D7),
                width: isReminded ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF142618).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openFestivalDetailModal(ev),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ev['badge'] as String,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isReminded) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notifications_active_rounded, size: 10, color: Color(0xFF15803D)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Pengingat Aktif',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF5A6B5D)),
                                  const SizedBox(width: 4),
                                  Text(
                                    ev['date'] as String,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF193D22),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ev['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF142618),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF2F663E)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ev['location'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5A6B5D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ev['desc'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF5A6B5D),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EBDC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5DEC9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF193D22)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'GPS: ${ev["gpsCoordinate"]}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF193D22),
                                ),
                              ),
                            ),
                            const Text(
                              'Lihat Detail & Rute',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF142618),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF142618)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // =====================================================================
        // SECTION 3: PASAR TRADISIONAL & HARI PAKAN NAGARI
        // =====================================================================
        const Text(
          'PASAR TRADISIONAL & HARI PAKAN NAGARI',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Color(0xFF1E5B82),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE89F3C).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.orange500, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.tr(
                        'Kalender Adat & Hari Pakan',
                        'Cultural & Market Day Calendar',
                      ),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hari Pakan adalah hari pasar tradisional bergilir nagari tempat warga menjual kuliner otentik.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ..._culturalEvents.map((evt) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green800.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          evt.badge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green800,
                          ),
                        ),
                      ),
                      Text(
                        evt.cityRegency,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evt.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 13, color: AppColors.coral500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evt.scheduleRule,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.coral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evt.nagariLocation,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evt.description,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
