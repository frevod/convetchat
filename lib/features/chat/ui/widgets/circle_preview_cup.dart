import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/domain/entities/record_mode.dart';
import 'package:convetchat/features/chat/data/services/circle_video_service.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const CirclePreviewCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final triple = context.select(
      (ChatCubit c) => (c.state.recordMode, c.state.isRecording),
    );
    if (triple.$1 != RecordMode.circle || !triple.$2) {
      return const SizedBox.shrink();
    }
    final config = getIt<CircleVideoService>().awesomeConfig;
    if (config == null) return const SizedBox.shrink();
    final size = (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 300.0);
    final tint = CupertinoColors.systemBlue.resolveFrom(context);
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
                      border: Border.all(color: tint, width: 3),
                    ),
                    child: ClipOval(
                      child: CameraAwesomeBuilder.custom(
                        progressIndicator: const _CupWaiting(),
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
                          if (!ready) {
                            return const _CupWaiting();
                          }
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

class const _CupWaiting() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF000000),
      child: Center(
        child: CupertinoActivityIndicator(radius: 20),
      ),
    );
  }
}
