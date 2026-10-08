import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/chat/ui/cubit/room_info_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const KnockRequestsPageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RoomInfoCubit>();
    final state = cubit.state;
    final requests = state.knockRequests;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Заявки')),
      child: SafeArea(
        top: false,
        child: requests.isEmpty
            ? const Center(child: Text('Заявок нет'))
            : ListView(
                children: [
                  CupertinoListSection.insetGrouped(
                    children: [
                      for (final request in requests)
                        CupertinoListTile(
                          leading: MxcAvatar(
                            mxc: request.avatarMxc,
                            fallback: avatarInitial(request.displayName),
                            size: 36,
                            context: context,
                          ),
                          title: Text(
                            request.displayName,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          subtitle: Text(
                            request.id,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          trailing: state.actionUserId == request.id
                              ? const AdaptiveLoadingIndicator()
                              : Row(
                                  mainAxisSize: .min,
                                  children: [
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          cubit.acceptKnock(request.id),
                                      child: const Icon(
                                        CupertinoIcons.check_mark,
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          cubit.rejectKnock(request.id),
                                      child: const Icon(CupertinoIcons.xmark),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
