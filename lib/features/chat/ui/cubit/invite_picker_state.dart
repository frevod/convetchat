import 'package:convetchat/features/chats/domain/entities/searched_user.dart';
import 'package:equatable/equatable.dart';

class const InvitePickerState({
  final String query = '',
  final bool isSearching = false,
  final List<SearchedUser> candidates = const [],
  final List<SearchedUser> results = const [],
  final Set<String> selected = const {},
  final bool isSending = false,
  final int sentCount = 0,
  final List<String> failed = const [],
  final String? errorMessage,
}) extends Equatable {
  InvitePickerState copyWith({
    String Function()? query,
    bool Function()? isSearching,
    List<SearchedUser> Function()? candidates,
    List<SearchedUser> Function()? results,
    Set<String> Function()? selected,
    bool Function()? isSending,
    int Function()? sentCount,
    List<String> Function()? failed,
    String? Function()? errorMessage,
  }) {
    return InvitePickerState(
      query: query != null ? query() : this.query,
      isSearching: isSearching != null ? isSearching() : this.isSearching,
      candidates: candidates != null ? candidates() : this.candidates,
      results: results != null ? results() : this.results,
      selected: selected != null ? selected() : this.selected,
      isSending: isSending != null ? isSending() : this.isSending,
      sentCount: sentCount != null ? sentCount() : this.sentCount,
      failed: failed != null ? failed() : this.failed,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  List<SearchedUser> get visible {
    if (query.trim().isEmpty) return candidates;
    final known = {for (final user in candidates) user.userId};
    return [
      ...results.where((user) => !known.contains(user.userId)),
      ...candidates.where(
        (user) =>
            user.displayName.toLowerCase().contains(
              query.trim().toLowerCase(),
            ) ||
            user.userId.toLowerCase().contains(query.trim().toLowerCase()),
      ),
    ];
  }

  @override
  List<Object?> get props => [
    query,
    isSearching,
    candidates,
    results,
    selected,
    isSending,
    sentCount,
    failed,
    errorMessage,
  ];
}
