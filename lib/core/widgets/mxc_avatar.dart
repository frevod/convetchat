import 'dart:typed_data';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/storage/media_disk_cache.dart';
import 'package:convetchat/core/storage/storage_quota_store.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:http/http.dart' as http;
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
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load().timeout(
      const Duration(seconds: 20),
      onTimeout: () => null,
    );
  }

  @override
  void didUpdateWidget(_MxcAvatarView old) {
    super.didUpdateWidget(old);
    if (old.mxc == widget.mxc && old.size == widget.size) return;
    _bytes = _load().timeout(
      const Duration(seconds: 20),
      onTimeout: () => null,
    );
  }

  String get _cacheKey =>
      'avatar:${widget.mxc}:${widget.size.toInt()}x${widget.size.toInt()}';

  Future<Uint8List?> _load() async {
    final mxc = widget.mxc;
    if (mxc == null || mxc.isEmpty) return null;
    try {
      final disk = await getIt<MediaDiskCache>().getBytes(_cacheKey);
      if (disk != null) return disk;
    } catch (_) {}
    try {
      final uri = await Uri.parse(mxc).getThumbnailUri(
        getIt<Client>(),
        width: widget.size * 3,
        height: widget.size * 3,
      );
      final token = getIt<Client>().accessToken;
      final response = await http.get(
        uri,
        headers: token == null ? null : {'authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final bytes = response.bodyBytes;
      try {
        final quota = await getIt<StorageQuotaStore>().getMaxBytes();
        await getIt<MediaDiskCache>().putBytes(
          _cacheKey,
          bytes,
          maxBytes: quota,
        );
      } catch (_) {}
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null && bytes.isNotEmpty) {
          return ClipOval(
            child: Image.memory(
              bytes,
              width: widget.size,
              height: widget.size,
              fit: .cover,
              gaplessPlayback: true,
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
