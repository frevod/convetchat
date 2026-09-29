import 'package:convetchat/features/auth/ui/widgets/login_button.dart';
import 'package:convetchat/features/auth/ui/widgets/login_field.dart';
import 'package:convetchat/features/auth/ui/widgets/password_field.dart';
import 'package:material_3_expressive/components/app_bars/m3e_app_bars.dart';
import 'package:material_ui/material_ui.dart';

class const LoginPageAndr({super.key}) extends StatefulWidget {
  @override
  State<LoginPageAndr> createState() => _LoginPageAndrState();
}

class _LoginPageAndrState() extends State<LoginPageAndr> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: Text('Вход'),
        automaticallyImplyLeading: true,
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: LoginButton(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: .center,
            children: [LoginField(), SizedBox(height: 10), PasswordField()],
          ),
        ),
      ),
    );
  }
}
