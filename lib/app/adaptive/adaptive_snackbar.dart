import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

enum AdaptiveSnackbarType() {
  success,
  error,
  info,
  warning,
  neutral,
}

class const AdaptiveSnackbar._() {
  static OverlayEntry? _cupertinoEntry;
  static Timer? _cupertinoTimer;

  static void show({
    required BuildContext context,
    required String message,
    AdaptiveSnackbarType type = .info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (getIt<PlatformStyle>().isCupertino) {
      _showCupertino(
        context: context,
        message: message,
        type: type,
        duration: duration,
      );
    } else {
      _showMaterial(
        context: context,
        message: message,
        type: type,
        duration: duration,
      );
    }
  }

  static void _showMaterial({
    required BuildContext context,
    required String message,
    required AdaptiveSnackbarType type,
    required Duration duration,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color snackBarColor = switch (type) {
      .success => Colors.green,
      .error => Colors.red,
      .warning => Colors.orange,
      .info => colorScheme.primary,
      .neutral => colorScheme.surfaceContainerHighest,
    };
    final Color textColor = switch (type) {
      .success || .error => Colors.white,
      .warning => Colors.black,
      .info => colorScheme.onPrimary,
      .neutral => colorScheme.onSurface,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: textColor)),
          backgroundColor: snackBarColor,
          duration: duration,
        ),
      );
  }

  static void _showCupertino({
    required BuildContext context,
    required String message,
    required AdaptiveSnackbarType type,
    required Duration duration,
  }) {
    _cupertinoTimer?.cancel();
    _cupertinoEntry?.remove();
    _cupertinoEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _CupertinoToastView(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          _cupertinoTimer?.cancel();
          if (_cupertinoEntry == entry) _cupertinoEntry = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _cupertinoEntry = entry;
    overlay.insert(entry);
    _cupertinoTimer = Timer(duration + const Duration(milliseconds: 400), () {
      if (_cupertinoEntry == entry && entry.mounted) {
        _cupertinoEntry = null;
        entry.remove();
      }
    });
  }
}

class const _CupertinoToastView({
  required final String message,
  required final AdaptiveSnackbarType type,
  required final Duration duration,
  required final VoidCallback onDismissed,
}) extends StatefulWidget {
  @override
  State<_CupertinoToastView> createState() => _CupertinoToastViewState();
}

class _CupertinoToastViewState()
    extends State<_CupertinoToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _hideTimer;
  bool _hiding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(curved);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _controller.forward();
    _hideTimer = Timer(widget.duration, _hide);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _hide() async {
    if (_hiding || !mounted) return;
    _hiding = true;
    try {
      await _controller.reverse();
    } catch (_) {
    }
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final (IconData?, Color) accent = switch (widget.type) {
      .success => (
        CupertinoIcons.check_mark_circled_solid,
        CupertinoColors.activeGreen.resolveFrom(context),
      ),
      .error => (
        CupertinoIcons.xmark_circle_fill,
        CupertinoColors.destructiveRed.resolveFrom(context),
      ),
      .info => (
        CupertinoIcons.info_circle_fill,
        CupertinoColors.activeBlue.resolveFrom(context),
      ),
      .warning => (
        CupertinoIcons.exclamationmark_triangle_fill,
        CupertinoColors.systemOrange.resolveFrom(context),
      ),
      .neutral => (null, CupertinoColors.systemGrey.resolveFrom(context)),
    };
    final background = CupertinoColors.secondarySystemBackground.resolveFrom(
      context,
    );
    final foreground = CupertinoColors.label.resolveFrom(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + keyboardInset),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Semantics(
                liveRegion: true,
                label: widget.message,
                child: Dismissible(
                  key: const ValueKey('adaptive_snackbar'),
                  direction: .down,
                  onDismissed: (_) => _hide(),
                  child: GestureDetector(
                    onTap: _hide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: .circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        spacing: 10,
                        children: [
                          if (accent.$1 != null)
                            Icon(accent.$1, size: 22, color: accent.$2),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                color: foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
