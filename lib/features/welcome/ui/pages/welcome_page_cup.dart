import 'package:convetchat/features/welcome/ui/widgets/continue_entry_point_button.dart';
import 'package:convetchat/features/welcome/ui/widgets/logo.dart';
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
              const ContinueEntryPointButton(),
            ],
          ),
        ),
      ),
    );
  }
}
