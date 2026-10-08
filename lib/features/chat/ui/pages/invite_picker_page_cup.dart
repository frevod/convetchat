import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/ui/cubit/invite_picker_cubit.dart';
import 'package:convetchat/features/chat/ui/cubit/invite_picker_state.dart';
import 'package:convetchat/features/chat/ui/widgets/invite_sheets.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const InvitePickerPageCup({super.key, required final String roomId})
    extends StatefulWidget {
  @override
  State<InvitePickerPageCup> createState() => _InvitePickerPageCupState();
}

class _InvitePickerPageCupState() extends State<InvitePickerPageCup> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue(
    BuildContext context,
    InvitePickerCubit cubit,
    int count,
  ) async {
    final reason = await openInviteReasonSheet(context);
    if (reason == null || !context.mounted) return;
    final ok = await cubit.inviteAll(
      widget.roomId,
      reason.isEmpty ? null : reason,
    );
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvitePickerCubit, InvitePickerState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AdaptiveSnackbar.show(
            context: context,
            message: state.errorMessage!,
            type: .error,
          );
          context.read<InvitePickerCubit>().clearError();
        }
      },
      builder: (context, state) {
        final cubit = context.read<InvitePickerCubit>();
        final manual = InvitePickerCubit.manualUserId(state.query);
        final visibleIds = {for (final user in state.visible) user.userId};
        final showManual = manual != null && !visibleIds.contains(manual);
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Пригласить'),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AdaptiveTextField(
                    controller: _controller,
                    label: 'Поиск людей',
                    onChanged: cubit.setQuery,
                  ),
                ),
                if (state.selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final userId in state.selected)
                          GestureDetector(
                            onTap: () => cubit.toggle(userId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeBlue.resolveFrom(
                                  context,
                                ),
                                borderRadius: .circular(16),
                              ),
                              child: Text(
                                _shortName(state, userId),
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child:
                      state.isSearching && state.visible.isEmpty && !showManual
                      ? const Center(child: AdaptiveLoadingIndicator())
                      : ListView(
                          children: [
                            if (manual != null && !visibleIds.contains(manual))
                              _CupRow(
                                title: 'Пригласить $manual',
                                subtitle: null,
                                avatarMxc: null,
                                selected: state.selected.contains(manual),
                                onTap: () => cubit.toggle(manual),
                              ),
                            for (final user in state.visible)
                              _CupRow(
                                title: user.displayName,
                                subtitle: user.userId,
                                avatarMxc: user.avatarMxc,
                                selected: state.selected.contains(user.userId),
                                onTap: () => cubit.toggle(user.userId),
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CupertinoButton.filled(
                    onPressed: state.selected.isEmpty || state.isSending
                        ? null
                        : () =>
                              _continue(context, cubit, state.selected.length),
                    child: state.isSending
                        ? const AdaptiveLoadingIndicator(
                            color: CupertinoColors.white,
                          )
                        : Text('Продолжить (${state.selected.length})'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortName(InvitePickerState state, String userId) {
    for (final user in state.visible) {
      if (user.userId == userId) return user.displayName;
    }
    for (final user in state.candidates) {
      if (user.userId == userId) return user.displayName;
    }
    return userId;
  }
}

class const _CupRow({
  required final String title,
  required final String? subtitle,
  required final String? avatarMxc,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return GestureDetector(
      behavior: .opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            MxcAvatar(
              mxc: avatarMxc,
              fallback: avatarInitial(title),
              size: 40,
              context: context,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                ],
              ),
            ),
            if (selected) const Icon(CupertinoIcons.checkmark),
          ],
        ),
      ),
    );
  }
}
