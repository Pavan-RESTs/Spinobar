import 'package:client/core/constants/image_strings.dart';
import 'package:client/core/theme/colors.dart';
import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String region;
  final List<Map<String, String>> parts;

  const SensorCard({super.key, required this.region, required this.parts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Color(0xff44474E),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                region,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              Image.asset(MediaStrings.info, width: 20),
            ],
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xff222222),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < parts.length; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          parts[i]['name'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      if (parts[i]['value'] != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xff2A2D35),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                parts[i]['value'] ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (parts[i]['unit'] != null) ...[
                                SizedBox(width: 2),
                                Text(
                                  parts[i]['unit'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 6),
                      ],

                      Builder(
                        builder: (context) {
                          final status = parts[i]['status'];

                          late Color badgeColor;
                          if (status == null || status == "--") {
                            badgeColor = AppColors.warning;
                          } else if (status == "Alert") {
                            badgeColor = Colors.red;
                          } else {
                            badgeColor = AppColors.accent;
                          }

                          return Container(
                            width: 36,
                            height: 22,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                status ?? '',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  if (i < parts.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        color: Colors.grey.withOpacity(0.3),
                        height: 1,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
