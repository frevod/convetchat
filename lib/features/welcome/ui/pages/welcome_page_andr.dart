import 'package:convetchat/features/welcome/ui/widgets/logo.dart';
import 'package:convetchat/features/welcome/ui/widgets/welcome_actions.dart';
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
              const SizedBox(height: 20),
              Text(
                'Добро пожаловать в ConvetChat',
                textAlign: .center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              const WelcomeActions(),
            ],
          ),
        ),
      ),
    );
  }
}
