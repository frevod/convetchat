import 'package:characters/characters.dart';

final _emojiCore = RegExp(
  '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{1F1E6}-\u{1F1FF}\u{20E3}]',
  unicode: true,
);

final _emojiCluster = RegExp(
  '^(?:\u200D|\uFE0F|\u20E3|[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2300}-\u{23FF}\u{2190}-\u{21FF}\u{1F1E6}-\u{1F1FF}0-9#*])+\$',
  unicode: true,
);

int emojiOnlyCount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final clusters = trimmed.characters.toList();
  for (final cluster in clusters) {
    if (!_emojiCluster.hasMatch(cluster) ||
        !_emojiCore.hasMatch(cluster)) {
      return 0;
    }
  }
  return clusters.length;
}

double? bigEmojiFontSize(int count) {
  return switch (count) {
    1 => 80,
    2 => 64,
    3 => 52,
    4 => 44,
    5 => 36,
    _ => null,
  };
}
