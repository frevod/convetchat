import 'dart:async';
import 'dart:convert';

import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_passphrase_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_qr_unsupported_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_sas_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_waiting_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_waiting_sas_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification_avatar.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/encryption.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const VerificationSheet({
  super.key,
  required final KeyVerification request,
}) extends StatefulWidget {
  static Future<bool> show(
    BuildContext context,
    KeyVerification? request,
  ) async {
    if (request == null) {
      getIt<Talker>().warning('[e2ee:sheet] show() получил null request');
      return false;
    }
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
                    Flexible(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(
                            sheetContext,
                          ),
                        ),
                        child: VerificationSheet(request: request),
                      ),
                    ),
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
          builder: (_) => VerificationSheet(request: request),
        ) ??
        false;
  }

  static String displayNameOf(KeyVerification request) {
    final userId = request.userId;
    final local = userId.split(':').first;
    return local.startsWith('@') ? local.substring(1) : userId;
  }

  @override
  State<VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState() extends State<VerificationSheet> {
  void Function()? _originalOnUpdate;
  final ValueNotifier<List<dynamic>?> _sasEmoji = ValueNotifier(null);
  TextEditingController? _inputController;
  bool _busy = false;
  bool _finished = false;
  bool _checkingInput = false;
  String? _inputError;

  KeyVerification get _request => widget.request;

  @override
  void initState() {
    super.initState();
    _originalOnUpdate = _request.onUpdate;
    _request.onUpdate = () {
      _originalOnUpdate?.call();
      if (mounted) setState(() {});
    };
    rootBundle.loadString('assets/sas-emoji.json').then((raw) {
      if (!mounted) return;
      _sasEmoji.value = json.decode(raw) as List<dynamic>;
    });
  }

  @override
  void dispose() {
    _request.onUpdate = _originalOnUpdate;
    _sasEmoji.dispose();
    _inputController?.dispose();
    if (!_finished) {
      unawaited(_request.cancel().catchError((_) {}));
    }
    super.dispose();
  }

  void _finish(bool result) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context, rootNavigator: false).pop(result);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _finished) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, s) {
      getIt<Talker>().error('[e2ee:sheet] действие упало', e, s);
    } finally {
      if (mounted && !_finished) setState(() => _busy = false);
    }
  }

  Widget _filled(String label, Future<void> Function() action) {
    return AdaptiveButton.filled(
      onPressed: () => _run(action),
      enabled: !_busy,
      child: Text(label, textAlign: .center),
    );
  }

  Widget _outlined(String label, Future<void> Function() action) {
    return AdaptiveButton.outlined(
      onPressed: () => _run(action),
      enabled: !_busy,
      child: Text(label, textAlign: .center),
    );
  }

  Future<void> _cancelAndClose() async {
    await _request.cancel();
    _finish(false);
  }

  Future<void> _checkInput(String input) async {
    if (input.isEmpty || _checkingInput || _finished) return;
    setState(() {
      _checkingInput = true;
      _inputError = null;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    var valid = false;
    try {
      await _request.openSSSS(keyOrPassphrase: input);
      valid = true;

      unawaited(getIt<EncryptionRepository>().signOwnDevice(input));
    } catch (_) {
      valid = false;
    }
    if (!mounted || _finished) return;
    setState(() {
      _checkingInput = false;
      if (!valid) _inputError = 'Неверная фраза или ключ';
    });
  }

  String get _displayName => VerificationSheet.displayNameOf(_request);

  @override
  Widget build(BuildContext context) {
    final state = _request.state;

    if (state == .done && !_finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(true));
    }

    final (title, body, buttons) = _content(state);

    final content = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text(title, textAlign: .center),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: body,
          ),
        ),
        if (buttons.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              16 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Row(
              spacing: 12,
              children: [for (final button in buttons) Expanded(child: button)],
            ),
          )
        else
          SizedBox(height: 16 + MediaQuery.viewPaddingOf(context).bottom),
      ],
    );

    if (getIt<PlatformStyle>().isCupertino) return content;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }

  (String, Widget, List<Widget>) _content(KeyVerificationState state) {
    switch (state) {
      case .showQRSuccess:
      case .confirmQRScan:
        return (
          'Проверка недоступна',
          const VerificationQrUnsupportedBody(),
          [_outlined('Закрыть', () async => _finish(false))],
        );
      case .askSSSS:
        _inputController ??= TextEditingController();
        return (
          'Проверка устройства',
          VerificationPassphraseBody(
            controller: _inputController!,
            inputError: _inputError,
            checkingInput: _checkingInput,
            isCupertino: getIt<PlatformStyle>().isCupertino,
            onSubmit: _checkInput,
          ),
          [
            _outlined('Пропустить', () => _request.openSSSS(skip: true)),
            _filled(
              'Отправить',
              () async => _checkInput(_inputController?.text ?? ''),
            ),
          ],
        );
      case .askAccept:
        return (
          'Новый запрос проверки',
          Column(
            mainAxisSize: .min,
            children: [
              const SizedBox(height: 8),
              VerificationAvatar(name: _displayName, radius: 32),
              const SizedBox(height: 16),
              Text(
                '$_displayName запрашивает проверку устройства',
                textAlign: .center,
              ),
            ],
          ),
          [
            _outlined('Отклонить', () async {
              await _request.rejectVerification();
              _finish(false);
            }),
            _filled('Принять', () => _request.acceptVerification()),
          ],
        );
      case .askChoice:
      case .waitingAccept:
        return (
          'Проверка устройства',
          VerificationWaitingBody(displayName: _displayName),
          [_outlined('Отмена', _cancelAndClose)],
        );
      case .askSas:
        return (
          _request.sasTypes.contains('emoji')
              ? 'Совпадают ли эмодзи?'
              : 'Совпадают ли числа?',
          ValueListenableBuilder<List<dynamic>?>(
            valueListenable: _sasEmoji,
            builder: (context, emoji, _) =>
                VerificationSasBody(request: _request, sasEmoji: emoji),
          ),
          [
            _outlined('Не совпадают', () => _request.rejectSas()),
            _filled('Совпадают', () => _request.acceptSas()),
          ],
        );
      case .waitingSas:
        return (
          'Проверка устройства',
          VerificationWaitingSasBody(
            useEmoji: _request.sasTypes.contains('emoji'),
          ),
          [_outlined('Отмена', _cancelAndClose)],
        );
      case .done:
        return (
          'Проверка завершена',
          const Column(
            mainAxisSize: .min,
            children: [
              SizedBox(height: 8),
              Text('Устройство подтверждено', textAlign: .center),
            ],
          ),
          const [],
        );
      case .error:
        getIt<Talker>().warning(
          '[e2ee:sheet] error: state=${_request.state.name} '
          'canceledCode=${_request.canceledCode} '
          'canceledReason=${_request.canceledReason} '
          'canceled=${_request.canceled}',
        );
        return (
          'Ошибка проверки',
          Column(
            mainAxisSize: .min,
            children: [
              const SizedBox(height: 8),
              Text(
                _request.canceledReason ?? 'Проверка не удалась',
                textAlign: .center,
              ),
            ],
          ),
          [_filled('Закрыть', () async => _finish(false))],
        );
    }
  }
}
