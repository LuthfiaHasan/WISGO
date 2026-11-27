import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/trip_eticket_store.dart';

/// Membuat file PDF e-Tiket Trip Go WISGO bergaya Boarding Pass yang siap di-print / unduh.
Future<Uint8List> buildTripETicketPdfBytes(TripETicket ticket) async {
  final doc = pw.Document(
    title: 'e-Tiket WISGO - ${ticket.bookingCode}',
    author: 'WISGO Sumatera Barat',
  );

  final forestColor = PdfColor.fromHex('#193D22');
  final brushColor = PdfColor.fromHex('#2F663E');
  final creamColor = PdfColor.fromHex('#FAF3E6');
  final sageColor = PdfColor.fromHex('#DFECE2');
  final goldColor = PdfColor.fromHex('#C89242');
  final inkColor = PdfColor.fromHex('#142618');
  final mutedColor = PdfColor.fromHex('#5A6B5D');
  final borderColor = PdfColor.fromHex('#D5E2D7');

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  final issuedStr =
      '${ticket.issuedAt.day.toString().padLeft(2, '0')}/${ticket.issuedAt.month.toString().padLeft(2, '0')}/${ticket.issuedAt.year} '
      '${ticket.issuedAt.hour.toString().padLeft(2, '0')}:${ticket.issuedAt.minute.toString().padLeft(2, '0')} WIB';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header Boarding Pass WISGO
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: forestColor,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(16),
                  topRight: pw.Radius.circular(16),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WISGO • EKOSISTEM WISATA PINTAR SUMBAR',
                        style: pw.TextStyle(
                          color: goldColor,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'E-TIKET RESMI TRIP GO',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Diterbitkan: $issuedStr',
                        style: const pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: sageColor,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      'LUNAS • ESCROW AKTIF',
                      style: pw.TextStyle(
                        color: forestColor,
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body Boarding Pass
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: creamColor,
                border: pw.Border.all(color: borderColor, width: 1.2),
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(16),
                  bottomRight: pw.Radius.circular(16),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Judul Trip & Kode Booking
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              ticket.category.toUpperCase(),
                              style: pw.TextStyle(
                                color: brushColor,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              ticket.tripTitle,
                              style: pw.TextStyle(
                                color: inkColor,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Destinasi Tunggal: ${ticket.singleDestination}',
                              style: pw.TextStyle(
                                color: mutedColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 14),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: forestColor, width: 1.2),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'KODE BOOKING',
                              style: pw.TextStyle(
                                color: mutedColor,
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              ticket.bookingCode,
                              style: pw.TextStyle(
                                color: forestColor,
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 16),
                  pw.Divider(color: borderColor),
                  pw.SizedBox(height: 14),

                  // Grid Detail Perjalanan & Titik Kumpul
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: _pdfInfoBox(
                          label: 'JADWAL KEBERANGKATAN',
                          value: '${ticket.departureDate}\n${ticket.departureTime} (${ticket.duration})',
                          labelColor: brushColor,
                          valueColor: inkColor,
                          borderColor: borderColor,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: _pdfInfoBox(
                          label: 'TITIK KUMPUL (GOOGLE MAPS)',
                          value: '${ticket.meetingPointName}\n${ticket.meetingPointAddress}',
                          labelColor: brushColor,
                          valueColor: inkColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: _pdfInfoBox(
                          label: 'PENYELENGGARA / PEMANDU',
                          value: '${ticket.organizerName}\nTelp: ${ticket.organizerPhone}',
                          labelColor: brushColor,
                          valueColor: inkColor,
                          borderColor: borderColor,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: _pdfInfoBox(
                          label: 'RINCIAN PEMBAYARAN',
                          value:
                              '${ticket.participantCount} Peserta • ${ticket.paymentMethod}\nTotal: Rp ${formatRupiah(ticket.totalAmount)} (LUNAS)',
                          labelColor: brushColor,
                          valueColor: forestColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 18),

                  // Garis Sobek + QR Code Verifikasi Lapangan
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Row(
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data:
                              'WISGO-ETICKET|${ticket.bookingCode}|${ticket.tripId}|${ticket.participantCount}',
                          width: 82,
                          height: 82,
                          color: forestColor,
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'VERIFIKASI KEHADIRAN DI TITIK KUMPUL',
                                style: pw.TextStyle(
                                  color: forestColor,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Tunjukkan QR Code atau Kode Booking ${ticket.bookingCode} ini kepada penyelenggara (${ticket.organizerName}) saat tiba di titik kumpul.',
                                style: pw.TextStyle(
                                  color: inkColor,
                                  fontSize: 9.5,
                                  lineSpacing: 2,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'Dana Anda dilindungi Rekening Penampung (Escrow) WISGO hingga perjalanan selesai dan terkonfirmasi.',
                                style: pw.TextStyle(
                                  color: mutedColor,
                                  fontSize: 8.5,
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
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _pdfInfoBox({
  required String label,
  required String value,
  required PdfColor labelColor,
  required PdfColor valueColor,
  required PdfColor borderColor,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: borderColor),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: labelColor,
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor,
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            lineSpacing: 2.5,
          ),
        ),
      ],
    ),
  );
}

/// Membuka dialog Print / Save as PDF langsung untuk e-Tiket Trip Go
Future<void> printOrDownloadTripETicketPdf(
  BuildContext context,
  TripETicket ticket,
) async {
  try {
    await Printing.layoutPdf(
      name: 'WISGO_eTiket_${ticket.bookingCode}.pdf',
      onLayout: (_) => buildTripETicketPdfBytes(ticket),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text('Gagal menyiapkan PDF e-Tiket: $e'),
      ),
    );
  }
}

/// Menampilkan Modal e-Tiket Resmi Trip Go (Boarding Pass + Tombol Print/Unduh PDF)
void showTripETicketSheet(BuildContext context, TripETicket ticket) {
  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'e-Tiket Resmi Trip Go',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Boarding Pass Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sageBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Hijau Rimba
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: AppColors.forest,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WISGO BOARDING PASS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                  color: AppColors.goldSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ticket.bookingCode,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'LUNAS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Isi e-Tiket
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.tripTitle,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Destinasi Tunggal: ${ticket.singleDestination}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brush,
                            ),
                          ),
                          const Divider(height: 22, color: AppColors.divider),
                          _ticketRow(
                            'Jadwal',
                            '${ticket.departureDate} • ${ticket.departureTime}',
                          ),
                          const SizedBox(height: 6),
                          _ticketRow('Titik Kumpul', ticket.meetingPointName),
                          const SizedBox(height: 6),
                          _ticketRow(
                            'Penyelenggara',
                            '${ticket.organizerName} (${ticket.organizerPhone})',
                          ),
                          const SizedBox(height: 6),
                          _ticketRow(
                            'Peserta & Metode',
                            '${ticket.participantCount} Orang • ${ticket.paymentMethod}',
                          ),
                          const SizedBox(height: 6),
                          _ticketRow(
                            'Total Terbayar',
                            'Rp ${formatRupiah(ticket.totalAmount)}',
                            valueColor: AppColors.success,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.creamSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warmBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 38,
                                  color: AppColors.forest,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tunjukkan e-Tiket ini kepada ${ticket.organizerName} saat kumpul di titik Google Maps.',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
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
              ),
              const SizedBox(height: 16),

              // Tombol Unduh / Print PDF
              ElevatedButton.icon(
                onPressed: () => printOrDownloadTripETicketPdf(ctx, ticket),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text(
                  'Unduh / Print e-Tiket (PDF)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: AppColors.cream,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _ticketRow(String label, String value, {Color? valueColor}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ),
    ],
  );
}
