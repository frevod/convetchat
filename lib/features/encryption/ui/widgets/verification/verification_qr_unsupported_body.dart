import 'package:material_ui/material_ui.dart';

class const VerificationQrUnsupportedBody({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: .min,
      children: [
        SizedBox(height: 16),
        Text(
          'QR-проверка не поддерживается. Попросите собеседника '
          'выбрать сравнение по эмодзи или числам.',
          textAlign: .center,
        ),
      ],
    );
  }
}
