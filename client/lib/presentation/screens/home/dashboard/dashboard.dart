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
  final NotificationService _notifService = NotificationService();
  final SensorDataService _dataService = SensorDataService();
  late ThresholdProvider thresholds;
  late TelemetryProvider provider;

  DateTime? _lastSaveTime;

  VoidCallback? _telemetryListener;

  @override
  void initState() {
    super.initState();

    _startAutoSave();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = context.read<TelemetryProvider>();
      thresholds = context.read<ThresholdProvider>();

      _telemetryListener = () {
        final telemetry = provider.telemetry;
        if (telemetry != null) {
          _checkAlerts(telemetry);
        }
      };
      provider.addListener(_telemetryListener!);
    });
  }

  @override
  void dispose() {
    try {
      if (_telemetryListener != null) {
        context.read<TelemetryProvider>().removeListener(_telemetryListener!);
      }
    } catch (_) {}
    super.dispose();
  }

  void _startAutoSave() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _saveSensorDataIfNeeded();
      _startAutoSave();
    });
  }

  void _checkAlerts(telemetry) {
    if (thresholds.sensor.length < 4 || thresholds.angle.isEmpty) {
      return;
    }

    final String thF1 = thresholds.sensor[0]['value'].toString();
    final String thF2 = thresholds.sensor[1]['value'].toString();
    final String thF3 = thresholds.sensor[2]['value'].toString();
    final String thF4 = thresholds.sensor[3]['value'].toString();
    final String thTemp = thresholds.sensor[4]['value'].toString();

    final String thTA = thresholds.angle[0]['value'].toString();

    List<String> alertingSensors = [];

    void notifyCategory(
      String categoryId,
      String title,
      String message, {
      String? actionData,
    }) {
      _notifService.addNotification(
        categoryId: categoryId,
        title: title,
        message: message,
        actionData: actionData,
      );
    }

    if (_isAlert(telemetry.f1, thF1)) {
      alertingSensors.add("F1-Right Shoulder");
      notifyCategory(
        'F1',
        "High Pressure - Right Shoulder",
        "Sensor F1 exceeded threshold ($thF1).",
      );
    }

    if (_isAlert(telemetry.f2, thF2)) {
      alertingSensors.add("F2-Left Shoulder");
      notifyCategory(
        'F2',
        "High Pressure - Left Shoulder",
        "Sensor F2 exceeded threshold ($thF2).",
      );
    }

    if (_isAlert(telemetry.f3, thF3)) {
      alertingSensors.add("F3-Core");
      notifyCategory(
        'F3',
        "High Pressure - Core",
        "Sensor F3 exceeded threshold ($thF3).",
      );
    }

    if (_isAlert(telemetry.f4, thF4)) {
      alertingSensors.add("F4-Back");
      notifyCategory(
        'F4',
        "High Pressure - Back",
        "Sensor F4 exceeded threshold ($thF4).",
      );
    }

    if (_isAlert(telemetry.rf, "60")) {
      alertingSensors.add("RF-Resultant Force");
      notifyCategory(
        'RF',
        "Resultant Force Too High",
        "RF exceeded safe limit of 60.",
      );
    }

    if (_isAlert(telemetry.ta, thTA)) {
      alertingSensors.add("TA-Tilt Angle");
      notifyCategory(
        'TA',
        "Unsafe Tilt Angle",
        "Tilt angle exceeded threshold ($thTA).",
      );
    }

    if (_isAlert(telemetry.temp, thTemp)) {
      alertingSensors.add("Temperature");
      notifyCategory(
        'TEMP',
        "High Battery Temperature",
        "Battery temperature exceeded ${thTemp}°C.",
      );
    }

    final batteryLevel = int.tryParse(telemetry.bt ?? "0") ?? 0;
    if (batteryLevel > 0 && batteryLevel < 20) {
      alertingSensors.add("Battery Level");
      if (batteryLevel < 10) {
        notifyCategory(
          'BATTERY_CRITICAL',
          "Critical Battery Level",
          "Battery level dropped below 10%. Charge immediately.",
        );
      } else {
        notifyCategory(
          'BATTERY_LOW',
          "Low Battery Warning",
          "Battery level dropped below 20%.",
        );
      }
    }
  }

  Future<void> _saveSensorDataIfNeeded() async {
    final telemetry = context.read<TelemetryProvider>().telemetry;
    if (telemetry == null) return;

    final now = DateTime.now();
    if (_lastSaveTime != null && now.difference(_lastSaveTime!).inSeconds < 5) {
      return;
    }

    final thresholds = context.read<ThresholdProvider>();
    if (thresholds.sensor.length < 4 || thresholds.angle.isEmpty) {
      debugPrint("⛔ Thresholds not loaded yet — skipping save");
      return;
    }

    String thF1 = thresholds.sensor[0]['value'].toString();
    String thF2 = thresholds.sensor[1]['value'].toString();
    String thF3 = thresholds.sensor[2]['value'].toString();
    String thF4 = thresholds.sensor[3]['value'].toString();
    String thTA = thresholds.angle[0]['value'].toString();

    List<String> alertingSensors = [];

    if (_isAlert(telemetry.f1, thF1)) alertingSensors.add('F1-Right Shoulder');
    if (_isAlert(telemetry.f2, thF2)) alertingSensors.add('F2-Left Shoulder');
    if (_isAlert(telemetry.f3, thF3)) alertingSensors.add('F3-Core');
    if (_isAlert(telemetry.f4, thF4)) alertingSensors.add('F4-Back');
    if (_isAlert(telemetry.rf, "60")) alertingSensors.add('RF-Resultant Force');
    if (_isAlert(telemetry.ta, thTA)) alertingSensors.add('TA-Tilt Angle');

    final tempValue = double.tryParse(telemetry.temp ?? '0') ?? 0;
    if (tempValue > 0) alertingSensors.add('Temperature');

    final batteryLevel = int.tryParse(telemetry.bt ?? "0") ?? 0;
    if (batteryLevel > 0 && batteryLevel < 20)
      alertingSensors.add('Battery Level');

    bool hasAlert = alertingSensors.isNotEmpty;

    String alertLevel = _calculateAlertLevel(
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
    double tv = double.tryParse(value) ?? 0;
    double th = double.tryParse(threshold) ?? 0;
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

    int alertCount = alerts.where((a) => a).length;

    if (alertCount >= 3) return "alert";
    if (alertCount > 0) return "warning";
    return "safe";
  }

  @override
  Widget build(BuildContext context) {
    String statusFromThreshold(String? telemetryValue, String? thresholdValue) {
      if (telemetryValue == null || thresholdValue == null) return "--";
      double tv = double.tryParse(telemetryValue) ?? 0;
      double th = double.tryParse(thresholdValue) ?? 0;
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

      List<String> statuses = [
        statusFromThreshold(telemetry.f1, thF1),
        statusFromThreshold(telemetry.f2, thF2),
        statusFromThreshold(telemetry.f3, thF3),
        statusFromThreshold(telemetry.f4, thF4),
        statusFromThreshold(telemetry.rf, "60"),
        statusFromThreshold(telemetry.ta, thTA),
      ];

      int alertCount = statuses.where((s) => s == "Alert").length;

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
                            const SizedBox(width: 10),
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
                        Text(
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
                            icon: const Icon(
                              Iconsax.notification_copy,
                              color: Colors.white,
                            ),
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
                            status: telemetry == null
                                ? "Disconnected"
                                : "Active",
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
                            status: telemetry == null
                                ? "No Data"
                                : "Monitoring",
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
                                  NavigationHelper.push(
                                    context,
                                    SensorThreshold(),
                                  );
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
              child: const MultiLineChart(showControlBar: true),
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
