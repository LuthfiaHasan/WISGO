import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';
import '../../services/trip_eticket_store.dart';
import 'trip_eticket_sheet.dart';

/// Modal Pembayaran Open Trip yang ringkas, bersih, dan user-friendly.
/// Total Pembayaran & Tombol Bayar dipaku (sticky) di bagian bawah agar tidak perlu di-scroll.
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
  String _selectedPaymentMethod = 'QRIS';
  bool _isProcessing = false;
  bool _isPaid = false;
  bool _agreedToTerms = false;
  String _bookingCode = '';
  TripETicket? _issuedTicket;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emergencyCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bookingCode =
        'TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _availableSlots => widget.trip.quotaMax - widget.trip.quotaFilled;
  int get _totalAmount => widget.trip.pricePerPerson * _participantCount;

  void _processPayment() {
    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      final ticket = TripETicket(
        bookingCode: _bookingCode,
        tripId: widget.trip.id,
        tripTitle: widget.trip.title,
        singleDestination: widget.trip.singleDestination,
        category: widget.trip.category,
        departureDate: widget.trip.departureDate,
        departureTime: widget.trip.departureTime,
        duration: widget.trip.duration,
        meetingPointName: widget.trip.meetingPointName,
        meetingPointAddress: widget.trip.meetingPointAddress,
        organizerName: widget.trip.organizer.name,
        organizerPhone: widget.trip.organizer.phone,
        participantCount: _participantCount,
        totalAmount: _totalAmount,
        paymentMethod: _selectedPaymentMethod,
        issuedAt: DateTime.now(),
      );
      TripETicketStore.instance.addTicket(ticket);
      widget.trip.participants.insert(
        0,
        OpenTripParticipant(
          userId: 'usr-current',
          bookingCode: _bookingCode,
          fullName: _nameCtrl.text.trim().isEmpty
              ? 'Peserta Open Trip'
              : _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim().isEmpty
              ? '0812-3456-7890'
              : _phoneCtrl.text.trim(),
          emergencyContact: _emergencyCtrl.text.trim().isEmpty
              ? '-'
              : _emergencyCtrl.text.trim(),
          seatCount: _participantCount,
          paymentMethod: _selectedPaymentMethod,
          totalPaid: _totalAmount,
          specialNotes: _notesCtrl.text.trim(),
          joinedAt: 'Hari ini',
          isScheduleReady: widget.trip.isScheduleReviewed,
          readinessDone:
              widget.trip.readinessChecklist.where((e) => e.isDone).length,
          readinessTotal: widget.trip.readinessChecklist.length,
          packingDone: widget.trip.packingList.where((e) => e.isPacked).length,
          packingTotal: widget.trip.packingList.length,
          isFinalized: widget.trip.isReadinessFinalized,
        ),
      );
      setState(() {
        _isProcessing = false;
        _isPaid = true;
        _issuedTicket = ticket;
        widget.trip.isCurrentUserJoined = true;
        widget.trip.quotaFilled =
            (widget.trip.quotaFilled + _participantCount)
                .clamp(0, widget.trip.quotaMax);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsetsBottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: _isPaid ? _buildSuccessReceipt() : _buildCheckoutLayout(),
        ),
      ),
    );
  }

  Widget _buildCheckoutLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. HEADER TETAP (TIDAK IKUT SCROLL)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 10),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: AppColors.forest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembayaran Open Trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Lengkapi data peserta & pilih metode pembayaran',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.warmBorder),

        // 2. KONTEN FORM RINGKAS
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kartu Ringkasan Trip + Jumlah Peserta
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trip.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 14,
                            color: AppColors.forest,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.trip.singleDestination,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.trip.departureDate} • ${widget.trip.departureTime} • ${widget.trip.meetingPointName}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const Divider(height: 18, color: AppColors.warmBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jumlah Peserta',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'Tersedia $_availableSlots kursi • Rp ${_formatRupiah(widget.trip.pricePerPerson)}/orang',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildStepButton(
                                icon: Icons.remove_rounded,
                                enabled: _participantCount > 1,
                                onTap: () =>
                                    setState(() => _participantCount--),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '$_participantCount',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                              _buildStepButton(
                                icon: Icons.add_rounded,
                                enabled: _participantCount < _availableSlots,
                                onTap: () =>
                                    setState(() => _participantCount++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Data Peserta
                const Text(
                  'Data Peserta',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: _fieldDecoration('Nama lengkap'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _fieldDecoration('Nomor WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _emergencyCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _fieldDecoration('Kontak darurat'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  decoration: _fieldDecoration('Catatan tambahan'),
                ),
                const SizedBox(height: 14),

                // Metode Pembayaran
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  id: 'QRIS',
                  name: 'QRIS',
                  desc: 'Semua bank & dompet digital',
                  icon: Icons.qr_code_scanner_rounded,
                ),
                _buildPaymentOption(
                  id: 'WISGO_PAY',
                  name: 'WISGO Pay',
                  desc: 'Saldo tersedia Rp 350.000',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _buildPaymentOption(
                  id: 'VIRTUAL_ACCOUNT',
                  name: 'Virtual Account',
                  desc: 'Bank Nagari & BSI',
                  icon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 10),

                // Fasilitas Singkat (Tanpa kata Include/Exclude)
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
                        'Sudah Termasuk',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.trip.includes.join(' • '),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.ink,
                          height: 1.35,
                        ),
                      ),
                      if (widget.trip.excludes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Tidak Termasuk',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.trip.excludes.join(' • '),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. STICKY FOOTER: TOTAL PEMBAYARAN & TOMBOL BAYAR (SELALU TAMPIL)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: const Border(
              top: BorderSide(color: AppColors.warmBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.forest,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) =>
                              setState(() => _agreedToTerms = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Saya menyetujui ketentuan perjalanan Open Trip ini.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran • $_participantCount orang',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${_formatRupiah(_totalAmount)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: (!_agreedToTerms || _isProcessing)
                          ? null
                          : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.warmBorder,
                        disabledForegroundColor: AppColors.muted,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Bayar Sekarang',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? AppColors.cream : AppColors.creamSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.sageBorder : AppColors.warmBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.forest : AppColors.muted,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
      filled: true,
      fillColor: AppColors.bgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.warmBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.4),
      ),
    );
  }

  Widget _buildSuccessReceipt() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pembayaran Berhasil',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'e-Tiket resmi perjalanan Anda sudah aktif',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Column(
              children: [
                _buildReceiptRow('Kode Booking', _bookingCode, isBold: true),
                const Divider(height: 16, color: AppColors.warmBorder),
                _buildReceiptRow('Destinasi', widget.trip.singleDestination),
                const SizedBox(height: 6),
                _buildReceiptRow(
                  'Total Dibayar',
                  'Rp ${_formatRupiah(_totalAmount)}',
                  valueColor: AppColors.success,
                  isBold: true,
                ),
                const SizedBox(height: 6),
                _buildReceiptRow('Metode Pembayaran', _selectedPaymentMethod),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_2_rounded,
                        size: 26,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tunjukkan e-Tiket ini kepada ${widget.trip.organizer.name} saat di titik kumpul.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_issuedTicket != null) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  printOrDownloadTripETicketPdf(context, _issuedTicket!),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text(
                'Unduh e-Tiket PDF',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forest,
                side: const BorderSide(color: AppColors.forest, width: 1.3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.forest,
                  content: Text(
                    'e-Tiket tersimpan di Riwayat Profil & Notifikasi.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Simpan e-Tiket & Selesai',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? AppColors.ink,
            ),
          ),
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
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.successBg : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.success : AppColors.warmBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.success : AppColors.forest,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.forest : AppColors.ink,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.success : AppColors.muted,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
