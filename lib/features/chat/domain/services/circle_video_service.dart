import 'dart:async';

import 'package:camera/camera.dart';

class CircleVideoService() {
  static const defaultQualityName = 'veryHigh';

  static const List<String> qualityNames = ['medium', 'high', 'veryHigh'];

  static String qualityLabel(String name) => switch (name) {
    'medium' => 'Среднее · 480p',
    'high' => 'Высокое · 720p',
    _ => 'Full HD · 1080p',
  };

  static ResolutionPreset qualityPreset(String name) => switch (name) {
    'medium' => .medium,
    'high' => .high,
    _ => .veryHigh,
  };

  CameraController? _controller;
  bool _videoRecording = false;

  Future<CameraController?>? _initFlight;

  CameraController? get controller => _controller;

  bool get hasPreview => _controller?.value.isInitialized == true;

  bool get isVideoRecording => _videoRecording;

  Future<CameraController?> ensureFrontPreview({
    ResolutionPreset preset = .veryHigh,
  }) async {
    final current = _controller;
    if (current != null && current.value.isInitialized) return current;
    final flight = _initFlight;
    if (flight != null) return flight;
    final future = _doInitFrontPreview(preset);
    _initFlight = future;
    try {
      return await future;
    } finally {
      _initFlight = null;
    }
  }

  Future<CameraController?> _doInitFrontPreview(ResolutionPreset preset) async {
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    _videoRecording = false;

    final cameras = await availableCameras();
    CameraDescription? front;
    for (final camera in cameras) {
      if (camera.lensDirection == .front) {
        front = camera;
        break;
      }
    }
    if (front == null) return null;

    final controller = CameraController(front, preset, enableAudio: true);
    try {
      await controller.initialize();
    } catch (_) {
      try {
        await controller.dispose();
      } catch (_) {}
      return null;
    }
    try {
      await controller.setFocusMode(.auto);
    } catch (_) {}
    try {
      await controller.setExposureMode(.auto);
    } catch (_) {}
    _controller = controller;
    return controller;
  }

  Future<void> startVideoRecording() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isRecordingVideo) {
      return;
    }
    await controller.startVideoRecording();
    _videoRecording = true;
  }

  Future<XFile?> stopVideoRecording() async {
    _videoRecording = false;
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isRecordingVideo) {
      return null;
    }
    try {
      return await controller.stopVideoRecording();
    } catch (_) {
      return null;
    }
  }

  Future<void> disposePreview() async {
    _videoRecording = false;
    final controller = _controller;
    _controller = null;
    try {
      await controller?.dispose();
    } catch (_) {}
  }

  void dispose() {
    unawaited(disposePreview());
  }
}
