import 'package:convetchat/core/firebase/crashlytics_talker_observer.dart';
import 'package:convetchat/core/logging/talker_file_sink.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

Talker createTalker() {
  return TalkerFlutter.init(
    logger: TalkerLogger(
      output: (message) {
        debugPrint(message);
        TalkerFileSink.write(message);
      },
    ),
    observer: CrashlyticsTalkerObserver(),
    settings: TalkerSettings(
      enabled: true,
      useHistory: true,
      maxHistoryItems: 100,
      useConsoleLogs: true,
    ),
  );
}
