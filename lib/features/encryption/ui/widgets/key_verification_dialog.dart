import 'dart:async';

import 'package:convetchat/app/adaptive/adaptive_dialog.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/widgets/dialog_action.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/adaptive_sas_sheet.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_passphrase_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_qr_unsupported_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_waiting_body.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_waiting_sas_body.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:matrix/encryption.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const KeyVerificationDialog({
  super.key,
  required final KeyVerification request,
  required final void Function(bool result) onResolved,
}) extends StatefulWidget {
  static Future<bool> show(BuildContext context, KeyVerification? request) {
    if (request == null) {
      getIt<Talker>().warning('[e2ee:dialog] show() получил null request');
      return Future.value(false);
    }
    final completer = Completer<bool>();
    showCupertinoDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => KeyVerificationDialog(
        request: request,
        onResolved: (result) {
          if (!completer.isCompleted) completer.complete(result);
        },
      ),
    );
    return completer.future;
  }

  @override
  State<KeyVerificationDialog> createState() => _KeyVerificationState();
}

class _KeyVerificationState() extends State<KeyVerificationDialog> {
  void Function()? _originalOnUpdate;
  TextEditingController? _inputController;
  bool _checkingInput = false;
  String? _inputError;
  bool _finishHandled = false;
  bool _sasDelegated = false;

  @override
  void initState() {
    super.initState();
    _originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = () {
      _originalOnUpdate?.call();
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    widget.request.onUpdate = _originalOnUpdate;
    if (!_finishHandled && !_sasDelegated) {
      widget.request.cancel('m.user');
    }
    _inputController?.dispose();
    super.dispose();
  }

  Future<void> _checkInput(String input) async {
    if (input.isEmpty || _checkingInput) return;
    setState(() {
      _checkingInput = true;
      _inputError = null;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    var valid = false;
    try {
      await widget.request.openSSSS(keyOrPassphrase: input);
      valid = true;
    } catch (_) {
      valid = false;
    }
    if (!mounted) return;
    setState(() {
      _checkingInput = false;
      if (!valid) _inputError = 'Неверная фраза или ключ';
    });
  }

  String get _displayName {
    final userId = widget.request.userId;
    final local = userId.split(':').first;
    return local.startsWith('@') ? local.substring(1) : userId;
  }

  void _resolveAndPop(bool result) {
    if (_finishHandled || !mounted) return;
    _finishHandled = true;
    widget.onResolved(result);
    Navigator.of(context, rootNavigator: false).pop(result);
  }

  Future<void> _handleDone() async {
    if (_finishHandled) return;
    AdaptiveSnackbar.show(
      context: context,
      message: 'Проверка устройства завершена',
      type: .success,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _resolveAndPop(true);
  }

  void _handleError() {
    if (_finishHandled) return;
    getIt<Talker>().warning(
      '[e2ee:dialog] error: state=${widget.request.state.name} '
      'canceledCode=${widget.request.canceledCode} '
      'canceledReason=${widget.request.canceledReason} '
      'canceled=${widget.request.canceled}',
    );
    AdaptiveSnackbar.show(
      context: context,
      message: 'Ошибка проверки: ${widget.request.canceledReason}',
      type: .error,
    );
    _resolveAndPop(false);
  }

  Future<void> _delegateSas() async {
    if (_sasDelegated || _finishHandled) return;
    if (widget.request.state != KeyVerificationState.askSas) return;
    _sasDelegated = true;
    final navigator = Navigator.of(context, rootNavigator: false);
    final onResolved = widget.onResolved;
    navigator.pop();
    final result = await AdaptiveSasSheet.show(
      navigator.context,
      widget.request,
    );
    if (!_finishHandled) {
      _finishHandled = true;
      onResolved(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = getIt<PlatformStyle>().isCupertino;
    var titleText = 'Проверка устройства';
    Widget body;
    final buttons = <Widget>[];

    switch (widget.request.state) {
      case .showQRSuccess:
      case .confirmQRScan:
        titleText = 'Проверка недоступна';
        body = const VerificationQrUnsupportedBody();
        buttons.add(
          DialogAction(
            onPressed: () => _resolveAndPop(false),
            child: const Text('Закрыть'),
          ),
        );
      case .askSSSS:
        _inputController ??= TextEditingController();
        body = VerificationPassphraseBody(
          controller: _inputController!,
          inputError: _inputError,
          checkingInput: _checkingInput,
          isCupertino: isCupertino,
          onSubmit: _checkInput,
        );
        buttons.add(
          DialogAction(
            onPressed: () => _checkInput(_inputController?.text ?? ''),
            child: const Text('Отправить'),
          ),
        );
        buttons.add(
          DialogAction(
            onPressed: () => widget.request.openSSSS(skip: true),
            child: const Text('Пропустить'),
          ),
        );
      case .askAccept:
        titleText = 'Новый запрос проверки';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showAcceptDialog();
        });
        body = const SizedBox.shrink();
      case .askChoice:
      case .waitingAccept:
        body = VerificationWaitingBody(displayName: _displayName);
        buttons.add(
          DialogAction(
            onPressed: () {
              widget.request.cancel();
              _resolveAndPop(false);
            },
            child: const Text('Отмена'),
          ),
        );
      case .askSas:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _delegateSas();
        });
        body = const SizedBox.shrink();
      case .waitingSas:
        body = VerificationWaitingSasBody(
          useEmoji: widget.request.sasTypes.contains('emoji'),
        );
      case .done:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleDone();
        });
        body = const SizedBox.shrink();
      case .error:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleError();
        });
        body = const SizedBox.shrink();
    }

    final content = SizedBox(
      height: 256,
      width: 256,
      child: ListView(children: [body]),
    );

    return CupertinoAlertDialog(
      title: Text(titleText),
      content: content,
      actions: buttons,
    );
  }

  Future<void> _showAcceptDialog() async {
    final displayName = _displayName;
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: 'Новый запрос проверки',
      message: '$displayName запрашивает проверку устройства',
      confirmLabel: 'Принять',
      cancelLabel: 'Отклонить',
      isDestructive: true,
    );
    if (!mounted) return;
    if (confirmed) {
      await widget.request.acceptVerification();
    } else {
      await widget.request.rejectVerification();
      _resolveAndPop(false);
    }
  }
}
