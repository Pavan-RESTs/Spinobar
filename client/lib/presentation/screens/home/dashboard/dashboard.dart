// lib/presentation/screens/home/dashboard/dashboard.dart
import 'package:client/core/theme/colors.dart';
import 'package:client/core/utils/navigation_helper.dart';
import 'package:client/core/utils/screen_dimension.dart';
import 'package:client/core/widgets/multi_line_chart.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/battery_card.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/free_view_canva.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/notification.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/sensor_card.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/stats_card.dart';
import 'package:client/presentation/screens/home/settings/data_logs.dart';
import 'package:client/presentation/screens/home/settings/sensor_threshold.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/image_strings.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../data/providers/telemetry_provider.dart';
import '../../../../data/providers/threshold_provider.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../data/services/sensor_db_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final SensorDataService _dataService = SensorDataService();
  final NotificationService _notif = NotificationService();

  DateTime? _lastNotificationTime;
  DateTime? _lastSaveTime;

  @override
  void initState() {
    super.initState();
    _startAutoSave();
  }

  bool _shouldNotify() {
    if (_lastNotificationTime == null) return true;
    return DateTime.now().difference(_lastNotificationTime!).inSeconds >= 10;
  }

  void _startAutoSave() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _saveSensorDataIfNeeded();
        _startAutoSave();
      }
    });
  }

  Future<void> _saveSensorDataIfNeeded() async {
    final telemetry = context.read<TelemetryProvider>().telemetry;
    if (telemetry == null) return;

    final now = DateTime.now();
    if (_lastSaveTime != null && now.difference(_lastSaveTime!).inSeconds < 5) {
      return;
    }

    final thresholds = context.read<ThresholdProvider>();

    // Ensure thresholds loaded
    if (thresholds.sensor.length < 4 || thresholds.angle.isEmpty) {
      debugPrint("⛔ Thresholds not loaded yet — skipping save");
      return;
    }

    // thresholds as strings
    String thF1 = thresholds.sensor[0]['value'].toString();
    String thF2 = thresholds.sensor[1]['value'].toString();
    String thF3 = thresholds.sensor[2]['value'].toString();
    String thF4 = thresholds.sensor[3]['value'].toString();
    String thTA = thresholds.angle[0]['value'].toString();

    final List<String> alertingSensors = [];

    // Helper to create/update notifications (one per id).
    void notifyWithId({
      required String id,
      required String title,
      required String message,
      required NotificationType type,
      NotificationPriority priority = NotificationPriority.normal,
    }) {
      final existing = _notif.getById(id);

      // If unread → update severity but DON'T block other alerts from sending
      if (existing != null && !existing.isRead) {
        _notif.upsertNotification(
          id: id,
          title: title,
          message: message,
          type: type,
          priority: priority,
        );
        return;
      }

      // Per-alert rate limiting (not global)
      if (_lastNotificationTime != null &&
          DateTime.now().difference(_lastNotificationTime!).inSeconds < 10) {
        // Only block same notification type for 10 seconds
        return;
      }

      // Add new notification
      _notif.addNotificationWithId(
        id: id,
        title: title,
        message: message,
        type: type,
        priority: priority,
      );

      _lastNotificationTime = DateTime.now();
    }

    // Sensor alerts

    if (_isAlert(telemetry.f1, thF1)) {
      alertingSensors.add("F1-Right Shoulder");
      notifyWithId(
        id: "ALERT_F1",
        title: "High Pressure - Right Shoulder",
        message: "Sensor F1 exceeded threshold ($thF1).",
        type: NotificationType.warning,
      );
    } else {
      // mark read but keep history (user chose B)
      _notif.markAsRead("ALERT_F1");
    }

    if (_isAlert(telemetry.f2, thF2)) {
      alertingSensors.add("F2-Left Shoulder");
      notifyWithId(
        id: "ALERT_F2",
        title: "High Pressure - Left Shoulder",
        message: "Sensor F2 exceeded threshold ($thF2).",
        type: NotificationType.warning,
      );
    } else {
      _notif.markAsRead("ALERT_F2");
    }

    if (_isAlert(telemetry.f3, thF3)) {
      alertingSensors.add("F3-Core");
      notifyWithId(
        id: "ALERT_F3",
        title: "High Pressure - Core",
        message: "Sensor F3 exceeded threshold ($thF3).",
        type: NotificationType.warning,
      );
    } else {
      _notif.markAsRead("ALERT_F3");
    }

    if (_isAlert(telemetry.f4, thF4)) {
      alertingSensors.add("F4-Back");
      notifyWithId(
        id: "ALERT_F4",
        title: "High Pressure - Back",
        message: "Sensor F4 exceeded threshold ($thF4).",
        type: NotificationType.warning,
      );
    } else {
      _notif.markAsRead("ALERT_F4");
    }

    // RF
    if (_isAlert(telemetry.rf, "60")) {
      alertingSensors.add("RF-Resultant Force");
      notifyWithId(
        id: "ALERT_RF",
        title: "Resultant Force Too High",
        message: "RF exceeded safe limit of 60.",
        type: NotificationType.alert,
        priority: NotificationPriority.high,
      );
    } else {
      _notif.markAsRead("ALERT_RF");
    }

    // Tilt angle
    if (_isAlert(telemetry.ta, thTA)) {
      alertingSensors.add("TA-Tilt Angle");
      notifyWithId(
        id: "ALERT_TA",
        title: "Unsafe Tilt Angle",
        message: "Tilt angle exceeded threshold ($thTA).",
        type: NotificationType.warning,
      );
    } else {
      _notif.markAsRead("ALERT_TA");
    }

    // Temperature (locked at 80; but still check telemetry)
    final tempValue = int.tryParse(telemetry.temp ?? "0") ?? 0;
    if (tempValue > 80) {
      alertingSensors.add("Temperature");
      notifyWithId(
        id: "ALERT_TEMP",
        title: "High Battery Temperature",
        message: "Battery temperature is ${tempValue}°C (threshold 80°C).",
        type: NotificationType.alert,
        priority: NotificationPriority.high,
      );
    } else {
      _notif.markAsRead("ALERT_TEMP");
    }

    // Battery level
    final batteryLevel = int.tryParse(telemetry.bt ?? "0") ?? 0;
    if (batteryLevel < 20) {
      alertingSensors.add("Battery Level");

      if (batteryLevel < 10) {
        notifyWithId(
          id: "ALERT_BATTERY",
          title: "Critical Battery Level",
          message: "Battery level ${batteryLevel}%. Charge immediately.",
          type: NotificationType.alert,
          priority: NotificationPriority.high,
        );
      } else {
        // low but not critical — update severity if exists
        notifyWithId(
          id: "ALERT_BATTERY",
          title: "Low Battery Warning",
          message: "Battery level ${batteryLevel}%.",
          type: NotificationType.warning,
          priority: NotificationPriority.normal,
        );
      }
    } else {
      _notif.markAsRead("ALERT_BATTERY");
    }

    final bool hasAlert = alertingSensors.isNotEmpty;

    final String alertLevel = _calculateAlertLevel(
      telemetry: telemetry,
      thF1: thF1,
      thF2: thF2,
      thF3: thF3,
      thF4: thF4,
      thTA: thTA,
    );

    try {
      await _dataService.saveSensorReading(
        f1: double.tryParse(telemetry.f1 ?? '0'),
        f2: double.tryParse(telemetry.f2 ?? '0'),
        f3: double.tryParse(telemetry.f3 ?? '0'),
        f4: double.tryParse(telemetry.f4 ?? '0'),
        rf: double.tryParse(telemetry.rf ?? '0'),
        ta: double.tryParse(telemetry.ta ?? '0'),
        temp: double.tryParse(telemetry.temp ?? '0'),
        hasAlert: hasAlert,
        alertingSensors: alertingSensors,
        alertLevel: alertLevel,
      );

      _lastSaveTime = DateTime.now();
    } catch (e) {
      debugPrint("Error saving sensor data: $e");
    }
  }

  bool _isAlert(String? value, String threshold) {
    if (value == null) return false;
    final double tv = double.tryParse(value) ?? 0;
    final double th = double.tryParse(threshold) ?? 0;
    return tv > th;
  }

  String _calculateAlertLevel({
    required telemetry,
    required String thF1,
    required String thF2,
    required String thF3,
    required String thF4,
    required String thTA,
  }) {
    List<bool> alerts = [
      _isAlert(telemetry.f1, thF1),
      _isAlert(telemetry.f2, thF2),
      _isAlert(telemetry.f3, thF3),
      _isAlert(telemetry.f4, thF4),
      _isAlert(telemetry.rf, "60"),
      _isAlert(telemetry.ta, thTA),
    ];

    final int alertCount = alerts.where((a) => a).length;

    if (alertCount >= 3) return "alert";
    if (alertCount > 0) return "warning";
    return "safe";
  }

  @override
  Widget build(BuildContext context) {
    String statusFromThreshold(String? telemetryValue, String? thresholdValue) {
      if (telemetryValue == null || thresholdValue == null) return "--";
      final double tv = double.tryParse(telemetryValue) ?? 0;
      final double th = double.tryParse(thresholdValue) ?? 0;
      return tv > th ? "Alert" : "Safe";
    }

    final thresholds = context.watch<ThresholdProvider>();
    final telemetry = context.watch<TelemetryProvider>().telemetry;

    String thF1 = thresholds.sensor.isNotEmpty
        ? thresholds.sensor[0]['value'].toString()
        : "0";
    String thF2 = thresholds.sensor.isNotEmpty
        ? thresholds.sensor[1]['value'].toString()
        : "0";
    String thF3 = thresholds.sensor.isNotEmpty
        ? thresholds.sensor[2]['value'].toString()
        : "0";
    String thF4 = thresholds.sensor.isNotEmpty
        ? thresholds.sensor[3]['value'].toString()
        : "0";
    String thTA = thresholds.angle.isNotEmpty
        ? thresholds.angle[0]['value'].toString()
        : "0";

    String showValue(String? value) => value ?? "--";

    String calculateAlertLevel() {
      if (telemetry == null) return "warning";

      final List<String> statuses = [
        statusFromThreshold(telemetry.f1, thF1),
        statusFromThreshold(telemetry.f2, thF2),
        statusFromThreshold(telemetry.f3, thF3),
        statusFromThreshold(telemetry.f4, thF4),
        statusFromThreshold(telemetry.rf, "60"),
        statusFromThreshold(telemetry.ta, thTA),
      ];

      final int alertCount = statuses.where((s) => s == "Alert").length;

      if (alertCount >= 3) return "alert";
      if (alertCount > 0) return "warning";
      return "safe";
    }

    bool hasAnyAlert() {
      if (telemetry == null) return false;
      return statusFromThreshold(telemetry.f1, thF1) == "Alert" ||
          statusFromThreshold(telemetry.f2, thF2) == "Alert" ||
          statusFromThreshold(telemetry.f3, thF3) == "Alert" ||
          statusFromThreshold(telemetry.f4, thF4) == "Alert" ||
          statusFromThreshold(telemetry.rf, "60") == "Alert" ||
          statusFromThreshold(telemetry.ta, thTA) == "Alert";
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: ScreenDimension.screenWidth * 0.04,
                              child: Image.asset(MediaStrings.spinobarLogo),
                            ),
                            SizedBox(width: 10),
                            const Text(
                              "Spinobar",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          "Hi! Mukesh Kumar",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        NotificationBadge(
                          count: NotificationService().unreadCount,
                          child: IconButton(
                            icon: const Icon(Iconsax.notification_copy,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.more_vert, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(28),
              width: ScreenDimension.screenWidth,
              height: 340,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [const Color(0x793665EF), Colors.transparent],
                  radius: 1.1,
                  center: AlignmentGeometry.bottomCenter,
                ),
              ),
              child: FreeViewCanva(
                hasAlert: hasAnyAlert(),
                alertLevel: calculateAlertLevel(),
                f1Status: statusFromThreshold(telemetry?.f1, thF1),
                f2Status: statusFromThreshold(telemetry?.f2, thF2),
                f3Status: statusFromThreshold(telemetry?.f3, thF3),
                f4Status: statusFromThreshold(telemetry?.f4, thF4),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: ScreenDimension.screenWidth,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 4,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Color(0xffD9D9D9),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          BatteryCard(bt: showValue(telemetry?.bt)),
                          StatsCard(
                            image: MediaStrings.wearStatus,
                            status:
                            telemetry == null ? "Disconnected" : "Active",
                            label: "Wear Status",
                            labelColor: telemetry == null
                                ? AppColors.warning
                                : AppColors.accent,
                          ),
                          StatsCard(
                            image: MediaStrings.batteryTemp,
                            status: telemetry == null
                                ? "No Data"
                                : '${showValue(telemetry.temp)}°C',
                            label: "Battery Temperature",
                            labelColor: telemetry == null
                                ? AppColors.warning
                                : (int.tryParse(telemetry.temp ?? '0') ?? 0) >
                                80
                                ? AppColors.error
                                : AppColors.accent,
                          ),
                          StatsCard(
                            image: MediaStrings.fallStatus,
                            status:
                            telemetry == null ? "No Data" : "Monitoring",
                            label: "Fall Detection",
                            labelColor: telemetry == null
                                ? AppColors.warning
                                : AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: (ScreenDimension.screenWidth / 2) * 0.86,
                          child: Column(
                            children: [
                              SensorCard(
                                region: 'Back',
                                parts: [
                                  {
                                    'name': 'Back',
                                    'status': statusFromThreshold(
                                      telemetry?.f4,
                                      thF4,
                                    ),
                                    'value': showValue(telemetry?.f4),
                                  },
                                ],
                              ),
                              const SizedBox(height: 14),
                              SensorCard(
                                region: 'Resultant Force',
                                parts: [
                                  {
                                    'name': 'Chest',
                                    'status': statusFromThreshold(
                                      telemetry?.rf,
                                      "60",
                                    ),
                                    'value': showValue(telemetry?.rf),
                                  },
                                ],
                              ),
                              const SizedBox(height: 14),
                              SensorCard(
                                region: 'Tilt Angle',
                                parts: [
                                  {
                                    'name': 'Angle',
                                    'status': statusFromThreshold(
                                      telemetry?.ta,
                                      thTA,
                                    ),
                                    'value': showValue(telemetry?.ta),
                                  },
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: (ScreenDimension.screenWidth / 2) * 0.86,
                          child: Column(
                            children: [
                              SensorCard(
                                region: 'Shoulder',
                                parts: [
                                  {
                                    'name': 'Right',
                                    'status': statusFromThreshold(
                                      telemetry?.f1,
                                      thF1,
                                    ),
                                    'value': showValue(telemetry?.f1),
                                  },
                                  {
                                    'name': 'Left',
                                    'status': statusFromThreshold(
                                      telemetry?.f2,
                                      thF2,
                                    ),
                                    'value': showValue(telemetry?.f2),
                                  },
                                ],
                              ),
                              const SizedBox(height: 14),
                              SensorCard(
                                region: 'Abdomen',
                                parts: [
                                  {
                                    'name': 'Core',
                                    'status': statusFromThreshold(
                                      telemetry?.f3,
                                      thF3,
                                    ),
                                    'value': showValue(telemetry?.f3),
                                  },
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(color: Colors.grey.withOpacity(0.6)),
                              const SizedBox(height: 3),
                              ElevatedButton(
                                onPressed: () {
                                  NavigationHelper.push(context, SensorThreshold());
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(200, 40),
                                  backgroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Manage',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(20, -10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    "Quick View",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 500,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MultiLineChart(showControlBar: true),
            ),
            Container(
              margin: const EdgeInsets.only(top: 0, bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  NavigationHelper.push(context, DataLogs());
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 42),
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Data Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
