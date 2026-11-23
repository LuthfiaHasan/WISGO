import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';
import 'widgets/morse_sos_modal.dart';

/// Layar Mitigasi Jalur Rawan & Tombol Darurat SOS GPS (FE-1 & Pilar 7)
/// Dilengkapi 4 Mekanisme Tanggap Darurat Tanpa Sinyal (Zero-Signal / Offline):
/// 1. SMS Fallback (Koordinat GPS via SMS 2G)
/// 2. Akses Cepat Panggilan Darurat Nasional 112 (Bebas Pulsa & Kuota)
/// 3. Offline Caching & Auto-Queue Sinyal SOS
/// 4. Alat Bantu Sinyal Fisik: Sirine Volume Maksimal & Senter Kedipan Pola Morse SOS
class HazardSosScreen extends StatefulWidget {
  const HazardSosScreen({super.key});

  @override
  State<HazardSosScreen> createState() => _HazardSosScreenState();
}

class _HazardSosScreenState extends State<HazardSosScreen>
    with SingleTickerProviderStateMixin {
  final DestinationRepository _repository = DestinationRepository();
  bool _isSendingSos = false;
  bool _isLoading = true;
  List<HazardAlertModel> _corridors = [];

  // 1. Status Jaringan & Offline Caching
  bool _isZeroSignalMode = false;
  static const double _lastKnownLat = -0.9468;
  static const double _lastKnownLng = 100.5182;
  static const String _lastKnownLocationName = 'Sitinjau Lauik (Padang - Solok)';
  static const int _cachedBatteryPercent = 84;
  final List<Map<String, dynamic>> _offlineSosQueue = [];

  // 2. Jenis Darurat
  String _selectedEmergencyType = 'Kendaraan Mogok di Tanjakan';
  static const List<String> _emergencyTypes = [
    'Kendaraan Mogok di Tanjakan',
    'Terjebak Longsor / Jalan Putus',
    'Darurat Medis / Kecelakaan',
    'Tersesat di Jalur Hutan (Zero-Signal)',
  ];

  // 3. Sirine Darurat
  bool _isSirenActive = false;
  AudioPlayer? _audioPlayer;
  late AnimationController _sirenPulseController;

  @override
  void initState() {
    super.initState();
    _sirenPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _loadHazards();
  }

  @override
  void dispose() {
    _sirenPulseController.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadHazards() async {
    setState(() => _isLoading = true);
    final data = await _repository.getHazardAlerts();
    if (!mounted) return;
    setState(() {
      _corridors = data;
      _isLoading = false;
    });
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'awas tutup total':
      case 'awas':
        return Colors.red.shade700;
      case 'siaga':
        return AppColors.coral500;
      case 'waspada':
        return const Color(0xFFE89F3C);
      case 'normal':
      default:
        return const Color(0xFF1E9E5A);
    }
  }

  // ==========================================
  // FITUR 1: SMS FALLBACK (KOORDINAT VIA SMS)
  // ==========================================
  String _buildEmergencySmsBody(String emergencyType) {
    return '[WISGO SOS DARURAT] Butuh Bantuan Segera!\n'
        'Jenis: $emergencyType\n'
        'Lokasi: $_lastKnownLocationName\n'
        'GPS: $_lastKnownLat, $_lastKnownLng\n'
        'Peta: https://maps.google.com/?q=$_lastKnownLat,$_lastKnownLng\n'
        'Baterai: $_cachedBatteryPercent%\n'
        'Pesan ini dikirim via SMS Fallback (Zero-Signal Mode)';
  }

  Future<void> _triggerSmsFallback(String emergencyType) async {
    const targetPhone = '+62811660115'; // Posko Siaga SAR Padang
    final message = _buildEmergencySmsBody(emergencyType);
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: targetPhone,
      queryParameters: {'body': message},
    );

    try {
      final launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showSmsFallbackDialog(targetPhone, message);
      }
    } catch (_) {
      if (mounted) {
        _showSmsFallbackDialog(targetPhone, message);
      }
    }
  }

  void _showSmsFallbackDialog(String phone, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sms_rounded, color: AppColors.green800, size: 24),
            SizedBox(width: 8),
            Text('SMS Fallback Darurat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jaringan data internet tidak tersedia. Sistem menyiapkan SMS darurat berikut:',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', height: 1.35),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin Pesan Darurat'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesan SMS darurat & koordinat GPS berhasil disalin ke clipboard!'),
                  backgroundColor: AppColors.green800,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FITUR 2: PANGGILAN CEPAT DARURAT (112)
  // ==========================================
  Future<void> _makeEmergencyCall(String number, String label) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await launchUrl(callUri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showCallFallbackSnackbar(number, label);
      }
    } catch (_) {
      if (mounted) {
        _showCallFallbackSnackbar(number, label);
      }
    }
  }

  void _showCallFallbackSnackbar(String number, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade900,
        content: Text('Panggil $label ke nomor $number (Bebas Pulsa)'),
        action: SnackBarAction(
          label: 'Salin Nomor',
          textColor: Colors.yellow,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: number));
          },
        ),
      ),
    );
  }

  // ==========================================
  // FITUR 3: OFFLINE CACHING & AUTO-QUEUE
  // ==========================================
  Future<void> _processSosTrigger() async {
    setState(() => _isSendingSos = true);

    if (_isZeroSignalMode) {
      // Masuk ke antrean sistem offline
      final queueId = 'SOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _offlineSosQueue.add({
        'id': queueId,
        'type': _selectedEmergencyType,
        'time': 'Baru Saja',
        'lat': _lastKnownLat,
        'lng': _lastKnownLng,
      });

      setState(() => _isSendingSos = false);

      // Jalankan SMS Fallback otomatis
      await _triggerSmsFallback(_selectedEmergencyType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            duration: const Duration(seconds: 5),
            content: Text(
              '⚠️ Mode Zero-Signal: Permintaan SOS ($queueId) tersimpan di Antrean Offline & Dialihkan ke SMS Darurat!',
            ),
          ),
        );
      }
    } else {
      // Jalur Online via API
      final signal = SOSSignalModel(
        touristName: 'Wisatawan WISGO',
        phoneNumber: '+6281234567890',
        emergencyType: _selectedEmergencyType,
        latitude: _lastKnownLat,
        longitude: _lastKnownLng,
        batteryPercent: _cachedBatteryPercent,
        nearestCorridor: 'Sitinjau Lauik',
      );

      await _repository.sendSosSignal(signal);

      if (!mounted) return;
      setState(() => _isSendingSos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green800,
          duration: const Duration(seconds: 4),
          content: Text(
            'Sinyal SOS ($_selectedEmergencyType) & GPS darurat berhasil dipancarkan ke Posko SAR & Satgas Nagari!',
          ),
        ),
      );
    }
  }

  void _syncOfflineQueue() {
    if (_offlineSosQueue.isEmpty) return;
    final count = _offlineSosQueue.length;
    setState(() {
      _offlineSosQueue.clear();
      _isZeroSignalMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.green800,
        content: Text('$count permintaan SOS dalam antrean berhasil disinkronkan ke Posko SAR Sumbar!'),
      ),
    );
  }

  // ==========================================
  // FITUR 4: SIRINE & SENTER MORSE (100% OFFLINE)
  // ==========================================
  Future<void> _toggleSiren() async {
    if (_isSirenActive) {
      _sirenPulseController.stop();
      _sirenPulseController.reset();
      await _audioPlayer?.stop();
      setState(() => _isSirenActive = false);
    } else {
      setState(() => _isSirenActive = true);
      _sirenPulseController.repeat(reverse: true);
      _audioPlayer ??= AudioPlayer();
      try {
        await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer!.play(AssetSource('audio/phr-1.mp3'));
      } catch (_) {}
    }
  }

  void _openMorseModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const MorseSosModal(),
      ),
    );
  }

  // ==========================================
  // DIALOG PANCARKAN SOS
  // ==========================================
  void _triggerSosDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.coral500, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pancarkan Sinyal Darurat SOS GPS',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Jenis Keadaan Darurat:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedEmergencyType,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _emergencyTypes.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => _selectedEmergencyType = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sage100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location, size: 14, color: AppColors.green800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Koordinat: $_lastKnownLat, $_lastKnownLng ($_lastKnownLocationName)',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.ink900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.battery_charging_full, size: 14, color: AppColors.green800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Status Baterai: $_cachedBatteryPercent% · Terhubung ke SAR Padang',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _isZeroSignalMode ? Icons.signal_cellular_connected_no_internet_0_bar : Icons.wifi_rounded,
                          size: 14,
                          color: _isZeroSignalMode ? Colors.red : AppColors.green800,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isZeroSignalMode
                                ? 'Mode: Zero-Signal (Fallback SMS Aktif)'
                                : 'Mode: Online (Koneksi Data Normal)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isZeroSignalMode ? Colors.red.shade800 : AppColors.green800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isZeroSignalMode
                    ? 'Saat internet mati, sistem otomatis menyiapkan SMS darurat koordinat & menyimpan permintaan ke antrean offline.'
                    : 'Sinyal akan dipancarkan ke Basarnas Sumbar, BPBD, & Posko Satgas Nagari terdekat.',
                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _processSosTrigger();
              },
              child: const Text('Ya, Pancarkan Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Pantauan Jalur Rawan & SOS GPS'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Status Jalur',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.green800),
            onPressed: _loadHazards,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green800))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // 1. STATUS BAR JARINGAN & OFFLINE CACHING GPS TERAKHIR
                _buildOfflineCacheStatusBar(),
                const SizedBox(height: 14),

                // 2. BANNER TOMBOL DARURAT SOS GPS (PILAR 7)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sos_rounded, color: Colors.white, size: 36),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tombol Bantuan Darurat SOS GPS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isZeroSignalMode
                            ? 'Mode Blank Spot Aktif: Tombol otomatis mengaktifkan SMS Fallback (berisi titik koordinat GPS) & antrean lokal tanpa kuota internet.'
                            : 'Gunakan saat darurat di tanjakan ekstrem atau kawasan blank spot. Sistem mengirim koordinat GPS dan peringatan otomatis ke posko penyelamatan nagari.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      PillButton(
                        text: _isSendingSos ? 'Memancarkan Sinyal...' : 'PANCARKAN SOS SEKARANG',
                        icon: const Icon(Icons.emergency_share, color: Colors.white, size: 18),
                        backgroundColor: const Color(0xFF8B0000),
                        onPressed: _isSendingSos ? null : _triggerSosDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. AKSES CEPAT PANGGILAN DARURAT (112 - BEBAS PULSA & KUOTA)
                _buildEmergencyCallCard(),
                const SizedBox(height: 20),

                // 4. DAFTAR KORIDOR RAWAN BENCANA (SITINJAU, ANAI, KELOK 9, KELOK 44)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Radar 4 Koridor Jalur Ekstrem',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_corridors.length} koridor aktif',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ..._corridors.map((c) {
                  final color = _severityColor(c.severity);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
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
                            Expanded(
                              child: Text(
                                c.location,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                c.severity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ruas: ${c.roadSegment} · Tanjakan ${c.slopeGradientDeg}°',
                          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.message,
                          style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.sage100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alt_route, size: 16, color: AppColors.green800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.detourRoute,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.ink900, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Posko: ${c.nearestRescuePost}',
                              style: const TextStyle(fontSize: 11, color: Colors.black45),
                            ),
                            Text(
                              c.emergencyContact,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),

                // 5. ALAT BANTU SINYAL FISIK (100% OFFLINE TANPA SINYAL)
                _buildPhysicalRescueToolsCard(),
              ],
            ),
    );
  }

  // WIDGET 1: STATUS BAR JARINGAN & OFFLINE CACHING GPS
  Widget _buildOfflineCacheStatusBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isZeroSignalMode ? Colors.orange.shade300 : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _isZeroSignalMode ? Icons.signal_cellular_off_rounded : Icons.cell_tower_rounded,
                      size: 18,
                      color: _isZeroSignalMode ? Colors.orange.shade800 : AppColors.green800,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _isZeroSignalMode ? 'Mode Blank Spot (Zero-Signal)' : 'Sinyal Normal (Data Aktif)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _isZeroSignalMode ? Colors.orange.shade900 : AppColors.green800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Switch Simulasi Sinyal
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Offline:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _isZeroSignalMode,
                      activeColor: Colors.orange.shade800,
                      onChanged: (val) {
                        setState(() => _isZeroSignalMode = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            children: [
              const Icon(Icons.pin_drop_rounded, size: 14, color: AppColors.green800),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Last Known GPS: $_lastKnownLat, $_lastKnownLng (Akurasi ±4m)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sage100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Cached', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.green800)),
              ),
            ],
          ),
          if (_offlineSosQueue.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_offlineSosQueue.length} SOS tersimpan di Antrean Offline lokal',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _syncOfflineQueue,
                    child: const Text('Sinkronkan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // WIDGET 2: AKSES CEPAT PANGGILAN DARURAT (112)
  Widget _buildEmergencyCallCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Colors.red, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panggilan Darurat Terpadu (112)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink900),
                    ),
                    Text(
                      'Bebas Pulsa & Kuota • Berfungsi di Semua Operator Seluler',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tombol Panggilan Utama 112
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: const Text(
                'PANGGIL 112 SEKARANG (BEBAS PULSA)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
              onPressed: () => _makeEmergencyCall('112', 'Panggilan Darurat 112'),
            ),
          ),
          const SizedBox(height: 10),
          // Baris Hotline Tambahan
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickCallChip('SAR: 115', '115', Colors.red.shade700),
                const SizedBox(width: 6),
                _buildQuickCallChip('Ambulans: 118', '118', AppColors.green800),
                const SizedBox(width: 6),
                _buildQuickCallChip('Polisi: 110', '110', AppColors.indigo500),
                const SizedBox(width: 6),
                _buildQuickCallChip('Posko Sitinjau', '0811660115', AppColors.orange500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCallChip(String label, String number, Color color) {
    return InkWell(
      onTap: () => _makeEmergencyCall(number, label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET 3: ALAT BANTU SINYAL FISIK (100% OFFLINE)
  Widget _buildPhysicalRescueToolsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.offline_bolt_rounded, color: AppColors.green800, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alat Bantu Sinyal Fisik (100% Offline)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink900),
                ),
              ),
              Text(
                'Nol Kuota/Sinyal',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan saat ponsel sama sekali tidak mendapat sinyal seluler untuk menarik perhatian warga nagari atau tim penyelamat dari kejauhan.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Alat 1: Sirine Suara Maksimal
              Expanded(
                child: AnimatedBuilder(
                  animation: _sirenPulseController,
                  builder: (context, child) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSirenActive
                            ? Color.lerp(Colors.red.shade700, Colors.red.shade900, _sirenPulseController.value)
                            : Colors.grey.shade100,
                        foregroundColor: _isSirenActive ? Colors.white : Colors.black87,
                        elevation: _isSirenActive ? 3 : 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: _isSirenActive ? Colors.red : Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                      ),
                      onPressed: _toggleSiren,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSirenActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 24,
                            color: _isSirenActive ? Colors.white : Colors.red.shade700,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSirenActive ? 'SIRINE AKTIF' : 'SIRINE SUARA',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _isSirenActive ? Colors.white : Colors.red.shade800,
                            ),
                          ),
                          Text(
                            _isSirenActive ? 'Volume 110dB' : 'Maksimal',
                            style: TextStyle(
                              fontSize: 10,
                              color: _isSirenActive ? Colors.white70 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Alat 2: Senter Kedipan Pola Morse SOS
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade50,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.amber.shade400, width: 1.2),
                    ),
                  ),
                  onPressed: _openMorseModal,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flare_rounded, size: 24, color: Colors.orange),
                      const SizedBox(height: 4),
                      Text(
                        'SENTER MORSE',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const Text(
                        'Pola · · · — — — · · ·',
                        style: TextStyle(fontSize: 10, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
