import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const AwesomeCircleConfig({
  required final String quality,
  required final bool mirror,
  required final int fps,
  required final bool autofocus,
  required final String filePath,
});

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

  static VideoRecordingQuality awesomeQuality(String name) => switch (name) {
    'medium' => .sd,
    'high' => .hd,
    _ => .fhd,
  };

  static int awesomeBitrate(String name) => switch (name) {
    'medium' => 3000000,
    'high' => 6000000,
    _ => 12000000,
  };

  CameraController? _controller;
  bool _videoRecording = false;

  Future<CameraController?>? _initFlight;

  AwesomeCircleConfig? _awesomeConfig;
  VideoCameraState? _awesomeVideo;
  VideoRecordingCameraState? _awesomeRecording;
  Completer<void>? _awesomeReady;

  AwesomeCircleConfig? get awesomeConfig => _awesomeConfig;

  CameraController? get controller => _controller;

  bool get hasPreview => _controller?.value.isInitialized == true;

  bool get isVideoRecording => _videoRecording || _awesomeRecording != null;

  Future<void> configureAwesome({
    required String quality,
    required bool mirror,
    required int fps,
    required bool autofocus,
  }) async {
    final dir = await getTemporaryDirectory();
    _awesomeConfig = AwesomeCircleConfig(
      quality: quality,
      mirror: mirror,
      fps: fps,
      autofocus: autofocus,
      filePath:
          '${dir.path}${Platform.pathSeparator}circle_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    _awesomeVideo = null;
    _awesomeRecording = null;
    _awesomeReady = Completer<void>();
  }

  void attachAwesomeVideo(VideoCameraState state) {
    _awesomeVideo = state;
    final ready = _awesomeReady;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  void attachAwesomeRecording(VideoRecordingCameraState state) {
    _awesomeRecording = state;
  }

  void detachAwesome() {
    _awesomeVideo = null;
    _awesomeRecording = null;
    _awesomeReady = null;
    _awesomeConfig = null;
  }

  Future<bool> waitAwesomeVideo({Duration timeout = const Duration(seconds: 12)}) async {
    final ready = _awesomeReady;
    if (ready == null) {
      return false;
    }
    try {
      await ready.future.timeout(timeout);
    } catch (_) {
      return false;
    }
    final attached = _awesomeVideo != null;
    return attached;
  }

  Future<bool> startAwesomeRecording() async {
    final state = _awesomeVideo;
    if (state == null) {
      return false;
    }
    try {
      await state.startRecording();
      _videoRecording = true;
      return true;
    } catch (e, s) {
      getIt<Talker>().error('[awesome] start recording failed', e, s);
      return false;
    }
  }

  Future<String?> stopAwesomeRecording() async {
    _videoRecording = false;
    final path = _awesomeConfig?.filePath;
    try {
      await _awesomeRecording?.stopRecording();
    } catch (e, s) {
      getIt<Talker>().error('[awesome] stop recording failed', e, s);
    }
    _awesomeRecording = null;
    if (path == null || path.isEmpty) return null;
    return path;
  }

  Future<void> abortAwesomeRecording() async {
    _videoRecording = false;
    final path = _awesomeConfig?.filePath;
    try {
      await _awesomeRecording?.stopRecording();
    } catch (_) {}
    _awesomeRecording = null;
    if (path != null && path.isNotEmpty) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

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
    detachAwesome();
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
