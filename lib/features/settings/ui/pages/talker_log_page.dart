import 'package:convetchat/core/di/locator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const TalkerLogPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TalkerScreen(talker: getIt<Talker>());
  }
}
