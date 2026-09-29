import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const UserSearchResultCup({
  super.key,
  required final String displayName,
  required final String userId,
  required final String initial,
  required final VoidCallback onTap,
  required final bool showLoading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final avatarBg = CupertinoColors.systemGrey5.resolveFrom(context);
    final subColor = CupertinoColors.systemGrey.resolveFrom(context);
    return GestureDetector(
      behavior: .opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: .center,
              decoration: BoxDecoration(color: avatarBg, shape: .circle),
              child: Text(initial, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    userId,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: TextStyle(fontSize: 13, color: subColor),
                  ),
                ],
              ),
            ),
            if (showLoading) const AdaptiveLoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
