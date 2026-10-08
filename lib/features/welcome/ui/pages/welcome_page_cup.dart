import 'package:convetchat/features/welcome/ui/widgets/logo.dart';
import 'package:convetchat/features/welcome/ui/widgets/welcome_actions.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const WelcomePageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Padding(
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
                style: CupertinoTheme.of(
                  context,
                ).textTheme.navTitleTextStyle,
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
