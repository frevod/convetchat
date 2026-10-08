import 'package:material_ui/material_ui.dart';

class const SettingsSectionHeader({super.key, required final String title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
