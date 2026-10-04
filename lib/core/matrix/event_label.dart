import 'package:convetchat/core/matrix/ru_matrix_localizations.dart';
import 'package:convetchat/core/utils/safe_text.dart';
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
  final text = event
      .calcLocalizedBodyFallback(
        ruMatrixLocalizations,
        hideReply: true,
        hideEdit: true,
        plaintextBody: true,
        removeMarkdown: true,
        withSenderNamePrefix: withSenderNamePrefix,
      )
      .trim();
  final clean = sanitizeForText(text);
  return clean.isEmpty ? 'Сообщение' : clean;
}

String stripReplyFallback(String body) {
  final kept = body.split('\n').where((line) => !line.startsWith('>')).toList();
  if (kept.isNotEmpty && RegExp(r'^<@[^>]+>\s*$').hasMatch(kept.first)) {
    kept.removeAt(0);
  }
  return kept.join('\n').trim();
}

String eventPreviewLabel(Event event, {required bool showSender}) {
  if (event.type == EventTypes.refreshingLastEvent) return '';
  if (event.type == EventTypes.RoomPinnedEvents) {
    return _pinPreviewLabel(event);
  }
  var label = event
      .calcLocalizedBodyFallback(
        ruMatrixLocalizations,
        hideReply: true,
        hideEdit: true,
        plaintextBody: true,
        removeMarkdown: true,
        withSenderNamePrefix: false,
      )
      .trim();
  label = sanitizeForText(label);
  if (label.isEmpty) return 'Сообщение';

  if (event.redacted || event.redactedBecause != null) return label;

  final own = event.senderId == event.room.client.userID;
  if (!isStateEvent(event) && (showSender || own)) {
    final name = own
        ? ruMatrixLocalizations.you
        : sanitizeForText(
            event.senderFromMemoryOrFallback.calcDisplayname(
              i18n: ruMatrixLocalizations,
            ),
          );
    label = '$name: $label';
  }
  return label;
}

String _pinPreviewLabel(Event event) {
  final pinned = event.content['pinned'];
  final hasPinned = pinned is Iterable && pinned.isNotEmpty;
  final own = event.senderId == event.room.client.userID;
  if (own) {
    return hasPinned ? 'Вы закрепили сообщение' : 'Вы открепили сообщение';
  }
  final name = event.senderFromMemoryOrFallback.calcDisplayname(
    i18n: ruMatrixLocalizations,
  );
  return '$name ${hasPinned ? 'закрепил сообщение' : 'открепил сообщение'}';
}
