import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cup;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> openUserPreviewSheet(BuildContext context, String userId) {
  if (getIt<PlatformStyle>().isCupertino) {
    return cup.showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => UserPreviewSheet(userId: userId),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => UserPreviewSheet(userId: userId),
  );
}

class const UserPreviewSheet({super.key, required final String userId})
    extends StatefulWidget {
  @override
  State<UserPreviewSheet> createState() => _UserPreviewSheetState();
}

class _UserPreviewSheetState() extends State<UserPreviewSheet> {
  late Future<Profile> _profile;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<Profile> _loadProfile() async {
    try {
      return await getIt<Client>().getProfileFromUserId(widget.userId);
    } catch (e, s) {
      getIt<Talker>().warning(
        '[chat] load profile failed: ${widget.userId}',
        e,
        s,
      );
      return Profile(userId: widget.userId);
    }
  }

  Future<void> _write() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final roomId = await getIt<Client>().startDirectChat(widget.userId);
      if (!mounted) return;
      Navigator.of(context).pop();
      getIt<GoRouter>().push('/chat/$roomId');
    } catch (e, s) {
      getIt<Talker>().error('[chat] create direct chat failed', e, s);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return Container(
        decoration: BoxDecoration(
          color: cup.CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _content(context),
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return FutureBuilder<Profile>(
      future: _profile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile?.displayName;
        final title = (displayName == null || displayName.isEmpty)
            ? widget.userId
            : displayName;
        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                MxcAvatar(
                  context: context,
                  mxc: profile?.avatarUrl?.toString(),
                  fallback: avatarInitial(title),
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(widget.userId, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                if (snapshot.connectionState == .waiting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: AdaptiveLoadingIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AdaptiveButton.filled(
              onPressed: _write,
              enabled: !_busy,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: AdaptiveLoadingIndicator(),
                    )
                  : const Text('Написать'),
            ),
          ],
        );
      },
    );
  }
}
