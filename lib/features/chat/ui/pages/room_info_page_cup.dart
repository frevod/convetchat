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
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class const RoomInfoPageCup({super.key}) extends StatelessWidget {
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
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: state.isLoading || info == null
            ? const Text('Информация')
            : Text(info.name),
      ),
      child: SafeArea(
        child: state.isLoading || info == null
            ? const Center(child: AdaptiveLoadingIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
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
                  CupertinoListSection.insetGrouped(
                    header: Text(
                      info.isDirect
                          ? 'Участники'
                          : 'Участники (${info.memberCount})',
                    ),
                    children: [
                      for (final member in info.members)
                        CupertinoListTile(
                          leading: MxcAvatar(
                            mxc: member.avatarMxc,
                            fallback: avatarInitial(member.displayName),
                            size: 36,
                            context: context,
                          ),
                          title: Text(
                            member.displayName,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          subtitle: Text(
                            member.invited ? 'Приглашён' : member.id,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          onTap: () => openUserPreviewSheet(context, member.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.isLeaving)
                    const Center(child: AdaptiveLoadingIndicator())
                  else
                    AdaptiveButton.filled(
                      isDestructive: true,
                      onPressed: () => _confirmLeave(context),
                      child: const Text('Покинуть комнату'),
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
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      shape: .circle,
                      border: Border.all(
                        color: CupertinoColors.secondarySystemBackground
                            .resolveFrom(context),
                        width: 2,
                      ),
                    ),
                    child: isSaving
                        ? const AdaptiveLoadingIndicator()
                        : const Icon(
                            CupertinoIcons.photo_camera,
                            size: 16,
                            color: CupertinoColors.label,
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
                style: const TextStyle(fontSize: 22, fontWeight: .w600),
              ),
            ),
            if (onEditName != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onEditName,
                child: const Icon(CupertinoIcons.pencil, size: 18),
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
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              if (onEditTopic != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onEditTopic,
                  child: const Icon(CupertinoIcons.pencil, size: 16),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
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
    const style = TextStyle(fontSize: 12);
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
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('Управление'),
              children: [
                if (_showKnock)
                  CupertinoListTile(
                    title: const Text('Заявки'),
                    additionalInfo: Text('${info.knockCount}'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () =>
                        context.push('/chat/${info.roomId}/info/knock'),
                  ),
                if (info.canInvite)
                  CupertinoListTile(
                    title: const Text('Пригласить участника'),
                    trailing: const Icon(CupertinoIcons.person_add),
                    onTap: () => _openInvite(context, info),
                  ),
                if (info.canChangeJoinRule)
                  CupertinoListTile(
                    title: const Text('Правило входа'),
                    additionalInfo: Text(joinRuleLabel(info.joinRule)),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => _pickJoinRule(context, info),
                  ),
              ],
            ),
            if (showNotifications)
              CupertinoListSection.insetGrouped(
                header: const Text('Уведомления'),
                children: [
                  CupertinoSlidingSegmentedControl<NotificationMode>(
                    groupValue: modeState.mode,
                    children: const {
                      NotificationMode.all: Text('Все'),
                      NotificationMode.mentions: Text('Упоминания'),
                      NotificationMode.off: Text('Выкл'),
                    },
                    onValueChanged: (mode) {
                      if (mode == null) return;
                      context.read<NotificationModeCubit>().setMode(mode);
                    },
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Future<void> _openInvite(BuildContext context, RoomInfo info) async {
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
  }

  Future<void> _pickJoinRule(BuildContext context, RoomInfo info) async {
    final rule = await openJoinRuleSheet(
      context: context,
      current: info.joinRule,
    );
    if (rule == null || !context.mounted) return;
    await context.read<RoomInfoCubit>().setJoinRule(rule);
  }
}

class const _Badges({required final RoomInfo info}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: .center,
      spacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemFill.resolveFrom(context),
            borderRadius: .circular(12),
          ),
          child: Text(
            info.isDirect ? 'Личный чат' : 'Группа',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (info.encrypted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemFill.resolveFrom(context),
              borderRadius: .circular(12),
            ),
            child: const Text('Шифрование', style: TextStyle(fontSize: 13)),
          ),
        if (!info.isDirect)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemFill.resolveFrom(context),
              borderRadius: .circular(12),
            ),
            child: Text(
              joinRuleLabel(info.joinRule),
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }
}
