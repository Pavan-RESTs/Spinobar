import 'package:client/core/theme/colors.dart';
import 'package:client/core/utils/screen_dimension.dart';
import 'package:client/presentation/screens/home/settings/widgets/settings_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/threshold_storage.dart';
import '../../../../data/providers/threshold_provider.dart';

class ResetDevice extends StatelessWidget {
  const ResetDevice({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SettingsAppBar(title: "Reset Device"),
              SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    "Erase All Data",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: ScreenDimension.screenWidth*0.5,
                    child: Text(
                      "Delete all the sensor and angle data and start a calibration from 0",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      await ThresholdStorage.resetAllThresholds();

                      try {
                        context.read<ThresholdProvider>().load();
                      } catch (_) {}

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("All threshold values reset to 0"),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(ScreenDimension.screenWidth*0.2, 36),
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Erase All Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
