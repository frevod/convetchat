import 'package:convetchat/features/auth/ui/widgets/server_continue_button.dart';
import 'package:convetchat/features/auth/ui/widgets/server_field.dart';
import 'package:material_3_expressive/components/app_bars/m3e_app_bars.dart';
import 'package:material_ui/material_ui.dart';

class const ServerPageAndr({super.key}) extends StatefulWidget {
  @override
  State<ServerPageAndr> createState() => _ServerPageAndrState();
}

class _ServerPageAndrState() extends State<ServerPageAndr> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: Text('Выбор сервера'),
        automaticallyImplyLeading: true,
      ),

      bottomSheet: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: ServerContinueButton(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 12,
          children: [
            Text(
              'Введите адрес вашего домашнего сервера',
              style: textTheme.titleMedium,
              textAlign: .center,
            ),
            Text(
              'Домашний сервер в Matrix — это место, где хранятся ваши данные'
              'В Matrix вы не привязаны к одному серверу, а можете использовать любой',
              style: textTheme.bodyMedium,
              textAlign: .center,
            ),
            Text(
              'Поддерживаются только серверы с MAS (Matrix Authentication Service)',
              style: textTheme.bodySmall,
              textAlign: .center,
            ),
            ServerField(),
          ],
        ),
      ),
    );
  }
}
