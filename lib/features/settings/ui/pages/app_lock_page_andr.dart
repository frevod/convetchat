import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/security/app_lock_service.dart';
import 'package:convetchat/features/settings/domain/repositories/security_repository.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Полноэкранная блокировка. Назад выйти нельзя — только верный PIN
/// или биометрия (если включена).
class const AppLockPageAndr({super.key}) extends StatefulWidget {
  @override
  State<AppLockPageAndr> createState() => _AppLockPageAndrState();
}

class _AppLockPageAndrState extends State<AppLockPageAndr> {
  String _pin = '';
  String? _error;
  bool _checking = false;
  bool _biometricsOn = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = getIt<SecurityRepository>();
    final on = await repo.isBiometricsEnabled();
    final available = await repo.canCheckBiometrics();
    if (!mounted) return;
    setState(() {
      _biometricsOn = on;
      _biometricsAvailable = available;
    });
    if (on && available) {
      await _tryBiometrics(auto: true);
    }
  }

  Future<void> _tryBiometrics({bool auto = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await getIt<SecurityRepository>().authenticate(
      reason: 'Разблокируйте ConvetChat',
    );
    if (!mounted) return;
    setState(() => _checking = false);
    if (ok) {
      getIt<AppLockService>().unlock();
    } else if (!auto) {
      setState(() => _error = 'Не удалось подтвердить биометрию');
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_checking || _pin.length >= 4) return;
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

  Future<void> _submit() async {
    setState(() => _checking = true);
    final ok = await getIt<SecurityRepository>().verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      getIt<AppLockService>().unlock();
      return;
    }
    setState(() {
      _checking = false;
      _pin = '';
      _error = 'Неверный код. Попробуйте снова';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // ignore: deprecated_member_use
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              children: [
                const Icon(Icons.lock_rounded, size: 48),
                const SizedBox(height: 16),
                Text('ConvetChat заблокирован', style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Введите код-пароль',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
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
                          color: i < _pin.length
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                        ),
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ],
                const Spacer(),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: [
                    for (final k in [
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                      '6',
                      '7',
                      '8',
                      '9',
                      '',
                      '0',
                      'back',
                    ])
                      if (k.isEmpty)
                        const SizedBox.shrink()
                      else if (k == 'back')
                        M3EButton.tonal(
                          onPressed: _pin.isEmpty
                              ? null
                              : () => setState(
                                  () => _pin = _pin.substring(
                                    0,
                                    _pin.length - 1,
                                  ),
                                ),
                          child: const Icon(Icons.backspace_outlined),
                        )
                      else
                        M3EButton.tonal(
                          onPressed: _checking ? null : () => _onDigit(k),
                          child: Text(
                            k,
                            style: textTheme.headlineMedium,
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_biometricsOn && _biometricsAvailable)
                  M3EButton.text(
                    onPressed: _checking ? null : () => _tryBiometrics(),
                    child: const Text('Войти по биометрии'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
