import 'package:equatable/equatable.dart';

class const SearchedMessage({
  required final String roomId,
  required final String eventId,
  required final String roomName,
  required final String senderName,
  required final String body,
  required final DateTime? timestamp,
}) extends Equatable {
  @override
  List<Object?> get props => [
    roomId,
    eventId,
    roomName,
    senderName,
    body,
    timestamp,
  ];
}
