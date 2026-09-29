abstract final class PushConfig() {
  static const String gatewayUrl = String.fromEnvironment(
    'PUSH_GATEWAY_URL',
    defaultValue: 'https://push.convet.xyz/_matrix/push/v1/notify',
  );

  static const String androidChannelId = 'convetchat_push';

  static const String androidChannelName = 'Сообщения';

  static const String androidChannelDescription =
      'Уведомления о новых сообщениях';

  static const String iosCategoryId = 'MESSAGING';

  static const String appIdPrefix = 'com.convet.convetchat';

  static const String formatEventIdOnly = 'event_id_only';
}
