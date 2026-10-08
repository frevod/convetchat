import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/call/presentation/cubits/room_call_cubit.dart';
import 'package:convetchat/features/call/presentation/cubits/room_call_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class const CallBannerAndr({super.key, required final String roomId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RoomCallCubit>(param1: roomId),
      child: BlocBuilder<RoomCallCubit, RoomCallState>(
        builder: (context, state) {
          final info = state is RoomCallLive ? state.info : null;
          if (info == null || !info.canJoin) return const SizedBox.shrink();          final scheme = Theme.of(context).colorScheme;
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: .circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.call_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Идёт голосовой звонок',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(
                    '/call/$roomId?mode=answer',
                    extra: {'roomId': roomId, 'roomName': info.roomName},
                  ),
                  child: const Text('Присоединиться'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
