import 'package:convetchat/features/auth/ui/widgets/login_button.dart';
import 'package:convetchat/features/auth/ui/widgets/login_field.dart';
import 'package:convetchat/features/auth/ui/widgets/password_field.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const LoginPageCup({super.key}) extends StatefulWidget {
  @override
  State<LoginPageCup> createState() => _LoginPageCupState();
}

class _LoginPageCupState() extends State<LoginPageCup> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Вход')),
      child: Center(
        child: Padding(
          padding: const EdgeInsetsGeometry.all(18.0),
          child: Column(
            mainAxisAlignment: .center,
            spacing: 10,
            children: [LoginField(), PasswordField(), LoginButton()],
          ),
        ),
      ),
    );
  }
}
