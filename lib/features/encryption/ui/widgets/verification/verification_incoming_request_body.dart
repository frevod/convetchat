import 'package:convetchat/features/encryption/ui/widgets/verification_avatar.dart';
import 'package:flutter/widgets.dart';

class const VerificationIncomingRequestBody({
  super.key,
  required final String displayName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        const SizedBox(height: 16),
        VerificationAvatar(name: displayName, radius: 32),
        const SizedBox(height: 16),
        Text('$displayName запрашивает проверку устройства'),
      ],
    );
  }
}
