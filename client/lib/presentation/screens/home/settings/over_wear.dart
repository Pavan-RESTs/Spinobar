import 'package:client/core/theme/colors.dart';
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
    { 'label': 'Time', 'value': 6, 'unit': 'min' }
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final saved = await ThresholdStorage.loadOverWearTime();
    if (saved != null) {
      setState(() => entities = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                lastUpdated: "5 days",

                onValueChanged: (index, newValue) {
                  setState(() {
                    entities[index]['value'] = newValue;
                  });
                },

                onReset: () {
                  setState(() {
                    entities = [
                      { 'label': 'Time', 'value': 6, 'unit': 'min' }
                    ];
                  });
                },

                onSave: () async {
                  await context.read<ThresholdProvider>().saveTime(entities);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Saved")),
                  );
                },

              ),
            ],
          ),
        ),
      ),
    );
  }
}
