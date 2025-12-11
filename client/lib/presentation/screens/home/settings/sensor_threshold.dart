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
  List<Map<String, dynamic>> sensorValues = [];
  List<Map<String, dynamic>> temperatureValue = [];
  List<Map<String, dynamic>> angleValue = [];

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
      sensorValues =
          savedSensors ??
          [
            {'label': 'Shoulder Right (F1)', 'min': 30, 'max': 60, 'unit': 'N'},
            {'label': 'Shoulder Left (F2)', 'min': 30, 'max': 60, 'unit': 'N'},
            {'label': 'Abdomen (F3)', 'min': 30, 'max': 60, 'unit': 'N'},
            {'label': 'Back (F4)', 'min': 30, 'max': 60, 'unit': 'N'},
          ];

      temperatureValue =
          savedTemperature ??
          [
            {'label': 'Temperature', 'value': 80, 'unit': '°C'},
          ];

      angleValue =
          savedAngle ??
          [
            {'label': 'Tilt Angle', 'value': 60, 'unit': 'Deg'},
          ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThresholdProvider>();

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
                  lastUpdated: provider.sensorUpdatedAt,
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
                          'label': 'Shoulder Left (F2)',
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
                    await provider.saveSensors(sensorValues);
                    CustomSnackbar.info("Sensor threshold reset");
                  },
                  onSave: () async {
                    await provider.saveSensors(sensorValues);
                    CustomSnackbar.success("Sensor thresholds saved");
                  },
                ),

                DataUpdateCard(
                  entities: temperatureValue,
                  label: "Temperature:",
                  lastUpdated: provider.temperatureUpdatedAt,
                  isRangeSlider: false,
                  minLimit: 0,
                  maxLimit: 200,
                  onValueChanged: (index, newValue) {
                    setState(() {
                      temperatureValue[index]['value'] = newValue;
                    });
                  },
                  onReset: () async {
                    setState(() {
                      temperatureValue = [
                        {'label': 'Temperature', 'value': 0, 'unit': '°C'},
                      ];
                    });

                    await provider.saveTemperature(temperatureValue);
                    CustomSnackbar.info("Temperature threshold reset");
                  },
                  onSave: () async {
                    await provider.saveTemperature(temperatureValue);
                    CustomSnackbar.success("Temperature threshold saved");
                  },
                ),

                DataUpdateCard(
                  entities: angleValue,
                  label: "Angle:",
                  lastUpdated: provider.angleUpdatedAt,
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
                    await provider.saveAngle(angleValue);
                    CustomSnackbar.info("Angle threshold reset");
                  },
                  onSave: () async {
                    await provider.saveAngle(angleValue);
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
