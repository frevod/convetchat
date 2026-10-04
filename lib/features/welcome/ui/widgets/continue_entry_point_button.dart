import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/adaptive/adaptive_buttons.dart';

class const ContinueEntryPointButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AdaptiveButton.filled(
        onPressed: () => context.push('/server_choice'),
        child: const Text('Продолжить'),
      ),
    );
  }
}
