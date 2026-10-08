import 'package:convetchat/features/chats/ui/widgets/encryption_banner.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/components/buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart';

class const EncryptionBannerAndr({
  super.key,
  required final EncryptionBannerType type,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final setup = type == .setup;
    final background = setup
        ? scheme.secondaryContainer
        : scheme.errorContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: .circular(14),
          color: background,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                mainAxisSize: .min,
                children: [
                  Expanded(
                    child: Text(
                      setup
                          ? 'Резервная копия не настроена. Чтобы не потерять доступ к сообщениям, рекомендуется схранить ключ восстановления'
                          : 'Резервная копия не восстановлена. Чтобы получить доступ к зашифрованным сообщениям подтвердите личность',
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: .infinity,
                child: M3EButton.filled(
                  onPressed: () => context.go('/backup'),
                  child: Text(setup ? 'Настроить' : 'Подтвердить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
