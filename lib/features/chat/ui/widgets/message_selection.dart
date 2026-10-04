import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

Future<String?> showForwardTargetPicker(BuildContext context) {
  final cubit = context.read<ChatCubit>();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider<ChatCubit>.value(
      value: cubit,
      child: const _ForwardTargetSheet(),
    ),
  );
}

class const _ForwardTargetSheet() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<ChatCubit>();
    final targets = cubit.state.forwardTargets;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Переслать в',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (targets.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Нет доступных чатов',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final target = targets[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(avatarInitial(target.name)),
                      ),
                      title: Text(
                        target.name,
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(target.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class const MessageSelectionBarTitle({super.key, required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Выбрано: $count', maxLines: 1, overflow: .ellipsis);
  }
}

class const MessageSelectionAction({
  super.key,
  required final IconData icon,
  required final String tooltip,
  required final VoidCallback onPressed,
  final bool destructive = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: .compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(icon, size: 22, color: destructive ? scheme.error : null),
    );
  }
}

Future<void> openForwardPickerAndPick(BuildContext context) async {
  final cubit = context.read<ChatCubit>();
  await cubit.openForwardPicker();
  if (!context.mounted) return;
  if (cubit.state.forwardTargets.isEmpty) return;
  final targetId = await showForwardTargetPicker(context);
  if (!context.mounted) return;
  if (targetId == null) {
    cubit.closeForwardPicker();
    return;
  }
  await cubit.forwardSelectedTo(targetId);
}

class const MessageSelectionActions({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    final hasOwn = selectedHasOwnMessages(cubit);

    return Row(
      mainAxisSize: .min,
      children: [
        MessageSelectionAction(
          icon: Icons.copy_rounded,
          tooltip: 'Копировать',
          onPressed: () => cubit.copySelected(),
        ),
        MessageSelectionAction(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Удалить',
          onPressed: hasOwn ? () => cubit.deleteSelected() : () {},
        ),
        MessageSelectionAction(
          icon: Icons.turn_right_rounded,
          tooltip: 'Переслать',
          onPressed: () => openForwardPickerAndPick(context),
        ),
      ],
    );
  }
}

bool selectedHasOwnMessages(ChatCubit cubit) =>
    cubit.state.selectedEventIds.any(
      (id) =>
          cubit.state.messages.any((m) => m.id == id && m.isOwn && !m.isState),
    );
