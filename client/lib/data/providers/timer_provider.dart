import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class OverWearTimerProvider extends ChangeNotifier {
  int elapsedMinutes = 0;
  Timer? _timer;
  int elapsedSeconds = 0;

  int? _thresholdMinutes;

  bool get isRunning => _timer != null;

  void loadThreshold(int minutes) {
    _thresholdMinutes = minutes;
    notifyListeners();
  }

  void start() {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds++;

      elapsedMinutes = elapsedSeconds ~/ 60;

      if (_thresholdMinutes != null && elapsedMinutes >= _thresholdMinutes!) {
        NotificationService().addNotification(
          categoryId: "OVERWEAR",
          title: "Over-wear Time Exceeded",
          message:
              "You have worn the device for more than $_thresholdMinutes minutes.",
        );
      }

      notifyListeners();
    });

    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void reset() {
    elapsedMinutes = 0;
    elapsedSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formattedTime {
    int m = elapsedSeconds ~/ 60;
    int s = elapsedSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
