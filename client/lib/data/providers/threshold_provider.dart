import 'package:flutter/cupertino.dart';

import '../models/threshold_storage.dart';

class ThresholdProvider extends ChangeNotifier {
  List<Map<String, dynamic>> sensor = [];
  List<Map<String, dynamic>> angle = [];
  List<Map<String, dynamic>> overwear = [];

  Future<void> load() async {
    sensor = await ThresholdStorage.loadSensorThresholds() ?? [];
    angle = await ThresholdStorage.loadAngleThreshold() ?? [];
    overwear = await ThresholdStorage.loadOverWearTime() ?? [];
    notifyListeners();
  }

  Future<void> saveSensors(List<Map<String, dynamic>> v) async {
    await ThresholdStorage.saveSensorThresholds(v);
    await load();
  }

  Future<void> saveAngle(List<Map<String, dynamic>> v) async {
    await ThresholdStorage.saveAngleThreshold(v);
    await load();
  }

  Future<void> saveTime(List<Map<String, dynamic>> v) async {
    await ThresholdStorage.saveOverWearTime(v);
    await load();
  }

  Future<void> reset() async {
    await ThresholdStorage.resetAllThresholds();
    await load();
  }
}
