import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification_avatar.dart';
import 'package:flutter/widgets.dart';

class const VerificationWaitingBody({
  super.key,
  required final String displayName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Stack(
            alignment: .center,
            children: [
              VerificationAvatar(name: displayName, radius: 24),
              const SizedBox(
                width: 50,
                height: 50,
                child: AdaptiveLoadingIndicator(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Ожидание принятия запроса на другом устройстве…',
            textAlign: .center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Примите запрос там. Если ничего не происходит — '
            'отмените и попробуйте снова.',
            textAlign: .center,
          ),
        ],
      ),
    );
  }
}
