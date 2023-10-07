import 'package:flutter/material.dart';

/// A ChangeNotifier class for managing the visibility of skip buttons in a video player.
///
/// This class provides methods to control the visibility of skip buttons (e.g., skip forward
/// and skip previous) in a video player. It uses the ChangeNotifier pattern to notify
/// listeners when the visibility state changes.
class SkipButtonNotifier extends ChangeNotifier{
  bool _showSkipToForward  = false;
  bool _showSkipToPrevious  = false;

  /// Indicates whether the "Skip Forward" button should be displayed.
  bool get showSkipToForward => _showSkipToForward;

  /// Sets the "Skip Forward" button to be visible and notifies listeners.
  ///
  /// The button will remain visible for 5 seconds before being hidden again.
  Future<void> addToSkipForward() async {
    _showSkipToForward = true;
    print('_showSkipToForward:$_showSkipToForward');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 5));
    notifyListeners();
  }

  /// Indicates whether the "Skip Previous" button should be displayed.
  bool get showSkipToPrevious => _showSkipToPrevious;

  /// Sets the "Skip Previous" button to be visible and notifies listeners.
  ///
  /// The button will remain visible for 5 seconds before being hidden again.
  Future<void> addToSkipPrevious() async {
    _showSkipToPrevious = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 5));
    notifyListeners();
  }

  /// Cancels the visibility of both "Skip Forward" and "Skip Previous" buttons.
  cancelSkip(){
    _showSkipToPrevious = false;
    _showSkipToForward = false;
    notifyListeners();
  }
}