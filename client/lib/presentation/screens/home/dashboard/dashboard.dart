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
    if (thresholds.sensor.length < 4 ||
        thresholds.temperature.isEmpty ||
        thresholds.angle.isEmpty) {
      return;
    }

    final String thF1Min = thresholds.sensor[0]['min'].toString();
    final String thF1Max = thresholds.sensor[0]['max'].toString();
    final String thF2Min = thresholds.sensor[1]['min'].toString();
    final String thF2Max = thresholds.sensor[1]['max'].toString();
    final String thF3Min = thresholds.sensor[2]['min'].toString();
    final String thF3Max = thresholds.sensor[2]['max'].toString();
    final String thF4Min = thresholds.sensor[3]['min'].toString();
    final String thF4Max = thresholds.sensor[3]['max'].toString();
    final String thTemp = thresholds.temperature[0]['value'].toString();
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

    bool f1Alert = _isRangeAlert(telemetry.f1, thF1Min, thF1Max);
    if (f1Alert) {
      alertingSensors.add("F1-Right Shoulder");
      notifyCategory(
        'F1',
        "Pressure Out of Range - Right Shoulder",
        "Sensor F1 outside threshold range ($thF1Min-$thF1Max).",
      );
    }

    bool f2Alert = _isRangeAlert(telemetry.f2, thF2Min, thF2Max);
    if (f2Alert) {
      alertingSensors.add("F2-Left Shoulder");
      notifyCategory(
        'F2',
        "Pressure Out of Range - Left Shoulder",
        "Sensor F2 outside threshold range ($thF2Min-$thF2Max).",
      );
    }

    bool f3Alert = _isRangeAlert(telemetry.f3, thF3Min, thF3Max);
    if (f3Alert) {
      alertingSensors.add("F3-Core");
      notifyCategory(
        'F3',
        "Pressure Out of Range - Core",
        "Sensor F3 outside threshold range ($thF3Min-$thF3Max).",
      );
    }

    bool f4Alert = _isRangeAlert(telemetry.f4, thF4Min, thF4Max);
    if (f4Alert) {
      alertingSensors.add("F4-Back");
      notifyCategory(
        'F4',
        "Pressure Out of Range - Back",
        "Sensor F4 outside threshold range ($thF4Min-$thF4Max).",
      );
    }

    bool rfAlert = _isAlert(telemetry.rf, "60");
    if (rfAlert) {
      alertingSensors.add("RF-Resultant Force");
      notifyCategory(
        'RF',
        "Resultant Force Too High",
        "RF exceeded safe limit of 60.",
      );
    }

    bool taAlert = _isAlert(telemetry.ta, thTA);
    if (taAlert) {
      alertingSensors.add("TA-Tilt Angle");
      notifyCategory(
        'TA',
        "Unsafe Tilt Angle",
        "Tilt angle exceeded threshold ($thTA).",
      );
    }

    bool tempAlert = _isAlert(telemetry.temp, thTemp);
    if (tempAlert) {
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
    if (thresholds.sensor.length < 4 ||
        thresholds.temperature.isEmpty ||
        thresholds.angle.isEmpty) {
      return;
    }

    String thF1Min = thresholds.sensor[0]['min'].toString();
    String thF1Max = thresholds.sensor[0]['max'].toString();
    String thF2Min = thresholds.sensor[1]['min'].toString();
    String thF2Max = thresholds.sensor[1]['max'].toString();
    String thF3Min = thresholds.sensor[2]['min'].toString();
    String thF3Max = thresholds.sensor[2]['max'].toString();
    String thF4Min = thresholds.sensor[3]['min'].toString();
    String thF4Max = thresholds.sensor[3]['max'].toString();
    String thTemp = thresholds.temperature[0]['value'].toString();
    String thTA = thresholds.angle[0]['value'].toString();

    List<String> alertingSensors = [];

    if (_isRangeAlert(telemetry.f1, thF1Min, thF1Max))
      alertingSensors.add('F1-Right Shoulder');
    if (_isRangeAlert(telemetry.f2, thF2Min, thF2Max))
      alertingSensors.add('F2-Left Shoulder');
    if (_isRangeAlert(telemetry.f3, thF3Min, thF3Max))
      alertingSensors.add('F3-Core');
    if (_isRangeAlert(telemetry.f4, thF4Min, thF4Max))
      alertingSensors.add('F4-Back');
    if (_isAlert(telemetry.rf, "60")) alertingSensors.add('RF-Resultant Force');
    if (_isAlert(telemetry.ta, thTA)) alertingSensors.add('TA-Tilt Angle');
    if (_isAlert(telemetry.temp, thTemp)) alertingSensors.add('Temperature');

    final batteryLevel = int.tryParse(telemetry.bt ?? "0") ?? 0;
    if (batteryLevel > 0 && batteryLevel < 20) {
      alertingSensors.add('Battery Level');
    }

    bool hasAlert = alertingSensors.isNotEmpty;

    String alertLevel = _calculateAlertLevel(
      telemetry: telemetry,
      thF1Min: thF1Min,
      thF1Max: thF1Max,
      thF2Min: thF2Min,
      thF2Max: thF2Max,
      thF3Min: thF3Min,
      thF3Max: thF3Max,
      thF4Min: thF4Min,
      thF4Max: thF4Max,
      thTA: thTA,
      thTemp: thTemp,
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
    } catch (e) {}
  }

  bool _isRangeAlert(String? value, String minThreshold, String maxThreshold) {
    if (value == null) return false;
    double tv = double.tryParse(value) ?? 0;
    double min = double.tryParse(minThreshold) ?? 0;
    double max = double.tryParse(maxThreshold) ?? 100;
    return tv < min || tv > max;
  }

  bool _isAlert(String? value, String threshold) {
    if (value == null) return false;
    double tv = double.tryParse(value) ?? 0;
    double th = double.tryParse(threshold) ?? 0;
    return tv > th;
  }

  String _calculateAlertLevel({
    required telemetry,
    required String thF1Min,
    required String thF1Max,
    required String thF2Min,
    required String thF2Max,
    required String thF3Min,
    required String thF3Max,
    required String thF4Min,
    required String thF4Max,
    required String thTA,
    required String thTemp,
  }) {
    List<bool> alerts = [
      _isRangeAlert(telemetry.f1, thF1Min, thF1Max),
      _isRangeAlert(telemetry.f2, thF2Min, thF2Max),
      _isRangeAlert(telemetry.f3, thF3Min, thF3Max),
      _isRangeAlert(telemetry.f4, thF4Min, thF4Max),
      _isAlert(telemetry.rf, "60"),
      _isAlert(telemetry.ta, thTA),
      _isAlert(telemetry.temp, thTemp),
    ];

    int alertCount = alerts.where((a) => a).length;

    if (alertCount >= 3) return "alert";
    if (alertCount > 0) return "warning";
    return "safe";
  }

  @override
  Widget build(BuildContext context) {
    String statusFromRangeThreshold(
      String? telemetryValue,
      String? minThreshold,
      String? maxThreshold,
    ) {
      if (telemetryValue == null ||
          minThreshold == null ||
          maxThreshold == null)
        return "--";
      double tv = double.tryParse(telemetryValue) ?? 0;
      double min = double.tryParse(minThreshold) ?? 0;
      double max = double.tryParse(maxThreshold) ?? 100;
      return (tv < min || tv > max) ? "Alert" : "Safe";
    }

    String statusFromThreshold(String? telemetryValue, String? thresholdValue) {
      if (telemetryValue == null || thresholdValue == null) return "--";
      double tv = double.tryParse(telemetryValue) ?? 0;
      double th = double.tryParse(thresholdValue) ?? 0;
      return tv > th ? "Alert" : "Safe";
    }

    final thresholds = context.watch<ThresholdProvider>();
    final telemetry = context.watch<TelemetryProvider>().telemetry;

    String thF1Min = thresholds.sensor.isNotEmpty
        ? thresholds.sensor[0]['min'].toString()
        : "0";
    String thF1Max = thresholds.sensor.isNotEmpty
        ? thresholds.sensor[0]['max'].toString()
        : "100";
    String thF2Min = thresholds.sensor.length > 1
        ? thresholds.sensor[1]['min'].toString()
        : "0";
    String thF2Max = thresholds.sensor.length > 1
        ? thresholds.sensor[1]['max'].toString()
        : "100";
    String thF3Min = thresholds.sensor.length > 2
        ? thresholds.sensor[2]['min'].toString()
        : "0";
    String thF3Max = thresholds.sensor.length > 2
        ? thresholds.sensor[2]['max'].toString()
        : "100";
    String thF4Min = thresholds.sensor.length > 3
        ? thresholds.sensor[3]['min'].toString()
        : "0";
    String thF4Max = thresholds.sensor.length > 3
        ? thresholds.sensor[3]['max'].toString()
        : "100";
    String thTemp = thresholds.temperature.isNotEmpty
        ? thresholds.temperature[0]['value'].toString()
        : "80";
    String thTA = thresholds.angle.isNotEmpty
        ? thresholds.angle[0]['value'].toString()
        : "0";

    String showValue(String? value) => value ?? "--";

    String calculateAlertLevel() {
      if (telemetry == null) return "warning";

      List<String> statuses = [
        statusFromRangeThreshold(telemetry.f1, thF1Min, thF1Max),
        statusFromRangeThreshold(telemetry.f2, thF2Min, thF2Max),
        statusFromRangeThreshold(telemetry.f3, thF3Min, thF3Max),
        statusFromRangeThreshold(telemetry.f4, thF4Min, thF4Max),
        statusFromThreshold(telemetry.rf, "60"),
        statusFromThreshold(telemetry.ta, thTA),
        statusFromThreshold(telemetry.temp, thTemp),
      ];

      int alertCount = statuses.where((s) => s == "Alert").length;

      if (alertCount >= 3) return "alert";
      if (alertCount > 0) return "warning";
      return "safe";
    }

    bool hasAnyAlert() {
      if (telemetry == null) return false;
      return statusFromRangeThreshold(telemetry.f1, thF1Min, thF1Max) ==
              "Alert" ||
          statusFromRangeThreshold(telemetry.f2, thF2Min, thF2Max) == "Alert" ||
          statusFromRangeThreshold(telemetry.f3, thF3Min, thF3Max) == "Alert" ||
          statusFromRangeThreshold(telemetry.f4, thF4Min, thF4Max) == "Alert" ||
          statusFromThreshold(telemetry.rf, "60") == "Alert" ||
          statusFromThreshold(telemetry.ta, thTA) == "Alert" ||
          statusFromThreshold(telemetry.temp, thTemp) == "Alert";
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
                f1Status: statusFromRangeThreshold(
                  telemetry?.f1,
                  thF1Min,
                  thF1Max,
                ),
                f2Status: statusFromRangeThreshold(
                  telemetry?.f2,
                  thF2Min,
                  thF2Max,
                ),
                f3Status: statusFromRangeThreshold(
                  telemetry?.f3,
                  thF3Min,
                  thF3Max,
                ),
                f4Status: statusFromRangeThreshold(
                  telemetry?.f4,
                  thF4Min,
                  thF4Max,
                ),
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
                                : (double.tryParse(telemetry.temp ?? '0') ??
                                          0) >
                                      double.parse(thTemp)
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
                                    'status': statusFromRangeThreshold(
                                      telemetry?.f4,
                                      thF4Min,
                                      thF4Max,
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
                              const SizedBox(height: 14),
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
                                    'status': statusFromRangeThreshold(
                                      telemetry?.f1,
                                      thF1Min,
                                      thF1Max,
                                    ),
                                    'value': showValue(telemetry?.f1),
                                  },
                                  {
                                    'name': 'Left',
                                    'status': statusFromRangeThreshold(
                                      telemetry?.f2,
                                      thF2Min,
                                      thF2Max,
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
                                    'status': statusFromRangeThreshold(
                                      telemetry?.f3,
                                      thF3Min,
                                      thF3Max,
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
