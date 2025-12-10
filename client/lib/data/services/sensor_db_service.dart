import '../models/sensor_readings.dart';
import '../repositories/sensor_repository.dart';

class SensorDataService {
  final SensorDatabase _db = SensorDatabase.instance;

  Future<void> saveSensorReading({
    required double? f1,
    required double? f2,
    required double? f3,
    required double? f4,
    required double? rf,
    required double? ta,
    required double? temp,
    required bool hasAlert,
    required List<String> alertingSensors,
    required String alertLevel,
  }) async {
    final reading = SensorReading(
      timestamp: DateTime.now(),
      f1: f1,
      f2: f2,
      f3: f3,
      f4: f4,
      rf: rf,
      ta: ta,
      temp: temp,
      hasAlert: hasAlert,
      alertingSensors: alertingSensors.join(','),
      alertLevel: alertLevel,
    );

    await _db.insertReading(reading);
  }

  Future<List<SensorReading>> getRecentReadings({int limit = 100}) async {
    return await _db.getReadingsPaginated(limit: limit, offset: 0);
  }

  Future<List<SensorReading>> getTodayReadings() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return await _db.getReadingsByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final totalReadings = await _db.getReadingsCount();
    final alertCount = await _db.getAlertCount();
    final latestReading = await _db.getLatestReading();

    return {
      'totalReadings': totalReadings,
      'alertCount': alertCount,
      'safeCount': totalReadings - alertCount,
      'latestReading': latestReading,
    };
  }

  Future<void> cleanupOldData({int daysToKeep = 30}) async {
    await _db.deleteOldReadings(daysToKeep);
  }

  Future<List<Map<String, dynamic>>> exportAllData() async {
    return await _db.exportData();
  }

  Future<List<Map<String, dynamic>>> exportDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = SensorDatabase.instance;
    final database = await db.database;

    return await database.query(
      'sensor_readings',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<SensorReading>> getReadingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _db.getReadingsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
