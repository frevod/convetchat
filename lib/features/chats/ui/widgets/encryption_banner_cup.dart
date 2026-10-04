import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/features/chats/ui/widgets/encryption_banner.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';

class const EncryptionBannerCup({
  super.key,
  required final EncryptionBannerType type,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final setup = type == .setup;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondarySystemFill,
            context,
          ),
          borderRadius: .circular(20),
        ),
        padding: const EdgeInsets.all(10),
        child: CupertinoListTile(
          title: Text(
            setup
                ? 'Резервная копия не включена'
                : 'Резервная копия не восстановлена',
            maxLines: 2,
          ),
          subtitle: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  setup
                      ? 'Чтобы не потерять сообщения, включите её'
                      : 'Чтобы получить доступ к зашифрованным сообщениям, '
                            'необходимо восстановить ключи шифрования',
                  maxLines: 3,
                ),
              ),
              SizedBox(
                width: .infinity,
                child: AdaptiveButton.filled(
                  onPressed: () => context.go('/backup'),
                  child: Text(
                    setup ? 'Настроить' : 'Подтвердить',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
