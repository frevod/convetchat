import 'package:equatable/equatable.dart';

class const CryptoIdentityState({
  required final bool connected,
  required final bool crossSigningEnabled,
  required final bool initialized,
  required final bool keyBackupEnabled,
}) extends Equatable {
  @override
  List<Object?> get props => [
    connected,
    crossSigningEnabled,
    initialized,
    keyBackupEnabled,
  ];
}
