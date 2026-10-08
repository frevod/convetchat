import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/core/widgets/user_preview_sheet.dart';
import 'package:convetchat/features/chat/domain/entities/room_info.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_cubit.dart';
import 'package:convetchat/features/chat/ui/widgets/invite_sheets.dart';
import 'package:convetchat/features/chat/ui/widgets/join_rule_sheet.dart';
import 'package:convetchat/features/chats/domain/entities/notification_mode.dart';
import 'package:convetchat/features/chats/ui/cubit/notification_mode_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/notification_mode_state.dart';
import 'package:convetchat/features/settings/ui/widgets/profile_field_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:system_asset_picker/system_asset_picker.dart';

class const RoomInfoPageAndr({super.key}) extends StatelessWidget {
  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: 'Покинуть комнату?',
      message: 'Вы перестанете получать сообщения из этой комнаты.',
      confirmLabel: 'Покинуть',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<RoomInfoCubit>().leave();
    }
  }

  Future<void> _editName(BuildContext context, RoomInfo info) async {
    final value = await editProfileFieldSheet(
      context: context,
      field: 'name',
      initialValue: info.name,
      label: 'Название',
    );
    if (value == null || !context.mounted) return;
    await context.read<RoomInfoCubit>().updateName(value);
  }

  Future<void> _editTopic(BuildContext context, RoomInfo info) async {
    final value = await editProfileFieldSheet(
      context: context,
      field: 'topic',
      initialValue: info.topic,
      label: 'Описание',
    );
    if (value == null || !context.mounted) return;
    await context.read<RoomInfoCubit>().updateTopic(value);
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final cubit = context.read<RoomInfoCubit>();
    if (cubit.state.isSaving) return;
    try {
      final XFile? file = await SystemAssetPicker.pickImage();
      if (!context.mounted || file == null) return;
      await cubit.updateAvatar(
        file.path,
        file.name.isNotEmpty ? file.name : 'avatar.jpg',
      );
    } catch (_) {
      if (!context.mounted) return;
      AdaptiveSnackbar.show(
        context: context,
        message: 'Не удалось выбрать фотографию',
        type: .error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RoomInfoCubit>();
    final state = cubit.state;
    final info = state.info;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: true,
        title: state.isLoading || info == null
            ? const Text('Информация о комнате')
            : Text(info.name),
      ),
      body: state.isLoading || info == null
          ? const Center(child: AdaptiveLoadingIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      children: [
                        _Header(
                          info: info,
                          isSaving: state.isSaving,
                          onEditName: info.canEditName
                              ? () => _editName(context, info)
                              : null,
                          onEditTopic: info.canEditTopic
                              ? () => _editTopic(context, info)
                              : null,
                          onEditAvatar: info.canEditAvatar
                              ? () => _pickAvatar(context)
                              : null,
                        ),
                        _ManageSection(info: info),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                          child: Text(
                            info.isDirect
                                ? 'Участники'
                                : 'Участники (${info.memberCount})',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        M3EList(
                          itemCount: info.members.length,
                          onTap: (index) => openUserPreviewSheet(
                            context,
                            info.members[index].id,
                          ),
                          itemBuilder: (context, index) {
                            final member = info.members[index];
                            return M3EListItem(
                              headline: member.displayName,
                              supportingText: member.id,
                              leading: MxcAvatar(
                                mxc: member.avatarMxc,
                                fallback: avatarInitial(member.displayName),
                                size: 40,
                                context: context,
                              ),
                              trailingText: member.invited ? 'Приглашён' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: state.isLeaving
                        ? const Center(child: AdaptiveLoadingIndicator())
                        : AdaptiveButton.filled(
                            isDestructive: true,
                            onPressed: () => _confirmLeave(context),
                            child: Text('Покинуть комнату'),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class const _Header({
  required final RoomInfo info,
  required final bool isSaving,
  required final VoidCallback? onEditName,
  required final VoidCallback? onEditTopic,
  required final VoidCallback? onEditAvatar,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        GestureDetector(
          onTap: isSaving ? null : onEditAvatar,
          child: Stack(
            clipBehavior: .none,
            children: [
              MxcAvatar(
                mxc: info.avatarMxc,
                fallback: avatarInitial(info.name),
                size: 88,
                context: context,
              ),
              if (onEditAvatar != null)
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: .circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: AdaptiveLoadingIndicator(),
                          )
                        : Icon(
                            Icons.photo_camera,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            Flexible(
              child: Text(
                info.name,
                textAlign: .center,
                style: textTheme.headlineSmall,
              ),
            ),
            if (onEditName != null)
              M3EIconButton(
                variant: .standard,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Переименовать',
                onPressed: onEditName,
              ),
          ],
        ),
        if (info.topic.isNotEmpty || onEditTopic != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: .center,
            mainAxisSize: .min,
            children: [
              Flexible(
                child: Text(
                  info.topic.isEmpty ? 'Добавить описание' : info.topic,
                  textAlign: .center,
                  style: textTheme.bodyMedium,
                ),
              ),
              if (onEditTopic != null)
                M3EIconButton(
                  variant: .standard,
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Изменить описание',
                  onPressed: onEditTopic,
                ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        _RoomIdRow(roomId: info.roomId, alias: info.canonicalAlias),
        const SizedBox(height: 8),
        _Badges(info: info),
      ],
    );
  }
}

class const _RoomIdRow({
  required final String roomId,
  required final String? alias,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final roomAlias = alias;
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.read<RoomInfoCubit>().copyRoomId(),
          child: Text(roomId, textAlign: .center, style: style),
        ),
        if (roomAlias != null)
          Text(roomAlias, textAlign: .center, style: style),
      ],
    );
  }
}

class const _ManageSection({required final RoomInfo info})
    extends StatelessWidget {
  bool get _showKnock => info.knockCount > 0 && info.canInvite;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationModeCubit, NotificationModeState>(
      builder: (context, modeState) {
        final showNotifications =
            info.encrypted && !modeState.isLoading && modeState.supported;
        final showSection =
            showNotifications ||
            _showKnock ||
            info.canInvite ||
            info.canChangeJoinRule;
        if (!showSection) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: .start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Управление',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            M3EList(
              itemCount:
                  (_showKnock ? 1 : 0) +
                  (info.canInvite ? 1 : 0) +
                  (info.canChangeJoinRule ? 1 : 0),
              onTap: (index) => _onManageTap(context, info, index),
              itemBuilder: (context, index) =>
                  _manageItem(context, info, index),
            ),
            if (showNotifications) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  'Уведомления',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Center(
                child: M3ESegmentedButton<NotificationMode>(
                  segments: const [
                    M3ESegment(value: NotificationMode.all, label: 'Все'),
                    M3ESegment(
                      value: NotificationMode.mentions,
                      label: 'Упоминания',
                    ),
                    M3ESegment(value: NotificationMode.off, label: 'Выкл'),
                  ],
                  selected: {modeState.mode},
                  enabled: !modeState.isSaving,
                  onSelectionChanged: (selected) => context
                      .read<NotificationModeCubit>()
                      .setMode(selected.single),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _onManageTap(BuildContext context, RoomInfo info, int index) async {
    var current = index;
    if (_showKnock) {
      if (current == 0) {
        context.push('/chat/${info.roomId}/info/knock');
        return;
      }
      current--;
    }
    if (info.canInvite) {
      if (current == 0) {
        final action = await openInviteOptionsSheet(context: context);
        if (!context.mounted) return;
        if (action == 'copy') {
          await copyInviteLink(context, info.roomId, info.canonicalAlias);
          if (!context.mounted) return;
          AdaptiveSnackbar.show(
            context: context,
            message: 'Ссылка скопирована',
            type: .success,
          );
          return;
        }
        if (action == 'pick' && context.mounted) {
          context.push('/chat/${info.roomId}/info/invite');
        }
        return;
      }
      current--;
    }
    if (info.canChangeJoinRule && current == 0) {
      _pickJoinRule(context, info);
    }
  }

  Future<void> _pickJoinRule(BuildContext context, RoomInfo info) async {
    final rule = await openJoinRuleSheet(
      context: context,
      current: info.joinRule,
    );
    if (rule == null || !context.mounted) return;
    await context.read<RoomInfoCubit>().setJoinRule(rule);
  }

  Widget _manageItem(BuildContext context, RoomInfo info, int index) {
    var current = index;
    if (_showKnock) {
      if (current == 0) {
        return M3EListItem(
          headline: 'Заявки',
          supportingText: _knockLabel(info.knockCount),
          trailing: const Icon(Icons.arrow_forward_rounded),
        );
      }
      current--;
    }
    if (info.canInvite) {
      if (current == 0) {
        return const M3EListItem(
          headline: 'Пригласить участника',
          trailing: Icon(Icons.person_add_rounded),
        );
      }
      current--;
    }
    return M3EListItem(
      headline: 'Правило входа',
      supportingText: joinRuleLabel(info.joinRule),
      trailing: const Icon(Icons.arrow_forward_rounded),
    );
  }
}

String _knockLabel(int count) {
  final lastTwo = count % 100;
  final last = count % 10;
  if (lastTwo >= 11 && lastTwo <= 14) return '$count заявок';
  if (last == 1) return '$count заявка';
  if (last >= 2 && last <= 4) return '$count заявки';
  return '$count заявок';
}

class const _Badges({required final RoomInfo info}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: .center,
      spacing: 8,
      children: [
        Chip(label: Text(info.isDirect ? 'Личный чат' : 'Группа')),
        if (info.encrypted) Chip(label: Text('Шифрование')),
        if (!info.isDirect) Chip(label: Text(joinRuleLabel(info.joinRule))),
      ],
    );
  }
}
