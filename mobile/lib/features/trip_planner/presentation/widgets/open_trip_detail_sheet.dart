import 'package:flutter/material.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/auth_guard.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';
import 'open_trip_offline_rules_sheet.dart';
import 'trip_go_agreement_dialog.dart';
import 'trip_group_chat_sheet.dart';
import 'verified_organizer_sheet.dart';

/// Modal Bottom Sheet Detail & Kelola Open Trip (Item 1-7 Open Trip)
/// Mengimplementasikan alur interaksi resmi BE-2:
/// - GET /api/v1/community/shared-trips/:id (Detail Trip + Daftar Peserta)
/// - POST /api/v1/community/shared-trips/:id/join (Gabung untuk Tamu / Non-Host)
/// - PUT /api/v1/community/shared-trips/:id (Edit semua field untuk Host)
/// - DELETE /api/v1/community/shared-trips/:id (Hapus Trip untuk Host)
class OpenTripDetailSheet extends StatefulWidget {
  final OpenTripItem trip;
  final ValueChanged<OpenTripItem>? onTripUpdated;
  final ValueChanged<String>? onTripDeleted;

  const OpenTripDetailSheet({
    super.key,
    required this.trip,
    this.onTripUpdated,
    this.onTripDeleted,
  });

  @override
  State<OpenTripDetailSheet> createState() => _OpenTripDetailSheetState();
}

class _OpenTripDetailSheetState extends State<OpenTripDetailSheet> {
  late OpenTripItem _currentTrip;
  bool _isLoading = true;
  bool _isJoining = false;
  List<OpenTripParticipant> _participants = [];
  int _totalParticipants = 0;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _loadTripDetail();
  }

  bool get _isHost {
    return ApiConfig.isAuthenticated &&
        _currentTrip.userId == ApiConfig.currentUserId;
  }

  bool get _hasJoined {
    return ApiConfig.isAuthenticated &&
        _participants.any((p) => p.userId == ApiConfig.currentUserId);
  }

  int get _availableSeats => _currentTrip.quotaMax - _currentTrip.quotaFilled;
  bool get _isQuotaFull => _availableSeats <= 0;

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _loadTripDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getSharedTripDetail(_currentTrip.id);
      if (!mounted) return;

      if (response.isSuccess && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final tripData = data['trip'];
        if (tripData is Map<String, dynamic>) {
          final newTitle = tripData['title']?.toString() ?? _currentTrip.title;
          final newRoute = tripData['destination_route']?.toString() ??
              _currentTrip.singleDestination;
          final newCat =
              tripData['category']?.toString() ?? _currentTrip.category;
          final newDestId = tripData['destination_id']?.toString() ??
              _currentTrip.destinationId;
          final newUserId =
              tripData['user_id']?.toString() ?? _currentTrip.userId;
          final newWa =
              tripData['contact_wa']?.toString() ?? _currentTrip.contactWa;
          final cost = tripData['cost_per_person'];
          final newCost =
              cost is num ? cost.toInt() : _currentTrip.pricePerPerson;
          final seats = tripData['available_seats'];
          final newSeats =
              seats is int ? seats : _currentTrip.availableSeats;

          _currentTrip = _currentTrip.copyWith(
            title: newTitle,
            singleDestination: newRoute,
            category: newCat,
            destinationId: newDestId,
            userId: newUserId,
            contactWa: newWa,
            pricePerPerson: newCost,
            quotaFilled: _currentTrip.quotaMax - newSeats,
          );
        }

        final pList = data['participants'];
        if (pList is List) {
          _participants = pList
              .whereType<Map<String, dynamic>>()
              .map((j) => OpenTripParticipant.fromJson(j))
              .toList();
        }
        _totalParticipants =
            (data['total_participants'] as int?) ?? _participants.length;
      } else {
        // Fallback offline / mock default participants
        if (_participants.isEmpty && _currentTrip.quotaFilled > 0) {
          _participants = [
            OpenTripParticipant(
              userId: 'usr-peserta-01',
              fullName: 'Budi Santoso',
              phoneNumber: '0812-2222-3333',
              joinedAt: 'Kemarin, 14.30 WIB',
            ),
            OpenTripParticipant(
              userId: 'usr-peserta-02',
              fullName: 'Siti Rahmawati',
              phoneNumber: '0813-8888-9999',
              joinedAt: 'Hari ini, 08.15 WIB',
            ),
          ];
          _totalParticipants = _participants.length;
        }
      }
    } catch (_) {
      // Fallback rapi jika luring
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleJoinTrip() async {
    final allowed = AuthGuard.check(context);
    if (!allowed) return;

    if (_isQuotaFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maaf, kuota Trip Go ini sudah penuh.')),
      );
      return;
    }

    // Pop-up Persetujuan Syarat & Ketentuan Trip Go sebelum bergabung (Poin 4)
    final agreed = await showTripGoJoinAgreementDialog(
      context,
      tripTitle: _currentTrip.title,
    );
    if (!agreed || !mounted) return;

    setState(() => _isJoining = true);
    try {
      final res = await ApiService.joinSharedTrip(
        tripId: _currentTrip.id,
        userId: ApiConfig.currentUserId,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        final updatedFilled = _currentTrip.quotaFilled + 1;
        _currentTrip = _currentTrip.copyWith(
          quotaFilled: updatedFilled > _currentTrip.quotaMax
              ? _currentTrip.quotaMax
              : updatedFilled,
        );
        _participants.add(
          OpenTripParticipant(
            userId: ApiConfig.currentUserId,
            fullName: ApiConfig.currentUserName,
            phoneNumber: ApiConfig.currentUserPhone.isNotEmpty
                ? ApiConfig.currentUserPhone
                : '0812-3456-7890',
            joinedAt: 'Baru saja',
          ),
        );
        _totalParticipants++;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selamat! Anda berhasil bergabung ke Trip Go.'),
            backgroundColor: AppColors.forest,
          ),
        );
        widget.onTripUpdated?.call(_currentTrip);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty
                ? res.message
                : 'Gagal bergabung ke Trip Go'),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kendala: $e'),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _confirmDeleteTrip() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.coralTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.terracotta,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Hapus Trip Go?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus Trip Go ini? Seluruh jadwal dan peserta terdaftar akan dibatalkan.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Hapus Trip',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final res = await ApiService.deleteSharedTrip(
      tripId: _currentTrip.id,
      userId: ApiConfig.currentUserId,
    );

    if (!mounted) return;

    if (res.isSuccess) {
      Navigator.of(context).pop(); // Tutup detail sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip Go berhasil dihapus'),
          backgroundColor: AppColors.forest,
        ),
      );
      widget.onTripDeleted?.call(_currentTrip.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty
              ? res.message
              : 'Gagal menghapus Trip Go'),
          backgroundColor: AppColors.terracotta,
        ),
      );
    }
  }

  void _openEditTripForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditOpenTripSheet(
        trip: _currentTrip,
        onSaved: (updatedTrip) {
          setState(() {
            _currentTrip = updatedTrip;
          });
          widget.onTripUpdated?.call(updatedTrip);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.warmBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.forest.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DETAIL TRIP GO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.forest,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (_isHost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.coralTint,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.terracotta
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'ANDA HOST',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.terracotta,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentTrip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.forest, size: 24),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.warmBorder),

          // Scrollable Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.forest),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Banner
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.network(
                                _currentTrip.coverUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: AppColors.sage,
                                  child: const Center(
                                    child: Icon(Icons.landscape_rounded,
                                        size: 48, color: AppColors.forest),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.70),
                                      ],
                                      stops: const [0.4, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.forest
                                        .withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _currentTrip.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 12,
                                right: 12,
                                child: Row(
                                  children: [
                                    const Icon(Icons.place_rounded,
                                        color: AppColors.cream, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _currentTrip.singleDestination,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Informasi Utama Grid
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.sageBorder),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Tanggal Keberangkatan',
                                value: _currentTrip.departureDate,
                                valueColor: AppColors.forest,
                              ),
                              const Divider(height: 16, color: AppColors.creamSubtle),
                              _buildInfoRow(
                                icon: Icons.payments_rounded,
                                label: 'Biaya Patungan',
                                value: 'Rp ${_formatRupiah(_currentTrip.pricePerPerson)} / org',
                                valueColor: AppColors.forest,
                              ),
                              const Divider(height: 16, color: AppColors.creamSubtle),
                              _buildInfoRow(
                                icon: Icons.airline_seat_recline_normal_rounded,
                                label: 'Sisa Kursi',
                                value: '$_availableSeats Kursi Tersisa',
                                valueColor: _isQuotaFull
                                    ? AppColors.terracotta
                                    : AppColors.forest,
                              ),
                              const Divider(height: 16, color: AppColors.creamSubtle),
                              _buildInfoRow(
                                icon: Icons.forum_rounded,
                                label: 'Kanal Komunikasi',
                                value: _currentTrip.communicationChannel,
                                valueColor: AppColors.forest,
                              ),
                              const Divider(height: 16, color: AppColors.creamSubtle),
                              _buildInfoRow(
                                icon: Icons.group_rounded,
                                label: 'Total Peserta',
                                value: '$_totalParticipants Terdaftar',
                                valueColor: AppColors.ink,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Deskripsi Destinasi Informatif & Kondisi Sebenarnya (Item 5 Spesifikasi Trip Go)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.sageBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.forest),
                                  SizedBox(width: 6),
                                  Text(
                                    'Deskripsi & Kondisi Nyata Destinasi',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _currentTrip.destinationDescription,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ink,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Rincian Detail Harga: Include & Exclude (Item 1 Spesifikasi Trip Go)
                        Container(
                          width: double.infinity,
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
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Detail Fasilitas & Layanan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatRupiah(_currentTrip.pricePerPerson)}/org',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Sudah Termasuk',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ..._currentTrip.includes.map((inc) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        inc,
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 8),
                              const Text(
                                'Tidak Termasuk',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ..._currentTrip.excludes.map((exc) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.cancel_rounded, size: 14, color: AppColors.danger),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        exc,
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card Penyelenggara Terverifikasi (Item 2 Spesifikasi Trip Go)
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => VerifiedOrganizerSheet(organizer: _currentTrip.organizer),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.successBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, size: 24, color: AppColors.success),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentTrip.organizer.name,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Penyelenggara Terverifikasi 7-Poin WISGO • ★ ${_currentTrip.organizer.rating}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.success, size: 20),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // TAMPILAN KHUSUS HOST: Daftar Peserta Bergabung
                        if (_isHost) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daftar Peserta Bergabung ($_totalParticipants)',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forest,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Sisa $_availableSeats',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_participants.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppColors.sageBorder),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.people_outline_rounded,
                                      size: 36, color: AppColors.muted),
                                  SizedBox(height: 8),
                                  Text(
                                    'Belum ada peserta yang bergabung',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _participants.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final p = _participants[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.sageBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.sage,
                                        child: Text(
                                          p.fullName.isNotEmpty
                                              ? p.fullName[0].toUpperCase()
                                              : 'P',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.fullName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Gabung: ${p.joinedAt}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: IconButton(
                                          tooltip: 'Buka Grup Chat Trip',
                                          icon: const Icon(
                                            Icons.forum_outlined,
                                            color: AppColors.forest,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (_) => TripGroupChatSheet(
                                                trip: _currentTrip,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 16),
                        ],

                        // Ruang Grup Chat In-App & SOP Perjalanan (Tanpa WhatsApp)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => TripGroupChatSheet(
                                      trip: _currentTrip,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.forum_rounded, size: 16),
                                label: const Text(
                                  'Chat',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.forest,
                                  backgroundColor: AppColors.sage,
                                  side: const BorderSide(
                                    color: AppColors.sageBorder,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => OpenTripOfflineRulesSheet(
                                      trip: _currentTrip,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.rule_folder_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'SOP Perjalanan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.forest,
                                  side: const BorderSide(
                                    color: AppColors.sageBorder,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.warmBorder)),
            ),
            child: SafeArea(
              child: _isHost
                  // Host Controls: Edit & Hapus
                  ? Row(
                      children: [
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: OutlinedButton.icon(
                              onPressed: _openEditTripForm,
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text(
                                'Edit Trip Go',
                                style: TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w800),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.forest,
                                side: const BorderSide(
                                    color: AppColors.forest, width: 1.4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ElevatedButton.icon(
                              onPressed: _confirmDeleteTrip,
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16),
                              label: const Text(
                                'Hapus Trip',
                                style: TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracotta,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  // Tamu & Peserta: Gabung / Penuh / Terdaftar
                  : SizedBox(
                      width: double.infinity,
                      child: _hasJoined
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.sageBorder),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: AppColors.forest, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Anda Sudah Terdaftar di Trip Ini',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _isQuotaFull
                              ? Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.coralTint,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Penuh (Kuota Kursi Habis)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.terracotta,
                                      ),
                                    ),
                                  ),
                                )
                              : MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isJoining ? null : _handleJoinTrip,
                                    icon: _isJoining
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.group_add_rounded,
                                            size: 18),
                                    label: Text(
                                      _isJoining
                                          ? 'Memproses...'
                                          : 'Gabung Trip Go',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.forest,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.forest),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Form Edit Open Trip (Membebaskan seluruh field untuk Host)
class _EditOpenTripSheet extends StatefulWidget {
  final OpenTripItem trip;
  final ValueChanged<OpenTripItem> onSaved;

  const _EditOpenTripSheet({
    required this.trip,
    required this.onSaved,
  });

  @override
  State<_EditOpenTripSheet> createState() => _EditOpenTripSheetState();
}

class _EditOpenTripSheetState extends State<_EditOpenTripSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _seatsController;
  late final TextEditingController _costController;
  late final TextEditingController _waController;

  late String _selectedDestinationId;
  late String _selectedDestinationName;
  late String _category;
  late DateTime _departureDate;
  bool _isSaving = false;

  // Katalog 5 Destinasi Utama BE-1
  static const List<Map<String, String>> _destCatalog = [
    {
      'id': 'dest-001',
      'name': 'Lembah Harau & Sarasah Bunta',
      'category': 'Wisata Alam & Pegunungan',
    },
    {
      'id': 'dest-002',
      'name': 'Jam Gadang Bukittinggi',
      'category': 'Wisata Sejarah & Budaya',
    },
    {
      'id': 'dest-003',
      'name': 'Pantai Carocok Painan & Pulau Cingkuak',
      'category': 'Wisata Bahari & Pantai',
    },
    {
      'id': 'dest-004',
      'name': 'Danau Maninjau & Kelok 44',
      'category': 'Wisata Alam & Pegunungan',
    },
    {
      'id': 'dest-005',
      'name': 'Kawasan Mandeh (Raja Ampat Minang)',
      'category': 'Wisata Bahari & Pantai',
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip.title);
    _seatsController = TextEditingController(
        text: widget.trip.availableSeats.toString());
    _costController = TextEditingController(
        text: widget.trip.pricePerPerson.toString());
    _waController = TextEditingController(text: widget.trip.contactWa);

    _selectedDestinationId = widget.trip.destinationId.isNotEmpty
        ? widget.trip.destinationId
        : 'dest-001';

    final matched = _destCatalog.firstWhere(
      (d) => d['id'] == _selectedDestinationId,
      orElse: () => _destCatalog.first,
    );
    _selectedDestinationName = matched['name']!;
    _category = matched['category']!;
    _departureDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _seatsController.dispose();
    _costController.dispose();
    _waController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _departureDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul trip tidak boleh kosong')),
      );
      return;
    }

    final seats = int.tryParse(_seatsController.text.trim()) ?? 0;
    if (seats < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sisa kursi tidak valid')),
      );
      return;
    }

    final cost = double.tryParse(_costController.text.trim()) ?? 0;
    final wa = _waController.text.trim();

    setState(() => _isSaving = true);

    try {
      final res = await ApiService.updateSharedTrip(
        tripId: widget.trip.id,
        userId: ApiConfig.currentUserId,
        title: title,
        destinationId: _selectedDestinationId,
        departureDate: _departureDate,
        availableSeats: seats,
        costPerPerson: cost,
        contactWa: wa,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        final updatedTrip = widget.trip.copyWith(
          title: title,
          singleDestination: _selectedDestinationName,
          category: _category,
          destinationId: _selectedDestinationId,
          contactWa: wa,
          pricePerPerson: cost.toInt(),
          quotaFilled: widget.trip.quotaMax - seats,
          departureDate:
              '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
        );

        Navigator.of(context).pop(); // Tutup form edit
        widget.onSaved(updatedTrip);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip Go berhasil diperbarui'),
            backgroundColor: AppColors.forest,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty
                ? res.message
                : 'Gagal memperbarui Trip Go (Error ${res.statusCode})'),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kendala: $e'),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.warmBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Trip Go',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.forest),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.warmBorder),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Trip
                  const Text(
                    'Judul Trip Go',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Contoh: Eksplor Mandeh Island Hopping',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sageBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sageBorder),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Destinasi Utama (Dropdown Katalog BE-1)
                  const Text(
                    'Destinasi Utama (Katalog BE-1)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDestinationId,
                        isExpanded: true,
                        items: _destCatalog.map((d) {
                          return DropdownMenuItem<String>(
                            value: d['id'],
                            child: Text(
                              d['name']!,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          final match = _destCatalog.firstWhere((d) => d['id'] == val);
                          setState(() {
                            _selectedDestinationId = val;
                            _selectedDestinationName = match['name']!;
                            _category = match['category']!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kategori Otomatis (Read-Only)
                  const Text(
                    'Kategori Perjalanan (Otomatis & Read-Only)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 16, color: AppColors.forest),
                        const SizedBox(width: 8),
                        Text(
                          _category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tanggal & Jam Keberangkatan (Picker)
                  const Text(
                    'Jadwal Keberangkatan (UTC RFC3339)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sageBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.forest),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_departureDate.day}/${_departureDate.month}/${_departureDate.year} pukul ${_departureDate.hour.toString().padLeft(2, '0')}:${_departureDate.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Text(
                            'Ubah',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sisa Kursi & Biaya Patungan
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sisa Kursi',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _seatsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: '4',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.sageBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.sageBorder),
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
                            const Text(
                              'Biaya / Orang (Rp)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _costController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: '200000',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.sageBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.sageBorder),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Kontak WA Host
                  const Text(
                    'Nomor WhatsApp Host',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _waController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: '081211111111',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sageBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sageBorder),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
