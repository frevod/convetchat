import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/settings/ui/cubit/presence_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/presence_state.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_state.dart';
import 'package:convetchat/features/settings/ui/pages/profile_page_andr.dart';
import 'package:convetchat/features/settings/ui/pages/profile_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ProfilePage({super.key, final SettingsCubit? cubit})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              AdaptiveSnackbar.show(
                context: context,
                message: state.errorMessage!,
                type: .error,
              );
              context.read<SettingsCubit>().clearError();
            }
          },
        ),
        BlocListener<PresenceCubit, PresenceState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              AdaptiveSnackbar.show(
                context: context,
                message: state.errorMessage!,
                type: .error,
              );
              context.read<PresenceCubit>().clearError();
            }
          },
        ),
      ],
      child: (getIt<PlatformStyle>().isCupertino)
          ? const ProfilePageCup()
          : const ProfilePageAndr(),
    );
    final c = cubit;
    if (c != null) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: c),
          BlocProvider(create: (_) => getIt<PresenceCubit>()),
        ],
        child: content,
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SettingsCubit>()),
        BlocProvider(create: (_) => getIt<PresenceCubit>()),
      ],
      child: content,
    );
  }
}
