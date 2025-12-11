import 'package:client/core/theme/colors.dart';
import 'package:client/core/utils/snackbar.dart';
import 'package:client/presentation/screens/home/settings/widgets/data_update_card.dart';
import 'package:client/presentation/screens/home/settings/widgets/settings_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/threshold_storage.dart';
import '../../../../data/providers/threshold_provider.dart';

class SensorThreshold extends StatefulWidget {
  const SensorThreshold({super.key});

  @override
  State<SensorThreshold> createState() => _SensorThresholdState();
}

class _SensorThresholdState extends State<SensorThreshold> {
  List<Map<String, dynamic>> sensorValues = [
    {'label': 'Shoulder Right (F1)', 'min': 30, 'max': 60, 'unit': 'N'},
    {'label': 'Shoulder Left  (F2)', 'min': 30, 'max': 60, 'unit': 'N'},
    {'label': 'Abdomen (F3)', 'min': 30, 'max': 60, 'unit': 'N'},
    {'label': 'Back (F4)', 'min': 30, 'max': 60, 'unit': 'N'},
  ];

  List<Map<String, dynamic>> temperatureValue = [
    {'label': 'Temperature', 'value': 80, 'unit': 'C'},
  ];

  List<Map<String, dynamic>> angleValue = [
    {'label': 'Tilt Angle', 'value': 60, 'unit': 'Deg'},
  ];

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() async {
    final savedSensors = await ThresholdStorage.loadSensorThresholds();
    final savedAngle = await ThresholdStorage.loadAngleThreshold();
    final savedTemperature = await ThresholdStorage.loadTemperatureThreshold();

    setState(() {
      if (savedSensors != null) sensorValues = savedSensors;
      if (savedAngle != null) angleValue = savedAngle;
      if (savedTemperature != null) temperatureValue = savedTemperature;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SettingsAppBar(title: "Sensor Threshold"),

                DataUpdateCard(
                  entities: sensorValues,
                  label: "Sensor Values:",
                  lastUpdated: "2 Days",
                  isRangeSlider: true,
                  minLimit: 0,
                  maxLimit: 255,
                  onValueChanged: (index, newValue) {
                    setState(() {
                      sensorValues[index]['min'] = newValue['min'];
                      sensorValues[index]['max'] = newValue['max'];
                    });
                  },
                  onReset: () async {
                    setState(() {
                      sensorValues = [
                        {
                          'label': 'Shoulder Right (F1)',
                          'min': 0,
                          'max': 100,
                          'unit': 'N',
                        },
                        {
                          'label': 'Shoulder Left  (F2)',
                          'min': 0,
                          'max': 100,
                          'unit': 'N',
                        },
                        {
                          'label': 'Abdomen (F3)',
                          'min': 0,
                          'max': 100,
                          'unit': 'N',
                        },
                        {
                          'label': 'Back (F4)',
                          'min': 0,
                          'max': 100,
                          'unit': 'N',
                        },
                      ];
                    });
                    await context.read<ThresholdProvider>().saveSensors(
                      sensorValues,
                    );
                    CustomSnackbar.info("Sensor threshold reset");
                  },
                  onSave: () async {
                    await context.read<ThresholdProvider>().saveSensors(
                      sensorValues,
                    );
                    CustomSnackbar.success("Sensor thresholds saved");
                  },
                ),

                DataUpdateCard(
                  entities: temperatureValue,
                  label: "Temperature:",
                  lastUpdated: "2 Days",
                  isRangeSlider: false,
                  minLimit: 0,
                  maxLimit: 100,
                  onValueChanged: (index, newValue) {
                    setState(() {
                      temperatureValue[index]['value'] = newValue;
                    });
                  },
                  onReset: () async {
                    setState(() {
                      temperatureValue = [
                        {'label': 'Temperature', 'value': 0, 'unit': 'C'},
                      ];
                    });

                    await context.read<ThresholdProvider>().saveTemperature(
                      temperatureValue,
                    );
                    CustomSnackbar.info("Temperature threshold reset");
                  },

                  onSave: () async {
                    await context.read<ThresholdProvider>().saveTemperature(
                      temperatureValue,
                    );
                    CustomSnackbar.success("Temperature threshold saved");
                  },
                ),

                DataUpdateCard(
                  entities: angleValue,
                  label: "Angle:",
                  lastUpdated: "3 days",
                  isRangeSlider: false,
                  minLimit: 0,
                  maxLimit: 90,
                  onValueChanged: (index, newValue) {
                    setState(() {
                      angleValue[index]['value'] = newValue;
                    });
                  },
                  onReset: () async {
                    setState(() {
                      angleValue = [
                        {'label': 'Tilt Angle', 'value': 0, 'unit': 'Deg'},
                      ];
                    });
                    await context.read<ThresholdProvider>().saveAngle(
                      angleValue,
                    );
                    CustomSnackbar.info("Angle threshold reset");
                  },
                  onSave: () async {
                    await context.read<ThresholdProvider>().saveAngle(
                      angleValue,
                    );
                    CustomSnackbar.success("Angle threshold saved");
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
