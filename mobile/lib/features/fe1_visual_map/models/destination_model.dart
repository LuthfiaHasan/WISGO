import '../../../core/widgets/crowd_badge.dart';

/// Model Destinasi Wisata Sumatera Barat (Sinkron dengan backend/internal/models/models.go)
class DestinationModel {
  final String id;
  final String categoryId; // cat-alam-geopark, cat-budaya-nagari, cat-hidden-gem, cat-religi, cat-kuliner
  final String name;
  final String category; // Alam & Geopark, Budaya & Nagari, Hidden Gem, Religi, Kuliner
  final String cityRegency; // 19 Kab/Kota Sumbar
  final String description;
  final double latitude;
  final double longitude;
  final String coverImage;
  final String crowdLevel; // Sepi, Sedang, Ramai
  final String weatherStatus;

  // 4 Statistik Keputusan (Layar 02 Paruh Atas)
  final String distanceKm;
  final String travelTime;
  final String entryFee;

  // Relasi
  final MedanIndicatorModel? medanIndicator;
  final List<LocalTipModel> tips;
  final List<OfficialTariffModel> tariffs;
  final List<Scene360Model> scenes360;

  const DestinationModel({
    required this.id,
    this.categoryId = 'cat-alam-geopark',
    required this.name,
    required this.category,
    required this.cityRegency,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.coverImage = '',
    required this.crowdLevel,
    this.weatherStatus = 'Cerah Berawan',
    this.distanceKm = '0 km',
    this.travelTime = '0 mnt',
    this.entryFee = 'Gratis',
    this.medanIndicator,
    this.tips = const [],
    this.tariffs = const [],
    this.scenes360 = const [],
  });

  CrowdLevel get crowdLevelEnum {
    switch (crowdLevel.toLowerCase()) {
      case 'sepi':
        return CrowdLevel.sepi;
      case 'ramai':
        return CrowdLevel.ramai;
      case 'sedang':
      default:
        return CrowdLevel.sedang;
    }
  }

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    final rawDist = json['distance_km'];
    final String parsedDistance = rawDist is num
        ? '${rawDist.toStringAsFixed(rawDist.truncateToDouble() == rawDist ? 0 : 1)} km'
        : (rawDist as String? ?? '120 km');

    final rawTime = json['travel_time'];
    final rawTimeMin = json['travel_time_min'];
    String parsedTime = '2j 30m';
    if (rawTime is String && rawTime.isNotEmpty) {
      parsedTime = rawTime;
    } else if (rawTimeMin is num && rawTimeMin > 0) {
      final mins = rawTimeMin.round();
      final h = mins ~/ 60;
      final m = mins % 60;
      parsedTime = h > 0 ? (m > 0 ? '${h}j ${m}m' : '$h jam') : '$m mnt';
    }

    final rawFee = json['entry_fee'];
    final rawCost = json['estimated_cost'];
    String parsedFee = 'Gratis';
    if (rawFee is String && rawFee.isNotEmpty) {
      parsedFee = rawFee;
    } else if (rawCost is num) {
      parsedFee = rawCost <= 0 ? 'Gratis' : 'Rp ${rawCost.round()}';
    }

    return DestinationModel(
      id: json['id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? 'cat-alam-geopark',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Alam & Geopark',
      cityRegency: json['city_regency'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      coverImage: json['cover_image'] as String? ?? '',
      crowdLevel: json['crowd_level'] as String? ?? 'Sedang',
      weatherStatus: json['weather_status'] as String? ?? 'Cerah Berawan',
      distanceKm: parsedDistance,
      travelTime: parsedTime,
      entryFee: parsedFee,
      medanIndicator: json['medan_indicator'] != null
          ? MedanIndicatorModel.fromJson(
              json['medan_indicator'] as Map<String, dynamic>,
            )
          : null,
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => LocalTipModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tariffs: (json['tariffs'] as List<dynamic>?)
              ?.map(
                (e) => OfficialTariffModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      scenes360: (json['scenes_360'] as List<dynamic>?)
              ?.map((e) => Scene360Model.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// 5 Indikator Medan Lapangan (Pilar 3)
class MedanIndicatorModel {
  final String id;
  final String destinationId;
  final String vehicleAccess; // Mobil OK, Hanya Motor, Jalan Kaki Saja
  final String trekkingLevel; // Mudah (Datar), Sedang, Ekstrem (Curam)
  final String cellularSignal; // 4G Kuat, Sinyal Lemah, Blank Spot (Zero-Signal)
  final String facilities; // Ada Toilet & Musala, Terbatas, Belum Ada
  final String guideNeed; // Wajib Pemandu Lokal, Disarankan, Bisa Mandiri

  const MedanIndicatorModel({
    this.id = '',
    this.destinationId = '',
    required this.vehicleAccess,
    required this.trekkingLevel,
    required this.cellularSignal,
    required this.facilities,
    required this.guideNeed,
  });

  factory MedanIndicatorModel.fromJson(Map<String, dynamic> json) {
    return MedanIndicatorModel(
      id: json['id'] as String? ?? '',
      destinationId: json['destination_id'] as String? ?? '',
      vehicleAccess: json['vehicle_access'] as String? ?? 'Mobil OK',
      trekkingLevel: json['trekking_level'] as String? ?? 'Mudah (Datar)',
      cellularSignal: json['cellular_signal'] as String? ?? '4G Kuat',
      facilities: json['facilities'] as String? ?? 'Ada Toilet & Musala',
      guideNeed: json['guide_need'] as String? ?? 'Bisa Mandiri',
    );
  }
}

/// Kartu Wajib: "Tips Menjaga Tempat Ini" (Pilar 3 & 6)
class LocalTipModel {
  final String id;
  final String destinationId;
  final String content;
  final bool isImportant;

  const LocalTipModel({
    required this.id,
    required this.destinationId,
    required this.content,
    this.isImportant = false,
  });

  factory LocalTipModel.fromJson(Map<String, dynamic> json) {
    return LocalTipModel(
      id: json['id'] as String? ?? '',
      destinationId: json['destination_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isImportant: json['is_important'] as bool? ?? false,
    );
  }
}

/// Tarif Resmi Perda / Nagari (Fair-Price Barometer)
class OfficialTariffModel {
  final String id;
  final String destinationId;
  final String itemName;
  final double price;
  final String unit;
  final String regulationRef;

  const OfficialTariffModel({
    required this.id,
    required this.destinationId,
    required this.itemName,
    required this.price,
    required this.unit,
    required this.regulationRef,
  });

  factory OfficialTariffModel.fromJson(Map<String, dynamic> json) {
    return OfficialTariffModel(
      id: json['id'] as String? ?? '',
      destinationId: json['destination_id'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'per orang',
      regulationRef: json['regulation_ref'] as String? ?? '',
    );
  }
}

/// Scene 360° (Aerial Drone & Ground Darat)
class Scene360Model {
  final String id;
  final String destinationId;
  final String title;
  final String type; // aerial | ground
  final String panoramaUrl;
  final double initialPitch;
  final double initialYaw;
  final List<Hotspot360Model> hotspots;

  const Scene360Model({
    required this.id,
    required this.destinationId,
    required this.title,
    required this.type,
    this.panoramaUrl = '',
    this.initialPitch = 0.0,
    this.initialYaw = 0.0,
    this.hotspots = const [],
  });

  factory Scene360Model.fromJson(Map<String, dynamic> json) {
    return Scene360Model(
      id: json['id'] as String? ?? '',
      destinationId: json['destination_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'ground',
      panoramaUrl: json['panorama_url'] as String? ?? '',
      initialPitch: (json['initial_pitch'] as num?)?.toDouble() ?? 0.0,
      initialYaw: (json['initial_yaw'] as num?)?.toDouble() ?? 0.0,
      hotspots: (json['hotspots'] as List<dynamic>?)
              ?.map((e) => Hotspot360Model.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// 4 Jenis Pin Kanvas 360° Terstandarisasi (Navigasi, Audio, Fasilitas, Mitra)
class Hotspot360Model {
  final String id;
  final String sceneId;
  final String type; // navigasi | audio | fasilitas | mitra
  final double pitch;
  final double yaw;
  final String title;
  final String targetRef;
  final String audioUrl;
  final String description;

  const Hotspot360Model({
    required this.id,
    required this.sceneId,
    required this.type,
    required this.pitch,
    required this.yaw,
    required this.title,
    this.targetRef = '',
    this.audioUrl = '',
    this.description = '',
  });

  factory Hotspot360Model.fromJson(Map<String, dynamic> json) {
    return Hotspot360Model(
      id: json['id'] as String? ?? '',
      sceneId: json['scene_id'] as String? ?? '',
      type: json['type'] as String? ?? 'navigasi',
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String? ?? '',
      targetRef: json['target_ref'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Entri Kamus Saku Audio Bahasa Minang (Pilar 1 — P1.4)
class MinangPhraseModel {
  final String id;
  final String category; // sapaan_adat, tawar_pasar, kuliner_rm, navigasi_darurat
  final String indonesianText;
  final String englishText;
  final String minangText;
  final String phoneticGuide;
  final String audioUrl;
  final String dialectNote; // Dialek Padang / Bukittinggi (Darek) / Pesisir
  final String usageContextTip;
  final String politenessLevel; // Kato Mandaki, Kato Mandata, Kato Manurun, Kato Malereang

  const MinangPhraseModel({
    required this.id,
    required this.category,
    required this.indonesianText,
    this.englishText = '',
    required this.minangText,
    required this.phoneticGuide,
    this.audioUrl = '',
    this.dialectNote = 'Umum Minangkabau',
    this.usageContextTip = '',
    this.politenessLevel = 'Kato Mandata',
  });

  factory MinangPhraseModel.fromJson(Map<String, dynamic> json) {
    return MinangPhraseModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'Umum',
      indonesianText: json['indonesian_text'] as String? ?? json['indo'] as String? ?? '',
      englishText: json['english_text'] as String? ?? json['en'] as String? ?? '',
      minangText: json['minang_text'] as String? ?? json['minang'] as String? ?? '',
      phoneticGuide: json['phonetic_guide'] as String? ?? json['phonetic'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      dialectNote: json['dialect_note'] as String? ?? 'Darek & Pesisir',
      usageContextTip: json['usage_context_tip'] as String? ?? json['context'] as String? ?? '',
      politenessLevel: json['politeness_level'] as String? ?? 'Kato Mandata',
    );
  }
}

/// Agenda Kalender Budaya & Hari Pakan Nagari (Pilar 1 — P1.4)
class CulturalEventModel {
  final String id;
  final String title;
  final String eventType; // Hari Pakan Nagari, Festival Budaya, Tradisi Adat
  final String nagariLocation;
  final String cityRegency;
  final String scheduleRule;
  final String badge;
  final String description;

  const CulturalEventModel({
    required this.id,
    required this.title,
    required this.eventType,
    required this.nagariLocation,
    required this.cityRegency,
    required this.scheduleRule,
    this.badge = 'Agenda Budaya',
    this.description = '',
  });

  factory CulturalEventModel.fromJson(Map<String, dynamic> json) {
    return CulturalEventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'Festival Budaya',
      nagariLocation: json['nagari_location'] as String? ?? json['location'] as String? ?? '',
      cityRegency: json['city_regency'] as String? ?? '',
      scheduleRule: json['schedule_rule'] as String? ?? json['schedule'] as String? ?? '',
      badge: json['badge'] as String? ?? 'Tradisi Leluhur',
      description: json['description'] as String? ?? json['desc'] as String? ?? '',
    );
  }
}

/// Alert Jalur Rawan Bencana Sumatera Barat (Pilar 7 — P7.2)
class HazardAlertModel {
  final String id;
  final String corridorCode;
  final String location;
  final String roadSegment;
  final String cityRegency;
  final double latitude;
  final double longitude;
  final String severity; // Normal, Waspada, Siaga, Awas Tutup Total
  final String hazardType;
  final String weatherStatus;
  final int slopeGradientDeg;
  final String message;
  final String detourRoute;
  final String nearestRescuePost;
  final String emergencyContact;

  const HazardAlertModel({
    required this.id,
    required this.corridorCode,
    required this.location,
    required this.roadSegment,
    this.cityRegency = 'Sumatera Barat',
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.severity,
    required this.hazardType,
    this.weatherStatus = 'Cerah Berawan',
    this.slopeGradientDeg = 0,
    required this.message,
    required this.detourRoute,
    this.nearestRescuePost = 'Posko BPBD Sumbar',
    this.emergencyContact = '112 / 115',
  });

  /// Alias getters untuk kompatibilitas tampilan UI
  String get corridorName => location;
  String get conditionDescription => message;
  String get alternativeRoute => detourRoute;
  String get lastUpdated => 'Baru saja';

  factory HazardAlertModel.fromJson(Map<String, dynamic> json) {
    return HazardAlertModel(
      id: json['id'] as String? ?? '',
      corridorCode: json['corridor_code'] as String? ?? '',
      location: json['location'] as String? ?? json['name'] as String? ?? '',
      roadSegment: json['road_segment'] as String? ?? '',
      cityRegency: json['city_regency'] as String? ?? 'Sumatera Barat',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? json['status'] as String? ?? 'Normal',
      hazardType: json['hazard_type'] as String? ?? '',
      weatherStatus: json['weather_status'] as String? ?? 'Cerah',
      slopeGradientDeg: (json['slope_gradient_deg'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? json['desc'] as String? ?? '',
      detourRoute: json['detour_route'] as String? ?? json['altRoute'] as String? ?? '',
      nearestRescuePost: json['nearest_rescue_post'] as String? ?? 'Posko Siaga Nagari',
      emergencyContact: json['emergency_contact'] as String? ?? '115 (SAR Sumbar)',
    );
  }
}

/// Sinyal Darurat SOS GPS (Pilar 7 — P7.2)
class SOSSignalModel {
  final String id;
  final String sosCode;
  final String touristName;
  final String phoneNumber;
  final String emergencyType;
  final double latitude;
  final double longitude;
  final int batteryPercent;
  final String nearestCorridor;
  final String status;
  final String notes;

  const SOSSignalModel({
    this.id = '',
    this.sosCode = '',
    required this.touristName,
    required this.phoneNumber,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.batteryPercent,
    this.nearestCorridor = '',
    this.status = 'Dipancarkan',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'tourist_name': touristName,
    'phone_number': phoneNumber,
    'emergency_type': emergencyType,
    'latitude': latitude,
    'longitude': longitude,
    'battery_percent': batteryPercent,
    'nearest_corridor': nearestCorridor,
    'notes': notes,
  };
}

/// Kontak Darurat Resmi Kebencanaan Sumbar (BE-1: emergency_contacts)
class EmergencyContactModel {
  final String id;
  final String corridorCode;
  final String agencyType;
  final String agencyName;
  final String phoneNumber;
  final String city;
  final double latitude;
  final double longitude;
  final bool isActive;

  const EmergencyContactModel({
    required this.id,
    required this.corridorCode,
    required this.agencyType,
    required this.agencyName,
    required this.phoneNumber,
    required this.city,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isActive = true,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String? ?? '',
      corridorCode: json['corridor_code'] as String? ?? '',
      agencyType: json['agency_type'] as String? ?? 'BPBD',
      agencyName: json['agency_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Landmark Gunung untuk Kompas Visual (Pilar 2)
class MountainLandmarkModel {
  final String name;
  final int elevationMdpl;
  final double latitude;
  final double longitude;
  final String regency;
  final double defaultBearingDeg;
  final String iconCode;
  final String description;

  const MountainLandmarkModel({
    required this.name,
    required this.elevationMdpl,
    required this.latitude,
    required this.longitude,
    required this.regency,
    required this.defaultBearingDeg,
    this.iconCode = 'volcano',
    this.description = '',
  });
}

/// Katalog Pakaian Adat Minangkabau (Pilar 1 — Minggu 4)
class TraditionalAttireModel {
  final String id;
  final String name;
  final String userType; // Bundo Kanduang / Marapulai / Penghulu
  final String regency;
  final String philosophy;
  final String imageUrl;
  final List<String> elements;

  const TraditionalAttireModel({
    required this.id,
    required this.name,
    required this.userType,
    required this.regency,
    required this.philosophy,
    required this.imageUrl,
    this.elements = const [],
  });
}

