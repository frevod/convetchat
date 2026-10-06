import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class const PendingMedia({
  required final String id,
  required final String filePath,
  required final String fileName,
  required final bool isVideo,
  required final Uint8List thumbBytes,
  final int? width,
  final int? height,
  final int? durationMs,
  final int? thumbWidth,
  final int? thumbHeight,
  final bool isFile = false,
  final int? size,
}) extends Equatable {
  @override
  List<Object?> get props => [
    id,
    filePath,
    fileName,
    isVideo,
    thumbBytes,
    width,
    height,
    durationMs,
    thumbWidth,
    thumbHeight,
    isFile,
    size,
  ];
}
