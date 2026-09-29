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
    final foreground = setup
        ? scheme.onSecondaryContainer
        : scheme.onErrorContainer;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: .circular(14),
          color: background,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: .min,
            spacing: 5,
            children: [
              Icon(
                setup ? Icons.shield_outlined : Icons.lock_outline_rounded,
                color: foreground,
              ),
              Expanded(
                child: Text(
                  setup
                      ? 'Шифрование ещё не настроено. Чтобы не потерять сообщения создайте резервную копию'
                      : 'Восстановите доступ к зашифрованным сообщениям',
                  style: TextStyle(color: foreground),
                ),
              ),
              M3EButton.filled(
                onPressed: () => context.go('/backup'),
                child: Text(setup ? 'Настроить' : 'Подтвердить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
