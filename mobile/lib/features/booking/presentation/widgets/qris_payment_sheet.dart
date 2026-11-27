import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QrisPaymentSheet extends StatefulWidget {
  final int totalAmount;
  final List<Map<String, dynamic>> orderItems;
  final String destinationTitle;
  final VoidCallback onPaymentSuccess;
  final void Function(Map<String, dynamic> receipt)? onReceiptGenerated;

  const QrisPaymentSheet({
    super.key,
    required this.totalAmount,
    required this.orderItems,
    required this.destinationTitle,
    required this.onPaymentSuccess,
    this.onReceiptGenerated,
  });

  @override
  State<QrisPaymentSheet> createState() => _QrisPaymentSheetState();
}

class _QrisPaymentSheetState extends State<QrisPaymentSheet> {
  String _selectedMethod = 'QRIS'; // 'QRIS' | 'GOPAY' | 'OVO' | 'DANA' | 'SHOPEEPAY'
  int _secondsLeft = 900; // 15 menit
  Timer? _countdownTimer;
  bool _isPaid = false;
  bool _isVerifying = false;
  String? _liveTicketQr;

  final String _escrowCode = 'WG-ESCROW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _timerString {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _verifyPayment() {
    setState(() => _isVerifying = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isPaid = true;
        });
        widget.onPaymentSuccess();
        widget.onReceiptGenerated?.call({
          'transactionId': _escrowCode,
          'destinationTitle': widget.destinationTitle,
          'totalAmount': widget.totalAmount,
          'orderItems': widget.orderItems,
          'paymentMethod': _selectedMethod,
          'date': '16 Nov 2026 • 14:15 WIB',
          'status': 'LUNAS (TERVERIFIKASI)',
        });
      }
    });
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
                      'PEMBAYARAN RESMI TERVERIFIKASI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.brush,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPaid ? 'Bukti Bayar Berhasil' : 'Pindai QRIS / Pilih E-Wallet',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
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

          Expanded(
            child: _isPaid ? _buildSuccessReceipt() : _buildPaymentForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Total Card with Escrow badge
        Container(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 12, color: AppColors.forest),
                        SizedBox(width: 4),
                        Text(
                          'Rekening Escrow Wisgo Aman',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.terracotta),
                      const SizedBox(width: 3),
                      Text(
                        _timerString,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Rp ${_formatNumber(widget.totalAmount)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kode Transaksi: $_escrowCode',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Method selector: QRIS vs E-Wallet
        Row(
          children: [
            _buildMethodTab('QRIS', 'QRIS Dinamis', Icons.qr_code_2_rounded),
            const SizedBox(width: 8),
            _buildMethodTab('GOPAY', 'GoPay', Icons.account_balance_wallet_rounded),
            const SizedBox(width: 8),
            _buildMethodTab('OVO', 'OVO', Icons.wallet_rounded),
            const SizedBox(width: 8),
            _buildMethodTab('DANA', 'DANA', Icons.payments_rounded),
          ],
        ),
        const SizedBox(height: 14),

        // QR Code Box (If QRIS or QR-based e-wallet)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.forest, width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedMethod == 'QRIS' ? 'QRIS NASIONAL' : 'BAYAR VIA $_selectedMethod',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cream,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Procedural QR Code Canvas Representation
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: CustomPaint(
                  painter: _QrisPainter(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'NMID: ID1020268894192 - POKDARWIS SUMBAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Mendukung BCA, Mandiri, BRI, BNI, BSI, GoPay, OVO, DANA, ShopeePay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Verify button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isVerifying ? null : _verifyPayment,
            icon: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                  )
                : const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(
              _isVerifying ? 'Memverifikasi Pembayaran...' : 'Cek Status Pembayaran Otomatis',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTab(String key, String label, IconData icon) {
    final isSel = _selectedMethod == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.forest : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.forest : AppColors.sageBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSel ? AppColors.cream : AppColors.forest),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? AppColors.cream : AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessReceipt() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.forest, size: 36),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pembayaran Terverifikasi!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dana aman di Rekening Escrow Wisgo Nagari',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // E-Tiket QR Digital Resmi Escrow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.forest.withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.forest),
                  SizedBox(width: 6),
                  Text(
                    'E-TIKET QR DIGITAL RESMI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Text(
                  _liveTicketQr ?? 'QR-RANCAK-TKT-LIVE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tunjukkan kode QR ini ke mitra nagari saat tiba di lokasi untuk validasi kedatangan & pencairan dana escrow.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Receipt details card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: AppColors.forest),
                        SizedBox(width: 4),
                        Text(
                          'STRUK RESMI PEMDA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '16 Nov 2026 • 14:15 WIB',
                    style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nomor Transaksi', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  Text(_escrowCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
                ],
              ),
              const Divider(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tujuan Wisata', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  Expanded(
                    child: Text(
                      widget.destinationTitle,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 14),
              const Text('Rincian Layanan Resmi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 6),
              ...widget.orderItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(' x', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        Text('Rp ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forest)),
                      ],
                    ),
                  )),
              const Divider(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Text('Rp ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.forest)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Terlindungi Rekening Escrow Nagari. Dijamin bebas pungutan liar di pintu gerbang.',
                  style: TextStyle(fontSize: 11, color: AppColors.brush),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons: Print Struk and Close
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showPrintOptionsDialog(context),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Cetak / Print Struk Resmi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.creamSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: AppColors.forest),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Struk ini tersimpan di Profil Anda dan dapat dibuka kembali serta dicetak kapan saja.',
                  style: TextStyle(fontSize: 11, color: AppColors.forest, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.forest,
              side: const BorderSide(color: AppColors.forest, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Selesai & Tutup Bukti Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _showPrintOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print_rounded, color: AppColors.forest, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Cetak Struk Resmi Wisgo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Thermal Receipt Preview Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warmBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '=== STRUK RESMI TIKET NAGARI ===',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const Text(
                      'DINAS PARIWISATA PROV. SUMATERA BARAT',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No: ',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Destinasi: ',
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Divider(height: 12, thickness: 0.8, color: Colors.black26),
                    ...widget.orderItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(' x', style: const TextStyle(fontSize: 11)),
                              Text('Rp ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                    const Divider(height: 12, thickness: 0.8, color: Colors.black26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL PEMBAYARAN:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('Rp ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.forest)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'LUNAS TERVERIFIKASI RESMI\nTunjukkan bukti pembayaran ini pada petugas loket resmi nagari',
                      style: TextStyle(fontSize: 11, color: AppColors.brush, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PILIH METODE PENCETAKAN:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              _buildPrintOptionTile(
                icon: Icons.bluetooth_audio_rounded,
                title: 'Printer Kasir Thermal Bluetooth (POS)',
                subtitle: 'Koneksikan ke printer thermal 58mm / 80mm petugas',
                onTap: () {
                  Navigator.pop(ctx);
                  _showPrintSuccessFeedback('Mengirim struk ke Printer Thermal Bluetooth... Berhasil dicetak!');
                },
              ),
              const SizedBox(height: 8),
              _buildPrintOptionTile(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Simpan / Cetak Dokumen PDF Resmi',
                subtitle: 'Unduh file PDF struk resmi dengan QR Code Perda',
                onTap: () {
                  Navigator.pop(ctx);
                  _showPrintSuccessFeedback('Berkas PDF Struk Resmi berhasil dibuat & siap dicetak.');
                },
              ),
              const SizedBox(height: 8),
              _buildPrintOptionTile(
                icon: Icons.share_rounded,
                title: 'Bagikan Bukti Struk ke WhatsApp',
                subtitle: 'Kirim tautan struk resmi ke kontak rombongan',
                onTap: () {
                  Navigator.pop(ctx);
                  _showPrintSuccessFeedback('Tautan struk resmi siap dibagikan via WhatsApp!');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrintOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warmBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.forest),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  void _showPrintSuccessFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 11.5))),
          ],
        ),
        backgroundColor: AppColors.forest,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatNumber(int val) {
    final s = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}

class _QrisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = AppColors.ink;

    // Corner Finder Patterns
    _drawFinder(canvas, 10, 10, black);
    _drawFinder(canvas, size.width - 45, 10, black);
    _drawFinder(canvas, 10, size.height - 45, black);

    // Inner QR Matrix Dots
    const step = 8.0;
    for (double x = 15; x < size.width - 15; x += step) {
      for (double y = 15; y < size.height - 15; y += step) {
        // Skip corner finders
        if ((x < 50 && y < 50) || (x > size.width - 55 && y < 50) || (x < 50 && y > size.height - 55)) {
          continue;
        }
        if ((x * y) % 3 == 0 || (x + y) % 5 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, 5, 5), black);
        }
      }
    }

    // Center Logo Badge
    final centerBox = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 38,
      height: 38,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(centerBox, const Radius.circular(8)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(centerBox, const Radius.circular(8)), Paint()..color = AppColors.forest..style = PaintingStyle.stroke..strokeWidth = 2);

    final fontPainter = TextPainter(
      text: const TextSpan(
        text: 'WISGO',
        style: TextStyle(color: AppColors.forest, fontSize: 11, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    );
    fontPainter.layout();
    fontPainter.paint(
      canvas,
      Offset(size.width / 2 - fontPainter.width / 2, size.height / 2 - fontPainter.height / 2),
    );
  }

  void _drawFinder(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x, y, 35, 35), paint);
    canvas.drawRect(Rect.fromLTWH(x + 5, y + 5, 25, 25), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(x + 10, y + 10, 15, 15), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
