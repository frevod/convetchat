import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_3_expressive/components/loading_indicator/m3e_loading_indicator.dart';

class const AdaptiveLoadingIndicator({super.key, final Color? color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return const CupertinoActivityIndicator();
    }
    return M3ELoadingIndicator(color: color);
  }
}
