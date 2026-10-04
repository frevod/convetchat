import 'package:convetchat/features/chats/domain/entities/connection_status.dart';
import 'package:flutter/widgets.dart';

class const ChatsAppBarTitle({
  super.key,
  required final ConnectionStatus connectionStatus,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final disconnected = connectionStatus == ConnectionStatus.disconnected;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        const Text('Чаты'),
        if (disconnected) ...[
          const SizedBox(height: 2),
          const Text(
            'Нет соединения с сервером',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11),
          ),
        ],
      ],
    );
  }
}
