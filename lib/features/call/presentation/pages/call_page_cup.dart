import 'package:cupertino_ui/cupertino_ui.dart';

class const CallPageCup({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Звонок')),
      child: Center(child: Text('Звонки пока доступны только на Android')),
    );
  }
}
