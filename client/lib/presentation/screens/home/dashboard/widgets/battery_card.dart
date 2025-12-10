import 'package:client/core/theme/colors.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/image_strings.dart';

class BatteryCard extends StatelessWidget {
  const BatteryCard({super.key, required this.bt});

  final String bt;

  Color getBatterColor(String btlevel) {
    int bt = int.tryParse(btlevel) ?? 0;
    if (bt >= 40) return AppColors.success;
    if (bt >= 20) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 70,
      decoration: BoxDecoration(
        color: Color(0xff42464F),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(MediaStrings.batteryTelemetry, width: 34),
              SizedBox(width: 10),
              Column(
                children: [
                  Image.asset(MediaStrings.batteryStatus, width: 26),
                  Transform.translate(
                    offset: Offset(0, 3),
                    child: Text(
                      bt != '--'?
                      '${bt}%': '--',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: bt!='--'?getBatterColor(bt):AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "Device Battery",
            style: TextStyle(fontSize: 12, color: Color(0xff9E9FA4)),
          ),
        ],
      ),
    );
  }
}
