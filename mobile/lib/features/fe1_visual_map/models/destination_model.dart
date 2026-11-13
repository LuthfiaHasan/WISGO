import '../../../core/widgets/crowd_badge.dart';

/// Model Destinasi Wisata Sumatera Barat (Sinkron dengan backend/internal/models/models.go)
class DestinationModel {
  final String id;
  final String name;
  final String category; // Alam, Budaya, Kuliner, Sejarah
  final String cityRegency; // 19 Kab/Kota Sumbar
  final String description;
  final double latitude;
  final double longitude;
  final String coverImage;
  final String crowdLevel; // Sepi, Sedang, Ramai

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
    required this.name,
    required this.category,
    required this.cityRegency,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.coverImage = '',
    required this.crowdLevel,
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
    return DestinationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Alam',
      cityRegency: json['city_regency'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      coverImage: json['cover_image'] as String? ?? '',
      crowdLevel: json['crowd_level'] as String? ?? 'Sedang',
      distanceKm: json['distance_km'] as String? ?? '120 km',
      travelTime: json['travel_time'] as String? ?? '2j 30m',
      entryFee: json['entry_fee'] as String? ?? 'Rp 10.000',
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

