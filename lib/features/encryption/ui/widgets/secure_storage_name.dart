import 'package:flutter/foundation.dart';

String secureStorageName() {
  switch (defaultTargetPlatform) {
    case .android:
      return 'Хранить в Android Keystore';
    case .iOS || .macOS:
      return 'Хранить в Связке ключей Apple';
    case .windows || .linux || .fuchsia:
      return 'Хранить безопасно на этом устройстве';
  }
}
