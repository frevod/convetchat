import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/chat/ui/widgets/edit_notice_andr.dart';
import 'package:convetchat/features/chat/ui/widgets/edit_notice_cup.dart';
import 'package:flutter/widgets.dart';

class const EditNotice({
  super.key,
  required final VoidCallback onCancel,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return EditNoticeCup(onCancel: onCancel, onTap: onTap);
    }
    return EditNoticeAndr(onCancel: onCancel, onTap: onTap);
  }
}
