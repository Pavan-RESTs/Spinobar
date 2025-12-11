import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/telemetry_model.dart';
import '../repositories/telemetry_repository.dart';
import '../services/notification_service.dart';
import 'threshold_provider.dart';

class TelemetryProvider extends ChangeNotifier {
  final ThresholdProvider thresholdProvider;

  TelemetryProvider(this.thresholdProvider);

  final TelemetryRepository _repo = TelemetryRepository();

  TelemetryModel? telemetry;

  // Timeout handling
  Timer? _timeoutTimer;
  static const Duration timeoutDuration = Duration(seconds: 3);

  // Over-wear timer
  Timer? _overWearTimer;
  int _overWearSeconds = 0;
  int get overWearSeconds => _overWearSeconds;

  // ---------------- INIT ----------------
  void init() {
    _repo.startListening((raw) {
      final wasConnected = telemetry != null;
      telemetry = TelemetryModel.fromRaw(raw);
      notifyListeners();

      // Reset timeout
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(timeoutDuration, () {
        telemetry = null;
        _stopOverWearTimer();
        notifyListeners();
      });

      // Start timer on first connection
      if (!wasConnected && telemetry != null) {
        _startOverWearTimer();
      }
    });
  }

  bool get isConnected => telemetry != null;

  // ---------------- OVER-WEAR TIMER ----------------
  void _startOverWearTimer() {
    _overWearTimer?.cancel();
    _overWearTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _overWearSeconds++;
      notifyListeners();
      _checkOverWearThreshold();
    });
  }

  void _stopOverWearTimer() {
    _overWearTimer?.cancel();
  }

  void resetOverWearTimer() {
    _overWearSeconds = 0;
    notifyListeners();
  }

  // ---------------- THRESHOLD CHECK ----------------
  void _checkOverWearThreshold() {
    if (!isConnected) return;

    if (thresholdProvider.overwear.isEmpty) return;

    int limitMinutes = thresholdProvider.overwear[0]['value'] ?? 0;
    int limitSeconds = limitMinutes * 60;

    if (limitMinutes == 0) return;

    if (_overWearSeconds >= limitSeconds) {
      NotificationService().addNotification(
        categoryId: "OVERWEAR",
        title: "Over-Wear Alert",
        message:
        "Device worn longer than allowed limit of $limitMinutes minutes.",
      );
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _overWearTimer?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
