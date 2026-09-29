import 'package:material_ui/material_ui.dart';

class const MessageDeletedLabel({
  super.key,
  required final Color color,
  final String text = 'Сообщение удалено',
  final IconData icon = Icons.delete_outline,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: .ellipsis,
            style: TextStyle(fontSize: 15, fontStyle: .italic, color: color),
          ),
        ),
      ],
    );
  }
}
