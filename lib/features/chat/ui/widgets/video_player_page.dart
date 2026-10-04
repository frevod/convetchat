import 'dart:io';

import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/widgets/video_player_page_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/video_player_page_cup.dart';
import 'package:flutter/widgets.dart';

class const VideoPlayerPage({required final Future<File> file, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return VideoPlayerPageCup(file: file);
    }
    return VideoPlayerPageAndr(file: file);
  }
}
