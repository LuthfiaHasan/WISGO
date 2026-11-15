import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';

/// Layar Mitigasi Jalur Rawan & Tombol Darurat SOS GPS (FE-1)
/// Pilar 7: Mitigasi Jalur Rawan & Mode Zero-Signal
class HazardSosScreen extends StatefulWidget {
  const HazardSosScreen({super.key});

  @override
  State<HazardSosScreen> createState() => _HazardSosScreenState();
}

class _HazardSosScreenState extends State<HazardSosScreen> {
  final DestinationRepository _repository = DestinationRepository();
  bool _isSendingSos = false;
  bool _isLoading = true;
  List<HazardAlertModel> _corridors = [];

  String _selectedEmergencyType = 'Kendaraan Mogok di Tanjakan';

  static const List<String> _emergencyTypes = [
    'Kendaraan Mogok di Tanjakan',
    'Terjebak Longsor / Jalan Putus',
    'Darurat Medis / Kecelakaan',
    'Tersesat di Jalur Hutan (Zero-Signal)',
  ];

  @override
  void initState() {
    super.initState();
    _loadHazards();
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
                            'Koordinat: -0.9468, 100.5182 (Sitinjau)',
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
                            'Status Baterai: 84% · Terhubung ke SAR Padang',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sinyal akan dipancarkan ke Basarnas Sumbar, BPBD, & Posko Satgas Nagari terdekat.',
                style: TextStyle(fontSize: 11.5, color: Colors.black54),
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
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isSendingSos = true);

                final signal = SOSSignalModel(
                  touristName: 'Wisatawan WISGO',
                  phoneNumber: '+6281234567890',
                  emergencyType: _selectedEmergencyType,
                  latitude: -0.9468,
                  longitude: 100.5182,
                  batteryPercent: 84,
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
                // 1. BANNER TOMBOL DARURAT SOS GPS (PILAR 7)
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
                      const Text(
                        'Gunakan saat darurat di tanjakan ekstrem atau kawasan blank spot. Sistem mengirim koordinat GPS dan peringatan otomatis ke posko penyelamatan nagari.',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      PillButton(
                        text: _isSendingSos ? 'Memancarkan Sinyal...' : 'PANCARKAN SOS SEKARANG',
                        icon: const Icon(Icons.emergency_share, color: Colors.white, size: 18),
                        backgroundColor: const Color(0xFF8B0000),
                        onPressed: _isSendingSos ? null : _triggerSosDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. HOTLINE DARURAT SUMATERA BARAT
                const Text(
                  'Kontak Darurat Siaga (Bebas Pulsa)',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHotlinePill('SAR Sumbar: 115', Icons.phone_in_talk, Colors.red.shade700),
                      const SizedBox(width: 8),
                      _buildHotlinePill('BPBD: 112', Icons.emergency, AppColors.orange500),
                      const SizedBox(width: 8),
                      _buildHotlinePill('Ambulans: 118', Icons.local_hospital, AppColors.green800),
                      const SizedBox(width: 8),
                      _buildHotlinePill('Polisi: 110', Icons.local_police, AppColors.indigo500),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. DAFTAR KORIDOR RAWAN BENCANA (SITINJAU, ANAI, KELOK 9, KELOK 44)
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
              ],
            ),
    );
  }

  Widget _buildHotlinePill(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
