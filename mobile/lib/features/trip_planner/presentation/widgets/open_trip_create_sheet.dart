import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';
import '../../utils/organizer_media_helper.dart';

/// Form Buat Open Trip Baru
/// Memenuhi Persyaratan:
/// 1. Open Trip HANYA memiliki 1 tujuan/destinasi dalam satu perjalanan.
/// 2. Kategori perjalanan ditentukan secara OTOMATIS berdasarkan destinasi yang dipilih.
/// 3. Transaksi dilakukan langsung melalui sistem WISGO.
/// 5. Titik kumpul Google Maps.
/// 6. Mekanisme verifikasi penyelenggara.
/// 7. Ketentuan aktivitas luar aplikasi.
class OpenTripCreateSheet extends StatefulWidget {
  final Function(OpenTripItem) onTripCreated;

  const OpenTripCreateSheet({
    super.key,
    required this.onTripCreated,
  });

  @override
  State<OpenTripCreateSheet> createState() => _OpenTripCreateSheetState();
}

class _OpenTripCreateSheetState extends State<OpenTripCreateSheet> {
  // Daftar Destinasi Tunggal Resmi Sumatera Barat (5 Kluster Kategori Induk)
  final List<String> _availableSingleDestinations = [
    'Lembah Harau & Sarasah Bunta',
    'Jam Gadang Bukittinggi',
    'Istano Basa Pagaruyung',
    'Ekowisata Air Terjun Nyarai',
    'Kawasan Bahari Mandeh',
    'Jembatan Akar Bayang',
    'Desa Wisata Nagari Tuo Pariangan',
    'Masjid Raya Sumatera Barat',
    'Los Lambuang Nasi Kapau Pasar Ateh',
    'Danau Singkarak & Kuliner Ikan Bilih',
  ];

  late String _selectedSingleDestination;
  late String _autoDeterminedCategory;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quotaMaxController = TextEditingController();

  // Titik Kumpul Terintegrasi Google Maps
  static const Map<String, Map<String, dynamic>> _meetingPointsByDestination = {
    'Lembah Harau & Sarasah Bunta': {
      'name': 'Rest Area Simpang Harau',
      'address': 'Jl. Raya Payakumbuh-Harau KM 8, Kab. Lima Puluh Kota',
      'lat': -0.1132,
      'lng': 100.6721,
    },
    'Jam Gadang Bukittinggi': {
      'name': 'Pelataran Jam Gadang',
      'address': 'Jl. Raya Pasar Ateh, Guguk Panjang, Kota Bukittinggi',
      'lat': -0.3052,
      'lng': 100.3692,
    },
    'Istano Basa Pagaruyung': {
      'name': 'Gerbang Utama Istano Basa Pagaruyung',
      'address': 'Nagari Pagaruyung, Kec. Tanjung Emas, Kab. Tanah Datar',
      'lat': -0.4712,
      'lng': 100.6214,
    },
    'Ekowisata Air Terjun Nyarai': {
      'name': 'Posko Pokdarwis LA Nyarai',
      'address': 'Korong Gamaran, Salibutan Lubuk Alung, Kab. Padang Pariaman',
      'lat': -0.6654,
      'lng': 100.2981,
    },
    'Kawasan Bahari Mandeh': {
      'name': 'Dermaga TPI Carocok Tarusan',
      'address': 'Kawasan Wisata Mandeh, Koto XI Tarusan, Kab. Pesisir Selatan',
      'lat': -1.2135,
      'lng': 100.4158,
    },
    'Jembatan Akar Bayang': {
      'name': 'Area Parkir Jembatan Akar Pulut-Pulut',
      'address': 'Nagari Pulut-Pulut, Kec. IV Nagari Bayang Utara, Pesisir Selatan',
      'lat': -1.2491,
      'lng': 100.5944,
    },
    'Desa Wisata Nagari Tuo Pariangan': {
      'name': 'Masjid Ishlah & Balai Adat Pariangan',
      'address': 'Nagari Pariangan, Kec. Pariangan, Kab. Tanah Datar',
      'lat': -0.4534,
      'lng': 100.5112,
    },
    'Masjid Raya Sumatera Barat': {
      'name': 'Pelataran Timur Masjid Raya Sumbar',
      'address': 'Jl. Khatib Sulaiman, Alai Parak Kopi, Kota Padang',
      'lat': -0.9242,
      'lng': 100.3623,
    },
    'Los Lambuang Nasi Kapau Pasar Ateh': {
      'name': 'Pintu Masuk Pasar Ateh / Los Lambuang',
      'address': 'Jl. Pasar Atas, Benteng Pasar Atas, Kota Bukittinggi',
      'lat': -0.3046,
      'lng': 100.3698,
    },
    'Danau Singkarak & Kuliner Ikan Bilih': {
      'name': 'Dermaga Wisata Batu Taba Singkarak',
      'address': 'Jl. Lintas Sumatera Batu Taba, Kec. Batipuh Selatan, Tanah Datar',
      'lat': -0.6184,
      'lng': 100.5318,
    },
  };

  late String _meetingPointName;
  late String _meetingAddress;
  late double _meetingLat;
  late double _meetingLng;
  String get _googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$_meetingLat,$_meetingLng';
  final TextEditingController _hostNameController = TextEditingController();
  final TextEditingController _hostLicenseController = TextEditingController();
  final TextEditingController _hostPhoneController = TextEditingController();
  final TextEditingController _hostSocialController = TextEditingController();
  final TextEditingController _hostExperienceController = TextEditingController();

  DateTime _departureDate = DateTime(2026, 12, 12);
  TimeOfDay _departureTime = const TimeOfDay(hour: 6, minute: 30);
  int _wizardStep = 0; // 0: Data Diri, 1: KTP & Wajah, 2: Detail Trip
  bool _hasUploadedKtp = false;
  PickedPhotoResult? _ktpPhoto;
  bool _hasVerifiedFace = false;
  String _difficultyLevel = 'Medium'; // 'Easy' | 'Medium' | 'Hard'
  bool get _isHardRoute => _difficultyLevel == 'Hard';
  bool _hasUploadedLicense = false;
  PickedPhotoResult? _licensePhoto;

  // Itinerary Rundown yang diisi manual oleh pembuat trip (Sistem sediakan slot jam)
  late List<TripItineraryStep> _itinerarySteps;

  // Fasilitas Include & Exclude yang diinput penyelenggara (berbeda tiap tempat)
  final List<String> _includes = [
    'Tiket masuk wisata',
    'Pemandu perjalanan',
    'Air mineral & P3K',
  ];
  final List<String> _excludes = [
    'Pengeluaran pribadi',
    'Transportasi menuju titik kumpul',
  ];

  // Peraturan / SOP Khusus Destinasi yang diinput penyelenggara
  final List<OfflineTripRule> _offlineRules = [
    const OfflineTripRule(
      title: 'Toleransi Waktu Titik Kumpul 15 Menit',
      ruleDescription: 'Peserta wajib hadir di meeting point sesuai jadwal keberangkatan.',
      iconCode: 'schedule',
    ),
    const OfflineTripRule(
      title: 'Patuhi Instruksi Pemandu & Etika Lokasi',
      ruleDescription: 'Dilarang membuang sampah sembarangan atau keluar dari jalur rombongan.',
      iconCode: 'warning',
    ),
  ];

  void _applyGoogleMapsPointFor(String dest) {
    final preset = _meetingPointsByDestination[dest] ??
        _meetingPointsByDestination.values.first;
    _meetingPointName = preset['name'] as String;
    _meetingAddress = preset['address'] as String;
    _meetingLat = preset['lat'] as double;
    _meetingLng = preset['lng'] as double;
  }

  @override
  void initState() {
    super.initState();
    _selectedSingleDestination = _availableSingleDestinations.first;
    _autoDeterminedCategory = determineCategoryForDestination(_selectedSingleDestination);
    _titleController.text = 'Eksplorasi $_selectedSingleDestination';
    _applyGoogleMapsPointFor(_selectedSingleDestination);

    // Inisialisasi rundown default dengan jam dari sistem untuk diisi/diubah pembuat trip
    _itinerarySteps = [
      TripItineraryStep(
        time: '06.30 - 07.30 WIB',
        activity: 'Kumpul di Meeting Point & Briefing Tim',
        location: _meetingPointName,
        notes: 'Presensi peserta, doa bersama & pembagian ID card rombongan',
        status: 'Akan Datang',
        icon: Icons.flag_rounded,
      ),
      TripItineraryStep(
        time: '07.30 - 11.30 WIB',
        activity: 'Eksplorasi Destinasi Utama & Trekking Alam',
        location: _selectedSingleDestination,
        notes: 'Aktivitas eksplorasi dipandu pemandu lokal bersertifikat',
        status: 'Akan Datang',
        icon: Icons.landscape_rounded,
      ),
      TripItineraryStep(
        time: '11.30 - 13.00 WIB',
        activity: 'Ishoma & Santap Kuliner Minang',
        location: 'Gazebo / Rest Area Nagari',
        notes: 'Makan siang bersama sajian khas lokal nagari',
        status: 'Akan Datang',
        icon: Icons.restaurant_rounded,
      ),
      TripItineraryStep(
        time: '13.00 - 16.30 WIB',
        activity: 'Sesi Foto Dokumentasi Bebas & Penutupan Trip',
        location: _selectedSingleDestination,
        notes: 'Foto bersama dan persiapan kembali ke titik asal',
        status: 'Akan Datang',
        icon: Icons.camera_alt_rounded,
      ),
    ];
  }

  void _showAddOrEditItineraryDialog({int? editIndex}) {
    final isEditing = editIndex != null;
    final existingStep = isEditing ? _itinerarySteps[editIndex] : null;

    final activityCtrl = TextEditingController(text: existingStep?.activity ?? '');
    final locationCtrl = TextEditingController(
      text: existingStep != null ? existingStep.location : _selectedSingleDestination,
    );
    final notesCtrl = TextEditingController(text: existingStep?.notes ?? '');

    // Waktu yang disediakan sistem (slot jam)
    String selectedTimeRange = existingStep?.time ?? '08.00 - 09.30 WIB';
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 30);

    // Preset jam rundown yang disediakan sistem
    final systemPresetHours = [
      '06.00 - 07.00 WIB',
      '06.30 - 07.30 WIB',
      '07.00 - 08.30 WIB',
      '07.30 - 09.30 WIB',
      '08.00 - 09.30 WIB',
      '08.30 - 10.30 WIB',
      '09.30 - 11.30 WIB',
      '11.30 - 13.00 WIB',
      '13.00 - 14.30 WIB',
      '13.00 - 16.30 WIB',
      '14.30 - 16.00 WIB',
      '16.00 - 17.30 WIB',
      '17.30 - 19.00 WIB',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule_rounded, color: AppColors.forest, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing ? 'Ubah Item Rundown' : 'Tambah Rundown Baru',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.forest),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Sistem
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.infoBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 15),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sistem menyediakan pilihan jam. Silakan pilih jam lalu isi kegiatan manual di bawah.',
                              style: TextStyle(fontSize: 11, color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. JAM / WAKTU
                    const Text(
                      'PILIHAN JAM / WAKTU',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.sageBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: systemPresetHours.contains(selectedTimeRange)
                              ? selectedTimeRange
                              : null,
                          hint: Text(selectedTimeRange, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest)),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.forest),
                          items: systemPresetHours.map((h) {
                            return DropdownMenuItem<String>(
                              value: h,
                              child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedTimeRange = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Opsi Custom Jam Manual
                    Row(
                      children: [
                        const Text('Atau pilih jam custom: ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        TextButton(
                          onPressed: () async {
                            final pickStart = await showTimePicker(context: dialogCtx, initialTime: startTime);
                            if (pickStart != null && dialogCtx.mounted) {
                              final pickEnd = await showTimePicker(context: dialogCtx, initialTime: endTime);
                              if (pickEnd != null) {
                                final sStr = '${pickStart.hour.toString().padLeft(2, '0')}.${pickStart.minute.toString().padLeft(2, '0')}';
                                final eStr = '${pickEnd.hour.toString().padLeft(2, '0')}.${pickEnd.minute.toString().padLeft(2, '0')}';
                                setDialogState(() {
                                  selectedTimeRange = '$sStr - $eStr WIB';
                                });
                              }
                            }
                          },
                          child: const Text('Pilih Jam Mulai & Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 2. NAMA KEGIATAN
                    const Text(
                      'NAMA KEGIATAN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: activityCtrl,
                      decoration: InputDecoration(
                        hintText: 'Kumpul & Briefing / Trekking Air Terjun',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. LOKASI KEGIATAN
                    const Text(
                      'LOKASI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: locationCtrl,
                      decoration: InputDecoration(
                        hintText: 'Titik Kumpul Rest Area / Tebing Echo',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. CATATAN
                    const Text(
                      'CATATAN KHUSUS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Wajib memakai alas kaki antiselip & jaket',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final activityText = activityCtrl.text.trim();
                    if (activityText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama kegiatan wajib diisi')),
                      );
                      return;
                    }

                    final newStep = TripItineraryStep(
                      time: selectedTimeRange,
                      activity: activityText,
                      location: locationCtrl.text.trim().isEmpty ? _selectedSingleDestination : locationCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty ? 'Mengikuti instruksi pemandu' : notesCtrl.text.trim(),
                      status: 'Akan Datang',
                      icon: activityText.toLowerCase().contains('kumpul') || activityText.toLowerCase().contains('meeting')
                          ? Icons.flag_rounded
                          : (activityText.toLowerCase().contains('makan') || activityText.toLowerCase().contains('sholat')
                              ? Icons.restaurant_rounded
                              : (activityText.toLowerCase().contains('foto') || activityText.toLowerCase().contains('dokumentasi')
                                  ? Icons.camera_alt_rounded
                                  : Icons.landscape_rounded)),
                    );

                    setState(() {
                      if (isEditing) {
                        _itinerarySteps[editIndex] = newStep;
                      } else {
                        _itinerarySteps.add(newStep);
                      }
                    });

                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Rundown'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddFacilityDialog({required bool isInclude}) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isInclude ? 'Tambah Fasilitas Termasuk' : 'Tambah Biaya Tidak Termasuk',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: _inputDecoration(
            isInclude
                ? 'Sewa Pelampung / Makan Siang Nasi Kapau'
                : 'Sewa Baju Adat / Ojek Lokal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              setState(() {
                if (isInclude) {
                  _includes.add(val);
                } else {
                  _excludes.add(val);
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddOrEditRuleDialog({int? editIndex}) async {
    final isEditing = editIndex != null;
    final existing = isEditing ? _offlineRules[editIndex] : null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.ruleDescription ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEditing ? 'Ubah Peraturan / SOP Trip' : 'Tambah Peraturan / SOP Trip',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: _inputDecoration('Judul peraturan'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: _inputDecoration('Penjelasan aturan khusus untuk destinasi ini...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final desc = descCtrl.text.trim();
              if (title.isEmpty) return;
              final rule = OfflineTripRule(
                title: title,
                ruleDescription: desc.isEmpty
                    ? 'Wajib dipatuhi seluruh peserta di lokasi.'
                    : desc,
                iconCode: 'warning',
              );
              setState(() {
                if (isEditing) {
                  _offlineRules[editIndex] = rule;
                } else {
                  _offlineRules.add(rule);
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
            ),
            child: Text(isEditing ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _quotaMaxController.dispose();
    _hostNameController.dispose();
    _hostLicenseController.dispose();
    _hostPhoneController.dispose();
    _hostSocialController.dispose();
    _hostExperienceController.dispose();
    super.dispose();
  }

  bool _detectHardRoute(String dest) {
    final lower = dest.toLowerCase();
    return lower.contains('hidden gem') ||
        lower.contains('nyarai') ||
        lower.contains('gunung') ||
        lower.contains('marapi') ||
        lower.contains('singgalang') ||
        lower.contains('jembatan akar');
  }

  void _onDestinationChanged(String newDest) {
    setState(() {
      _selectedSingleDestination = newDest;
      // Item 2: Kategori otomatis ditentukan berdasarkan destinasi yang dipilih
      _autoDeterminedCategory = determineCategoryForDestination(newDest);
      _difficultyLevel = _detectHardRoute(newDest) ? 'Hard' : 'Medium';
      _titleController.text = 'Eksplorasi $newDest';
      _applyGoogleMapsPointFor(newDest);
    });
  }

  Future<void> _openGoogleMapsPin() async {
    final uri = Uri.parse(_googleMapsUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pin Google Maps: $_meetingPointName ($_meetingLat, $_meetingLng)')),
      );
    }
  }

  Future<void> _showPickGoogleMapsHubDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                'Pilih Titik Kumpul Google Maps',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: ListView(
                  children: _meetingPointsByDestination.entries.map((entry) {
                    final preset = entry.value;
                    final name = preset['name'] as String;
                    final address = preset['address'] as String;
                    final isCurrent = name == _meetingPointName;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Icon(
                        Icons.location_on_rounded,
                        color: isCurrent ? AppColors.forest : AppColors.danger,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      subtitle: Text(
                        address,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.forest)
                          : null,
                      onTap: () {
                        setState(() {
                          _meetingPointName = name;
                          _meetingAddress = address;
                          _meetingLat = preset['lat'] as double;
                          _meetingLng = preset['lng'] as double;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _departureDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (picked != null) {
      setState(() => _departureTime = picked);
    }
  }

  Future<void> _pickKtpPhoto() async {
    final result = await pickOrganizerPhotoMax250Kb(
      defaultFileName: 'foto_ktp_penyelenggara.jpg',
    );
    if (!mounted || result.cancelled) return;
    if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text(result.errorMessage!),
        ),
      );
      return;
    }
    setState(() {
      _ktpPhoto = result;
      _hasUploadedKtp = true;
    });
  }

  Future<void> _pickLicensePhoto() async {
    final result = await pickOrganizerPhotoMax250Kb(
      defaultFileName: 'lisensi_pemandu.jpg',
    );
    if (!mounted || result.cancelled) return;
    if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text(result.errorMessage!),
        ),
      );
      return;
    }
    setState(() {
      _licensePhoto = result;
      _hasUploadedLicense = true;
    });
  }

  Future<void> _openFaceLivenessVerification() async {
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FaceLivenessDialog(),
    );
    if (!mounted) return;
    if (verified == true) {
      setState(() => _hasVerifiedFace = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.forest,
          content: Text('Autentikasi wajah berhasil diverifikasi.'),
        ),
      );
    }
  }

  void _submitTrip() {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi judul perjalanan dan tarif peserta')),
      );
      return;
    }

    if (_hostNameController.text.trim().isEmpty ||
        _hostPhoneController.text.trim().isEmpty ||
        _hostSocialController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text(
            'Lengkapi Nama, Nomor WhatsApp, dan Instagram terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    if (!_hasUploadedKtp || !_hasVerifiedFace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text(
            'Selesaikan Upload KTP dan Autentikasi Wajah terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    if (_isHardRoute && (!_hasUploadedLicense || _hostLicenseController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text(
            'Level Hard wajib Upload Lisensi dan mengisi Keterangan Lisensi.',
          ),
        ),
      );
      return;
    }

    if (!_isHardRoute && _hostExperienceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text(
            'Silakan isi Keterangan Lisensi atau Pengalaman terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'\D'), '')) ?? 100000;
    final quota = int.tryParse(_quotaMaxController.text.replaceAll(RegExp(r'\D'), '')) ?? 8;

    final newTrip = OpenTripItem(
      id: 'TRIP-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      singleDestination: _selectedSingleDestination, // ATURAN 1: 1 Destinasi Tunggal
      category: _autoDeterminedCategory, // ATURAN 2: Kategori Otomatis
      coverUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
      departureDate:
          '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
      returnDate:
          '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
      departureTime:
          '${_departureTime.hour.toString().padLeft(2, '0')}.${_departureTime.minute.toString().padLeft(2, '0')} WIB',
      duration: '1 Hari (Day Trip)',
      meetingPointName: _meetingPointName,
      meetingPointAddress: _meetingAddress,
      meetingPointLat: _meetingLat,
      meetingPointLng: _meetingLng,
      googleMapsUrl: _googleMapsUrl,
      pricePerPerson: price,
      includes: List<String>.from(_includes),
      excludes: List<String>.from(_excludes),
      quotaMax: quota,
      quotaFilled: 1, // Host sebagai peserta pertama
      verificationStatus: TripVerificationStatus.pendingAdmin,
      difficultyLevel: _difficultyLevel,
      isCreatedByCurrentUser: true,
      organizer: VerifiedOrganizer(
        id: 'ORG-USER',
        name: _hostNameController.text.trim(),
        isVerified: false,
        licenseNumber: _hostLicenseController.text.trim(),
        ktpStatus: 'Menunggu Verifikasi Admin WISGO',
        phone: _hostPhoneController.text.trim(),
        socialMedia: _hostSocialController.text.trim().isEmpty
            ? '@wisgo_host'
            : _hostSocialController.text.trim(),
        experienceYears: _hostExperienceController.text.trim().isEmpty
            ? 'Pemandu Lokal Sumatera Barat'
            : _hostExperienceController.text.trim(),
        organizationName: 'Penyelenggara Trip Go WISGO',
      ),
      offlineRules: List<OfflineTripRule>.from(_offlineRules),
      readinessChecklist: [
        TripReadinessItem(
          id: 'ready_1',
          title: 'Konfirmasi Transportasi Rombongan',
          description: 'Armada wisata siap',
          isDone: true,
          category: 'Transportasi',
        ),
        TripReadinessItem(
          id: 'ready_2',
          title: 'Tiket Masuk Resmi Perda Telah Dibayar',
          description: 'Melalui sistem pembayaran terintegrasi WISGO',
          isDone: true,
          category: 'Perizinan',
        ),
      ],
      jobdeskList: [
        TripJobdeskItem(
          id: 'j_1',
          roleTitle: 'Tour Leader & Pemandu',
          picName: _hostNameController.text.trim(),
          picRole: 'Penyelenggara',
          tasks: ['Memimpin rute', 'Briefing keselamatan'],
          status: 'Siap',
          icon: Icons.person_pin_circle_rounded,
        ),
      ],
      packingList: [
        TripPackingItem(
          id: 'p_1',
          category: 'Pakaian & Perlengkapan',
          itemName: 'Pakaian Ganti & Jaket Windbreaker',
          isPacked: true,
        ),
        TripPackingItem(
          id: 'p_2',
          category: 'Dokumen & Ibadah',
          itemName: 'e-KTP Asli & Alat Sholat',
          isPacked: true,
        ),
      ],
      itinerary: List<TripItineraryStep>.from(_itinerarySteps),
      messages: [
        TripChatMessage(
          id: 'm_host_init',
          senderName: '${_hostNameController.text.trim()} (Host)',
          senderRole: 'Host',
          message:
              'Jadwal Trip Go resmi diterbitkan melalui sistem WISGO! Silakan berkoordinasi di sini.',
          timestamp: 'Baru saja',
          isPinnedNotice: true,
        ),
      ],
      whatsappGroupLink: 'https://chat.whatsapp.com/WisgoOpenTrip2026',
    );

    widget.onTripCreated(newTrip);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        content: Text(
          ' Berhasil membuat Trip Go: ${newTrip.singleDestination} ($newTrip.category)!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'PENGAJUAN PENYELENGGARA OPEN TRIP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ikuti 3 langkah pendaftaran penyelenggara sebelum verifikasi Admin WISGO',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 12),

              // Indikator 3 Halaman Bertahap
              Row(
                children: [
                  _wizardPill(0, '1. Data Diri'),
                  const SizedBox(width: 6),
                  _wizardPill(1, '2. KTP & Wajah'),
                  const SizedBox(width: 6),
                  _wizardPill(2, '3. Detail Trip'),
                ],
              ),
              const SizedBox(height: 16),

              if (_wizardStep == 0) ...[
                _buildFieldLabel('DATA DIRI PENYELENGGARA'),
                const SizedBox(height: 6),
                const Text(
                  'Nama',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _hostNameController,
                  decoration: _inputDecoration('Masukkan nama lengkap'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nomor WhatsApp',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _hostPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('08xxxxxxxxxx'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Instagram',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _hostSocialController,
                  decoration: _inputDecoration('@username'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    if (_hostNameController.text.trim().isEmpty ||
                        _hostPhoneController.text.trim().isEmpty ||
                        _hostSocialController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.terracotta,
                          content: Text('Lengkapi Nama, Nomor WhatsApp, dan Instagram terlebih dahulu.'),
                        ),
                      );
                      return;
                    }
                    setState(() => _wizardStep = 1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Lanjut ke Upload KTP & Wajah →',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ] else if (_wizardStep == 1) ...[
                _buildFieldLabel('UPLOAD KTP & AUTENTIKASI WAJAH'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasUploadedKtp ? AppColors.successBorder : AppColors.warmBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: _hasUploadedKtp ? AppColors.successBg : AppColors.creamSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _hasUploadedKtp ? Icons.check_circle_rounded : Icons.badge_outlined,
                              size: 20,
                              color: _hasUploadedKtp ? AppColors.success : AppColors.forest,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upload KTP',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                                ),
                                Text(
                                  _hasUploadedKtp && _ktpPhoto != null
                                      ? '${_ktpPhoto!.name} • ${_ktpPhoto!.formattedSizeKb}'
                                      : 'Foto JPG, JPEG, PNG, atau gambar lainnya, maksimal 250 KB',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _hasUploadedKtp ? AppColors.success : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _pickKtpPhoto,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              side: const BorderSide(color: AppColors.sageBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(_hasUploadedKtp ? 'Ganti' : 'Upload KTP', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (_hasUploadedKtp && _ktpPhoto?.bytes != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _ktpPhoto!.bytes!,
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasVerifiedFace ? AppColors.successBorder : AppColors.warmBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _hasVerifiedFace ? AppColors.successBg : AppColors.creamSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _hasVerifiedFace ? Icons.check_circle_rounded : Icons.face_retouching_natural_rounded,
                          size: 20,
                          color: _hasVerifiedFace ? AppColors.success : AppColors.forest,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verifikasi / Autentikasi Wajah',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                            Text(
                              _hasVerifiedFace
                                  ? 'Autentikasi wajah terverifikasi ✓'
                                  : 'Nyalakan kamera lalu ikuti arahan tengok kanan & kiri',
                              style: TextStyle(
                                fontSize: 11,
                                color: _hasVerifiedFace ? AppColors.success : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _openFaceLivenessVerification,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.sageBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_hasVerifiedFace ? 'Ulangi' : 'Buka Kamera', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _wizardStep = 0),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.sageBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('← Kembali', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_hasUploadedKtp || !_hasVerifiedFace) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.terracotta,
                                content: Text('Selesaikan Upload KTP dan Autentikasi Wajah terlebih dahulu.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _wizardStep = 2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: AppColors.cream,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Lanjut ke Detail Trip →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
              // LANGKAH 3: DETAIL TRIP & LISENSI
              _buildFieldLabel('DETAIL TRIP'),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: ['Easy', 'Medium', 'Hard'].map((lvl) {
                        final selected = _difficultyLevel == lvl;
                        final isHard = lvl == 'Hard';
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: lvl == 'Hard' ? 0 : 6),
                            child: ChoiceChip(
                              selected: selected,
                              label: Center(
                                child: Text(
                                  lvl,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? Colors.white
                                        : (isHard ? AppColors.terracotta : AppColors.forest),
                                  ),
                                ),
                              ),
                              selectedColor: isHard ? AppColors.terracotta : AppColors.forest,
                              backgroundColor: isHard ? AppColors.coralTint : AppColors.creamSubtle,
                              showCheckmark: false,
                              side: BorderSide(
                                color: selected
                                    ? (isHard ? AppColors.terracotta : AppColors.forest)
                                    : AppColors.sageBorder,
                              ),
                              onSelected: (_) => setState(() => _difficultyLevel = lvl),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    if (_isHardRoute) ...[
                      Container(
                        padding: const EdgeInsets.all(9),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.coralTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.terracotta),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Level Hard wajib mengupload lisensi pemandu resmi.',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _hasUploadedLicense && _licensePhoto != null
                                  ? '${_licensePhoto!.name} • ${_licensePhoto!.formattedSizeKb}'
                                  : 'Belum ada foto lisensi diunggah',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _hasUploadedLicense ? AppColors.success : AppColors.muted,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _pickLicensePhoto,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              side: const BorderSide(color: AppColors.sageBorder),
                            ),
                            child: Text(_hasUploadedLicense ? 'Ganti' : 'Upload Lisensi', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Keterangan Lisensi',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _hostLicenseController,
                        maxLines: 2,
                        decoration: _inputDecoration('Masukkan nomor dan keterangan lisensi'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(9),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.forest),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Level $_difficultyLevel tidak wajib upload lisensi, cukup sertakan keterangan pengalaman.',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.forest),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Keterangan Lisensi',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _hostExperienceController,
                        maxLines: 2,
                        decoration: _inputDecoration('Masukkan pengalaman memandu atau keterangan lisensi'),
                      ),
                    ],
                  ],
                ),
              ),

              // Tujuan Destinasi
              _buildFieldLabel('TUJUAN DESTINASI'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSingleDestination,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.forest),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forest),
                    items: _availableSingleDestinations.map((dest) {
                      return DropdownMenuItem<String>(
                        value: dest,
                        child: Text(dest),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onDestinationChanged(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 2. ATURAN 2: KATEGORI OTOMATIS (Auto Category Detection)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori Otomatis Terdeteksi:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.forest),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _autoDeterminedCategory,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Judul Trip
              _buildFieldLabel('JUDUL TRIP GO'),
              TextField(
                controller: _titleController,
                decoration: _inputDecoration('Contoh: Eksplor Tebing Lembah Harau'),
              ),
              const SizedBox(height: 14),

              // Tanggal & Jam Kumpul
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('TANGGAL KEBERANGKATAN'),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.sageBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.forest),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('JAM KUMPUL'),
                        InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.sageBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_departureTime.hour.toString().padLeft(2, '0')}.${_departureTime.minute.toString().padLeft(2, '0')} WIB',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.forest),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Titik Kumpul
              _buildFieldLabel('TITIK KUMPUL'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _meetingPointName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _meetingAddress,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pin GPS: ${_meetingLat.toStringAsFixed(4)}, ${_meetingLng.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showPickGoogleMapsHubDialog,
                            icon: const Icon(Icons.edit_location_alt_rounded, size: 15),
                            label: const Text(
                              'Ganti Titik',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              side: const BorderSide(color: AppColors.sageBorder),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleMapsPin,
                            icon: const Icon(Icons.map_rounded, size: 15),
                            label: const Text(
                              'Buka Google Maps ↗',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: AppColors.cream,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tarif & Kuota
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('TARIF PESERTA'),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('KUOTA MAKSIMAL'),
                        TextField(
                          controller: _quotaMaxController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // RUNDOWN & ITINERARY PERJALANAN
              _buildFieldLabel('RUNDOWN ITINERARY'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.forest.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.schedule_rounded, size: 16, color: AppColors.forest),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal Rundown Perjalanan',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest),
                              ),
                              Text(
                                'Sistem menyediakan jam/waktu, Anda mengisi kegiatan & lokasi.',
                                style: TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Daftar Item Rundown
                    ..._itinerarySteps.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final step = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                step.time,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.info),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.activity,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                                  ),
                                  if (step.location.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.place_rounded, size: 11, color: AppColors.muted),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            step.location,
                                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (step.notes.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      step.notes,
                                      style: TextStyle(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.65)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.forest),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showAddOrEditItineraryDialog(editIndex: idx),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _itinerarySteps.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 6),

                    // Tombol Tambah Item Rundown
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddOrEditItineraryDialog(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Tambah Jam & Kegiatan Rundown', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.forest),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Detail Fasilitas & Layanan
              _buildFieldLabel('DETAIL FASILITAS'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Termasuk dalam Harga',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddFacilityDialog(isInclude: true),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.forest,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._includes.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(entry.value, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.muted),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() => _includes.removeAt(entry.key)),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 18, color: AppColors.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tidak Termasuk',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.danger),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddFacilityDialog(isInclude: false),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.forest,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._excludes.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_rounded, size: 15, color: AppColors.danger),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(entry.value, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.muted),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() => _excludes.removeAt(entry.key)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Peraturan & SOP Perjalanan
              _buildFieldLabel('PERATURAN & SOP PERJALANAN'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aturan ini akan tampil ke peserta di tombol SOP Perjalanan sebelum mereka mendaftar.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    ..._offlineRules.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final rule = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.creamSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warmBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.rule_folder_rounded, size: 16, color: AppColors.forest),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rule.title,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rule.ruleDescription,
                                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 15, color: AppColors.forest),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showAddOrEditRuleDialog(editIndex: idx),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _offlineRules.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddOrEditRuleDialog(),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Tambah Peraturan / SOP Lokasi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.forest),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tombol Navigasi & Ajukan Verifikasi Admin
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _wizardStep = 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: const BorderSide(color: AppColors.sageBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('← Kembali', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _submitTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Ajukan Verifikasi Admin',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _wizardPill(int stepIdx, String label) {
    final isActive = _wizardStep == stepIdx;
    final isDone = _wizardStep > stepIdx;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.forest
              : (isDone ? AppColors.successBg : AppColors.creamSubtle),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.forest
                : (isDone ? AppColors.successBorder : AppColors.warmBorder),
          ),
        ),
        child: Text(
          isDone ? '$label ✓' : label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isActive
                ? AppColors.cream
                : (isDone ? AppColors.success : AppColors.muted),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: AppColors.forest,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration([String? hint]) {
    return InputDecoration(
      hintText: (hint == null || hint.isEmpty) ? null : hint,
      hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.muted),
      filled: true,
      fillColor: AppColors.cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.sageBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
      ),
    );
  }
}

/// Dialog Kamera Live untuk Verifikasi / Autentikasi Wajah (Hadap Depan → Kanan → Kiri)
class _FaceLivenessDialog extends StatefulWidget {
  const _FaceLivenessDialog();

  @override
  State<_FaceLivenessDialog> createState() => _FaceLivenessDialogState();
}

class _FaceLivenessDialogState extends State<_FaceLivenessDialog> {
  static const List<Map<String, dynamic>> _steps = [
    {
      'title': 'Hadap Depan',
      'instruction': 'Posisikan wajah lurus di tengah bingkai kamera',
      'icon': Icons.face_rounded,
    },
    {
      'title': 'Tengok ke Kanan',
      'instruction': 'Putar kepala perlahan ke arah kanan',
      'icon': Icons.arrow_forward_rounded,
    },
    {
      'title': 'Tengok ke Kiri',
      'instruction': 'Putar kepala perlahan ke arah kiri',
      'icon': Icons.arrow_back_rounded,
    },
  ];

  int _stepIndex = 0;
  bool _cameraReady = false;
  bool _completed = false;
  String? _cameraError;
  Timer? _autoTimer;

  void _startAutoStepTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted || _completed) return;
      _advanceStep();
    });
  }

  void _advanceStep() {
    _autoTimer?.cancel();
    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
      if (_cameraReady) {
        _startAutoStepTimer();
      }
    } else {
      setState(() => _completed = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps[_stepIndex];
    final progress = _completed ? 1.0 : (_stepIndex + 1) / _steps.length;

    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.forest, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Autentikasi Wajah',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Camera Oval Frame
            Container(
              width: 220,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(110),
                border: Border.all(
                  color: _completed ? AppColors.success : AppColors.forest,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(106),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LiveFaceCameraView(
                      onCameraReady: () {
                        if (!mounted) return;
                        setState(() => _cameraReady = true);
                        _startAutoStepTimer();
                      },
                      onCameraError: (err) {
                        if (!mounted) return;
                        setState(() => _cameraError = err);
                      },
                    ),
                    if (_completed)
                      Container(
                        color: AppColors.forest.withValues(alpha: 0.65),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Step Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.creamSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _completed ? AppColors.success : AppColors.forest,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Instruction Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _completed ? AppColors.successBg : AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _completed ? AppColors.successBorder : AppColors.warmBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _completed ? AppColors.success : AppColors.forest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _completed ? Icons.check_rounded : current['icon'] as IconData,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _completed
                              ? 'Wajah Terverifikasi'
                              : 'Langkah ${_stepIndex + 1}/3 • ${current['title']}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _completed ? AppColors.success : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _completed
                              ? 'Pencocokan wajah selesai.'
                              : current['instruction'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Manual / Next Action Button
            if (!_completed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _advanceStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _cameraError != null
                        ? 'Lanjutkan Langkah ${_stepIndex + 1}/3'
                        : 'Konfirmasi ${current['title']}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
