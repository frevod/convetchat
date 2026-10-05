import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:convetchat/features/settings/ui/pages/experimental_page_andr.dart';
import 'package:convetchat/features/settings/ui/pages/experimental_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const ExperimentalPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsCubit>(),
      child: (getIt<PlatformStyle>().isCupertino)
          ? const ExperimentalPageCup()
          : const ExperimentalPageAndr(),
    );
  }
}
