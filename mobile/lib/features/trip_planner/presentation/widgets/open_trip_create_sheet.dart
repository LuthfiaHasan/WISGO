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

  DateTime _departureDate = DateTime(2026, 12, 12);
  TimeOfDay _departureTime = const TimeOfDay(hour: 6, minute: 30);

  @override
  void initState() {
    super.initState();
    _selectedSingleDestination = _availableSingleDestinations.first;
    _autoDeterminedCategory = determineCategoryForDestination(_selectedSingleDestination);
    _titleController.text = 'Eksplorasi $_selectedSingleDestination';
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
    super.dispose();
  }

  void _onDestinationChanged(String newDest) {
    setState(() {
      _selectedSingleDestination = newDest;
      // Item 2: Kategori otomatis ditentukan berdasarkan destinasi yang dipilih
      _autoDeterminedCategory = determineCategoryForDestination(newDest);
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
      quotaMax: quota,
      quotaFilled: 1, // Host sebagai peserta pertama
      organizer: VerifiedOrganizer(
        id: 'ORG-USER',
        name: _hostNameController.text.trim(),
        licenseNumber: _hostLicenseController.text.trim(),
        ktpStatus: 'Terverifikasi e-KTP & KYC WISGO',
        phone: _hostPhoneController.text.trim(),
        organizationName: 'Penyelenggara Terdaftar WISGO',
      ),
      offlineRules: const [
        OfflineTripRule(
          title: 'Toleransi Waktu Titik Kumpul 15 Menit',
          ruleDescription: 'Peserta wajib hadir di meeting point tepat waktu.',
          iconCode: 'schedule',
        ),
        OfflineTripRule(
          title: 'Asuransi Keselamatan Perjalanan',
          ruleDescription: 'Peserta terdaftar asuransi resmi selama kegiatan berlangsung.',
          iconCode: 'security',
        ),
      ],
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
      itinerary: [
        TripItineraryStep(
          time: '06.30 - 07.00 WIB',
          activity: 'Kumpul di Titik Kumpul (Google Maps)',
          location: _meetingPointNameController.text.trim(),
          notes: 'Briefing dan presensi',
          status: 'Akan Datang',
          icon: Icons.place_rounded,
        ),
        TripItineraryStep(
          time: '07.00 - 15.00 WIB',
          activity: 'Eksplorasi $_selectedSingleDestination',
          location: _selectedSingleDestination,
          notes: 'Aktivitas inti dan dokumentasi',
          status: 'Akan Datang',
          icon: Icons.landscape_rounded,
        ),
      ],
      messages: [
        TripChatMessage(
          id: 'm_host_init',
          senderName: '${_hostNameController.text.trim()} (Host)',
          senderRole: 'Host',
          message:
              'Jadwal Open Trip resmi diterbitkan melalui sistem WISGO! Silakan berkoordinasi di sini.',
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
          ' Berhasil membuat Open Trip: ${newTrip.singleDestination} ($newTrip.category)!',
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
                'BUAT JADWAL OPEN TRIP BARU',
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
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF15803D), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori Otomatis Terdeteksi:',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _autoDeterminedCategory,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF15803D),
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
              _buildFieldLabel('JUDUL OPEN TRIP'),
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

              // Penyelenggara & Verifikasi
              _buildFieldLabel('PENYELENGGARA TERVERIFIKASI'),
              TextField(
                controller: _hostNameController,
                decoration: _inputDecoration('Nama Lengkap Penyelenggara / Guide'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _hostLicenseController,
                decoration: _inputDecoration('Nomor Lisensi Pemandu HPI / Pokdarwis'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _hostPhoneController,
                decoration: _inputDecoration('Nomor WhatsApp Penyelenggara'),
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
                  'Publikasikan Open Trip ke Sistem WISGO',
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
          fontSize: 10,
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
