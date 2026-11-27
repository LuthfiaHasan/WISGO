import 'package:flutter/foundation.dart';

/// Model e-Tiket Resmi Trip Go WISGO yang tersimpan di Riwayat & Notifikasi
class TripETicket {
  final String bookingCode;
  final String tripId;
  final String tripTitle;
  final String singleDestination;
  final String category;
  final String departureDate;
  final String departureTime;
  final String duration;
  final String meetingPointName;
  final String meetingPointAddress;
  final String organizerName;
  final String organizerPhone;
  final int participantCount;
  final int totalAmount;
  final String paymentMethod;
  final DateTime issuedAt;

  const TripETicket({
    required this.bookingCode,
    required this.tripId,
    required this.tripTitle,
    required this.singleDestination,
    required this.category,
    required this.departureDate,
    required this.departureTime,
    required this.duration,
    required this.meetingPointName,
    required this.meetingPointAddress,
    required this.organizerName,
    required this.organizerPhone,
    required this.participantCount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.issuedAt,
  });
}

/// Penyimpanan terpusat e-Tiket Trip Go (terhubung ke Riwayat, Notifikasi & PDF Print)
class TripETicketStore extends ChangeNotifier {
  TripETicketStore._();
  static final TripETicketStore instance = TripETicketStore._();

  final List<TripETicket> _tickets = [];
  TripETicket? _lastIssuedTicket;

  List<TripETicket> get tickets => List.unmodifiable(_tickets);
  TripETicket? get lastIssuedTicket => _lastIssuedTicket;

  void addTicket(TripETicket ticket) {
    final alreadyExists =
        _tickets.any((t) => t.bookingCode == ticket.bookingCode);
    if (alreadyExists) return;
    _tickets.insert(0, ticket);
    _lastIssuedTicket = ticket;
    notifyListeners();
  }

  TripETicket? findByCode(String bookingCode) {
    for (final t in _tickets) {
      if (t.bookingCode == bookingCode) return t;
    }
    return null;
  }
}
