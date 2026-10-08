import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/call/domain/entities/call_support.dart';
import 'package:convetchat/features/call/domain/usecases/check_call_support_usecase.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const CallButtonAndr({
  super.key,
  required final String roomId,
  required final String roomName,
  required final String? partnerUserId,
}) extends StatelessWidget {
  Future<void> _onPressed(BuildContext context) async {
    final support = await getIt<CheckCallSupportUseCase>()();
    if (!context.mounted) return;
    if (!support.isSupported) {
      AdaptiveSnackbar.show(
        context: context,
        message:
            support.failure?.message() ?? 'Звонки недоступны, попробуйте позже',
        type: .error,
      );
      return;
    }
    if (!context.mounted) return;
    context.push('/call/$roomId', extra: roomName);
  }

  @override
  Widget build(BuildContext context) {
    if (partnerUserId == null) return const SizedBox.shrink();
    return M3EIconButton(
      variant: .standard,
      onPressed: () => _onPressed(context),
      icon: const Icon(Icons.call_rounded),
      tooltip: 'Позвонить',
    );
  }
}
