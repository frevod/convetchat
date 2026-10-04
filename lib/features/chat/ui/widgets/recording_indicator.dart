import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/features/chat/ui/widgets/waveform_bars.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class const RecordingIndicator({
  super.key,

  required final List<double> levels,
  required final Duration elapsed,

  final bool showCancel = false,
  final VoidCallback? onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    final Color accent;
    final Color timeColor;
    if (isCupertino) {
      accent = CupertinoColors.activeBlue;
      timeColor = CupertinoColors.systemGrey;
    } else {
      final scheme = Theme.of(context).colorScheme;
      accent = scheme.primary;
      timeColor = scheme.onSurfaceVariant;
    }
    return Padding(
      padding: isCupertino
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: .min,
        children: [
          if (!showCancel)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'Проведите влево для отмены',
                style: TextStyle(fontSize: 11, color: timeColor),
              ),
            ),
          Row(
            children: [
              if (showCancel) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: .opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCancel?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isCupertino
                          ? CupertinoIcons.delete
                          : Icons.delete_outline_rounded,
                      size: 25,
                      color: timeColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),

              SizedBox(
                width: 44,
                child: Text(
                  mediaTimeText(elapsed),
                  maxLines: 1,
                  style: TextStyle(fontSize: 13, color: timeColor),
                  textAlign: .center,
                ),
              ),

              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: WaveformBars(
                    values: levels,
                    playedColor: CupertinoColors.systemGrey,
                    trackColor: accent.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
