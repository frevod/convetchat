import 'package:convetchat/features/welcome/ui/widgets/login_entry_point_button.dart';
import 'package:convetchat/features/welcome/ui/widgets/logo.dart';
import 'package:material_ui/material_ui.dart';

class const WelcomePageAndr({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Column(
            mainAxisAlignment: .center,
            spacing: 5,
            children: [
              const Logo(),
              SizedBox(height: 20),
              const LoginEntryPointButton(),
            ],
          ),
        ),
      ),
    );
  }
}
