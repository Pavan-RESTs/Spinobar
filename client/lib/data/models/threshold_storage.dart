import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ThresholdStorage {
  static const _sensorKey = "sensor_thresholds";
  static const _sensorUpdatedKey = "sensor_updated_at";

  static const _temperatureKey = "temperature_threshold";
  static const _temperatureUpdatedKey = "temperature_updated_at";

  static const _angleKey = "angle_threshold";
  static const _angleUpdatedKey = "angle_updated_at";

  static const _timeKey = "overwear_time";
  static const _timeUpdatedKey = "overwear_time_updated_at";

  static Future<void> saveSensorThresholds(
    List<Map<String, dynamic>> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sensorKey, jsonEncode(values));
    await prefs.setString(_sensorUpdatedKey, DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> loadSensorThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_sensorKey);
    if (data == null) return null;

    return (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<DateTime?> loadSensorUpdatedTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? ts = prefs.getString(_sensorUpdatedKey);
    return ts != null ? DateTime.parse(ts) : null;
  }

  static Future<void> saveTemperatureThreshold(
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_temperatureKey, jsonEncode(value));
    await prefs.setString(
      _temperatureUpdatedKey,
      DateTime.now().toIso8601String(),
    );
  }

  static Future<List<Map<String, dynamic>>?> loadTemperatureThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_temperatureKey);
    if (data == null) return null;

    return (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<DateTime?> loadTemperatureUpdatedTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? ts = prefs.getString(_temperatureUpdatedKey);
    return ts != null ? DateTime.parse(ts) : null;
  }

  static Future<void> saveAngleThreshold(
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_angleKey, jsonEncode(value));
    await prefs.setString(_angleUpdatedKey, DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> loadAngleThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_angleKey);
    if (data == null) return null;

    return (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<DateTime?> loadAngleUpdatedTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? ts = prefs.getString(_angleUpdatedKey);
    return ts != null ? DateTime.parse(ts) : null;
  }

  static Future<void> saveOverWearTime(List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, jsonEncode(value));
    await prefs.setString(_timeUpdatedKey, DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> loadOverWearTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_timeKey);
    if (data == null) return null;

    return (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<DateTime?> loadOverWearUpdatedTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? ts = prefs.getString(_timeUpdatedKey);
    return ts != null ? DateTime.parse(ts) : null;
  }

  static Future<void> resetAllThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    await prefs.setString(
      _sensorKey,
      jsonEncode([
        {'label': 'Shoulder Right (F1)', 'min': 0, 'max': 100, 'unit': 'N'},
        {'label': 'Shoulder Left  (F2)', 'min': 0, 'max': 100, 'unit': 'N'},
        {'label': 'Abdomen (F3)', 'min': 0, 'max': 100, 'unit': 'N'},
        {'label': 'Back (F4)', 'min': 0, 'max': 100, 'unit': 'N'},
      ]),
    );
    await prefs.setString(_sensorUpdatedKey, now);

    await prefs.setString(
      _temperatureKey,
      jsonEncode([
        {'label': 'Temperature', 'value': 80, 'unit': 'C'},
      ]),
    );
    await prefs.setString(_temperatureUpdatedKey, now);

    await prefs.setString(
      _angleKey,
      jsonEncode([
        {'label': 'Tilt Angle', 'value': 0, 'unit': 'Deg'},
      ]),
    );
    await prefs.setString(_angleUpdatedKey, now);

    await prefs.setString(
      _timeKey,
      jsonEncode([
        {'label': 'Time', 'value': 0, 'unit': 'min'},
      ]),
    );
    await prefs.setString(_timeUpdatedKey, now);
  }
}
