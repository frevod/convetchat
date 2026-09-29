import 'package:equatable/equatable.dart';

enum MediaKind() {
  image,
  video,
}

class const MediaAttachment({
  required final MediaKind kind,
  final int? width,
  final int? height,
  final int? durationMs,
  final String? mimeType,
  final int? size,
  final String? fileName,

  final String? caption,
}) extends Equatable {
  double get aspect {
    if (width == null || height == null || width! <= 0 || height! <= 0) {
      return 1;
    }
    return (width! / height!).clamp(0.5, 2.0);
  }

  @override
  List<Object?> get props => [
    kind,
    width,
    height,
    durationMs,
    mimeType,
    size,
    fileName,
    caption,
  ];
}
