import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../../core/theme/app_colors.dart';
import 'organizer_media_helper.dart';

const int _kMaxPhotoBytes = 250 * 1024; // 250 KB

Future<PickedPhotoResult> pickOrganizerPhotoMax250Kb({
  String defaultFileName = 'foto_ktp.jpg',
}) {
  final completer = Completer<PickedPhotoResult>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/jpg,image/png,image/webp,image/*';

  input.onchange = (web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      if (!completer.isCompleted) {
        completer.complete(const PickedPhotoResult(cancelled: true));
      }
      return;
    }

    final file = files.item(0);
    if (file == null) {
      if (!completer.isCompleted) {
        completer.complete(const PickedPhotoResult(cancelled: true));
      }
      return;
    }

    final fileName = file.name;
    final lowerName = fileName.toLowerCase();
    final isImageMime = file.type.startsWith('image/');
    final isImageExt = lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.bmp') ||
        lowerName.endsWith('.heic');

    if (!isImageMime && !isImageExt) {
      if (!completer.isCompleted) {
        completer.complete(
          const PickedPhotoResult(
            errorMessage: 'Format file harus berupa foto JPG, JPEG, PNG, atau format gambar lainnya.',
          ),
        );
      }
      return;
    }

    final sizeBytes = file.size;
    if (sizeBytes > _kMaxPhotoBytes) {
      final kb = (sizeBytes / 1024).ceil();
      if (!completer.isCompleted) {
        completer.complete(
          PickedPhotoResult(
            sizeBytes: sizeBytes,
            errorMessage: 'Ukuran foto $kb KB melebihi batas maksimal 250 KB.',
          ),
        );
      }
      return;
    }

    final reader = web.FileReader();
    reader.onload = (web.Event _) {
      final result = reader.result;
      Uint8List? bytes;
      if (result != null) {
        try {
          bytes = (result as JSArrayBuffer).toDart.asUint8List();
        } catch (_) {
          bytes = null;
        }
      }
      if (!completer.isCompleted) {
        completer.complete(
          PickedPhotoResult(
            name: fileName,
            bytes: bytes,
            sizeBytes: sizeBytes,
          ),
        );
      }
    }.toJS;
    reader.onerror = (web.Event _) {
      if (!completer.isCompleted) {
        completer.complete(
          const PickedPhotoResult(
            errorMessage: 'Gagal membaca file foto. Coba pilih ulang.',
          ),
        );
      }
    }.toJS;
    reader.readAsArrayBuffer(file);
  }.toJS;

  input.oncancel = (web.Event _) {
    if (!completer.isCompleted) {
      completer.complete(const PickedPhotoResult(cancelled: true));
    }
  }.toJS;

  input.click();
  return completer.future;
}

Widget buildLiveFaceCameraView({
  VoidCallback? onCameraReady,
  ValueChanged<String>? onCameraError,
}) {
  return _WebLiveFaceCameraView(
    onCameraReady: onCameraReady,
    onCameraError: onCameraError,
  );
}

class _WebLiveFaceCameraView extends StatefulWidget {
  final VoidCallback? onCameraReady;
  final ValueChanged<String>? onCameraError;

  const _WebLiveFaceCameraView({
    this.onCameraReady,
    this.onCameraError,
  });

  @override
  State<_WebLiveFaceCameraView> createState() => _WebLiveFaceCameraViewState();
}

class _WebLiveFaceCameraViewState extends State<_WebLiveFaceCameraView> {
  static int _viewCounter = 0;
  late final String _viewType;
  late final web.HTMLVideoElement _videoElement;
  web.MediaStream? _stream;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewCounter++;
    _viewType = 'wisgo-face-liveness-cam-$_viewCounter';
    _videoElement = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..playsInline = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _videoElement,
    );

    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final constraints = web.MediaStreamConstraints(
        video: {'facingMode': 'user'}.jsify()!,
        audio: false.toJS,
      );
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      if (!mounted) {
        _stopStream(stream);
        return;
      }
      _stream = stream;
      _videoElement.srcObject = stream;
      await _videoElement.play().toDart;
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onCameraReady?.call();
    } catch (_) {
      if (!mounted) return;
      const msg = 'Kamera tidak dapat diakses. Pastikan izin kamera browser diaktifkan.';
      setState(() {
        _isLoading = false;
        _error = msg;
      });
      widget.onCameraError?.call(msg);
    }
  }

  void _stopStream(web.MediaStream? stream) {
    if (stream == null) return;
    final tracks = stream.getTracks().toDart;
    for (final track in tracks) {
      track.stop();
    }
  }

  @override
  void dispose() {
    _stopStream(_stream);
    _videoElement.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: const Color(0xFF142119),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded, color: AppColors.terracotta, size: 36),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.cream,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (_isLoading)
          Container(
            color: const Color(0xFF142119),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.cream,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Menyalakan kamera...',
                  style: TextStyle(fontSize: 11.5, color: AppColors.cream),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
