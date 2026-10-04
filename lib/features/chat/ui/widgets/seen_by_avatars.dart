import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:material_ui/material_ui.dart';

class const SeenByAvatars({
  super.key,
  required final List<SeenByUser> seenBy,
  required final bool isOwn,
  final double indent = 0,
}) extends StatelessWidget {
  static const _maxAvatars = 7;
  static const _size = 16.0;

  @override
  Widget build(BuildContext context) {
    if (seenBy.isEmpty) return const SizedBox.shrink();
    final visible = seenBy.length > _maxAvatars
        ? seenBy.sublist(0, _maxAvatars)
        : seenBy;
    final overflow = seenBy.length - visible.length;
    return Padding(
      padding: EdgeInsets.only(
        left: 12 + indent,
        right: 12,
        top: 1,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment: isOwn ? .end : .start,
        children: [
          Wrap(
            spacing: 4,
            crossAxisAlignment: .center,
            children: [
              for (final user in visible)
                MxcAvatar(
                  mxc: user.avatarMxc,
                  fallback: avatarInitial(
                    user.displayName.isEmpty ? user.id : user.displayName,
                  ),
                  size: _size,
                  context: context,
                ),
              if (overflow > 0)
                SizedBox(
                  width: _size,
                  height: _size,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(32),
                    child: Center(
                      child: Text(
                        '+$overflow',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
