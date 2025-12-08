import 'dart:ui';

import 'package:client/core/theme/colors.dart';
import 'package:client/presentation/screens/home/settings/data_logs.dart';
import 'package:client/presentation/screens/home/settings/over_wear.dart';
import 'package:client/presentation/screens/home/settings/reset_device.dart';
import 'package:client/presentation/screens/home/settings/sensor_threshold.dart';
import 'package:client/presentation/screens/home/settings/settings.dart';
import 'package:flutter/material.dart';

import 'dashboard/dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Dashboard(),
    Settings(),
    SensorThreshold(),
    OverWear(),
    DataLogs(),
    ResetDevice(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withOpacity(0.8),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 11,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 5),
                      child: Icon(Icons.dashboard_outlined, size: 28),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 5),
                      child: Icon(Icons.dashboard, size: 28),
                    ),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 5),
                      child: Icon(Icons.settings_outlined, size: 28),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 5),
                      child: Icon(Icons.settings, size: 28),
                    ),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}