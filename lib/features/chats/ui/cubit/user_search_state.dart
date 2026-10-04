import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:equatable/equatable.dart';

class const UserSearchState({
  final List<SearchedUser> results = const [],
  final bool isSearching = false,
  final bool isCreating = false,
  final String? errorMessage,
}) extends Equatable {
  UserSearchState copyWith({
    List<SearchedUser> Function()? results,
    bool Function()? isSearching,
    bool Function()? isCreating,
    String? Function()? errorMessage,
  }) {
    return UserSearchState(
      results: results != null ? results() : this.results,
      isSearching: isSearching != null ? isSearching() : this.isSearching,
      isCreating: isCreating != null ? isCreating() : this.isCreating,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [results, isSearching, isCreating, errorMessage];
}
