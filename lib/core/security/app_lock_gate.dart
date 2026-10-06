import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/security/app_lock_service.dart';
import 'package:convetchat/features/settings/ui/pages/app_lock_page.dart';
import 'package:flutter/widgets.dart';

class const AppLockGate({required final Widget child, super.key})
    extends StatefulWidget {
  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState() extends State<AppLockGate> {
  @override
  void initState() {
    super.initState();
    getIt<AppLockService>().init();
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
