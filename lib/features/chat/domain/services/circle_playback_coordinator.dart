import 'package:flutter/foundation.dart';

class CirclePlaybackCoordinator() extends ChangeNotifier {
  String? _activeId;

  String? get activeId => _activeId;

  String? _autoplayId;

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

  void requestAutoplay(String eventId) {
    _autoplayId = eventId;
    notifyListeners();
  }

  bool consumeAutoplay(String eventId) {
    if (_autoplayId != eventId) return false;
    _autoplayId = null;
    return true;
  }
}
