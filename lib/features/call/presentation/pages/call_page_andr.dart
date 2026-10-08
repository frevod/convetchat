import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/call/domain/entities/call_support.dart';
import 'package:convetchat/features/call/presentation/cubits/call_cubit.dart';
import 'package:convetchat/features/call/presentation/cubits/call_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const CallPageAndr({
  super.key,
  required final String roomName,
  required final bool answer,
}) extends StatefulWidget {
  @override
  State<CallPageAndr> createState() => _CallPageAndrState();
}

class _CallPageAndrState() extends State<CallPageAndr> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CallCubit>();
    if (widget.answer) {
      cubit.answer();
    } else {
      cubit.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallCubit, CallState>(
      listener: (context, state) {
        if (state is CallEnded) context.pop();
      },
      child: Scaffold(
        appBar: M3EAppBar.top(
          shapeFamily: .round,
          density: .compact,
          title: const Text('Голосовой звонок'),
        ),
        body: BlocBuilder<CallCubit, CallState>(
          builder: (context, state) {
            return switch (state) {
              CallChecking() || CallInitial() => const _BusyView(
                text: 'Проверка поддержки звонков…',
              ),
              CallConnecting() => const _BusyView(text: 'Подключение…'),
              CallWaiting() => _WaitingView(
                roomName: widget.roomName,
                joining: widget.answer,
                onHangup: () => context.read<CallCubit>().hangup(),
              ),
              CallActive(:final isMuted, :final speakerOn) => _ActiveView(
                roomName: widget.roomName,
                isMuted: isMuted,
                speakerOn: speakerOn,
                onToggleMute: () => context.read<CallCubit>().toggleMute(),
                onToggleSpeaker: () => context.read<CallCubit>().toggleSpeaker(),
                onHangup: () => context.read<CallCubit>().hangup(),
              ),
              CallFailed(:final failure) => _FailedView(
                message: failure.message(),
                onClose: () => context.pop(),
                onRetry: () {
                  final cubit = context.read<CallCubit>();
                  if (widget.answer) {
                    cubit.answer();
                  } else {
                    cubit.start();
                  }
                },
              ),
              CallEnded() => const Center(child: AdaptiveLoadingIndicator()),
            };
          },
        ),
      ),
    );
  }
}

class const _BusyView({required final String text}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          const AdaptiveLoadingIndicator(),
          const SizedBox(height: 16),
          Text(text),
        ],
      ),
    );
  }
}

class const _WaitingView({
  required final String roomName,
  required final bool joining,
  required final VoidCallback onHangup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              roomName.isEmpty ? '?' : roomName[0],
              style: TextStyle(fontSize: 40, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 24),
          Text(roomName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(joining ? 'Присоединение…' : 'Вызов…'),
          const SizedBox(height: 48),
          M3EButton.filled(
            onPressed: onHangup,
            child: const Icon(Icons.call_end_rounded),
          ),
        ],
      ),
    );
  }
}

class const _ActiveView({
  required final String roomName,
  required final bool isMuted,
  required final bool speakerOn,
  required final VoidCallback onToggleMute,
  required final VoidCallback onToggleSpeaker,
  required final VoidCallback onHangup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              roomName.isEmpty ? '?' : roomName[0],
              style: TextStyle(fontSize: 40, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 24),
          Text(roomName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Разговор'),
          const SizedBox(height: 48),
          Row(
            mainAxisSize: .min,
            children: [
              M3EButton.tonal(
                onPressed: onToggleMute,
                child: Icon(
                  isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                ),
              ),
              const SizedBox(width: 16),
              M3EButton.filled(
                onPressed: onHangup,
                child: const Icon(Icons.call_end_rounded),
              ),
              const SizedBox(width: 16),
              M3EButton.tonal(
                onPressed: onToggleSpeaker,
                child: Icon(
                  speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _FailedView({
  required final String message,
  required final VoidCallback onClose,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: .min,
          children: [
            const Icon(Icons.call_end_rounded, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: .center),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: .min,
              children: [
                M3EButton.outlined(
                  onPressed: onClose,
                  child: const Text('Закрыть'),
                ),
                const SizedBox(width: 12),
                M3EButton.filled(
                  onPressed: onRetry,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
