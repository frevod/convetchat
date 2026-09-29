import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

enum AdaptiveDialogAxis() {
  vertical,
  horizontal,
}

class const AdaptiveDialog({
  super.key,
  final AdaptiveDialogAxis axis = .horizontal,
  required final String title,
  required final String subtitle,
  required final List<AdaptiveDialogAction> actions,
}) extends StatelessWidget {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    AdaptiveDialogAxis axis = .horizontal,
    required List<AdaptiveDialogAction> actions,
    bool barrierDismissible = false,
  }) {
    if (getIt<PlatformStyle>().isCupertino) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: 'AdaptiveDialog',
        builder: (dialogContext) => AdaptiveDialog(
          axis: axis,
          title: title,
          subtitle: subtitle,
          actions: actions,
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: const Color(0x00000000),
      elevation: 0,
      useSafeArea: true,
      builder: (sheetContext) => AdaptiveDialog(
        axis: axis,
        title: title,
        subtitle: subtitle,
        actions: actions,
      ),
    );
  }

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Продолжить',
    String cancelLabel = 'Отмена',
    bool isPrimary = true,
    bool isDestructive = false,
    AdaptiveDialogAxis axis = .horizontal,
  }) async {
    final cancel = AdaptiveDialogAction(
      label: cancelLabel,
      isPrimary: isDestructive,
      result: false,
    );
    final confirmAction = AdaptiveDialogAction(
      label: confirmLabel,
      isPrimary: !isDestructive && isPrimary,
      isDestructive: isDestructive,
      result: true,
    );
    final actions = axis == .vertical
        ? [confirmAction, cancel]
        : [cancel, confirmAction];
    final result = await show<bool>(
      context: context,
      title: title,
      subtitle: message,
      axis: axis,
      actions: actions,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(subtitle),
        actions: actions,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isVertical = axis == .vertical || actions.length > 2;

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: .circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (isVertical)
            Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              spacing: 8,
              children: actions,
            )
          else
            Row(
              spacing: 12,
              children: [for (final action in actions) Expanded(child: action)],
            ),
        ],
      ),
    );
  }
}

class const AdaptiveDialogAction({
  super.key,
  required final String label,
  final VoidCallback? onTap,
  final Object? result,
  final bool isPrimary = false,
  final bool isDestructive = false,
}) extends StatelessWidget {
  void _handleTap(BuildContext context) {
    onTap?.call();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return CupertinoDialogAction(
        onPressed: () => _handleTap(context),
        isDefaultAction: isPrimary && !isDestructive,
        isDestructiveAction: isDestructive,
        child: Text(label),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    if (isPrimary) {
      return M3EButton.filled(
        onPressed: () => _handleTap(context),
        size: .md,
        decoration: M3EButtonDecoration(
          backgroundColor: isDestructive
              ? WidgetStateProperty.all(scheme.error)
              : null,
          foregroundColor: isDestructive
              ? WidgetStateProperty.all(scheme.onError)
              : null,
        ),
        child: Text(label),
      );
    }
    return M3EButton.tonal(
      onPressed: () => _handleTap(context),
      size: .md,
      decoration: M3EButtonDecoration(
        foregroundColor: isDestructive
            ? WidgetStateProperty.all(scheme.error)
            : null,
      ),
      child: Text(label),
    );
  }
}
