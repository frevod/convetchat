import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/ui/cubit/invite_picker_cubit.dart';
import 'package:convetchat/features/chat/ui/cubit/invite_picker_state.dart';
import 'package:convetchat/features/chat/ui/widgets/invite_sheets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const InvitePickerPageAndr({super.key, required final String roomId})
    extends StatefulWidget {
  @override
  State<InvitePickerPageAndr> createState() => _InvitePickerPageAndrState();
}

class _InvitePickerPageAndrState() extends State<InvitePickerPageAndr> {
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
      AdaptiveSnackbar.show(
        context: context,
        message: count == 1
            ? 'Приглашение отправлено'
            : 'Приглашения отправлены',
        type: .success,
      );
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
        return Scaffold(
          appBar: M3EAppBar.top(
            shapeFamily: .round,
            density: .compact,
            automaticallyImplyLeading: true,
            title: const Text('Пригласить'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
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
                            M3EChip(
                              type: .filter,
                              label: _shortName(state, userId),
                              selected: true,
                              onPressed: () => cubit.toggle(userId),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child:
                        state.isSearching &&
                            state.visible.isEmpty &&
                            !showManual
                        ? const Center(child: AdaptiveLoadingIndicator())
                        : M3EList.scrollable(
                            itemCount:
                                state.visible.length + (showManual ? 1 : 0),
                            onTap: (index) {
                              if (index >= state.visible.length &&
                                  manual != null) {
                                cubit.toggle(manual);
                                return;
                              }
                              cubit.toggle(state.visible[index].userId);
                            },
                            itemBuilder: (context, index) {
                              if (index >= state.visible.length &&
                                  manual != null) {
                                final selected = state.selected.contains(
                                  manual,
                                );
                                return M3EListItem(
                                  headline: 'Пригласить $manual',
                                  trailing: selected
                                      ? const Icon(Icons.check_rounded)
                                      : null,
                                );
                              }
                              final user = state.visible[index];
                              final selected = state.selected.contains(
                                user.userId,
                              );
                              return M3EListItem(
                                headline: user.displayName,
                                supportingText: user.userId,
                                largeLeading: true,
                                leading: MxcAvatar(
                                  mxc: user.avatarMxc,
                                  fallback: avatarInitial(user.displayName),
                                  size: 40,
                                  context: context,
                                ),
                                trailing: selected
                                    ? const Icon(Icons.check_rounded)
                                    : null,
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AdaptiveButton.filled(
                      onPressed: state.selected.isEmpty || state.isSending
                          ? () {}
                          : () => _continue(
                              context,
                              cubit,
                              state.selected.length,
                            ),
                      enabled: state.selected.isNotEmpty && !state.isSending,
                      child: state.isSending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: AdaptiveLoadingIndicator(),
                            )
                          : Text('Продолжить (${state.selected.length})'),
                    ),
                  ),
                ],
              ),
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
