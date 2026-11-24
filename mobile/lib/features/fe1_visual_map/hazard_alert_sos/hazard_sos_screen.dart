import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
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
  bool _isLoading = true;
  List<HazardAlertModel> _corridors = [];
  List<EmergencyContactModel> _officialContacts = [];

  @override
  void initState() {
    super.initState();
    _loadHazards();
  }

  Future<void> _loadHazards() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getHazardAlerts(),
      _repository.getEmergencyContacts(),
    ]);
    if (!mounted) return;
    setState(() {
      _corridors = results[0] as List<HazardAlertModel>;
      _officialContacts = results[1] as List<EmergencyContactModel>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Pantauan Jalur Rawan & Kontak Darurat'),
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
                // 1. HOTLINE DARURAT SUMATERA BARAT
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
                      _buildHotlinePill('SAR Sumbar: 115', 'Basarnas Padang / Sumbar', '115', Icons.phone_in_talk, Colors.red.shade700),
                      const SizedBox(width: 8),
                      _buildHotlinePill('BPBD: 112', 'BPBD & Damkar Terpadu', '112', Icons.emergency, AppColors.orange500),
                      const SizedBox(width: 8),
                      _buildHotlinePill('Ambulans: 118', 'Layanan Medis Darurat', '118', Icons.local_hospital, AppColors.green800),
                      const SizedBox(width: 8),
                      _buildHotlinePill('Polisi: 110', 'Kepolisian RI (Polri)', '110', Icons.local_police, AppColors.indigo500),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2B. 6 NOMOR DARURAT BENCANA RESMI SUMATERA BARAT (DATA REAL)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nomor Darurat Bencana Sumbar',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.green800.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '6 Kontak Resmi',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._buildOfficialEmergencyCards(),
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

  Color _getContactColor(String agencyType) {
    switch (agencyType.toLowerCase()) {
      case 'damkar':
        return Colors.deepOrange;
      case 'pmi':
        return Colors.red.shade700;
      case 'polisi':
        return AppColors.indigo500;
      case 'bpbd':
      default:
        return AppColors.orange500;
    }
  }

  IconData _getContactIcon(String agencyType) {
    switch (agencyType.toLowerCase()) {
      case 'damkar':
        return Icons.local_fire_department;
      case 'pmi':
        return Icons.health_and_safety;
      case 'polisi':
        return Icons.local_police;
      case 'bpbd':
      default:
        return Icons.emergency;
    }
  }

  List<Widget> _buildOfficialEmergencyCards() {
    if (_officialContacts.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              'Memuat kontak darurat dari server backend...',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
        ),
      ];
    }

    return _officialContacts.map((c) {
      final name = c.agencyName;
      final phone = c.phoneNumber;
      final city = c.city;
      final color = _getContactColor(c.agencyType);
      final icon = _getContactIcon(c.agencyType);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showCallSimulationDialog(name, phone, icon, color),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          city,
                          style: const TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cream100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showCallSimulationDialog(String agency, String number, IconData icon, Color color) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Simulasi Panggilan Darurat',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instansi: $agency',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink900),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Nomor Darurat: ', style: TextStyle(fontSize: 13, color: Colors.black54)),
                Text(
                  number,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFF57F17), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode Uji Coba: Fitur dialer otomatis sengaja ditahan agar tidak melakukan panggilan nyata ke nomor darurat instansi terkait saat pengujian/demo.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037), height: 1.35),
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
            child: const Text('Tutup', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlinePill(String title, String agency, String number, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCallSimulationDialog(agency, number, icon, color),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
        ),
      ),
    );
  }
}
