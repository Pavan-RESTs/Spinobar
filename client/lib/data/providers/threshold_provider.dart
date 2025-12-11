import 'package:flutter/cupertino.dart';

import '../models/threshold_storage.dart';

class ThresholdProvider extends ChangeNotifier {
  List<Map<String, dynamic>> sensor = [];
  List<Map<String, dynamic>> temperature = [];
  List<Map<String, dynamic>> angle = [];
  List<Map<String, dynamic>> overwear = [];

  DateTime? sensorUpdatedAt;
  DateTime? temperatureUpdatedAt;
  DateTime? angleUpdatedAt;
  DateTime? overwearUpdatedAt;

  Future<void> load() async {
    sensor = await ThresholdStorage.loadSensorThresholds() ?? [];
    temperature = await ThresholdStorage.loadTemperatureThreshold() ?? [];
    angle = await ThresholdStorage.loadAngleThreshold() ?? [];
    overwear = await ThresholdStorage.loadOverWearTime() ?? [];

    sensorUpdatedAt = await ThresholdStorage.loadSensorUpdatedTime();
    temperatureUpdatedAt = await ThresholdStorage.loadTemperatureUpdatedTime();
    angleUpdatedAt = await ThresholdStorage.loadAngleUpdatedTime();
    overwearUpdatedAt = await ThresholdStorage.loadOverWearUpdatedTime();

    if (sensor.isEmpty) {
      sensor = [
        {'label': 'Shoulder Right (F1)', 'min': 30, 'max': 60, 'unit': 'N'},
        {'label': 'Shoulder Left  (F2)', 'min': 30, 'max': 60, 'unit': 'N'},
        {'label': 'Abdomen (F3)', 'min': 30, 'max': 60, 'unit': 'N'},
        {'label': 'Back (F4)', 'min': 30, 'max': 60, 'unit': 'N'},
      ];
      await ThresholdStorage.saveSensorThresholds(sensor);
    }

    if (temperature.isEmpty) {
      temperature = [
        {'label': 'Temperature', 'value': 80, 'unit': 'C'},
      ];
      await ThresholdStorage.saveTemperatureThreshold(temperature);
    }

    if (angle.isEmpty) {
      angle = [
        {'label': 'Tilt Angle', 'value': 60, 'unit': 'Deg'},
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

  Future<void> saveTemperature(List<Map<String, dynamic>> v) async {
    await ThresholdStorage.saveTemperatureThreshold(v);
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
