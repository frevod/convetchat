import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chats/ui/widgets/encryption_banner_andr.dart';
import 'package:convetchat/features/chats/ui/widgets/encryption_banner_cup.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

enum EncryptionBannerType() {
  setup,

  verify,
}

class const EncryptionBanner({super.key}) extends StatefulWidget {
  @override
  State<EncryptionBanner> createState() => _EncryptionBannerState();
}

class _EncryptionBannerState() extends State<EncryptionBanner> {
  EncryptionBannerType? _type;
  StreamSubscription<SyncStatusUpdate>? _syncSub;
  DateTime _lastCheck = DateTime.fromMillisecondsSinceEpoch(0);
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
    _syncSub = getIt<Client>().onSyncStatus.stream.listen((_) {
      if (DateTime.now().difference(_lastCheck) < const Duration(seconds: 15)) {
        return;
      }
      _check();
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    _lastCheck = DateTime.now();
    try {
      final repo = getIt<EncryptionRepository>();
      final identity = await repo.getIdentityState();
      if (!mounted) return;
      final EncryptionBannerType? type;
      if (!identity.initialized) {
        type = EncryptionBannerType.setup;
      } else if (!identity.connected) {
        type = EncryptionBannerType.verify;
      } else {
        type = null;
      }
      if (type != _type) setState(() => _type = type);
    } catch (e, s) {
      getIt<Talker>().error('[chats] check encryption state failed', e, s);
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    if (type == null) return const SizedBox.shrink();
    if (getIt<PlatformStyle>().isCupertino) {
      return EncryptionBannerCup(type: type);
    }
    return EncryptionBannerAndr(type: type);
  }
}
