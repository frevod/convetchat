import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const KnockRequestsPageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RoomInfoCubit>();
    final state = cubit.state;
    final requests = state.knockRequests;

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: true,
        title: const Text('Заявки'),
      ),
      body: requests.isEmpty
          ? const Center(child: Text('Заявок нет'))
          : M3EList.scrollable(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final busy = state.actionUserId == request.id;
                return M3EListItem(
                  headline: request.displayName,
                  supportingText: request.id,
                  leading: MxcAvatar(
                    mxc: request.avatarMxc,
                    fallback: avatarInitial(request.displayName),
                    size: 40,
                    context: context,
                  ),
                  trailing: busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: AdaptiveLoadingIndicator(),
                        )
                      : Row(
                          mainAxisSize: .min,
                          children: [
                            M3EIconButton(
                              icon: const Icon(Icons.check_rounded),
                              tooltip: 'Впустить',
                              onPressed: () => cubit.acceptKnock(request.id),
                            ),
                            M3EIconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Отклонить',
                              onPressed: () => cubit.rejectKnock(request.id),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
