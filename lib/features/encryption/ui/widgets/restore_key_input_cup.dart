import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/encryption/ui/widgets/unlock_error_text.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const RestoreKeyInputCup({
  super.key,
  required final TextEditingController controller,
  required final bool isLoading,
  required final bool obscureText,
  required final bool keyEntered,
  required final Object? unlockError,
  required final VoidCallback onToggleObscure,
  required final VoidCallback onUnlock,
  required final VoidCallback onOpenKeyFile,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        AdaptiveTextField(
          enabled: !isLoading,
          obscureText: obscureText,
          controller: controller,
          label: 'Кодовая фраза или ключ',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isLoading ? null : onToggleObscure,
              child: Icon(
                obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 20,
              ),
            ),
            const Spacer(),
            if (isLoading)
              const SizedBox.square(
                dimension: 32,
                child: Center(child: AdaptiveLoadingIndicator()),
              )
            else
              AdaptiveButton.filled(
                onPressed: keyEntered ? onUnlock : onOpenKeyFile,
                child: Text(
                  keyEntered ? 'Разблокировать' : 'Открыть файл',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
        if (unlockError != null) ...[
          const SizedBox(height: 6),
          Text(
            unlockErrorText(unlockError!),
            style: TextStyle(
              color: CupertinoColors.systemRed.resolveFrom(context),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
