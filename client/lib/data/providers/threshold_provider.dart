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

    if (sensor.isEmpty) {
      sensor = [
        {'label': 'Shoulder Right (F1)', 'value': 0, 'unit': 'N'},
        {'label': 'Shoulder Left  (F2)', 'value': 0, 'unit': 'N'},
        {'label': 'Abdomen (F3)', 'value': 0, 'unit': 'N'},
        {'label': 'Back (F4)', 'value': 0, 'unit': 'N'},
        {'label': 'Temperature', 'value': 80, 'unit': '°C'},
      ];
      await ThresholdStorage.saveSensorThresholds(sensor);
    }

    if (angle.isEmpty) {
      angle = [
        {'label': 'Tilt Angle', 'value': 0, 'unit': 'Deg'},
      ];
      await ThresholdStorage.saveAngleThreshold(angle);
    }

    if (overwear.isEmpty) {
      overwear = [
        {'label': 'Time', 'value': 0, 'unit': 'min'},
      ];
      await ThresholdStorage.saveOverWearTime(overwear);
    }

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
