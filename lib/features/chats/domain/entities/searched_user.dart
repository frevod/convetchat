import 'package:equatable/equatable.dart';

class const SearchedUser({
  required final String userId,
  required final String displayName,
}) extends Equatable {
  @override
  List<Object?> get props => [userId, displayName];
}
