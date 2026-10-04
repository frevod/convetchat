import 'package:convetchat/core/di/locator.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final LaunchMode accountLaunchMode =
    defaultTargetPlatform == TargetPlatform.android
    ? LaunchMode.inAppBrowserView
    : LaunchMode.externalApplication;

Future<bool> launchAccountUri(Uri uri) async {
  final opened = await launchUrl(uri, mode: accountLaunchMode);
  if (!opened) {
    getIt<Talker>().warning(
      '[settings] Не удалось открыть панель аккаунта: $uri '
      '(mode=$accountLaunchMode)',
    );
  }
  return opened;
}

Future<bool> openAccountManagement() async {
  final uri = await fetchAccountManagementUri();
  if (uri == null) return false;
  return launchAccountUri(uri);
}

Future<Uri?> fetchAccountManagementUri() async {
  try {
    return (await getIt<Client>().getAuthMetadata()).accountManagementUri;
  } catch (e) {
    getIt<Talker>().warning('[settings] MAS не отдал адрес панели: $e');
    return null;
  }
}
