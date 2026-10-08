import 'package:camera/camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/domain/entities/record_mode.dart';
import 'package:convetchat/features/chat/data/services/circle_video_service.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const CirclePreviewAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final triple = context.select(
      (ChatCubit c) =>
          (c.state.recordMode, c.state.isRecording, c.state.circleReady),
    );
    if (triple.$1 != RecordMode.circle || !triple.$2) {
      return const SizedBox.shrink();
    }
    final config = getIt<CircleVideoService>().awesomeConfig;
    if (config != null) return _AwesomeOverlay(config: config);
    final size = (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 300.0);
    final scheme = Theme.of(context).colorScheme;
    final controller = getIt<CircleVideoService>().controller;
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: const Color(0xFF000000).withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: .circle,
                      border: Border.all(color: scheme.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: .expand,
                        children: [
                          const ColoredBox(color: Color(0xFF000000)),
                          _PreviewBody(controller: controller, size: size),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class const _AwesomeOverlay({
  required final AwesomeCircleConfig config,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 300.0);
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x73000000),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: .circle,
                      border: Border.all(color: scheme.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: CameraAwesomeBuilder.custom(
                        progressIndicator: const _Waiting(),
                        saveConfig: SaveConfig.video(
                          pathBuilder: (sensors) async =>
                              SingleCaptureRequest(
                                config.filePath,
                                sensors.first,
                              ),
                          videoOptions: VideoOptions(
                            enableAudio: true,
                            quality: CircleVideoService.awesomeQuality(
                              config.quality,
                            ),
                            android: AndroidVideoOptions(
                              bitrate: CircleVideoService.awesomeBitrate(
                                config.quality,
                              ),
                              fallbackStrategy:
                                  QualityFallbackStrategy.lower,
                            ),
                            ios: CupertinoVideoOptions(fps: config.fps),
                          ),
                          mirrorFrontCamera: config.mirror,
                        ),
                        sensorConfig: SensorConfig.single(
                          sensor: Sensor.position(SensorPosition.front),
                          zoom: 0,
                        ),
                        previewFit: CameraPreviewFit.cover,
                        onPreviewTapBuilder: config.autofocus
                            ? null
                            : (state) =>
                                  OnPreviewTap(onTap: (_, _, _) {}),
                        builder: (state, _) {
                          var ready = false;
                          state.when(
                            onVideoMode: (video) {
                              getIt<CircleVideoService>()
                                  .attachAwesomeVideo(video);
                              ready = true;
                            },
                            onVideoRecordingMode: (recording) {
                              getIt<CircleVideoService>()
                                  .attachAwesomeRecording(recording);
                              ready = true;
                            },
                          );
                          if (!ready) return const _Waiting();
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class const _PreviewBody({
  required final CameraController? controller,
  required final double size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) return const _Waiting();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final live = getIt<CircleVideoService>().controller;
        if (!identical(live, controller)) return const _Waiting();
        if (!controller.value.isInitialized) return const _Waiting();
        final ar = controller.value.aspectRatio;
        if (ar <= 0) return CameraPreview(controller);
        final portrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final displayAr = portrait ? 1 / ar : ar;
        return SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: .cover,
            clipBehavior: .hardEdge,
            child: SizedBox(
              width: size,
              height: size / displayAr,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}

class const _Waiting() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF000000),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: M3EProgressIndicator.circularWavy(size: 40),
        ),
      ),
    );
  }
}
