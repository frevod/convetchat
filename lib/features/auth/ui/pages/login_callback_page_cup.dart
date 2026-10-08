import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/auth/ui/pages/login_callback_page.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';

class const LoginCallbackPageCup({super.key, final String? token})
    extends StatefulWidget {
  @override
  State<LoginCallbackPageCup> createState() => _LoginCallbackPageCupState();
}

class _LoginCallbackPageCupState() extends State<LoginCallbackPageCup> {
  String? _error;

  @override
  void initState() {
    super.initState();
    completeTokenLogin(context, widget.token).then((message) {
      if (mounted && message != null) setState(() => _error = message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Вход')),
      child: Center(
        child: Padding(
          padding: const EdgeInsetsGeometry.all(18.0),
          child: _error == null
              ? const AdaptiveLoadingIndicator()
              : Column(
                  mainAxisSize: .min,
                  spacing: 12,
                  children: [
                    Text(_error!, textAlign: .center),
                    AdaptiveButton.filled(
                      onPressed: () => context.go('/welcome'),
                      child: const Text('Назад'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
