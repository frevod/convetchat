import 'package:convetchat/features/auth/ui/widgets/server_continue_button.dart';
import 'package:convetchat/features/auth/ui/widgets/server_field.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const ServerPageCup({super.key}) extends StatefulWidget {
  @override
  State<ServerPageCup> createState() => _ServerPageCupState();
}

class _ServerPageCupState() extends State<ServerPageCup> {
  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Выбор сервера'),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsetsGeometry.all(18.0),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .stretch,
            spacing: 12,
            children: [
              Text(
                'Введите адрес вашего домашнего сервера.',
                style: baseStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Домашний сервер в Matrix — это место, где хранятся ваши данные. '
                'В Matrix вы не привязаны к одному серверу, а можете использовать любой.',
              ),
              Text(
                'Поддерживаются только серверы с MAS (Matrix Authentication Service).',
                style: baseStyle.copyWith(fontSize: 13),
              ),
              ServerField(),
              SizedBox(height: 10),
              ServerContinueButton(),
            ],
          ),
        ),
      ),
    );
  }
}
