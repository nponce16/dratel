import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  // -- MEME MODE logic --
  int _secretTapCount = 0;
  final bool _isMemeMode = false;

  // Getters for the view to read
  bool get isMemeMode => _isMemeMode;

  void handleSecretTap() {
    if (_isMemeMode) return;

    _secretTapCount++;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0; // Reset
      notifyListeners(); 
    }

    // TODO: easter egg logic :)
  }
}