import '../entities/call_support.dart';

final class const CallException(
  final CallSupportFailure failure, [
  final Object? cause,
]) implements Exception {
  @override
  String toString() => 'CallException($failure, cause=$cause)';
}
