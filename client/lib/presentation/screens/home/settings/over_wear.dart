import 'package:client/core/theme/colors.dart';
import 'package:client/core/utils/snackbar.dart';
import 'package:client/presentation/screens/home/settings/widgets/data_update_card.dart';
import 'package:client/presentation/screens/home/settings/widgets/settings_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/threshold_storage.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThresholdProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            children: [
              const SettingsAppBar(title: "Over Wear"),

              DataUpdateCard(
                entities: entities,
                label: "Set Time:",
                lastUpdated: provider.overwearUpdatedAt,   // << UPDATED

                isRangeSlider: false,
                minLimit: 0,
                maxLimit: 300, // 5 hours max or adjust as needed

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

                  await provider.saveTime(entities);
                  CustomSnackbar.info("Over-wear time reset");
                },

                onSave: () async {
                  await provider.saveTime(entities);
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
