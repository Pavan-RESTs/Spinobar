import 'dart:async';

import 'package:flutter/material.dart';

import '../models/telemetry_model.dart';
import '../repositories/telemetry_repository.dart';

class TelemetryProvider extends ChangeNotifier {
  final TelemetryRepository _repo = TelemetryRepository();
  TelemetryModel? telemetry;

  Timer? _timeoutTimer;
  static const Duration timeoutDuration = Duration(seconds: 3);

  void init() {
    _repo.startListening((raw) {
      telemetry = TelemetryModel.fromRaw(raw);
      notifyListeners();
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(timeoutDuration, () {
        telemetry = null;
        notifyListeners();
      });
    });
  }

  bool get isConnected => telemetry != null;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
