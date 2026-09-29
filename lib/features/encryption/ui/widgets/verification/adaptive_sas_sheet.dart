import 'dart:async';
import 'dart:convert';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_sas_sheet.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_waiting_sas_body.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/encryption.dart';

class const AdaptiveSasSheet({
  super.key,
  required final KeyVerification request,
}) extends StatefulWidget {
  static Future<bool> show(
    BuildContext context,
    KeyVerification request,
  ) async {
    if (getIt<PlatformStyle>().isCupertino) {
      return await showCupertinoModalPopup<bool>(
            context: context,
            useRootNavigator: false,
            barrierDismissible: false,
            builder: (sheetContext) => Container(
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground.resolveFrom(
                  sheetContext,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey2.resolveFrom(
                          sheetContext,
                        ),
                        borderRadius: .circular(2.5),
                      ),
                    ),
                    AdaptiveSasSheet(request: request),
                  ],
                ),
              ),
            ),
          ) ??
          false;
    }
    return await showModalBottomSheet<bool>(
          context: context,
          useRootNavigator: false,
          backgroundColor: const Color(0x00000000),
          elevation: 0,
          useSafeArea: true,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          builder: (_) => M3EBottomSheet(
            showDragHandle: true,
            child: AdaptiveSasSheet(request: request),
          ),
        ) ??
        false;
  }

  @override
  State<AdaptiveSasSheet> createState() => _AdaptiveSasSheetState();
}

class _AdaptiveSasSheetState() extends State<AdaptiveSasSheet> {
  void Function()? _originalOnUpdate;
  final ValueNotifier<List<dynamic>?> _sasEmoji = ValueNotifier(null);
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = () {
      _originalOnUpdate?.call();
      if (!mounted) return;
      setState(() {});
      _maybeClose();
    };
    rootBundle.loadString('assets/sas-emoji.json').then((raw) {
      if (!mounted) return;
      _sasEmoji.value = json.decode(raw) as List<dynamic>;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeClose());
  }

  void _maybeClose() {
    if (_closing) return;
    final state = widget.request.state;
    if (state != KeyVerificationState.done &&
        state != KeyVerificationState.error) {
      return;
    }
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: false,
      ).pop(state == KeyVerificationState.done);
    });
  }

  @override
  void dispose() {
    widget.request.onUpdate = _originalOnUpdate;
    _sasEmoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.request.state;
    if (state == KeyVerificationState.askSas) {
      return VerificationSasSheet(request: widget.request, sasEmoji: _sasEmoji);
    }
    if (state == KeyVerificationState.waitingSas) {
      return VerificationWaitingSasBody(
        useEmoji: widget.request.sasTypes.contains('emoji'),
      );
    }
    return const SizedBox.shrink();
  }
}
