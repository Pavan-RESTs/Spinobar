import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ThresholdStorage {
  static const _sensorKey = "sensor_thresholds";
  static const _angleKey = "angle_threshold";
  static const _timeKey = "overwear_time";

  static Future<void> saveSensorThresholds(
    List<Map<String, dynamic>> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_sensorKey, jsonEncode(values));
  }

  static Future<List<Map<String, dynamic>>?> loadSensorThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_sensorKey);
    if (data == null) return null;

    final list = (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return list;
  }

  static Future<void> saveAngleThreshold(
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_angleKey, jsonEncode(value));
  }

  static Future<List<Map<String, dynamic>>?> loadAngleThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_angleKey);
    if (data == null) return null;

    return (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> saveOverWearTime(List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, jsonEncode(value));
  }

  static Future<List<Map<String, dynamic>>?> loadOverWearTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_timeKey);
    if (data == null) return null;

    return (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> resetAllThresholds() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _sensorKey,
      jsonEncode([
        {'label': 'Shoulder Right (F1)', 'value': 0, 'unit': 'N'},
        {'label': 'Shoulder Left  (F2)', 'value': 0, 'unit': 'N'},
        {'label': 'Abdomen (F3)', 'value': 0, 'unit': 'N'},
        {'label': 'Back (F4)', 'value': 0, 'unit': 'N'},
        {'label': 'Temperature', 'value': 80, 'unit': '°C'},
      ]),
    );

    await prefs.setString(
      _angleKey,
      jsonEncode([
        {'label': 'Tilt Angle', 'value': 0, 'unit': 'Deg'},
      ]),
    );

    await prefs.setString(
      _timeKey,
      jsonEncode([
        {'label': 'Time', 'value': 0, 'unit': 'min'},
      ]),
    );
  }
}
