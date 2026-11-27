import 'package:flutter/foundation.dart';
import '../../auth/services/auth_session.dart';
import '../../fair_price/data/models/fair_price_tariff_model.dart';
import '../../gamification/services/gamification_service.dart';
import '../../trip_planner/models/open_trip_model.dart';

/// Store terpusat untuk Ulasan Destinasi (terhubung antara Beranda & Trip Go).
/// Fitur tambah ulasan terkunci sampai wisatawan menyelesaikan kunjungan (Check-In GPS)
/// atau menyelesaikan Open Trip di destinasi yang sama.
class DestinationReviewStore extends ChangeNotifier {
  DestinationReviewStore._();
  static final DestinationReviewStore instance = DestinationReviewStore._();

  final Map<String, List<UserReview>> _addedReviewsByDestId = {};
  final Set<String> _completedTripDestinations = {};

  List<UserReview> reviewsForDestination(SavedDestinationModel place) {
    final added = _addedReviewsByDestId[place.id] ?? const <UserReview>[];
    return [...added, ...place.reviews];
  }

  int extraCountFor(String destinationId) =>
      _addedReviewsByDestId[destinationId]?.length ?? 0;

  void addReview(String destinationId, UserReview review) {
    _addedReviewsByDestId.putIfAbsent(destinationId, () => []);
    _addedReviewsByDestId[destinationId]!.insert(0, review);
    notifyListeners();
  }

  void unlockFromCompletedOpenTrip(String destinationName) {
    _completedTripDestinations.add(destinationName.toLowerCase());
    notifyListeners();
  }

  bool _namesMatch(String a, String b) {
    final la = a.toLowerCase();
    final lb = b.toLowerCase();
    if (la.contains(lb) || lb.contains(la)) return true;
    final words = la.split(RegExp(r'[\s&,()]+')).where((w) => w.length >= 4);
    for (final w in words) {
      if (lb.contains(w)) return true;
    }
    return false;
  }

  /// True hanya jika pengguna sudah menyelesaikan kunjungan (Check-In GPS)
  /// ATAU sudah menyelesaikan Open Trip pada destinasi ini.
  bool canWriteReviewForDestination(SavedDestinationModel place) {
    if (AuthSession.instance.isGuest) return false;

    // 1. Cek riwayat kunjungan / Check-In GPS selesai
    final visited = GamificationService.instance.activityHistory.any(
      (act) => _namesMatch(act.destinationTitle, place.title),
    );
    if (visited) return true;

    // 2. Cek Open Trip yang diikuti & sudah selesai
    for (final tripDest in _completedTripDestinations) {
      if (_namesMatch(tripDest, place.title)) return true;
    }
    for (final trip in kMockOpenTrips) {
      if (trip.isCurrentUserJoined &&
          trip.isTripCompleted &&
          _namesMatch(trip.singleDestination, place.title)) {
        return true;
      }
    }
    return false;
  }
}
