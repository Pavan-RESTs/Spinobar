import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sensor_readings.dart';

class SensorDatabase {
  static final SensorDatabase instance = SensorDatabase._init();
  static Database? _database;

  SensorDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sensor_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE sensor_readings (
        id $idType,
        timestamp $integerType,
        f1 $realType,
        f2 $realType,
        f3 $realType,
        f4 $realType,
        rf $realType,
        ta $realType,
        temp $realType,              -- ✅ TEMP ADDED HERE
        hasAlert $integerType,
        alertingSensors $textType,
        alertLevel $textType
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON sensor_readings(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_hasAlert ON sensor_readings(hasAlert, timestamp DESC)
    ''');
  }

  Future<int> insertReading(SensorReading reading) async {
    final db = await instance.database;
    return await db.insert('sensor_readings', reading.toMap());
  }

  Future<List<SensorReading>> getAllReadings() async {
    final db = await instance.database;
    const orderBy = 'timestamp DESC';
    final result = await db.query('sensor_readings', orderBy: orderBy);
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  Future<List<SensorReading>> getReadingsPaginated({
    required int limit,
    required int offset,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'sensor_readings',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  Future<List<SensorReading>> getReadingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'sensor_readings',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  Future<List<SensorReading>> getAlertReadings() async {
    final db = await instance.database;
    final result = await db.query(
      'sensor_readings',
      where: 'hasAlert = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  Future<List<SensorReading>> getReadingsByAlertLevel(String alertLevel) async {
    final db = await instance.database;
    final result = await db.query(
      'sensor_readings',
      where: 'alertLevel = ?',
      whereArgs: [alertLevel],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  Future<SensorReading?> getLatestReading() async {
    final db = await instance.database;
    final result = await db.query(
      'sensor_readings',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return SensorReading.fromMap(result.first);
    }
    return null;
  }

  Future<int> getReadingsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM sensor_readings');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAlertCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM sensor_readings WHERE hasAlert = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteOldReadings(int daysToKeep) async {
    final db = await instance.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return await db.delete(
      'sensor_readings',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  Future<int> deleteAllReadings() async {
    final db = await instance.database;
    return await db.delete('sensor_readings');
  }

  Future<int> deleteReading(int id) async {
    final db = await instance.database;
    return await db.delete('sensor_readings', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> exportData() async {
    final db = await instance.database;
    return await db.query('sensor_readings', orderBy: 'timestamp DESC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
