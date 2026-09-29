import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

class const MxcAvatar({
  super.key,
  required BuildContext context,

  required final String? mxc,

  required final String fallback,
  final double size = 48,

  final bool showLoadingRing = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uri>(
      future: _thumbnailUri(),
      builder: (context, snapshot) {
        final uri = snapshot.data;
        if (uri != null && uri.toString().isNotEmpty) {
          return ClipOval(
            child: Image.network(
              uri.toString(),
              headers: _authHeaders(),
              width: size,
              height: size,
              fit: .cover,
              errorBuilder: (context, _, _) => _fallback(context),
            ),
          );
        }
        final fallbackWidget = _fallback(context);
        if (showLoadingRing &&
            snapshot.connectionState == ConnectionState.waiting &&
            !getIt<PlatformStyle>().isCupertino) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                fallbackWidget,
                M3EProgressIndicator.circularWavy(size: size),
              ],
            ),
          );
        }
        return fallbackWidget;
      },
    );
  }

  Future<Uri> _thumbnailUri() async {
    if (mxc == null || mxc!.isEmpty) return Uri();
    return Uri.parse(mxc!)
        .getThumbnailUri(getIt<Client>(), width: size * 3, height: size * 3);
  }

  Map<String, String>? _authHeaders() {
    final token = getIt<Client>().accessToken;
    if (token == null) return null;
    return {'authorization': 'Bearer $token'};
  }

  Widget _fallback(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return Container(
      width: size,
      height: size,
      alignment: .center,
      decoration: BoxDecoration(
        color: isCupertino
            ? CupertinoColors.systemBlue.resolveFrom(context)
            : Theme.of(context).colorScheme.primaryContainer,
        shape: .circle,
      ),
      child: Text(
        fallback,
        style: TextStyle(
          fontSize: size * 0.42,
          color: isCupertino ? CupertinoColors.white : null,
        ),
      ),
    );
  }
}
