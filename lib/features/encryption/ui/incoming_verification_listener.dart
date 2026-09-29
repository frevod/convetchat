import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/widgets/key_verification_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

StreamSubscription<KeyVerification>? _subscription;

void initIncomingVerificationListener() {
  _subscription?.cancel();
  final client = getIt<Client>();
  _subscription = client.onKeyVerificationRequest.stream.listen((
    request,
  ) async {
    final context =
        getIt<GoRouter>().routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      getIt<Talker>().warning(
        'Нет контекста для диалога проверки — запрос пропущен',
      );
      return;
    }

    final verified = await KeyVerificationDialog.show(context, request);
    if (!verified || !context.mounted) return;

    try {
      await getIt<EncryptionRepository>().requestMissingSessions();
    } catch (e, s) {
      getIt<Talker>().error('Не удалось запросить ключи', e, s);
    }
  });
}
