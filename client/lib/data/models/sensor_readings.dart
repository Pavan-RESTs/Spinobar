class SensorReading {
  final int? id;
  final DateTime timestamp;
  final double? f1;
  final double? f2;
  final double? f3;
  final double? f4;
  final double? rf;
  final double? ta;
  final double? temp;
  final bool hasAlert;
  final String alertingSensors;
  final String alertLevel;

  SensorReading({
    this.id,
    required this.timestamp,
    this.f1,
    this.f2,
    this.f3,
    this.f4,
    this.rf,
    this.ta,
    this.temp,
    required this.hasAlert,
    required this.alertingSensors,
    required this.alertLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'f1': f1,
      'f2': f2,
      'f3': f3,
      'f4': f4,
      'rf': rf,
      'ta': ta,
      'temp': temp,
      'hasAlert': hasAlert ? 1 : 0,
      'alertingSensors': alertingSensors,
      'alertLevel': alertLevel,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      f1: map['f1'],
      f2: map['f2'],
      f3: map['f3'],
      f4: map['f4'],
      rf: map['rf'],
      ta: map['ta'],
      temp: map['temp'],
      hasAlert: map['hasAlert'] == 1,
      alertingSensors: map['alertingSensors'] ?? '',
      alertLevel: map['alertLevel'] ?? 'safe',
    );
  }

  @override
  String toString() {
    return 'SensorReading{id: $id, timestamp: $timestamp, f1: $f1, f2: $f2, f3: $f3, f4: $f4, rf: $rf, ta: $ta, temp: $temp, hasAlert: $hasAlert, alertingSensors: $alertingSensors, alertLevel: $alertLevel}';
  }
}
