import 'package:convetchat/features/chats/domain/entities/join_rule.dart';
import 'package:matrix/matrix.dart';

class ServerCapabilities._() {
  static const msc3664Keys = {
    'org.matrix.msc3664',
    'im.nheko.msc3664.related_event_match',
  };

  static const msc3266Keys = {'org.matrix.msc3266'};

  static const publicJoinRule = JoinRule.public;
  static const inviteJoinRule = JoinRule.invite;
  static const knockJoinRule = JoinRule.knock;
  static const knockRestrictedJoinRule = JoinRule.knockRestricted;

  static const inviteRuleId = '.m.rule.invite_for_me';

  static bool canJoin(String? joinRule) =>
      joinRule == null || joinRule == publicJoinRule;

  static bool canKnock(String? joinRule) =>
      joinRule == knockJoinRule || joinRule == knockRestrictedJoinRule;

  static GetVersionsResponse? _versionsResponse;
  static DateTime? _fetchedAt;
  static const _cacheTtl = Duration(hours: 12);

  static Future<GetVersionsResponse?> _versions(Client client) async {
    final cached = _versionsResponse;
    if (cached != null &&
        _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < _cacheTtl) {
      return cached;
    }
    try {
      final versions = await client.getVersions();
      _versionsResponse = versions;
      _fetchedAt = DateTime.now();
      return versions;
    } catch (_) {
      return cached;
    }
  }

  static Future<void> refresh(Client client) async {
    try {
      final versions = await client.getVersions(cacheLifetime: Duration.zero);
      _versionsResponse = versions;
      _fetchedAt = DateTime.now();
    } catch (_) {}
  }

  static Future<Map<String, bool>?> unstableFeatures(
    Client client, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) await refresh(client);
    return (await _versions(client))?.unstableFeatures;
  }

  static Future<List<String>?> specVersions(Client client) async {
    return (await _versions(client))?.versions;
  }

  static Future<bool> roomSummarySupported(Client client) async {
    final versions = await _versions(client);
    return supportsRoomSummary(versions?.versions, versions?.unstableFeatures);
  }

  static bool supportsRoomSummary(
    List<String>? versions,
    Map<String, bool>? features,
  ) {
    if (features != null && msc3266Keys.any((key) => features[key] == true)) {
      return true;
    }
    if (versions == null) return false;
    for (final version in versions) {
      final parts = version.split('.');
      if (parts.length != 2 || !parts[0].startsWith('v')) continue;
      final major = int.tryParse(parts[0].substring(1));
      final minor = int.tryParse(parts[1]);
      if (major == null || minor == null) continue;
      if (major > 1 || (major == 1 && minor >= 15)) return true;
    }
    return false;
  }

  static const mentionsOnlyRuleId = '.org.matrix.msc4028.encrypted_event';

  static bool supportsMentionsOnly(PushRuleSet? ruleset) {
    if (ruleset == null) return false;
    return (ruleset.override ?? const <PushRule>[]).any(
      (rule) => rule.ruleId == mentionsOnlyRuleId,
    );
  }

  static const msc3026Keys = {'org.matrix.msc3026.busy_presence'};

  static bool? supportsBusyPresence(Map<String, bool>? features) {
    if (features == null) return null;
    for (final key in msc3026Keys) {
      final value = features[key];
      if (value != null) return value;
    }
    return null;
  }

  static bool profileFieldsSupported(Capabilities? capabilities) {
    return capabilities?.mProfileFields?.enabled ?? false;
  }

  static bool canEditProfileField(Capabilities? capabilities, String field) {
    final cap = capabilities?.mProfileFields;
    if (cap == null || !cap.enabled) return false;
    if (cap.allowed != null) return cap.allowed!.contains(field);
    if (cap.disallowed != null) return !cap.disallowed!.contains(field);
    return true;
  }

  static bool isValidProfileFieldKey(String key) {
    if (key.startsWith('m.')) return false;
    if (!key.contains('.')) return false;
    return RegExp(r'^[a-z0-9_.-]+$').hasMatch(key);
  }

  static bool supportsMsc3664(Map<String, bool>? features) {
    if (features == null) return false;
    return msc3664Keys.any((key) => features[key] == true);
  }

  static PushRule? findPushRule(
    PushRuleSet? ruleset,
    PushRuleKind kind,
    String ruleId,
  ) {
    if (ruleset == null) return null;
    final List<PushRule>? list = switch (kind) {
      PushRuleKind.content => ruleset.content,
      PushRuleKind.override => ruleset.override,
      PushRuleKind.room => ruleset.room,
      PushRuleKind.sender => ruleset.sender,
      PushRuleKind.underride => ruleset.underride,
    };
    if (list == null) return null;
    for (final rule in list) {
      if (rule.ruleId == ruleId) return rule;
    }
    return null;
  }
}
