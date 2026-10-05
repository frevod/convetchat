import 'package:flutter/foundation.dart';

abstract final class PlatformInfos() {
  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static bool get supportsVideoPlayer =>
      !kIsWeb &&
      defaultTargetPlatform != TargetPlatform.linux &&
      defaultTargetPlatform != TargetPlatform.windows;

  static bool get supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get platformCanRecord =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;

  static bool get supportsFirebase => !isLinux;
}
