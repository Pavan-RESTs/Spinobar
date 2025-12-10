import 'package:client/core/utils/navigation_helper.dart';
import 'package:flutter/material.dart';

class SettingsAppBar extends StatelessWidget {
  const SettingsAppBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          child: Icon(Icons.arrow_back, color: Colors.white),
          onTap: () => NavigationHelper.pop(context),
        ),
        SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Spacer(),
        Icon(Icons.more_vert, color: Colors.white, size: 24),
      ],
    );
  }
}
