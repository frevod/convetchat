import 'package:equatable/equatable.dart';

class const VoiceMessage({
  required final String eventId,
  required final String mxc,
  required final int durationMs,
  required final List<int> waveform,
  required final String mimeType,
}) extends Equatable {
  Duration get duration => Duration(milliseconds: durationMs);

  @override
  List<Object?> get props => [eventId, mxc, durationMs, waveform, mimeType];
}
