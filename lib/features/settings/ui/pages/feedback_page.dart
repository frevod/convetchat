import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/settings/ui/cubit/feedback_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/feedback_state.dart';
import 'package:convetchat/features/settings/ui/pages/feedback_page_andr.dart';
import 'package:convetchat/features/settings/ui/pages/feedback_page_cup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class const FeedbackPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeedbackCubit>(),
      child: BlocListener<FeedbackCubit, FeedbackState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AdaptiveSnackbar.show(
              context: context,
              message: state.errorMessage!,
              type: .error,
            );
            context.read<FeedbackCubit>().clearError();
          }
        },
        child: (getIt<PlatformStyle>().isCupertino)
            ? const FeedbackPageCup()
            : const FeedbackPageAndr(),
      ),
    );
  }
}
