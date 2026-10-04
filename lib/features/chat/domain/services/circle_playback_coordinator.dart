import 'package:flutter/foundation.dart';

class CirclePlaybackCoordinator() extends ChangeNotifier {
  String? _activeId;

  String? get activeId => _activeId;

  void playStarted(String eventId) {
    if (_activeId == eventId) return;
    _activeId = eventId;
    notifyListeners();
  }

  void playStopped(String eventId) {
    if (_activeId != eventId) return;
    _activeId = null;
    notifyListeners();
  }
}
