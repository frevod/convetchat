import 'package:convetchat/core/matrix/ru_matrix_localizations.dart';
import 'package:matrix/matrix.dart';

bool isStateEvent(Event event) =>
    event.type != EventTypes.Message &&
    event.type != EventTypes.Sticker &&
    event.type != EventTypes.Encrypted;

bool isChatVisible(Event event) {
  if (event.relationshipType == RelationshipTypes.edit ||
      event.relationshipType == RelationshipTypes.reaction) {
    return false;
  }
  if (event.type == EventTypes.Reaction ||
      event.type == EventTypes.Redaction ||
      event.type == EventTypes.refreshingLastEvent) {
    return false;
  }
  if (event.type == PollEventContent.responseType) return false;
  if (event.type.startsWith('m.key.verification.')) return false;
  return true;
}

String eventLabel(Event event, {bool withSenderNamePrefix = false}) {
  if (event.type == EventTypes.refreshingLastEvent) return '';
  final text = event.calcLocalizedBodyFallback(
    ruMatrixLocalizations,
    hideReply: true,
    hideEdit: true,
    plaintextBody: true,
    removeMarkdown: true,
    withSenderNamePrefix: withSenderNamePrefix,
  ).trim();
  return text.isEmpty ? 'Сообщение' : text;
}

String eventPreviewLabel(Event event, {required bool showSender}) {
  if (event.type == EventTypes.refreshingLastEvent) return '';
  var label = event.calcLocalizedBodyFallback(
    ruMatrixLocalizations,
    hideReply: true,
    hideEdit: true,
    plaintextBody: true,
    removeMarkdown: true,
    withSenderNamePrefix: false,
  ).trim();
  if (label.isEmpty) return 'Сообщение';

  final own = event.senderId == event.room.client.userID;
  if (!isStateEvent(event) && (showSender || own)) {
    final name = own
        ? ruMatrixLocalizations.you
        : event.senderFromMemoryOrFallback.calcDisplayname(
            i18n: ruMatrixLocalizations,
          );
    label = '$name: $label';
  }
  return label;
}
