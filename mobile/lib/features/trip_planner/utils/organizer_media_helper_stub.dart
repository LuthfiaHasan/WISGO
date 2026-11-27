import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'organizer_media_helper.dart';

Future<PickedPhotoResult> pickOrganizerPhotoMax250Kb({
  String defaultFileName = 'foto_ktp.jpg',
}) async {
  return PickedPhotoResult(
    name: defaultFileName,
    bytes: null,
    sizeBytes: 148 * 1024,
  );
}

Widget buildLiveFaceCameraView({
  VoidCallback? onCameraReady,
  ValueChanged<String>? onCameraError,
}) {
  return _StubCameraView(onCameraReady: onCameraReady);
}

class _StubCameraView extends StatefulWidget {
  final VoidCallback? onCameraReady;
  const _StubCameraView({this.onCameraReady});

  @override
  State<_StubCameraView> createState() => _StubCameraViewState();
}

class _StubCameraViewState extends State<_StubCameraView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCameraReady?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF142119),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_rounded,
            size: 46,
            color: AppColors.cream.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamera Depan Aktif',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.cream.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
