import 'package:client/core/theme/colors.dart';
import 'package:client/core/utils/navigation_helper.dart';
import 'package:client/core/utils/screen_dimension.dart';
import 'package:client/core/widgets/multi_line_chart.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/battery_card.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/free_view_canva.dart';
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

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

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

    String showValue(String? value) {
      return value ?? "--";
    }

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

      if (alertCount >= 3) {
        return "alert";
      } else if (alertCount > 0) {
        return "warning";
      } else {
        return "safe";
      }
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
                padding: EdgeInsets.all(20),
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
                            Text(
                              "Spinobar",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7),
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
                        Icon(Iconsax.notification_copy, color: Colors.white),
                        SizedBox(width: 20),
                        Icon(Icons.more_vert, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(28),
              width: ScreenDimension.screenWidth,
              height: 340,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x793665EF), Colors.transparent],
                  radius: 1.1,
                  center: AlignmentGeometry.bottomCenter,
                ),
              ),

              child: FreeViewCanva(
                hasAlert: hasAnyAlert(),
                alertLevel: calculateAlertLevel(),
                // Pass individual sensor statuses
                f1Status: statusFromThreshold(telemetry?.f1, thF1),
                f2Status: statusFromThreshold(telemetry?.f2, thF2),
                f3Status: statusFromThreshold(telemetry?.f3, thF3),
                f4Status: statusFromThreshold(telemetry?.f4, thF4),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -10),
              child: Container(
                padding: EdgeInsets.all(20),
                width: ScreenDimension.screenWidth,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Color(0xffD9D9D9),
                      ),
                    ),
                    SizedBox(height: 32),
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
                    SizedBox(height: 32),
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
                              SizedBox(height: 14),
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
                              SizedBox(height: 14),
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
                              SizedBox(height: 14),
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
                              SizedBox(height: 10),
                              Divider(color: Colors.grey.withOpacity(0.6)),
                              SizedBox(height: 3),
                              ElevatedButton(
                                onPressed: () {
                                  NavigationHelper.push(
                                    context,
                                    SensorThreshold(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(200, 40),
                                  backgroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
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
              offset: Offset(20, -10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
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
              margin: EdgeInsets.only(top: 10),
              height: 400,
              padding: EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: MultiLineChart(),
            ),
            Container(
              margin: EdgeInsets.only(top: 0, bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  NavigationHelper.push(context, DataLogs());
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 42),
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
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
