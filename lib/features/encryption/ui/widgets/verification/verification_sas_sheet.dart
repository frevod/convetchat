import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_sas_body.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/encryption.dart';

class const VerificationSasSheet({
  super.key,
  required final KeyVerification request,
  required final ValueListenable<List<dynamic>?> sasEmoji,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) return _cup(context);
    return _andr(context);
  }

  String _title(KeyVerification request) => request.sasTypes.contains('emoji')
      ? 'Совпадают ли эмодзи?'
      : 'Совпадают ли числа?';

  Widget _sas(KeyVerification request) =>
      ValueListenableBuilder<List<dynamic>?>(
        valueListenable: sasEmoji,
        builder: (context, emoji, _) =>
            VerificationSasBody(request: request, sasEmoji: emoji),
      );

  Widget _cup(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return DefaultTextStyle(
      style: TextStyle(color: label),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Text(
                _title(request),
                textAlign: .center,
                style: const TextStyle(fontSize: 17, fontWeight: .w700),
              ),
              const SizedBox(height: 12),
              _sas(request),
              const SizedBox(height: 16),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: AdaptiveButton.outlined(
                      onPressed: () {
                        request.rejectSas();
                      },
                      child: Text(
                        'Не совпадают',
                        textAlign: .center,
                        style: TextStyle(
                          color: CupertinoColors.destructiveRed.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AdaptiveButton.filled(
                      onPressed: () {
                        request.acceptSas();
                      },
                      child: const Text('Совпадают', textAlign: .center),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _andr(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SingleChildScrollView(
      child: Container(
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
              _title(request),
              style: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 16),
            _sas(request),
            const SizedBox(height: 20),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: M3EButton.outlined(
                    onPressed: () {
                      request.rejectSas();
                    },
                    child: DefaultTextStyle(
                      style: TextStyle(color: scheme.error),
                      child: const Text('Не совпадают'),
                    ),
                  ),
                ),
                Expanded(
                  child: M3EButton.filled(
                    onPressed: () {
                      request.acceptSas();
                    },
                    child: const Text('Совпадают'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
