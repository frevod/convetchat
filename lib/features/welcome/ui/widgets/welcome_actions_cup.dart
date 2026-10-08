import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/features/auth/domain/entities/auth_mode.dart';
import 'package:convetchat/features/auth/ui/pages/login_callback_page.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';

class const WelcomeActionsCup({super.key}) extends StatefulWidget {
  @override
  State<WelcomeActionsCup> createState() => _WelcomeActionsCupState();
}

class _WelcomeActionsCupState() extends State<WelcomeActionsCup> {
  bool _busy = false;

  Future<void> _onAuthPressed(AuthMode mode) async {
    final useDefault = await AdaptiveDialog.show<bool>(
      context: context,
      title: mode == .register
          ? 'Где вы хотите зарегистрироваться?'
          : 'Где вы хотите войти?',
      subtitle: mode == .register
          ? 'Выберите сервер, на котором будет создан ваш аккаунт.'
          : 'Выберите сервер, на котором находится ваш аккаунт.',
      axis: .vertical,
      actions: const [
        AdaptiveDialogAction(
          label: 'Использовать сервер convet.xyz',
          isPrimary: true,
          result: true,
        ),
        AdaptiveDialogAction(
          label: 'Ввести свой адрес сервера',
          result: false,
        ),
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
            CupertinoButton(
              padding: const EdgeInsets.all(12),
              onPressed: () {},
              child: const Icon(CupertinoIcons.qrcode),
            ),
            Expanded(
              child: AdaptiveButton.filled(
                onPressed: () => _onAuthPressed(.login),
                child: const Text('Войти'),
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: AdaptiveButton.outlined(
            onPressed: () => _onAuthPressed(.register),
            child: const Text('Зарегистрироваться'),
          ),
        ),
      ],
    );
  }
}
