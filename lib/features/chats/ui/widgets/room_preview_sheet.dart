import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/server_capabilities.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/domain/repositories/chats_repository.dart';
import 'package:convetchat/features/chats/ui/cubit/room_preview_cubit.dart';
import 'package:convetchat/features/chats/ui/cubit/room_preview_state.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cup;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Future<void> openRoomPreviewSheet({
  required BuildContext context,
  required String roomIdOrAlias,
  PublicRoom? fallback,
  M3ESearchController? searchController,
}) async {
  final sheet = BlocProvider(
    create: (_) =>
        RoomPreviewCubit(getIt<ChatsRepository>())
          ..load(roomIdOrAlias, fallback: fallback),
    child: _RoomPreviewSheet(searchController: searchController),
  );
  if (getIt<PlatformStyle>().isCupertino) {
    await cup.showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => sheet,
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => sheet,
  );
}

class const _RoomPreviewSheet({
  required final M3ESearchController? searchController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomPreviewCubit, RoomPreviewState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AdaptiveSnackbar.show(
            context: context,
            message: state.errorMessage!,
            type: .error,
          );
          context.read<RoomPreviewCubit>().clearError();
        }
      },
      builder: (context, state) {
        final preview = state.preview;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                if (state.isLoading || preview == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: AdaptiveLoadingIndicator()),
                  )
                else ...[
                  _Header(
                    name: preview.name,
                    topic: preview.topic,
                    avatarMxc: preview.avatarMxc,
                    memberCount: preview.memberCount,
                    badge: _ruleBadge(preview.joinRule),
                  ),
                  const SizedBox(height: 16),
                  _Actions(searchController: searchController),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _ruleBadge(String joinRule) {
  if (ServerCapabilities.canJoin(joinRule)) return 'Открытая';
  if (ServerCapabilities.canKnock(joinRule)) return 'Вход по заявке';
  return 'Закрытая';
}

class const _Header({
  required final String name,
  required final String topic,
  required final String? avatarMxc,
  required final int memberCount,
  required final String badge,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        MxcAvatar(
          context: context,
          mxc: avatarMxc,
          fallback: avatarInitial(name),
          size: 56,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text(name, style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 2),
              Text(
                '$memberCount уч. • $badge',
                style: const TextStyle(fontSize: 13),
              ),
              if (topic.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(topic, style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class const _Actions({required final M3ESearchController? searchController})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RoomPreviewCubit>();
    final state = cubit.state;
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();
    if (preview.knocked) {
      return Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          const Text('Заявка отправлена — дождитесь, пока вас впустят'),
          const SizedBox(height: 12),
          AdaptiveButton.outlined(
            onPressed: state.isBusy ? () {} : cubit.cancelKnock,
            enabled: !state.isBusy,
            child: state.isBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: AdaptiveLoadingIndicator(),
                  )
                : const Text('Отозвать заявку'),
          ),
        ],
      );
    }
    if (ServerCapabilities.canJoin(preview.joinRule)) {
      return AdaptiveButton.filled(
        onPressed: state.isBusy ? () {} : () => _join(context, cubit),
        enabled: !state.isBusy,
        child: state.isBusy
            ? const SizedBox.square(
                dimension: 20,
                child: AdaptiveLoadingIndicator(),
              )
            : const Text('Войти'),
      );
    }
    if (ServerCapabilities.canKnock(preview.joinRule)) {
      return AdaptiveButton.filled(
        onPressed: state.isBusy ? () {} : cubit.knock,
        enabled: !state.isBusy,
        child: state.isBusy
            ? const SizedBox.square(
                dimension: 20,
                child: AdaptiveLoadingIndicator(),
              )
            : const Text('Стучаться'),
      );
    }
    return const Text('Закрытая комната — нужно приглашение');
  }

  Future<void> _join(BuildContext context, RoomPreviewCubit cubit) async {
    final roomId = await cubit.join();
    if (roomId == null || !context.mounted) return;
    final controller = searchController;
    Navigator.of(context).pop();
    if (controller != null && controller.isOpen) {
      controller.closeView(roomId);
    }
    getIt<GoRouter>().push('/chat/$roomId');
  }
}
