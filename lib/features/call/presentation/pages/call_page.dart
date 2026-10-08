import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/call/presentation/cubits/call_cubit.dart';
import 'package:convetchat/features/call/presentation/pages/call_page_andr.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'call_page_cup.dart';

class const CallPage({
  super.key,
  required final String roomId,
  required final String roomName,
  required final bool answer,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CallCubit>(param1: roomId),
      child: (getIt<PlatformStyle>().isCupertino)
          ? const CallPageCup()
          : CallPageAndr(roomName: roomName, answer: answer),
    );
  }
}
