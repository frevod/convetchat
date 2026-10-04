import 'package:flutter/widgets.dart';
import 'package:matrix/encryption.dart';

class const SasCompare({
  super.key,
  required final KeyVerification request,
  required final List<dynamic>? sasEmoji,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (request.sasTypes.contains('emoji')) {
      return Column(
        mainAxisSize: .min,
        children: [
          Wrap(
            alignment: .center,
            children: request.sasEmojis
                .map((e) => SasEmoji(emoji: e, sasEmoji: sasEmoji))
                .toList(),
          ),
        ],
      );
    }
    final numbers = request.sasNumbers;
    return Column(
      mainAxisSize: .min,
      children: [
        Text(
          '${numbers.first}-${numbers[1]}-${numbers[2]}',
          textAlign: .center,
          style: const TextStyle(fontSize: 40),
        ),
      ],
    );
  }
}

class const SasEmoji({
  super.key,
  required final KeyVerificationEmoji emoji,
  required final List<dynamic>? sasEmoji,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        Text(emoji.emoji, style: const TextStyle(fontSize: 50)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(_localizedName()),
        ),
        const SizedBox(height: 10, width: 5),
      ],
    );
  }

  String _localizedName() {
    final sasEmoji = this.sasEmoji;
    if (sasEmoji == null) return emoji.name;
    final translations = Map<String, String?>.from(
      sasEmoji[emoji.number]['translated_descriptions'] as Map,
    );
    translations['en'] = emoji.name;
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      final wantParts = locale.toString().split('_');
      final wantLanguage = wantParts.removeAt(0);
      for (final haveLocale in translations.keys) {
        final haveParts = haveLocale.split('_');
        final haveLanguage = haveParts.removeAt(0);
        if (haveLanguage == wantLanguage &&
            (Set.from(haveParts)..removeAll(wantParts)).isEmpty &&
            (translations[haveLocale]?.isNotEmpty ?? false)) {
          return translations[haveLocale]!;
        }
      }
    }
    return emoji.name;
  }
}
