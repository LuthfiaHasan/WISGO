import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'organizer_media_helper_stub.dart'
    if (dart.library.js_interop) 'organizer_media_helper_web.dart' as impl;

class PickedPhotoResult {
  final String? name;
  final Uint8List? bytes;
  final int sizeBytes;
  final String? errorMessage;
  final bool cancelled;

  const PickedPhotoResult({
    this.name,
    this.bytes,
    this.sizeBytes = 0,
    this.errorMessage,
    this.cancelled = false,
  });

  bool get isValid => errorMessage == null && !cancelled && name != null;

  String get formattedSizeKb => '${(sizeBytes / 1024).ceil()} KB';
}

/// Membuka pemilih file gambar (jpg, jpeg, png, webp, dll) dengan batas maksimal 250 KB.
Future<PickedPhotoResult> pickOrganizerPhotoMax250Kb({
  String defaultFileName = 'foto_ktp.jpg',
}) {
  return impl.pickOrganizerPhotoMax250Kb(defaultFileName: defaultFileName);
}

/// Widget kamera depan live untuk verifikasi / autentikasi wajah.
class LiveFaceCameraView extends StatelessWidget {
  final VoidCallback? onCameraReady;
  final ValueChanged<String>? onCameraError;

  const LiveFaceCameraView({
    super.key,
    this.onCameraReady,
    this.onCameraError,
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildLiveFaceCameraView(
      onCameraReady: onCameraReady,
      onCameraError: onCameraError,
    );
  }
}
