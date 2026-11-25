import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';

/// Modal Transaksi Langsung Melalui Sistem WISGO (Item 3 Open Trip)
class OpenTripPaymentSheet extends StatefulWidget {
  final OpenTripItem trip;

  const OpenTripPaymentSheet({
    super.key,
    required this.trip,
  });

  @override
  State<OpenTripPaymentSheet> createState() => _OpenTripPaymentSheetState();
}

class _OpenTripPaymentSheetState extends State<OpenTripPaymentSheet> {
  int _participantCount = 1;
  String _selectedPaymentMethod = 'QRIS'; // 'QRIS', 'WISGO_PAY', 'VIRTUAL_ACCOUNT'
  bool _isProcessing = false;
  bool _isPaid = false;
  bool _agreedToTerms = false;
  String _bookingCode = '';

  @override
  void initState() {
    super.initState();
    _bookingCode = 'TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  int get _availableSlots => widget.trip.quotaMax - widget.trip.quotaFilled;
  int get _totalAmount => widget.trip.pricePerPerson * _participantCount;

  void _processPayment() {
    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isPaid = true;
        widget.trip.quotaFilled = (widget.trip.quotaFilled + _participantCount).clamp(0, widget.trip.quotaMax);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: SafeArea(
        top: false,
        child: _isPaid ? _buildSuccessReceipt() : _buildCheckoutForm(),
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.forest, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRANSAKSI SISTEM RESMI WISGO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.forest,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pembayaran Aman & Escrow Terlindungi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ringkasan Trip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.creamSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.trip.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Destinasi Tunggal: ${widget.trip.singleDestination}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.trip.departureDate} • ${widget.trip.departureTime}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                ),
                Text(
                  'Titik Kumpul: ${widget.trip.meetingPointName}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pengaturan Jumlah Peserta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah Peserta',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  Text(
                    'Sisa kuota: $_availableSlots orang',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _participantCount > 1
                        ? () => setState(() => _participantCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.forest,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: Text(
                      '$_participantCount',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                  ),
                  IconButton(
                    onPressed: _participantCount < _availableSlots
                        ? () => setState(() => _participantCount++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.forest,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pilihan Metode Pembayaran
          const Text(
            'Metode Pembayaran Resmi WISGO',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            id: 'QRIS',
            name: 'QRIS WISGO (Semua Bank & e-Wallet)',
            desc: 'BCA, Mandiri, BRI, BNI, GoPay, OVO, ShopeePay',
            icon: Icons.qr_code_scanner_rounded,
          ),
          _buildPaymentOption(
            id: 'WISGO_PAY',
            name: 'Saldo Dompet WISGO Pay',
            desc: 'Saldo Anda: Rp 350.000 (Langsung Terpotong)',
            icon: Icons.account_balance_wallet_rounded,
          ),
          _buildPaymentOption(
            id: 'VIRTUAL_ACCOUNT',
            name: 'Virtual Account Bank Nagari / BSI',
            desc: 'Konfirmasi otomatis 24 jam tanpa upload bukti',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),

          // 1. Rincian Fasilitas & Layanan (Include & Exclude - Item 1 Spesifikasi Trip Go)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.creamSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Fasilitas Termasuk (Include):',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
                const SizedBox(height: 4),
                ...widget.trip.includes.map((inc) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          inc,
                          style: const TextStyle(fontSize: 11, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                const Text(
                  'Tidak Termasuk (Exclude):',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.danger),
                ),
                const SizedBox(height: 4),
                ...widget.trip.excludes.map((exc) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel_rounded, size: 13, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          exc,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Rincian Biaya Transparan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.creamSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildFeeRow('Tarif Trip Go (${_participantCount}x)', 'Rp ${_formatRupiah(_totalAmount)}'),
                const SizedBox(height: 6),
                _buildFeeRow('Asuransi Keselamatan Rekreasi', 'Termasuk (Rp 0)'),
                const SizedBox(height: 6),
                _buildFeeRow('Proteksi Escrow Rekening Penampung', 'Gratis Resmi WISGO'),
                const Divider(height: 16, color: AppColors.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text('Rp ${_formatRupiah(_totalAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.forest)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Banner Escrow & Payment Gateway Terpusat (Item 7 Spesifikasi Trip Go)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_rounded, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Gateway & Rekening Penampung Terpusat',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pembayaran disalurkan melalui Payment Gateway resmi ke Rekening Penampung WISGO (Escrow Admin). Dana baru diteruskan ke penyelenggara setelah trip selesai dan terkonfirmasi.',
                        style: TextStyle(fontSize: 11, color: AppColors.forest, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Checkbox Persetujuan Ketentuan & Tanggung Jawab Platform (Item 3 Spesifikasi Trip Go)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  activeColor: AppColors.forest,
                  onChanged: (val) {
                    setState(() => _agreedToTerms = val ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8, right: 8),
                      child: Text(
                        'Saya memahami & menyetujui bahwa WISGO hanya sebagai penyedia platform digital. Seluruh proses dan aktivitas teknis selama pelaksanaan Trip Go menjadi tanggung jawab bersama antara pihak penyelenggara dan peserta.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warningDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Bayar (Hanya aktif bila checkbox telah disetujui)
          ElevatedButton(
            onPressed: (!_agreedToTerms || _isProcessing) ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Bayar Rp ${_formatRupiah(_totalAmount)} via Payment Gateway WISGO',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessReceipt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'TRANSAKSI WISGO BERHASIL!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.forest),
        ),
        const SizedBox(height: 4),
        const Text(
          'e-Tiket Resmi Trip Go & Perlindungan Escrow Aktif',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.creamSubtle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nomor Transaksi:', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  Text(_bookingCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
                ],
              ),
              const Divider(height: 16, color: AppColors.divider),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Destinasi Tunggal:', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  Text(widget.trip.singleDestination, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Terbayar:', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  Text('Rp ${_formatRupiah(_totalAmount)} (LUNAS)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Metode Pembayaran:', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  Text(_selectedPaymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 28, color: AppColors.forest),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tunjukkan e-Tiket ini kepada ${widget.trip.organizer.name} saat kumpul di titik Google Maps.',
                        style: const TextStyle(fontSize: 11, color: AppColors.forest, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Simpan e-Tiket & Selesai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String name,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.successBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.success : AppColors.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.success : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF065F46) : AppColors.ink,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.success : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ],
    );
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
