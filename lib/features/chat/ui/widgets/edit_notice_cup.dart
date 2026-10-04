import 'package:cupertino_ui/cupertino_ui.dart';

class const EditNoticeCup({
  super.key,
  required final VoidCallback onCancel,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    final grey = CupertinoColors.systemGrey.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: .opaque,
                onTap: onTap,
                child: Row(
                  children: [
                    Icon(CupertinoIcons.pencil, size: 16, color: blue),
                    const SizedBox(width: 8),
                    Text(
                      'Редактирование',
                      style: TextStyle(fontWeight: .w600, color: blue),
                    ),
                  ],
                ),
              ),
            ),
            CupertinoButton(
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              child: Icon(CupertinoIcons.xmark, size: 18, color: grey),
            ),
          ],
        ),
      ),
    );
  }
}
