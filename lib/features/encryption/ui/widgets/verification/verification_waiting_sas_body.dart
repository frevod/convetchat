import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:flutter/widgets.dart';

class const VerificationWaitingSasBody({
  super.key,
  required final bool useEmoji,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        const SizedBox(height: 16),
        const AdaptiveLoadingIndicator(),
        const SizedBox(height: 16),
        Text(
          useEmoji
              ? 'Ожидание подтверждения эмодзи на другом устройстве…'
              : 'Ожидание подтверждения чисел на другом устройстве…',
          textAlign: .center,
        ),
      ],
    );
  }
}
