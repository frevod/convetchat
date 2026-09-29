import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/domain/entities/pending_media.dart';
import 'package:convetchat/features/chat/ui/widgets/pending_media_strip_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/pending_media_strip_cup.dart';
import 'package:flutter/widgets.dart';

class const PendingMediaStrip({
  required final List<PendingMedia> items,
  required final Future<void> Function(String id) onRemove,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return PendingMediaStripCup(items: items, onRemove: onRemove);
    }
    return PendingMediaStripAndr(items: items, onRemove: onRemove);
  }
}
