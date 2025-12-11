import 'package:client/core/theme/colors.dart';
import 'package:client/core/utils/snackbar.dart';
import 'package:client/presentation/screens/home/settings/widgets/data_update_card.dart';
import 'package:client/presentation/screens/home/settings/widgets/settings_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/threshold_storage.dart';
import '../../../../data/providers/threshold_provider.dart';
import '../../../../data/providers/timer_provider.dart';
import '../../../../data/services/notification_service.dart';

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
      entities =
          saved ??
          [
            {'label': 'Time', 'value': 6, 'unit': 'min'},
          ];
    });

    final timer = context.read<OverWearTimerProvider>();
    timer.loadThreshold(entities.first['value']);
  }

  @override
  Widget build(BuildContext context) {
    final thresholdProvider = context.watch<ThresholdProvider>();
    final timerProvider = context.watch<OverWearTimerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsAppBar(title: "Over Wear"),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      "Elapsed Time: ${timerProvider.formattedTime}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: timerProvider.isRunning
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        timerProvider.isRunning ? "Running" : "Stopped",
                        style: TextStyle(
                          color: timerProvider.isRunning
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final timer = context.read<OverWearTimerProvider>();
                        timer.reset();

                        NotificationService().addNotification(
                          categoryId: "TIMER_RESET",
                          title: "Timer Reset",
                          message: "Over-wear timer has been reset manually.",
                        );
                      },
                      icon: const Icon(Iconsax.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),

              DataUpdateCard(
                entities: entities,
                label: "Set Threshold Time:",
                lastUpdated: thresholdProvider.overwearUpdatedAt,

                isRangeSlider: false,
                minLimit: 0,
                maxLimit: 300,

                onValueChanged: (index, newValue) {
                  setState(() {
                    entities[index]['value'] = newValue;
                  });
                },

                onReset: () async {
                  setState(() {
                    entities = [
                      {'label': 'Time', 'value': 0, 'unit': 'min'},
                    ];
                  });

                  timerProvider.reset();

                  await thresholdProvider.saveTime(entities);
                  CustomSnackbar.info("Over-wear time reset");
                },

                onSave: () async {
                  await thresholdProvider.saveTime(entities);

                  final newThreshold = entities.first['value'];
                  timerProvider.loadThreshold(newThreshold);

                  CustomSnackbar.success('Over-wear time saved');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
