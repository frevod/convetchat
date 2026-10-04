import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_cubit.dart';
import 'package:convetchat/features/encryption/ui/cubit/encryption_state.dart';
import 'package:convetchat/features/encryption/ui/pages/backup_page_andr.dart';
import 'package:convetchat/features/encryption/ui/pages/backup_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const BackupPage({super.key, required final bool reset})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EncryptionCubit>(param1: reset),
      child: BlocListener<EncryptionCubit, EncryptionState>(
        listener: (context, state) {
          if (state.step == .done) {
            context.read<EncryptionCubit>().finishAndGoChats();
          } else if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<EncryptionCubit>().clearError();
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const BackupPageCup()
            : const BackupPageAndr(),
      ),
    );
  }
}
