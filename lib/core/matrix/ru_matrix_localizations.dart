import 'package:matrix/matrix.dart';

class const RuMatrixLocalizations() extends MatrixLocalizations {
  @override
  String get emptyChat => 'Пустой чат';

  @override
  String get invitedUsersOnly => 'Только приглашённым пользователям';

  @override
  String get fromTheInvitation => 'С момента приглашения';

  @override
  String get fromJoining => 'С момента присоединения';

  @override
  String get visibleForAllParticipants => 'Видима для всех участников';

  @override
  String get visibleForEveryone => 'Видна всем';

  @override
  String get guestsCanJoin => 'Гости могут присоединиться';

  @override
  String get guestsAreForbidden => 'Гости не могут присоединиться';

  @override
  String get anyoneCanJoin => 'Каждый может присоединиться';

  @override
  String get needPantalaimonWarning => 'Ошибка шифрования';

  @override
  String get channelCorruptedDecryptError => 'Шифрование было повреждено';

  @override
  String get encryptionNotEnabled => 'Шифрование не включено';

  @override
  String get unknownEncryptionAlgorithm => 'Неизвестный алгоритм шифрования';

  @override
  String get noPermission => 'Нет ключа для этого сообщения';

  @override
  String get you => 'Вы';

  @override
  String get roomHasBeenUpgraded => 'Комната обновлена';

  @override
  String get youAcceptedTheInvitation => 'Вы приняли приглашение';

  @override
  String get youRejectedTheInvitation => 'Вы отклонили приглашение';

  @override
  String get youJoinedTheChat => 'Вы присоединились к чату';

  @override
  String get unknownUser => 'Пользователь';

  @override
  String get cancelledSend => 'Отправка отменена';

  @override
  String get refreshingLastEvent => 'Загрузка... Пожалуйста, подождите.';

  @override
  String youInvitedBy(String senderName) => 'Вас пригласил(а) $senderName';

  @override
  String invitedBy(String senderName) => 'Пригласил(а): $senderName';

  @override
  String youInvitedUser(String targetName) => 'Вы пригласили $targetName';

  @override
  String youUnbannedUser(String targetName) => 'Вы разблокировали $targetName';

  @override
  String youBannedUser(String targetName) => 'Вы заблокировали $targetName';

  @override
  String youKicked(String targetName) => 'Вы выгнали $targetName';

  @override
  String youKickedAndBanned(String targetName) =>
      'Вы выгнали и заблокировали $targetName';

  @override
  String youHaveWithdrawnTheInvitationFor(String targetName) =>
      'Вы отозвали приглашение для $targetName';

  @override
  String groupWith(String displayname) => 'Группа с $displayname';

  @override
  String removedBy(Event redactedEvent) {
    if (redactedEvent.senderId == redactedEvent.room.client.userID) {
      return 'Вы удалили это сообщение';
    }
    final name = redactedEvent.senderFromMemoryOrFallback.calcDisplayname();
    return '$name удалил(а) это сообщение';
  }

  @override
  String sentASticker(String senderName) => 'Стикер';

  @override
  String redactedAnEvent(Event redactedEvent) {
    if (redactedEvent.senderId == redactedEvent.room.client.userID) {
      return 'Вы удалили это сообщение';
    }
    final name = redactedEvent.senderFromMemoryOrFallback.calcDisplayname();
    return '$name удалил(а) это сообщение';
  }

  @override
  String changedTheRoomAliases(String senderName) =>
      '$senderName изменил(а) псевдонимы комнаты';

  @override
  String changedTheRoomInvitationLink(String senderName) =>
      '$senderName изменил(а) ссылку для приглашения';

  @override
  String createdTheChat(String senderName) => '$senderName создал(а) чат';

  @override
  String changedTheJoinRules(String senderName) =>
      '$senderName изменил(а) правила присоединения';

  @override
  String changedTheJoinRulesTo(String senderName, String localizedString) =>
      '$senderName изменил(а) правила присоединения на $localizedString';

  @override
  String acceptedTheInvitation(String targetName) =>
      '$targetName принял(а) приглашение';

  @override
  String rejectedTheInvitation(String targetName) =>
      '$targetName отклонил(а) приглашение';

  @override
  String hasWithdrawnTheInvitationFor(String senderName, String targetName) =>
      '$senderName отозвал(а) приглашение для $targetName';

  @override
  String joinedTheChat(String targetName) =>
      '$targetName присоединился(а) к чату';

  @override
  String kickedAndBanned(String senderName, String targetName) =>
      '$senderName выгнал(а) и заблокировал(а) $targetName';

  @override
  String kicked(String senderName, String targetName) =>
      '$senderName выгнал(а) $targetName';

  @override
  String userLeftTheChat(String targetName) => '$targetName покинул(а) чат';

  @override
  String bannedUser(String senderName, String targetName) =>
      '$senderName заблокировал(а) $targetName';

  @override
  String unbannedUser(String senderName, String targetName) =>
      '$senderName разблокировал(а) $targetName';

  @override
  String invitedUser(String senderName, String targetName) =>
      '$senderName пригласил(а) $targetName';

  @override
  String changedTheProfileAvatar(String targetName) =>
      '$targetName изменил(а) аватар';

  @override
  String changedTheDisplaynameTo(String targetName, String newDisplayname) =>
      '$targetName изменил(а) отображаемое имя на «$newDisplayname»';

  @override
  String changedTheChatPermissions(String senderName) =>
      '$senderName изменил(а) права доступа к чату';

  @override
  String changedTheChatNameTo(String senderName, String content) =>
      content.isEmpty
      ? '$senderName убрал(а) название чата'
      : '$senderName изменил(а) имя чата на «$content»';

  @override
  String changedTheChatDescriptionTo(String senderName, String content) =>
      content.isEmpty
      ? '$senderName убрал(а) описание чата'
      : '$senderName изменил(а) описание чата на «$content»';

  @override
  String changedTheChatAvatar(String senderName) =>
      '$senderName изменил(а) аватар чата';

  @override
  String changedTheGuestAccessRules(String senderName) =>
      '$senderName изменил(а) правила гостевого доступа';

  @override
  String changedTheGuestAccessRulesTo(
    String senderName,
    String localizedString,
  ) => '$senderName изменил(а) правила гостевого доступа на $localizedString';

  @override
  String changedTheHistoryVisibility(String senderName) =>
      '$senderName изменил(а) видимость истории';

  @override
  String changedTheHistoryVisibilityTo(
    String senderName,
    String localizedString,
  ) => '$senderName изменил(а) видимость истории на $localizedString';

  @override
  String activatedEndToEndEncryption(String senderName) =>
      '$senderName активировал(а) сквозное шифрование';

  @override
  String sentAPicture(String senderName) => 'Изображение';

  @override
  String sentAFile(String senderName) => 'Файл';

  @override
  String sentAnAudio(String senderName) => 'Аудио';

  @override
  String voiceMessage(String senderName, Duration? duration) {
    if (duration == null) return 'Голосовое сообщение';
    final mm = duration.inMinutes.toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return 'Голосовое сообщение $mm:$ss';
  }

  @override
  String sentAVideo(String senderName) => 'Видео';

  @override
  String sentReaction(String senderName, String reactionKey) =>
      '$senderName отреагировал(а): $reactionKey';

  @override
  String sharedTheLocation(String senderName) => 'Местоположение';

  @override
  String couldNotDecryptMessage(String errorText) =>
      'Не удалось расшифровать сообщение';

  @override
  String unknownEvent(String typeKey) => 'Служебное событие: $typeKey';

  @override
  String startedACall(String senderName) => '$senderName начал(а) звонок';

  @override
  String endedTheCall(String senderName) => '$senderName завершил(а) звонок';

  @override
  String answeredTheCall(String senderName) =>
      '$senderName ответил(а) на звонок';

  @override
  String sentCallInformations(String senderName) =>
      '$senderName отправил(а) информацию о звонке';

  @override
  String wasDirectChatDisplayName(String oldDisplayName) =>
      'Пустой чат (был $oldDisplayName)';

  @override
  String hasKnocked(String targetName) => '$targetName постучался';

  @override
  String requestedKeyVerification(String senderName) =>
      '$senderName запросил(а) проверку ключей';

  @override
  String startedKeyVerification(String senderName) =>
      '$senderName начал(а) проверку ключей';

  @override
  String acceptedKeyVerification(String senderName) =>
      '$senderName принял(а) проверку ключей';

  @override
  String isReadyForKeyVerification(String senderName) =>
      '$senderName готов(а) к проверке ключей';

  @override
  String completedKeyVerification(String senderName) =>
      '$senderName завершил(а) проверку ключей';

  @override
  String canceledKeyVerification(String senderName) =>
      '$senderName отклонил(а) проверку ключей';

  @override
  String startedAPoll(String senderName) => '$senderName начал(а) опрос';

  @override
  String get pollHasBeenEnded => 'Опрос завершён';

  @override
  String incomingCallFrom(String senderName) =>
      'Входящий звонок от $senderName';
}

const ruMatrixLocalizations = RuMatrixLocalizations();
