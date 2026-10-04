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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Выбор сервера'),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsetsGeometry.all(18.0),
          child: Column(
            mainAxisAlignment: .center,
            children: [
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
