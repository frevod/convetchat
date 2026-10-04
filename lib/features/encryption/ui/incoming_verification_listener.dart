import 'dart:async';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/encryption/domain/repositories/encryption_repository.dart';
import 'package:convetchat/features/encryption/ui/widgets/verification/verification_sheet.dart';
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
        '[e2ee:incoming] Нет контекста для диалога — запрос пропущен: '
        'tx=${request.transactionId} state=${request.state.name}',
      );
      return;
    }

    final verified = await VerificationSheet.show(context, request);
    if (!verified || !context.mounted) return;

    try {
      await getIt<EncryptionRepository>().requestMissingSessions();
    } catch (e, s) {
      getIt<Talker>().error('Не удалось запросить ключи', e, s);
    }
  });
}
