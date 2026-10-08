import 'package:matrix/matrix.dart';
import 'package:talker_flutter/talker_flutter.dart';

void attachMatrixLogsToTalker(Talker talker) {
  Logs().onLog = (event) {
    final message = '[matrix] ${event.title}';
    switch (event.level) {
      case Level.wtf:
      case Level.error:
        talker.error(message, event.exception, event.stackTrace);
      case Level.warning:
        talker.warning(message, event.exception, event.stackTrace);
      case Level.info:
        talker.info(message, event.exception, event.stackTrace);
      case Level.debug:
        if (event.title.contains('Error parsing push rule') &&
            '${event.exception}'.contains('Unknown push condition')) {
          talker.verbose(message, event.exception, event.stackTrace);
        } else {
          talker.debug(message, event.exception, event.stackTrace);
        }
      case Level.verbose:
        talker.verbose(message, event.exception, event.stackTrace);
    }
  };
}
