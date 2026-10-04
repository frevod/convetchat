import 'package:flutter/foundation.dart';

enum PlatformStyle() {
  cupertino,
  material,
}

extension PlatformStyleX on PlatformStyle {
  bool get isCupertino => this == .cupertino;

  bool get isMaterial => this == .material;
}

PlatformStyle platformStyle() {
  switch (defaultTargetPlatform) {
    case .iOS:
    case .macOS:
      return .cupertino;
    case .android:
    case .windows:
    case .linux:
    case .fuchsia:
      return .material;
  }
}
