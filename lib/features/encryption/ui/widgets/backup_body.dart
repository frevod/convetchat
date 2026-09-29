import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/widgets/new_passphrase_view.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_bootstrap_view.dart';
import 'package:convetchat/features/encryption/ui/widgets/store_recovery_key_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const BackupBody({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (context.watch<EncryptionCubit>().state.step) {
      .loading || .done => const Center(child: AdaptiveLoadingIndicator()),
      .setupPassphrase => const NewPassphraseView(),
      .showRecoveryKey => const StoreRecoveryKeyView(),
      .restore => const RestoreBootstrapView(),
    };
  }
}
