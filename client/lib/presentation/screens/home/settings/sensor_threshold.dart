import 'package:client/core/theme/colors.dart';
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
    {'label': 'Shoulder Right (F1)', 'value': 60, 'unit': 'N'},
    {'label': 'Shoulder Left  (F2)', 'value': 60, 'unit': 'N'},
    {'label': 'Abdomen (F3)', 'value': 60, 'unit': 'N'},
    {'label': 'Back (F4)', 'value': 60, 'unit': 'N'},
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
    setState(() {
      if (savedSensors != null) sensorValues = savedSensors;
      if (savedAngle != null) angleValue = savedAngle;
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
                  onValueChanged: (index, newValue) {
                    setState(() {
                      sensorValues[index]['value'] = newValue;
                    });
                  },
                  onReset: ()  async {
                    setState(() {
                      sensorValues = [
                        {
                          'label': 'Shoulder Right (F1)',
                          'value': 0,
                          'unit': 'N',
                        },
                        {
                          'label': 'Shoulder Left  (F2)',
                          'value': 0,
                          'unit': 'N',
                        },
                        {'label': 'Abdomen (F3)', 'value': 0, 'unit': 'N'},
                        {'label': 'Back (F4)', 'value': 0, 'unit': 'N'},
                      ];
                    });
                    await context.read<ThresholdProvider>().saveSensors(
                      sensorValues,
                    );
                  },
                  onSave: () async {
                    await context.read<ThresholdProvider>().saveSensors(
                      sensorValues,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Sensor thresholds saved")),
                    );
                  },
                ),

                DataUpdateCard(
                  entities: angleValue,
                  label: "Angle:",
                  lastUpdated: "3 days",
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
                  },
                  onSave: () async {
                    await context.read<ThresholdProvider>().saveAngle(
                      angleValue,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Angle threshold saved")),
                    );
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
