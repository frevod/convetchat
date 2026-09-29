import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class const VerificationPassphraseBody({
  super.key,
  required final TextEditingController controller,
  required final String? inputError,
  required final bool checkingInput,
  required final bool isCupertino,
  required final ValueChanged<String> onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        const Text(
          'Введите кодовую фразу или ключ восстановления',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (isCupertino)
          CupertinoTextField(
            controller: controller,
            obscureText: true,
            autocorrect: false,
            placeholder: 'Фраза или ключ',
            onSubmitted: onSubmit,
          )
        else
          TextField(
            controller: controller,
            obscureText: true,
            autocorrect: false,
            onSubmitted: onSubmit,
            decoration: const InputDecoration(
              hintText: 'Фраза или ключ',
              border: OutlineInputBorder(),
            ),
          ),
        if (inputError != null) ...[
          const SizedBox(height: 6),
          Text(
            inputError!,
            style: TextStyle(
              color: isCupertino
                  ? CupertinoColors.systemRed
                  : Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
        if (checkingInput) ...[
          const SizedBox(height: 10),
          const Center(child: AdaptiveLoadingIndicator()),
        ],
      ],
    );
  }
}
