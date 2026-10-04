import 'package:convetchat/features/chats/domain/entities/public_room.dart';
import 'package:convetchat/features/chats/domain/entities/search_filter.dart';
import 'package:convetchat/features/chats/domain/entities/searched_message.dart';
import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:equatable/equatable.dart';

class const ChatSearchState({
  final String query = '',
  final SearchFilter filter = SearchFilter.chats,
  final bool isSearching = false,
  final List<SearchedMessage> messageHits = const [],
  final List<SearchedUser> userHits = const [],
  final List<PublicRoom> publicHits = const [],
  final String? joiningRoomId,
  final bool isCreatingChat = false,
  final String? errorMessage,
}) extends Equatable {
  ChatSearchState copyWith({
    String Function()? query,
    SearchFilter Function()? filter,
    bool Function()? isSearching,
    List<SearchedMessage> Function()? messageHits,
    List<SearchedUser> Function()? userHits,
    List<PublicRoom> Function()? publicHits,
    String? Function()? joiningRoomId,
    bool Function()? isCreatingChat,
    String? Function()? errorMessage,
  }) {
    return ChatSearchState(
      query: query != null ? query() : this.query,
      filter: filter != null ? filter() : this.filter,
      isSearching: isSearching != null ? isSearching() : this.isSearching,
      messageHits: messageHits != null ? messageHits() : this.messageHits,
      userHits: userHits != null ? userHits() : this.userHits,
      publicHits: publicHits != null ? publicHits() : this.publicHits,
      joiningRoomId: joiningRoomId != null
          ? joiningRoomId()
          : this.joiningRoomId,
      isCreatingChat: isCreatingChat != null
          ? isCreatingChat()
          : this.isCreatingChat,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    query,
    filter,
    isSearching,
    messageHits,
    userHits,
    publicHits,
    joiningRoomId,
    isCreatingChat,
    errorMessage,
  ];
}
