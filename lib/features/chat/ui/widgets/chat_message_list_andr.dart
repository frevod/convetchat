import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_cubit.dart';
import 'package:convetchat/features/chat/ui/cubit/chat_state.dart';
import 'package:convetchat/features/chat/ui/widgets/message_bubble.dart';
import 'package:convetchat/features/chat/ui/widgets/message_grouping.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/components/floating_action_buttons/m3e_floating_action_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const ChatMessageListAndr({super.key}) extends StatefulWidget {
  @override
  State<ChatMessageListAndr> createState() => _ChatMessageListAndrState();
}

class _ChatMessageListAndrState() extends State<ChatMessageListAndr> {
  final ScrollController _scrollController = ScrollController();

  final Map<String, GlobalKey> _anchors = {};

  bool _showScrollDown = false;

  late final AppLifecycleListener _lifecycle;

  static const _bottomThreshold = 120.0;
  static const _scrollDownThreshold = 400.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _lifecycle = AppLifecycleListener(
      onShow: () {
        if (_isAtBottom && mounted) {
          context.read<ChatCubit>().markAsRead();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show =
        _scrollController.hasClients &&
        _scrollController.position.pixels > _scrollDownThreshold;
    if (show != _showScrollDown && mounted) {
      setState(() => _showScrollDown = show);
    }
  }

  void _scrollDown() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool get _isAtBottom {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.pixels <= _bottomThreshold;
  }

  GlobalKey _anchorFor(String id) =>
      _anchors.putIfAbsent(id, () => GlobalKey());

  Future<void> _scrollTo(String eventId) async {
    final cubit = context.read<ChatCubit>();
    const maxRetries = 10;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final anchor = _anchors[eventId]?.currentContext;
      if (anchor != null) {
        await Scrollable.ensureVisible(
          // ignore: use_build_context_synchronously
          anchor,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }

      final visible = cubit.state.messages;
      final targetIdx = visible.indexWhere((m) => m.id == eventId);
      if (targetIdx >= 0 && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;

        final targetPos = visible.length > 1
            ? (targetIdx / (visible.length - 1)) * maxScroll
            : 0.0;
        _scrollController.jumpTo(targetPos.clamp(0.0, maxScroll));

        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        continue;
      }

      final prevCount = visible.length;
      await cubit.loadMore();
      if (!mounted) return;
      if (cubit.state.messages.length == prevCount) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatCubit>();
    final state = cubit.state;

    if (state.isLoading) {
      return const Center(child: AdaptiveLoadingIndicator());
    }

    final visible = state.messages;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          'Пока нет сообщений',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final indexById = <String, int>{};
    for (var i = 0; i < visible.length; i++) {
      indexById[visible[i].id] = i;
    }

    _anchors.removeWhere((id, _) => !indexById.containsKey(id));

    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          current.scrollNonce != previous.scrollNonce &&
          current.scrollToEventId != null,
      listener: (context, state) => _scrollTo(state.scrollToEventId!),
      child: BlocListener<ChatCubit, ChatState>(
        listenWhen: (previous, current) =>
            (previous.isLoading && !current.isLoading) ||
            current.messages.length > previous.messages.length,
        listener: (context, state) {
          if (_isAtBottom) {
            context.read<ChatCubit>().markAsRead();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            });
          }
        },
        child: Builder(
          builder: (context) {
            if (state.isLoading) {
              return const Center(child: AdaptiveLoadingIndicator());
            }

            final visible = state.messages;
            if (visible.isEmpty) {
              return Center(
                child: Text(
                  'Пока нет сообщений',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            final indexById = <String, int>{};
            for (var i = 0; i < visible.length; i++) {
              indexById[visible[i].id] = i;
            }

            _anchors.removeWhere((id, _) => !indexById.containsKey(id));

            return Stack(
              children: [
                KeyedSubtree(
                  key: const ValueKey('messageList'),
                  child: ListView.custom(
                    controller: _scrollController,
                    reverse: true,
                    childrenDelegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final msgIndex = index;
                        if (msgIndex == visible.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: AdaptiveLoadingIndicator()),
                          );
                        }

                        if (msgIndex > visible.length - 50) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => cubit.loadMore(),
                          );
                        }
                        final message = visible[msgIndex];

                        final above = msgIndex + 1 < visible.length
                            ? visible[msgIndex + 1]
                            : null;
                        final below = msgIndex > 0
                            ? visible[msgIndex - 1]
                            : null;

                        final isState = message.isState;
                        final prevState =
                            msgIndex > 0 && visible[msgIndex - 1].isState;
                        final nextState =
                            msgIndex + 1 < visible.length &&
                            visible[msgIndex + 1].isState;
                        final expanded = state.expandedEventIds.contains(
                          message.id,
                        );
                        return MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          highlighted: message.id == state.highlightEventId,
                          anchorKey: _anchorFor(message.id),
                          isCollapsed: isState && prevState && !expanded,
                          expanded: expanded,
                          onExpand: isState && nextState && !prevState
                              ? () => cubit.toggleExpandedEvents(message.id)
                              : null,
                          aboveSameSender:
                              above != null && areSameGroup(message, above),
                          belowSameSender:
                              below != null && areSameGroup(message, below),
                        );
                      },
                      childCount:
                          visible.length + (state.isLoadingMore ? 1 : 0),
                      findChildIndexCallback: (key) {
                        if (key is ValueKey<String>) {
                          return indexById[key.value];
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AnimatedOpacity(
                    opacity: _showScrollDown ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showScrollDown,
                      child: M3EFab(
                        size: .small,
                        onPressed: _scrollDown,
                        icon: const Icon(Icons.arrow_downward_rounded),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
