import 'package:convetchat/core/matrix/server_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

PushRule inviteRule() => PushRule(
  actions: const ['notify'],
  ruleId: ServerCapabilities.inviteRuleId,
  default$: true,
  enabled: true,
);

void main() {
  group('findPushRule', () {
    test('finds invite rule in override', () {
      final ruleset = PushRuleSet(override: [inviteRule()]);
      final found = ServerCapabilities.findPushRule(
        ruleset,
        PushRuleKind.override,
        ServerCapabilities.inviteRuleId,
      );
      expect(found?.ruleId, ServerCapabilities.inviteRuleId);
    });

    test('ignores rule id in wrong kind list', () {
      final ruleset = PushRuleSet(override: [inviteRule()]);
      final found = ServerCapabilities.findPushRule(
        ruleset,
        PushRuleKind.underride,
        ServerCapabilities.inviteRuleId,
      );
      expect(found, isNull);
    });

    test('returns null when ruleset or list is missing', () {
      expect(
        ServerCapabilities.findPushRule(
          null,
          PushRuleKind.override,
          ServerCapabilities.inviteRuleId,
        ),
        isNull,
      );
      expect(
        ServerCapabilities.findPushRule(
          PushRuleSet(),
          PushRuleKind.override,
          ServerCapabilities.inviteRuleId,
        ),
        isNull,
      );
    });
  });

  group('join rules', () {
    test('canJoin allows missing and public rules', () {
      expect(ServerCapabilities.canJoin(null), isTrue);
      expect(
        ServerCapabilities.canJoin(ServerCapabilities.publicJoinRule),
        isTrue,
      );
      expect(
        ServerCapabilities.canJoin(ServerCapabilities.knockJoinRule),
        isFalse,
      );
      expect(
        ServerCapabilities.canJoin(ServerCapabilities.inviteJoinRule),
        isFalse,
      );
    });

    test('canKnock allows knock and knock_restricted', () {
      expect(
        ServerCapabilities.canKnock(ServerCapabilities.knockJoinRule),
        isTrue,
      );
      expect(
        ServerCapabilities.canKnock(ServerCapabilities.knockRestrictedJoinRule),
        isTrue,
      );
      expect(
        ServerCapabilities.canKnock(ServerCapabilities.publicJoinRule),
        isFalse,
      );
      expect(ServerCapabilities.canKnock(null), isFalse);
    });
  });

  group('supportsRoomSummary', () {
    test('accepts spec v1.15 and newer', () {
      expect(ServerCapabilities.supportsRoomSummary(['v1.15'], null), isTrue);
      expect(
        ServerCapabilities.supportsRoomSummary(['v1.10', 'v1.16'], null),
        isTrue,
      );
      expect(ServerCapabilities.supportsRoomSummary(['v2.0'], null), isTrue);
    });

    test('rejects older specs and garbage', () {
      expect(ServerCapabilities.supportsRoomSummary(['v1.14'], null), isFalse);
      expect(ServerCapabilities.supportsRoomSummary(null, null), isFalse);
      expect(ServerCapabilities.supportsRoomSummary(['soon'], null), isFalse);
    });

    test('accepts unstable msc3266 key', () {
      expect(
        ServerCapabilities.supportsRoomSummary(
          ['v1.10'],
          {'org.matrix.msc3266': true},
        ),
        isTrue,
      );
      expect(
        ServerCapabilities.supportsRoomSummary(
          ['v1.10'],
          {'org.matrix.msc3266': false},
        ),
        isFalse,
      );
    });
  });
  group('supportsMsc3664', () {
    test('matches any known unstable key', () {
      expect(
        ServerCapabilities.supportsMsc3664({'org.matrix.msc3664': true}),
        isTrue,
      );
      expect(
        ServerCapabilities.supportsMsc3664({
          'im.nheko.msc3664.related_event_match': true,
        }),
        isTrue,
      );
    });

    test('rejects null, false and unknown keys', () {
      expect(ServerCapabilities.supportsMsc3664(null), isFalse);
      expect(
        ServerCapabilities.supportsMsc3664({'org.matrix.msc3664': false}),
        isFalse,
      );
      expect(
        ServerCapabilities.supportsMsc3664({'org.matrix.msc9999': true}),
        isFalse,
      );
    });
  });

  group('profile field keys', () {
    test('accepts namespaced keys', () {
      expect(
        ServerCapabilities.isValidProfileFieldKey('com.example.title'),
        isTrue,
      );
      expect(
        ServerCapabilities.isValidProfileFieldKey('com.convetchat.post_1'),
        isTrue,
      );
    });

    test('rejects reserved and malformed keys', () {
      expect(ServerCapabilities.isValidProfileFieldKey('m.tz'), isFalse);
      expect(ServerCapabilities.isValidProfileFieldKey('title'), isFalse);
      expect(ServerCapabilities.isValidProfileFieldKey(''), isFalse);
      expect(
        ServerCapabilities.isValidProfileFieldKey('com.example.Заголовок'),
        isFalse,
      );
      expect(
        ServerCapabilities.isValidProfileFieldKey('com.example.a b'),
        isFalse,
      );
    });
  });

  group('profile fields capability', () {
    Capabilities withFields(ProfileFieldsCapability? fields) =>
        Capabilities(mProfileFields: fields);

    test('supported only when capability enabled', () {
      expect(ServerCapabilities.profileFieldsSupported(null), isFalse);
      expect(
        ServerCapabilities.profileFieldsSupported(
          withFields(ProfileFieldsCapability(enabled: false)),
        ),
        isFalse,
      );
      expect(
        ServerCapabilities.profileFieldsSupported(
          withFields(ProfileFieldsCapability(enabled: true)),
        ),
        isTrue,
      );
    });

    test('canEditProfileField respects allow and deny lists', () {
      expect(
        ServerCapabilities.canEditProfileField(null, 'com.example.title'),
        isFalse,
      );
      expect(
        ServerCapabilities.canEditProfileField(
          withFields(ProfileFieldsCapability(enabled: false)),
          'com.example.title',
        ),
        isFalse,
      );
      expect(
        ServerCapabilities.canEditProfileField(
          withFields(
            ProfileFieldsCapability(
              enabled: true,
              allowed: ['com.example.title'],
            ),
          ),
          'com.example.title',
        ),
        isTrue,
      );
      expect(
        ServerCapabilities.canEditProfileField(
          withFields(
            ProfileFieldsCapability(
              enabled: true,
              allowed: ['com.example.title'],
            ),
          ),
          'com.example.other',
        ),
        isFalse,
      );
      expect(
        ServerCapabilities.canEditProfileField(
          withFields(
            ProfileFieldsCapability(
              enabled: true,
              disallowed: ['com.example.locked'],
            ),
          ),
          'com.example.locked',
        ),
        isFalse,
      );
      expect(
        ServerCapabilities.canEditProfileField(
          withFields(
            ProfileFieldsCapability(
              enabled: true,
              disallowed: ['com.example.locked'],
            ),
          ),
          'com.example.free',
        ),
        isTrue,
      );
    });
  });

  group('supportsBusyPresence', () {
    test('passes explicit server flags through', () {
      expect(
        ServerCapabilities.supportsBusyPresence({
          'org.matrix.msc3026.busy_presence': true,
        }),
        isTrue,
      );
      expect(
        ServerCapabilities.supportsBusyPresence({
          'org.matrix.msc3026.busy_presence': false,
        }),
        isFalse,
      );
    });

    test('returns null when unknown', () {
      expect(ServerCapabilities.supportsBusyPresence(null), isNull);
      expect(ServerCapabilities.supportsBusyPresence({}), isNull);
      expect(
        ServerCapabilities.supportsBusyPresence({'org.matrix.msc9999': true}),
        isNull,
      );
    });
  });
}
