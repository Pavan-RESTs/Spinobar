import 'dart:async';

import 'package:flutter/material.dart';

import '../models/telemetry_model.dart';
import '../services/udp_telemetry_service.dart';

class TelemetryProvider extends ChangeNotifier {
  final UdpTelemetryService _udp = UdpTelemetryService();
  TelemetryModel? telemetry;

  Timer? _timeoutTimer;
  static const Duration timeoutDuration = Duration(seconds: 10);

  bool _isListening = false;

  bool get isConnected => telemetry != null && _isListening;
  bool get isListening => _isListening;

  Future<void> startUdpListening() async {
    if (_isListening) return;

    _isListening = true;

    await _udp.listen((raw) {
      _handleIncoming(raw);
    });

    notifyListeners();
  }

  void stopUdpListening() {
    if (!_isListening) return;

    _isListening = false;
    _udp.dispose();

    telemetry = null;
    notifyListeners();
  }

  void _handleIncoming(String raw) {
    telemetry = TelemetryModel.fromRaw(raw);
    notifyListeners();

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(timeoutDuration, () {
      telemetry = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    stopUdpListening();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
