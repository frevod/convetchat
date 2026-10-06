import 'dart:async';

import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/encryption/ui/incoming_verification_listener.dart';
import 'package:convetchat/features/encryption/ui/key_forward_listener.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const SplashPageCup({super.key}) extends StatefulWidget {
  @override
  State<SplashPageCup> createState() => _SplashPageCupState();
}

class _SplashPageCupState() extends State<SplashPageCup> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final client = await getIt.getAsync<Client>().timeout(
        const Duration(seconds: 60),
      );
      if (!mounted) return;
      initIncomingVerificationListener();
      initKeyForwardListener();
      context.go(client.isLogged() ? '/chats' : '/welcome');
    } catch (e, s) {
      getIt<Talker>().error('[bootstrap] app launch failed', e, s);
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: _failed
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Не удалось запуститься. Перезапустите приложение.',
                  textAlign: .center,
                ),
              )
            : const AdaptiveLoadingIndicator(),
      ),
    );
  }
}
