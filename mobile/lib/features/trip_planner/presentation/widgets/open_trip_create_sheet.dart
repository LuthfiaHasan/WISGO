import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';

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
    'Ekowisata Air Terjun Nyarai (Hidden Gem)',
    'Kawasan Bahari Mandeh',
    'Jembatan Akar Bayang (Hidden Gem)',
    'Desa Wisata Nagari Tuo Pariangan',
    'Masjid Raya Sumatera Barat (Religi)',
    'Los Lambuang Nasi Kapau Pasar Ateh (Kuliner)',
    'Danau Singkarak & Kuliner Ikan Bilih',
  ];

  late String _selectedSingleDestination;
  late String _autoDeterminedCategory;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _meetingPointNameController =
      TextEditingController(text: 'Rest Area Simpang Harau');
  final TextEditingController _meetingAddressController =
      TextEditingController(text: 'Jl. Raya Payakumbuh-Harau KM 8, Kab. Lima Puluh Kota');
  final TextEditingController _priceController = TextEditingController(text: '125000');
  final TextEditingController _quotaMaxController = TextEditingController(text: '8');
  final TextEditingController _hostNameController =
      TextEditingController(text: 'Rahmat Hidayat (Guide Nagari)');
  final TextEditingController _hostLicenseController =
      TextEditingController(text: 'HPI-SB-2024-0412 (Pemandu Berlisensi)');
  final TextEditingController _hostPhoneController =
      TextEditingController(text: '0812-7578-953');
  final TextEditingController _hostSocialController =
      TextEditingController(text: '@rahmathidayat_guide (Instagram)');
  final TextEditingController _hostExperienceController =
      TextEditingController(text: '4+ Tahun Pengalaman Pemandu Wisata Sumbar');

  DateTime _departureDate = DateTime(2026, 12, 12);
  TimeOfDay _departureTime = const TimeOfDay(hour: 6, minute: 30);
  bool _hasUploadedKtp = false;
  bool _isHardRoute = false;
  bool _hasUploadedLicense = false;

  // Itinerary Rundown yang diisi manual oleh pembuat trip (Sistem sediakan slot jam)
  late List<TripItineraryStep> _itinerarySteps;

  // Fasilitas Include & Exclude yang diinput penyelenggara (berbeda tiap tempat)
  final List<String> _includes = [
    'Tiket Masuk Resmi Kawasan',
    'Pemandu Lokal Selama Perjalanan',
    'Air Mineral & P3K Dasar',
  ];
  final List<String> _excludes = [
    'Pengeluaran Pribadi & Cinderamata',
    'Transportasi Menuju Titik Kumpul',
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

  @override
  void initState() {
    super.initState();
    _selectedSingleDestination = _availableSingleDestinations.first;
    _autoDeterminedCategory = determineCategoryForDestination(_selectedSingleDestination);
    _titleController.text = 'Eksplorasi $_selectedSingleDestination';

    // Inisialisasi rundown default dengan jam dari sistem untuk diisi/diubah pembuat trip
    _itinerarySteps = [
      TripItineraryStep(
        time: '06.30 - 07.30 WIB',
        activity: 'Kumpul di Meeting Point & Briefing Tim',
        location: _meetingPointNameController.text.trim(),
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
        activity: 'Ishoma (Istirahat, Sholat & Santap Kuliner Minang)',
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

                    // 1. JAM / WAKTU (DISEDIAKAN SISTEM)
                    const Text(
                      'PILIHAN JAM / WAKTU (DARI SISTEM):',
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

                    // 2. NAMA KEGIATAN (DIISI MANUAL OLEH PEMBUAT TRIP)
                    const Text(
                      'NAMA KEGIATAN / AKTIVITAS (MANUAL):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: activityCtrl,
                      decoration: InputDecoration(
                        hintText: 'Cth: Kumpul & Briefing / Trekking Air Terjun',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. LOKASI KEGIATAN (MANUAL)
                    const Text(
                      'LOKASI / TEMPAT (MANUAL):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: locationCtrl,
                      decoration: InputDecoration(
                        hintText: 'Cth: Titik Kumpul Rest Area / Tebing Echo',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. CATATAN / SOP (MANUAL)
                    const Text(
                      'CATATAN / INSTRUKSI KHUSUS (MANUAL):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Cth: Wajib memakai alas kaki antiselip & jaket',
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
          isInclude ? 'Tambah Fasilitas Include' : 'Tambah Biaya Exclude',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: _inputDecoration(
            isInclude
                ? 'Cth: Sewa Pelampung / Makan Siang Nasi Kapau'
                : 'Cth: Sewa Baju Adat / Ojek Lokal',
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
              decoration: _inputDecoration('Judul Peraturan (Cth: Wajib Alas Kaki Antiselip)'),
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
    _meetingPointNameController.dispose();
    _meetingAddressController.dispose();
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
      _isHardRoute = _detectHardRoute(newDest);
      _titleController.text = 'Eksplorasi $newDest';
    });
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

  void _submitTrip() {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi judul perjalanan dan harga')),
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
            'Langkah 1: Lengkapi Data Diri (Nama, Nomor Telepon, dan Instagram).',
          ),
        ),
      );
      return;
    }

    if (!_hasUploadedKtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.terracotta,
          content: Text(
            'Langkah 2: Wajib Upload KTP sebelum mengajukan Open Trip.',
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
            'Langkah 3: Jalur Hard wajib mengisi nomor & Upload Lisensi Pemandu.',
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
            'Langkah 3: Untuk tempat umum, silakan isi Pengalaman Penyelenggara.',
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
      meetingPointName: _meetingPointNameController.text.trim(),
      meetingPointAddress: _meetingAddressController.text.trim(),
      meetingPointLat: -0.1132,
      meetingPointLng: 100.6721,
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-0.1132,100.6721',
      pricePerPerson: price,
      includes: List<String>.from(_includes),
      excludes: List<String>.from(_excludes),
      quotaMax: quota,
      quotaFilled: 1, // Host sebagai peserta pertama
      verificationStatus: TripVerificationStatus.pendingAdmin,
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
                'BUAT JADWAL TRIP GO BARU',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sistem WISGO: 1 Destinasi Tunggal per Perjalanan • Kategori Otomatis',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 18),

              // 1. ATURAN 1: PILIH DESTINASI TUNGGAL (Single Destination)
              _buildFieldLabel('1. TUJUAN / DESTINASI TUNGGAL (WAJIB 1 DESTINASI)'),
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

              // Titik Kumpul (Google Maps)
              _buildFieldLabel('TITIK KUMPUL (TERINTEGRASI GOOGLE MAPS)'),
              TextField(
                controller: _meetingPointNameController,
                decoration: _inputDecoration('Nama Tempat Titik Kumpul (e.g. Rest Area Simpang Harau)'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _meetingAddressController,
                decoration: _inputDecoration('Alamat Lengkap Titik Kumpul untuk Google Maps'),
              ),
              const SizedBox(height: 14),

              // Tarif & Kuota
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('TARIF PER PESERTA (RP)'),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Contoh: 125000'),
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
                          decoration: _inputDecoration('Contoh: 8 Orang'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // RUNDOWN & ITINERARY PERJALANAN (DIISI MANUAL OLEH PEMBUAT TRIP)
              _buildFieldLabel('RUNDOWN ITINERARY (DIISI MANUAL OLEH PEMBUAT TRIP)'),
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

              // Detail Fasilitas & Layanan (Include & Exclude — Diinput Penyelenggara)
              _buildFieldLabel('DETAIL FASILITAS (INCLUDE & EXCLUDE)'),
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
                          'Termasuk dalam Harga (Include):',
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
                          'Tidak Termasuk (Exclude):',
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

              // Peraturan & SOP Perjalanan (Diinput Penyelenggara karena tiap tempat berbeda)
              _buildFieldLabel('PERATURAN & SOP PERJALANAN (KHUSUS LOKASI INI)'),
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

              // 1. Data Diri Penyelenggara (Nama, Nomor Telepon, Instagram)
              _buildFieldLabel('1. DATA DIRI PENYELENGGARA'),
              TextField(
                controller: _hostNameController,
                decoration: _inputDecoration('Nama Lengkap'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _hostPhoneController,
                decoration: _inputDecoration('Nomor Telepon Aktif'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _hostSocialController,
                decoration: _inputDecoration('Akun Instagram (Cth: @username)'),
              ),
              const SizedBox(height: 14),

              // 2. Upload KTP (Wajib)
              _buildFieldLabel('2. UPLOAD KTP (WAJIB)'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasUploadedKtp ? AppColors.successBorder : AppColors.warmBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hasUploadedKtp ? AppColors.successBg : AppColors.creamSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _hasUploadedKtp ? Icons.check_circle_rounded : Icons.badge_outlined,
                        size: 18,
                        color: _hasUploadedKtp ? AppColors.success : AppColors.forest,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload Foto e-KTP',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          Text(
                            _hasUploadedKtp
                                ? 'e-KTP berhasil diunggah untuk verifikasi admin'
                                : 'Wajib diunggah sebagai syarat verifikasi penyelenggara',
                            style: TextStyle(
                              fontSize: 11,
                              color: _hasUploadedKtp ? AppColors.success : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _hasUploadedKtp = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: const BorderSide(color: AppColors.sageBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _hasUploadedKtp ? 'Ganti' : 'Upload KTP',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Lisensi (Wajib untuk Jalur Hard) atau Cukup Pengalaman (Tempat Umum)
              _buildFieldLabel('3. LISENSI (WAJIB HARD) / PENGALAMAN (TEMPAT UMUM)'),
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
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            selected: !_isHardRoute,
                            label: Center(
                              child: Text(
                                'Tempat Umum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: !_isHardRoute ? Colors.white : AppColors.forest,
                                ),
                              ),
                            ),
                            selectedColor: AppColors.forest,
                            backgroundColor: AppColors.creamSubtle,
                            showCheckmark: false,
                            side: BorderSide(
                              color: !_isHardRoute ? AppColors.forest : AppColors.sageBorder,
                            ),
                            onSelected: (_) => setState(() => _isHardRoute = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            selected: _isHardRoute,
                            label: Center(
                              child: Text(
                                'Jalur Hard (Wajib Lisensi)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _isHardRoute ? Colors.white : AppColors.terracotta,
                                ),
                              ),
                            ),
                            selectedColor: AppColors.terracotta,
                            backgroundColor: AppColors.coralTint,
                            showCheckmark: false,
                            side: BorderSide(
                              color: _isHardRoute ? AppColors.terracotta : AppColors.warmBorder,
                            ),
                            onSelected: (_) => setState(() => _isHardRoute = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isHardRoute) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _hasUploadedLicense ? AppColors.successBg : AppColors.coralTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _hasUploadedLicense ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                              size: 18,
                              color: _hasUploadedLicense ? AppColors.success : AppColors.terracotta,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upload Lisensi Pemandu (Wajib Hard)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                                ),
                                Text(
                                  _hasUploadedLicense
                                      ? 'Dokumen lisensi berhasil diunggah'
                                      : 'Wajib unggah sertifikat/lisensi HPI, BNSP, atau Guide Gunung',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _hasUploadedLicense ? AppColors.success : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => setState(() => _hasUploadedLicense = true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              side: const BorderSide(color: AppColors.sageBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              _hasUploadedLicense ? 'Ganti' : 'Upload',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _hostLicenseController,
                        decoration: _inputDecoration('Nomor Lisensi Pemandu (Wajib untuk Jalur Hard)'),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 15, color: AppColors.forest),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Untuk destinasi tempat umum tidak wajib lisensi — cukup tuliskan pengalaman Anda memandu/mengelola trip.',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.forest),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: _hostExperienceController,
                      maxLines: 2,
                      decoration: _inputDecoration('Pengalaman Penyelenggara (Cth: 3 Tahun Guide Wisata Sumbar)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Publikasi
              ElevatedButton(
                onPressed: _submitTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Ajukan Verifikasi Admin & Buat Trip Go',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
