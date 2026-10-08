import 'package:convetchat/core/push/mention_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mentionsUser', () {
    test('matches user id in m.mentions', () {
      expect(
        mentionsUser(
          content: {
            'm.mentions': {
              'user_ids': ['@alice:server', '@bob:server'],
            },
          },
          plainBody: 'привет',
          userId: '@bob:server',
          displayName: 'Боб',
        ),
        isTrue,
      );
    });

    test('ignores other user ids', () {
      expect(
        mentionsUser(
          content: {
            'm.mentions': {
              'user_ids': ['@alice:server'],
            },
          },
          plainBody: 'привет всем',
          userId: '@bob:server',
          displayName: 'Боб',
        ),
        isFalse,
      );
    });

    test('matches room mention flag', () {
      expect(
        mentionsUser(
          content: {
            'm.mentions': {'room': true},
          },
          plainBody: 'всем привет',
          userId: '@bob:server',
          displayName: 'Боб',
        ),
        isTrue,
      );
    });

    test('matches display name in body', () {
      expect(
        mentionsUser(
          content: {},
          plainBody: 'Боб, глянь это',
          userId: '@bob:server',
          displayName: 'Боб',
        ),
        isTrue,
      );
    });

    test('returns false for plain message', () {
      expect(
        mentionsUser(
          content: {'body': 'просто текст'},
          plainBody: 'просто текст',
          userId: '@bob:server',
          displayName: 'Боб',
        ),
        isFalse,
      );
    });

    test('tolerates missing display name', () {
      expect(
        mentionsUser(
          content: {},
          plainBody: 'Боб, глянь это',
          userId: '@bob:server',
          displayName: null,
        ),
        isFalse,
      );
    });
  });
}
