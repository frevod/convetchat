import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/encryption/ui/widgets/unlock_error_text.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_3_expressive/components/icon_buttons/m3e_icon_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const RestoreKeyInputAndr({
  super.key,
  required final TextEditingController controller,
  required final bool isLoading,
  required final bool obscureText,
  required final bool keyEntered,
  required final Object? unlockError,
  required final VoidCallback onToggleObscure,
  required final VoidCallback onUnlock,
  required final VoidCallback onOpenKeyFile,
  required final ValueChanged<String> onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: isLoading,
      obscureText: obscureText,
      controller: controller,
      minLines: 1,
      maxLines: obscureText ? 1 : 4,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Кодовая фраза или ключ',
        prefixIcon: M3EIconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
          ),
          onPressed: onToggleObscure,
        ),
        errorText: unlockError == null ? null : unlockErrorText(unlockError!),
        errorMaxLines: 4,
        suffixIcon: isLoading
            ? const SizedBox.square(
                dimension: 32,
                child: Center(child: AdaptiveLoadingIndicator()),
              )
            : M3EButton.text(
                onPressed: keyEntered ? onUnlock : onOpenKeyFile,
                child: Text(keyEntered ? 'Разблокировать' : 'Открыть файл'),
              ),
      ),
    );
  }
}
