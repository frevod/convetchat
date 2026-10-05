import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/security/app_lock_service.dart';
import 'package:convetchat/features/settings/ui/pages/app_lock_page.dart';
import 'package:flutter/widgets.dart';

/// Оверлей поверх всего приложения. Когда сервис в `locked`,
/// перекрывает контент экраном PIN — обойти через навигацию нельзя.
class const AppLockGate({required final Widget child, super.key}) extends StatefulWidget {
  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<AppLockService>().init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getIt<AppLockService>().onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<bool>(
          valueListenable: getIt<AppLockService>(),
          builder: (context, locked, _) {
            if (!locked) return const SizedBox.shrink();
            return const Positioned.fill(child: AppLockPage());
          },
        ),
      ],
    );
  }
}
