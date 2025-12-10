import 'package:client/core/constants/image_strings.dart';
import 'package:client/presentation/screens/home/dashboard/widgets/notification.dart';
import 'package:client/presentation/screens/home/settings/data_logs.dart';
import 'package:client/presentation/screens/home/settings/over_wear.dart';
import 'package:client/presentation/screens/home/settings/reset_device.dart';
import 'package:client/presentation/screens/home/settings/sensor_threshold.dart';
import 'package:client/presentation/screens/home/settings/widgets/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class Settings extends StatelessWidget {
  List<String> settingsB1 = ["Sensors", "Over Wear", "Data Logs", "Reset Data"];
  List<String> settingsB2 = ["Notifications", "Device Info"];
  List<String> settingsB3 = ["Add New Account", "Logout"];

  List<String> assetsB1 = [
    MediaStrings.sensors,
    MediaStrings.overWear,
    MediaStrings.dataLogs,
    MediaStrings.resetData,
  ];
  List<String> assetsB2 = [MediaStrings.notifications, MediaStrings.deviceInfo];
  List<String> assetsB3 = [MediaStrings.newAccount, MediaStrings.logout];

  List<Widget> nextPagesB1 = [
    SensorThreshold(),
    OverWear(),
    DataLogs(),
    ResetDevice(),
  ];

  List<Widget> nextPagesB2 = [NotificationPage()];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Device Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Help",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.help_outline, color: Colors.white, size: 16),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "User Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsetsGeometry.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentGeometry.centerLeft,
                    end: AlignmentGeometry.centerRight,
                    colors: [Color(0xff0D53A4), Color(0xff00162D)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                width: double.infinity,
                child: Row(
                  children: [
                    Image.asset(MediaStrings.profile, width: 60),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mukesh Kumar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "mk@gmail.com",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Icon(Iconsax.user_edit_copy, color: Colors.white),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Settings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SettingsList(
                options: settingsB1,
                assets: assetsB1,
                nextPages: nextPagesB1,
              ),
              SettingsList(
                options: settingsB2,
                assets: assetsB2,
                nextPages: nextPagesB2,
              ),
              SettingsList(options: settingsB3, assets: assetsB3),
            ],
          ),
        ),
      ),
    );
  }
}
