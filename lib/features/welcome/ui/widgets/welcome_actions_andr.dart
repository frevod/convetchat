import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/features/auth/domain/entities/auth_mode.dart';
import 'package:convetchat/features/auth/ui/pages/login_callback_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

class const WelcomeActionsAndr({super.key}) extends StatefulWidget {
  @override
  State<WelcomeActionsAndr> createState() => _WelcomeActionsAndrState();
}

class _WelcomeActionsAndrState() extends State<WelcomeActionsAndr> {
  bool _busy = false;

  Future<void> _onAuthPressed(AuthMode mode) async {
    final useDefault = await AdaptiveDialog.show<bool>(
      context: context,
      title: mode == .register
          ? 'Где вы хотите зарегистрироваться?'
          : 'Где вы хотите войти?',
      subtitle: mode == .register
          ? 'Выберите сервер, на котором будет создан ваш аккаунт'
          : 'Выберите сервер, на котором находится ваш аккаунт',
      axis: .vertical,
      actions: const [
        AdaptiveDialogAction(
          label: 'Использовать сервер convet.xyz',
          isPrimary: true,
          result: true,
        ),
        AdaptiveDialogAction(label: 'Ввести свой адрес сервера', result: false),
      ],
    );
    if (!mounted || useDefault == null) return;
    if (!useDefault) {
      context.push('/server_choice', extra: mode);
      return;
    }
    setState(() => _busy = true);
    final message = await startDefaultServerSso(context, mode);
    if (!mounted) return;
    if (message != null) {
      AdaptiveSnackbar.show(context: context, message: message, type: .error);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Center(child: AdaptiveLoadingIndicator());
    }
    return Column(
      mainAxisSize: .min,
      spacing: 12,
      children: [
        Row(
          spacing: 12,
          children: [
            M3EIconButton(
              icon: const Icon(Icons.qr_code_rounded),
              tooltip: 'Войти по QR',
              onPressed: () {},
              size: .md,
            ),
            Expanded(
              child: M3EButton.filled(
                size: .md,
                onPressed: () => _onAuthPressed(.login),
                child: const Text('Войти'),
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: M3EButton.outlined(
            size: .md,
            onPressed: () => _onAuthPressed(.register),
            child: const Text('Зарегистрироваться'),
          ),
        ),
      ],
    );
  }
}
