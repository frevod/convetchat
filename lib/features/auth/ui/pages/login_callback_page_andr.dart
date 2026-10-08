import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/auth/ui/pages/login_callback_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/components/app_bars/m3e_app_bars.dart';
import 'package:material_ui/material_ui.dart';

class const LoginCallbackPageAndr({super.key, final String? token})
    extends StatefulWidget {
  @override
  State<LoginCallbackPageAndr> createState() => _LoginCallbackPageAndrState();
}

class _LoginCallbackPageAndrState() extends State<LoginCallbackPageAndr> {
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
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: Text('Вход'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
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
