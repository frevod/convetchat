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
  Widget build(BuildContext context) => _MxcAvatarView(
    mxc: mxc,
    fallback: fallback,
    size: size,
    showLoadingRing: showLoadingRing,
  );
}

class const _MxcAvatarView({
  required final String? mxc,
  required final String fallback,
  required final double size,
  required final bool showLoadingRing,
}) extends StatefulWidget {
  @override
  State<_MxcAvatarView> createState() => _MxcAvatarViewState();
}

class _MxcAvatarViewState() extends State<_MxcAvatarView> {
  late Future<Uri> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = _resolve();
  }

  @override
  void didUpdateWidget(_MxcAvatarView old) {
    super.didUpdateWidget(old);
    if (old.mxc == widget.mxc && old.size == widget.size) return;
    _thumbnail = _resolve();
  }

  Future<Uri> _resolve() {
    final mxc = widget.mxc;
    if (mxc == null || mxc.isEmpty) return Future.value(Uri());
    return Uri.parse(mxc).getThumbnailUri(
      getIt<Client>(),
      width: widget.size * 3,
      height: widget.size * 3,
    );
  }

  Map<String, String>? _authHeaders() {
    final token = getIt<Client>().accessToken;
    if (token == null) return null;
    return {'authorization': 'Bearer $token'};
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return FutureBuilder<Uri>(
      future: _thumbnail,
      builder: (context, snapshot) {
        final uri = snapshot.data;
        if (uri != null && uri.toString().isNotEmpty) {
          return ClipOval(
            child: Image.network(
              uri.toString(),
              headers: _authHeaders(),
              width: widget.size,
              height: widget.size,
              fit: .cover,
              errorBuilder: (context, _, _) => _fallback(context),
            ),
          );
        }
        final fallbackWidget = _fallback(context);
        if (widget.showLoadingRing &&
            snapshot.connectionState == ConnectionState.waiting &&
            !isCupertino) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                fallbackWidget,
                M3EProgressIndicator.circularWavy(size: widget.size),
              ],
            ),
          );
        }
        return fallbackWidget;
      },
    );
  }

  Widget _fallback(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: .center,
      decoration: BoxDecoration(
        color: isCupertino
            ? CupertinoColors.systemBlue.resolveFrom(context)
            : Theme.of(context).colorScheme.primaryContainer,
        shape: .circle,
      ),
      child: Text(
        widget.fallback,
        style: TextStyle(
          fontSize: widget.size * 0.42,
          color: isCupertino ? CupertinoColors.white : null,
        ),
      ),
    );
  }
}
