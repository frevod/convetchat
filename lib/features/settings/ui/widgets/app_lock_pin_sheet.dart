import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/settings/domain/repositories/security_repository.dart';
import 'package:convetchat/features/settings/ui/widgets/pin_shape_indicator.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

enum AppLockPinMode() {
  setup,
  verify,
  change,
}

class const AppLockPinSheet._() {
  static Future<bool> showSetup(BuildContext context) =>
      _show(context, mode: AppLockPinMode.setup);

  static Future<bool> showVerify(BuildContext context) =>
      _show(context, mode: AppLockPinMode.verify);

  static Future<bool> showChange(BuildContext context) =>
      _show(context, mode: AppLockPinMode.change);

  static Future<bool> _show(
    BuildContext context, {
    required AppLockPinMode mode,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0x00000000),
      elevation: 0,
      builder: (_) => _PinSheetBody(mode: mode),
    );
    return result ?? false;
  }
}

class const _PinSheetBody({required final AppLockPinMode mode})
    extends StatefulWidget {
  @override
  State<_PinSheetBody> createState() => _PinSheetBodyState();
}

class _PinSheetBodyState() extends State<_PinSheetBody> {
  String _pin = '';
  String? _firstEntry;
  bool _saving = false;
  bool _verifyingOld = false;
  String? _error;

  bool get _isCupertino => getIt<PlatformStyle>().isCupertino;

  String get _title => switch (widget.mode) {
    AppLockPinMode.setup =>
      _firstEntry == null ? 'Придумайте код-пароль' : 'Повторите код-пароль',
    AppLockPinMode.verify => 'Введите код-пароль',
    AppLockPinMode.change =>
      _verifyingOld
          ? 'Введите старый код'
          : _firstEntry == null
          ? 'Придумайте новый код'
          : 'Повторите новый код',
  };

  @override
  void initState() {
    super.initState();
    if (widget.mode == AppLockPinMode.change) _verifyingOld = true;
  }

  Future<void> _onDigit(String digit) async {
    if (_saving || _pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      await _submit();
    }
  }

  void _onBackspace() {
    if (_saving || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final repo = getIt<SecurityRepository>();
    final pin = _pin;
    if (widget.mode == AppLockPinMode.verify) {
      setState(() => _saving = true);
      final ok = await repo.verifyPin(pin);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _saving = false;
          _pin = '';
          _error = 'Неверный код. Попробуйте снова';
        });
      }
      return;
    }
    if (widget.mode == AppLockPinMode.change && _verifyingOld) {
      setState(() => _saving = true);
      final ok = await repo.verifyPin(pin);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _saving = false;
          _verifyingOld = false;
          _pin = '';
        });
      } else {
        setState(() {
          _saving = false;
          _pin = '';
          _error = 'Неверный код. Попробуйте снова';
        });
      }
      return;
    }
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = pin;
        _pin = '';
      });
      return;
    }
    if (_firstEntry != pin) {
      setState(() {
        _firstEntry = null;
        _pin = '';
        _error = 'Коды не совпадают. Начните заново';
      });
      return;
    }
    setState(() => _saving = true);
    try {
      await repo.setPin(pin);
      await repo.setAppLockEnabled(true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, s) {
      getIt<Talker>().error('[security] save PIN failed', e, s);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _firstEntry = null;
        _pin = '';
        _error = 'Не удалось сохранить код';
      });
      AdaptiveSnackbar.show(
        context: context,
        message: 'Не удалось сохранить код-пароль',
        type: .error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) return _buildCupertino(context);
    return _buildMaterial(context);
  }

  Widget _dots({required Color filled, required Color empty}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        for (var i = 0; i < 4; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length ? filled : empty,
            ),
          ),
      ],
    );
  }

  Widget _numpad({
    required Widget Function(String label, VoidCallback onTap) keyBuilder,
    required VoidCallback onBackspace,
  }) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        for (final k in keys)
          if (k.isEmpty)
            const SizedBox.shrink()
          else if (k == 'back')
            GestureDetector(
              onTap: onBackspace,
              child: const Center(
                child: Icon(CupertinoIcons.delete_left, size: 28),
              ),
            )
          else
            keyBuilder(k, () => _onDigit(k)),
      ],
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: .circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(_title, style: textTheme.headlineSmall),
          const SizedBox(height: 20),
          PinShapeIndicator(filled: _pin.length),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: 20),
          _numpad(
            onBackspace: _onBackspace,
            keyBuilder: (label, onTap) => M3EButton.tonal(
              onPressed: _saving ? null : onTap,
              child: Text(label, style: textTheme.headlineMedium),
            ),
          ),
          const SizedBox(height: 8),
          M3EButton.text(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertino(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.navTitleTextStyle;
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3.resolveFrom(context),
              borderRadius: .circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(_title, style: textStyle),
          const SizedBox(height: 20),
          _dots(
            filled: CupertinoColors.activeBlue.resolveFrom(context),
            empty: CupertinoColors.systemGrey4.resolveFrom(context),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ],
          const SizedBox(height: 20),
          _numpad(
            onBackspace: _onBackspace,
            keyBuilder: (label, onTap) => GestureDetector(
              onTap: _saving ? null : onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemFill.resolveFrom(
                    context,
                  ),
                  borderRadius: .circular(12),
                ),
                alignment: Alignment.center,
                child: Text(label, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}
