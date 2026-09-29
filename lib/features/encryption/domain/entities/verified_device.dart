import 'package:equatable/equatable.dart';

class const VerifiedDevice({
  required final String displayName,
  required final DateTime lastActive,
}) extends Equatable {
  @override
  List<Object?> get props => [displayName, lastActive];
}
