import 'package:client/core/theme/colors.dart';
import 'package:client/presentation/screens/home/settings/widgets/data_update_card.dart';
import 'package:client/presentation/screens/home/settings/widgets/settings_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/snackbar.dart';
import '../../../../data/models/threshold_storage.dart';
import '../../../../data/providers/telemetry_provider.dart';
import '../../../../data/providers/threshold_provider.dart';

class OverWear extends StatefulWidget {
  const OverWear({super.key});

  @override
  State<OverWear> createState() => _OverWearState();
}

class _OverWearState extends State<OverWear> {
  List<Map<String, dynamic>> entities = [
    {'label': 'Time', 'value': 6, 'unit': 'min'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final saved = await ThresholdStorage.loadOverWearTime();
    setState(() {
      entities = saved ??
          [
            {'label': 'Time', 'value': 6, 'unit': 'min'},
          ];
    });
  }

  String _formatSeconds(int totalSeconds) {
    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(
        2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final telemetryProvider = context.watch<TelemetryProvider>();
    final thresholdProvider = context.watch<ThresholdProvider>();

    final int wornSeconds = telemetryProvider.overWearSeconds;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsAppBar(title: "Over Wear"),
              const SizedBox(height: 20),

              // Live timer display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff2C2D33),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Wear Time",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatSeconds(wornSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              DataUpdateCard(
                entities: entities,
                label: "Set Max Wear Time (Minutes):",
                lastUpdated: thresholdProvider.overwearUpdatedAt,
                isRangeSlider: false,
                minLimit: 0,
                maxLimit: 300,
                onValueChanged: (index, newValue) {
                  setState(() => entities[index]['value'] = newValue);
                },
                onReset: () async {
                  setState(() {
                    entities = [{'label': 'Time', 'value': 0, 'unit': 'min'}];
                  });
                  await thresholdProvider.saveTime(entities);
                  CustomSnackbar.info("Timer reset saved");
                },
                onSave: () async {
                  await thresholdProvider.saveTime(entities);
                  CustomSnackbar.success("Timer threshold saved");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
