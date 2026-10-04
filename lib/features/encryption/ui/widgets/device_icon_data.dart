import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

IconData deviceIconData(String displayName, {required bool cupertino}) {
  final name = displayName.toLowerCase();
  bool any(Set<String> needles) => needles.any(name.contains);

  if (any({'android'})) {
    return cupertino
        ? CupertinoIcons.device_phone_portrait
        : Icons.phone_android_rounded;
  }
  if (any({'ios', 'ipad', 'iphone', 'ipod'})) {
    return cupertino
        ? CupertinoIcons.device_phone_portrait
        : Icons.phone_iphone_rounded;
  }
  if (any({
    'web',
    'http://',
    'https://',
    'firefox',
    'chrome',
    '/_matrix',
    'safari',
    'opera',
  })) {
    return cupertino ? CupertinoIcons.globe : Icons.web_rounded;
  }
  if (any({'desktop', 'windows', 'macos', 'linux', 'ubuntu'})) {
    return cupertino
        ? CupertinoIcons.device_desktop
        : Icons.desktop_mac_rounded;
  }
  return cupertino ? CupertinoIcons.question : Icons.device_unknown_rounded;
}
