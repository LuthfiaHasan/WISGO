import '../network/api_client.dart';
import '../network/api_config.dart';
import '../models/user_profile.dart';

/// ==============================================================================
/// WISGO (Rancak.in) - JEMBATAN LAYANAN API TERPADU (UNIFIED API SERVICE)
/// 
/// Menyediakan akses lengkap ke seluruh 48+ endpoint backend untuk semua modul:
/// • Modul BE-1: Core, Spasial, 360°, Shunlu, Audio GPS, Pungli, Budaya & Bencana
/// • Modul BE-2: Auth, Saved, Mitra Nagari, Planner, Escrow, Komunitas & Paspor
/// ==============================================================================
class ApiService {
  // ============================================================================
  // 1. SISTEM & KESEHATAN KONEKSI (HEALTH CHECK)
  // ============================================================================

  /// Cek status koneksi server backend dan database cloud Supabase
  static Future<ApiResponse<dynamic>> checkHealth() async {
    // Memanggil endpoint /health di root server
    final cleanBase = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    try {
      final response = await ApiClient.get('/health', headers: {'Origin': cleanBase});
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Gagal menghubungi server: $e');
    }
  }

  // ============================================================================
  // 2. AUTENTIKASI & SIMPAN TEMPAT (BE-2 · PILAR 4 & 5)
  // ============================================================================

  /// Kirim kode OTP 4-digit ke nomor WhatsApp/SMS wisatawan
  static Future<ApiResponse<dynamic>> requestOtp({required String phoneNumber}) async {
    return await ApiClient.post('/auth/request-otp', body: {
      'phone_number': phoneNumber,
    });
  }

  /// Verifikasi kode OTP dan dapatkan token autentikasi JWT
  static Future<ApiResponse<dynamic>> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    String? fullName,
  }) async {
    final response = await ApiClient.post('/auth/verify-otp', body: {
      'phone_number': phoneNumber,
      'otp_code': otpCode,
      if (fullName != null) 'full_name': fullName,
    });

    if (response.isSuccess && response.data is Map<String, dynamic>) {
      final token = response.data['token']?.toString();
      final userMap = response.data['user'];
      UserProfile? profile;
      if (userMap is Map<String, dynamic>) {
        profile = UserProfile.fromJson(userMap);
      }
      ApiConfig.setAuthSession(token: token, user: profile);
    }
    return response;
  }

  /// Ambil profil wisatawan yang sedang login
  static Future<ApiResponse<dynamic>> getCurrentUser() async {
    return await ApiClient.get('/auth/me');
  }

  /// Ambil daftar destinasi yang disimpan (favorit/bookmark)
  static Future<ApiResponse<dynamic>> getSavedPlaces({String? userId}) async {
    final uid = userId ?? ApiConfig.currentUserId;
    return await ApiClient.get('/users/saved', queryParams: {'user_id': uid});
  }

  /// Toggle simpan / hapus destinasi dari daftar favorit
  static Future<ApiResponse<dynamic>> toggleSavedPlace({
    required String destinationId,
    String? userId,
  }) async {
    final uid = userId ?? ApiConfig.currentUserId;
    return await ApiClient.post('/users/saved/$destinationId', body: {
      'destination_id': destinationId,
      'user_id': uid,
    });
  }

  /// Alias simpan destinasi
  static Future<ApiResponse<dynamic>> savePlace(String destinationId, {String? userId}) async {
    return await toggleSavedPlace(destinationId: destinationId, userId: userId);
  }

  /// Alias hapus destinasi dari simpanan
  static Future<ApiResponse<dynamic>> removeSavedPlace(String destinationId, {String? userId}) async {
    return await toggleSavedPlace(destinationId: destinationId, userId: userId);
  }

  /// Logout wisatawan dan bersihkan sesi auth in-memory
  static void logout() {
    ApiConfig.clearAuth();
  }

  /// Cek status login saat ini
  static bool isAuthenticated() {
    return ApiConfig.isAuthenticated;
  }

  /// Ambil profil saat ini dari sesi memori
  static UserProfile? getProfile() {
    return ApiConfig.currentUser;
  }

  // ============================================================================
  // 3. KATALOG DESTINASI & SPASIAL (BE-1 · PILAR 2 & 7)
  // ============================================================================

  /// Ambil 20 destinasi prioritas Sumbar dengan filter spasial & kategori
  static Future<ApiResponse<dynamic>> getDestinations({
    String? category,
    String? cityRegency,
    String? crowdLevel,
    String? signal,
    String? search,
  }) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (cityRegency != null && cityRegency.isNotEmpty) params['city'] = cityRegency;
    if (crowdLevel != null && crowdLevel.isNotEmpty) params['crowd'] = crowdLevel;
    if (signal != null && signal.isNotEmpty) params['signal'] = signal;
    if (search != null && search.isNotEmpty) params['q'] = search;

    return await ApiClient.get('/destinations', queryParams: params);
  }

  /// Ambil detail destinasi, 5 indikator medan, tips, dan tarif Perda
  static Future<ApiResponse<dynamic>> getDestinationDetail(
    String idOrSlug, {
    double? userLat,
    double? userLng,
  }) async {
    final params = <String, String>{};
    if (userLat != null && userLng != null) {
      params['lat'] = userLat.toString();
      params['lng'] = userLng.toString();
    }
    return await ApiClient.get('/destinations/$idOrSlug', queryParams: params);
  }

  /// Unduh paket destinasi offline (Mode Zero-Signal / Offline Pocket)
  static Future<ApiResponse<dynamic>> getOfflineBundle({
    String? category,
    String? city,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (city != null) params['city'] = city;
    return await ApiClient.get('/destinations/offline-bundle', queryParams: params);
  }

  // ============================================================================
  // 4. TUR VIRTUAL 360° IMERSIF & 4 PIN INTERAKTIF (BE-1 · PILAR 1)
  // ============================================================================

  /// Ambil seluruh panorama 360° (Aerial & Ground) beserta 4 Pin untuk destinasi
  static Future<ApiResponse<dynamic>> getScenes360(String destinationId) async {
    return await ApiClient.get('/scenes-360/$destinationId');
  }

  /// Ambil detail scene 360° tertentu beserta hotspot-nya
  static Future<ApiResponse<dynamic>> getSceneDetail(String sceneId) async {
    return await ApiClient.get('/scenes-360/detail/$sceneId');
  }

  // ============================================================================
  // 5. NAVIGASI CERDAS AMAP: SHUNLU, PETA MIKRO & AUDIO GPS (BE-1 · PILAR 2)
  // ============================================================================

  /// Pencarian titik singgah searah rute ("Shunlu") dengan kalkulasi detour menit
  static Future<ApiResponse<dynamic>> searchShunlu({
    required double lat,
    required double lng,
    String? category, // rm_padang, spbu, masjid_bersih, atm, bengkel
    double radiusKm = 10.0,
  }) async {
    return await ApiClient.get('/spatial/shunlu', queryParams: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      if (category != null) 'category': category,
      'radius': radiusKm.toString(),
    });
  }

  /// Ambil data peta mikro pejalan kaki kawasan (gerbang, toilet, foto, rute)
  static Future<ApiResponse<dynamic>> getMicroMap(String destinationId) async {
    return await ApiClient.get('/spatial/micro-map/$destinationId');
  }

  /// Pemicu audio narasi cerita budaya otomatis berbasis radius GPS (<= 15 meter)
  static Future<ApiResponse<dynamic>> triggerGpsAudio({
    required String destinationId,
    required double userLat,
    required double userLng,
  }) async {
    return await ApiClient.post('/spatial/audio-guide', body: {
      'destination_id': destinationId,
      'user_lat': userLat,
      'user_lng': userLng,
    });
  }

  // ============================================================================
  // 6. MITRA NAGARI MINANGKABAU (BE-2 · PILAR 5)
  // ============================================================================

  /// Ambil katalog 5 kategori mitra nagari Minang dengan filter level pedas 0–5
  static Future<ApiResponse<dynamic>> getPartners({
    String? category, // Homestay Rumah Gadang, Kuliner Halal, Transport & Perahu, dll.
    int? spicyLevel,  // 0-5
    String? nagari,
  }) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (spicyLevel != null) params['spicy_level'] = spicyLevel.toString();
    if (nagari != null && nagari.isNotEmpty) params['nagari'] = nagari;

    return await ApiClient.get('/partners', queryParams: params);
  }

  /// Ambil detail spesifik mitra nagari berdasarkan ID
  static Future<ApiResponse<dynamic>> getPartnerDetail(String partnerId) async {
    return await ApiClient.get('/partners/$partnerId');
  }

  // ============================================================================
  // 7. ITINERARY 7 HARI & AUTO-GENERATOR (BE-2 · PILAR 4)
  // ============================================================================

  /// Ambil daftar rencana perjalanan milik wisatawan
  static Future<ApiResponse<dynamic>> getItineraries({String userId = 'usr-001'}) async {
    return await ApiClient.get('/itineraries', queryParams: {'user_id': userId});
  }

  /// Ambil detail lengkap satu rencana perjalanan beserta rincian per jam
  static Future<ApiResponse<dynamic>> getItineraryDetail(String itineraryId) async {
    return await ApiClient.get('/itineraries/$itineraryId');
  }

  /// Buat rencana perjalanan otomatis cerdas berdasarkan preferensi rombongan
  static Future<ApiResponse<dynamic>> generateAutoItinerary({
    required int totalDays,
    required String arrivalPoint, // BIM / Darat
    required String groupProfile, // keluarga, petualang, budaya, kuliner
    String userId = 'usr-001',
  }) async {
    return await ApiClient.post('/itineraries/generate', body: {
      'total_days': totalDays,
      'arrival_point': arrivalPoint,
      'group_profile': groupProfile,
      'user_id': userId,
    });
  }

  /// Simpan atau perbarui rencana perjalanan
  static Future<ApiResponse<dynamic>> saveItinerary(Map<String, dynamic> itinerary) async {
    return await ApiClient.post('/itineraries/save', body: itinerary);
  }

  // ============================================================================
  // 8. PRIVATE GROUP ROOM, VOTING & RADAR ROMBONGAN (BE-2 · PILAR 4)
  // ============================================================================

  /// Buat ruang rombongan baru via kode/link WhatsApp
  static Future<ApiResponse<dynamic>> createGroupRoom({
    required String title,
    String leaderId = 'usr-001',
    String? leaderPhone,
    String? leaderName,
  }) async {
    return await ApiClient.post('/groups/create', body: {
      'title': title,
      'leader_id': leaderId,
      'leader_phone': leaderPhone ?? '6281211112222',
      'leader_name': leaderName ?? 'Leader Rombongan',
    });
  }

  /// Ambil data ruang rombongan & daftar anggota berdasarkan kode ruang
  static Future<ApiResponse<dynamic>> getGroupRoom(String roomCode) async {
    return await ApiClient.get('/groups/$roomCode');
  }

  /// Gabung ke ruang rombongan yang dibagikan via link WhatsApp
  static Future<ApiResponse<dynamic>> joinGroupRoom({
    required String roomCode,
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {
    return await ApiClient.post('/groups/join', body: {
      'room_code': roomCode,
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
    });
  }

  /// Lakukan voting live destinasi/homestay bersama rombongan
  static Future<ApiResponse<dynamic>> submitGroupVote({
    required String roomCode,
    required String userId,
    required String destinationId,
    required String voteType, // upvote / downvote
  }) async {
    return await ApiClient.post('/groups/vote', body: {
      'room_code': roomCode,
      'user_id': userId,
      'destination_id': destinationId,
      'vote_type': voteType,
    });
  }

  /// Ambil rekapitulasi hasil voting destinasi rombongan
  static Future<ApiResponse<dynamic>> getGroupVotes(String roomCode) async {
    return await ApiClient.get('/groups/$roomCode/votes');
  }

  /// Kirim sinyal ping lokasi GPS anggota rombongan (Radar Lapangan)
  static Future<ApiResponse<dynamic>> pingGroupRadar({
    required String roomCode,
    required String userId,
    required double latitude,
    required double longitude,
    required String memberName,
  }) async {
    return await ApiClient.post('/groups/radar/ping', body: {
      'room_code': roomCode,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'member_name': memberName,
    });
  }

  /// Ambil feed radar posisi seluruh anggota rombongan
  static Future<ApiResponse<dynamic>> getGroupRadar(String roomCode) async {
    return await ApiClient.get('/groups/$roomCode/radar');
  }

  // ============================================================================
  // 9. ESCROW, QUICK BOOKING & E-TICKET QR (BE-2 · PILAR 5)
  // ============================================================================

  /// Buat pemesanan baru (dana ditahan di Escrow Rekening Bersama)
  static Future<ApiResponse<dynamic>> createBooking({
    required String partnerId,
    String userId = 'usr-001',
    required double totalAmount,
    String currency = 'IDR', // IDR / MYR
  }) async {
    return await ApiClient.post('/escrow/bookings', body: {
      'partner_id': partnerId,
      'user_id': userId,
      'total_amount': totalAmount,
      'currency': currency,
    });
  }

  /// Buat pemesanan baru dari payload Map/Json
  static Future<ApiResponse<dynamic>> createBookingFromMap(Map<String, dynamic> payload) async {
    return await ApiClient.post('/escrow/bookings', body: payload);
  }

  /// Ambil string kode QR E-Ticket resmi setelah dikonfirmasi mitra
  static Future<ApiResponse<dynamic>> getTicketQR(String bookingId) async {
    return await ApiClient.get('/bookings/$bookingId/ticket-qr');
  }

  /// Pindai QR tiket oleh Mitra Nagari saat tamu tiba untuk mencairkan saldo Escrow
  static Future<ApiResponse<dynamic>> scanRedeemEscrow({
    required String qrCodeTicket,
    required String partnerId,
  }) async {
    return await ApiClient.post('/escrow/scan-redeem', body: {
      'qr_code_ticket': qrCodeTicket,
      'partner_id': partnerId,
    });
  }

  /// Simulasi balasan WhatsApp Mitra: '1' untuk Terima atau '0' untuk Tolak
  static Future<ApiResponse<dynamic>> simulateWaWebhook({
    required String bookingId,
    required String partnerPhone,
    required String action, // "1" = Terima & Terbitkan QR, "0" = Tolak & Refund
    String currency = 'IDR',
  }) async {
    return await ApiClient.post('/bookings/wa-webhook', body: {
      'booking_id': bookingId,
      'partner_phone': partnerPhone,
      'action': action,
      'currency': currency,
    });
  }

  // ============================================================================
  // 10. KOMUNITAS & SHARED TRIPS (BE-2 · PILAR 6)
  // ============================================================================

  /// Ajukan tempat baru (Hidden Gem) dengan proteksi radius lokasi sensitif
  static Future<ApiResponse<dynamic>> submitCommunityPlace({
    required String name,
    required String category,
    required String cityRegency,
    required String description,
    required double latitude,
    required double longitude,
    required String tipsMenjaga,
    bool isSensitive = false,
    String userId = 'usr-001',
  }) async {
    return await ApiClient.post('/community/places', body: {
      'user_id': userId,
      'name': name,
      'category': category,
      'city_regency': cityRegency,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'tips_menjaga': tipsMenjaga,
      'is_sensitive': isSensitive,
    });
  }

  /// Ambil daftar tempat wisata usulan komunitas
  static Future<ApiResponse<dynamic>> getCommunityPlaces() async {
    return await ApiClient.get('/community/places');
  }

  /// Pasang ajakan tebengan / patungan sewa mobil (Board Cari Barengan)
  static Future<ApiResponse<dynamic>> createSharedTrip({
    required String title,
    required String destinationRoute,
    required DateTime departureDate,
    required int availableSeats,
    required double costPerPerson,
    required String contactWa,
    String userId = 'usr-001',
  }) async {
    return await ApiClient.post('/shared-trips', body: {
      'user_id': userId,
      'title': title,
      'destination_route': destinationRoute,
      'departure_date': departureDate.toIso8601String(),
      'available_seats': availableSeats,
      'cost_per_person': costPerPerson,
      'contact_wa': contactWa,
    });
  }

  /// Ambil daftar tebengan / cari barengan yang tersedia
  static Future<ApiResponse<dynamic>> getSharedTrips() async {
    return await ApiClient.get('/shared-trips');
  }

  // ============================================================================
  // 10b. OPEN TRIP / SHARED TRIPS DETAIL & MANAGEMENT (BE-2 · PILAR 6)
  // ============================================================================

  /// Ambil detail Open Trip beserta daftar peserta terdaftar
  /// GET /api/v1/community/shared-trips/:id
  static Future<ApiResponse<dynamic>> getSharedTripDetail(String tripId) async {
    return await ApiClient.get('/community/shared-trips/$tripId');
  }

  /// Perbarui Open Trip oleh Host
  /// PUT /api/v1/community/shared-trips/:id
  static Future<ApiResponse<dynamic>> updateSharedTrip({
    required String tripId,
    required String userId,
    required String title,
    required String destinationId,
    required DateTime departureDate,
    required int availableSeats,
    required double costPerPerson,
    required String contactWa,
  }) async {
    return await ApiClient.put('/community/shared-trips/$tripId', body: {
      'user_id': userId,
      'title': title,
      'destination_id': destinationId,
      'departure_date': departureDate.toUtc().toIso8601String(),
      'available_seats': availableSeats,
      'cost_per_person': costPerPerson,
      'contact_wa': contactWa,
    });
  }

  /// Gabung ke Open Trip sebagai peserta
  /// POST /api/v1/community/shared-trips/:id/join
  static Future<ApiResponse<dynamic>> joinSharedTrip({
    required String tripId,
    String? userId,
  }) async {
    final uid = userId ?? ApiConfig.currentUserId;
    return await ApiClient.post('/community/shared-trips/$tripId/join', body: {
      'user_id': uid,
    });
  }

  /// Hapus Open Trip oleh Host
  /// DELETE /api/v1/community/shared-trips/:id?user_id=<uid>
  static Future<ApiResponse<dynamic>> deleteSharedTrip({
    required String tripId,
    String? userId,
  }) async {
    final uid = userId ?? ApiConfig.currentUserId;
    return await ApiClient.delete(
      '/community/shared-trips/$tripId',
      queryParams: {'user_id': uid},
    );
  }

  // ============================================================================
  // 11. GAMIFIKASI: PASPOR DIGITAL MINANG & SERTIFIKAT (BE-2 · PILAR 6)
  // ============================================================================

  /// Ambil daftar spot ikonik bersejarah untuk stempel paspor digital
  static Future<ApiResponse<dynamic>> getPassportSpots() async {
    return await ApiClient.get('/gamification/spots');
  }

  /// Lakukan stempel check-in GPS valid (radius <= 200m Anti-Fake GPS)
  static Future<ApiResponse<dynamic>> checkInPassport({
    required String spotId,
    required double userLat,
    required double userLng,
    String userId = 'usr-001',
  }) async {
    return await ApiClient.post('/gamification/check-in', body: {
      'user_id': userId,
      'spot_id': spotId,
      'user_lat': userLat,
      'user_lng': userLng,
    });
  }

  /// Ambil rekap stempel paspor digital milik wisatawan
  static Future<ApiResponse<dynamic>> getUserPassport({String userId = 'usr-001'}) async {
    return await ApiClient.get('/gamification/passport/$userId');
  }

  /// Klaim / unduh Sertifikat Digital Resmi Gubernur Sumatera Barat
  static Future<ApiResponse<dynamic>> getGovernorCertificate({String userId = 'usr-001'}) async {
    return await ApiClient.get('/gamification/certificate/$userId');
  }

  // ============================================================================
  // 12. BUDAYA, JALUR EKSTREM & ANTI-PUNGLI (BE-1 · PILAR 1, 3, 7)
  // ============================================================================

  /// Ambil leaderboard ranking destinasi berdasarkan perilaku nyata (Gaode Guide)
  static Future<ApiResponse<dynamic>> getCultureRankings() async {
    return await ApiClient.get('/culture/rankings');
  }

  /// Ambil kamus saku frasa bahasa Minang & etika tutur Kato Nan Ampek
  static Future<ApiResponse<dynamic>> getMinangPhrases() async {
    return await ApiClient.get('/culture/phrases');
  }

  /// Ambil kalender acara adat & jadwal Hari Pakan Nagari
  static Future<ApiResponse<dynamic>> getCulturalEvents() async {
    return await ApiClient.get('/culture/events');
  }

  /// Ambil status pantauan jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9)
  static Future<ApiResponse<dynamic>> getHazardAlerts() async {
    return await ApiClient.get('/hazards/alerts');
  }

  /// Kirim sinyal darurat SOS GPS bergeolokasi
  static Future<ApiResponse<dynamic>> sendSosSignal({
    required double userLat,
    required double userLng,
    required String emergencyType, // medis, kecelakaan, bencana, tersesat
    required String notes,
    String userId = 'usr-001',
  }) async {
    return await ApiClient.post('/sos/signal', body: {
      'user_id': userId,
      'latitude': userLat,
      'longitude': userLng,
      'emergency_type': emergencyType,
      'notes': notes,
    });
  }

  /// Laporkan pungutan liar (pungli) / fasilitas rusak anonim ke Satgas Saber Pungli
  static Future<ApiResponse<dynamic>> reportPungli({
    required String destinationId,
    required String incidentType,
    required double officialPrice,
    required double overchargeAmount,
    required String description,
    required double latitude,
    required double longitude,
    String photoEvidence = 'https://wisgo.sumbarprov.go.id/evidence/demo.jpg',
  }) async {
    return await ApiClient.post('/pungli/report', body: {
      'destination_id': destinationId,
      'incident_type': incidentType,
      'official_perda_price_idr': officialPrice,
      'overcharge_amount_idr': overchargeAmount,
      'photo_evidence': photoEvidence,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    });
  }

  /// Verifikasi keaslian Plang Smart QR Fisik di lokasi wisata
  static Future<ApiResponse<dynamic>> verifyQRPlacard(String qrCode) async {
    return await ApiClient.get('/pungli/verify-qr/$qrCode');
  }
}
