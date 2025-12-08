import 'package:client/core/theme/colors.dart';
import 'package:client/presentation/screens/home/settings/widgets/data_table.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/utils/screen_dimension.dart';
import '../../../../core/widgets/multi_line_chart.dart';

class DataLogs extends StatelessWidget {
  const DataLogs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      child: Icon(Icons.arrow_back, color: Colors.white,),
                      onTap: () => NavigationHelper.pop(context),
                    ),
                    SizedBox(width: 20),
                    Text(
                      "Data Logs",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(ScreenDimension.screenWidth*0.3, 36),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Export Data',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 40),

                  height: 360,
                  decoration: BoxDecoration(
                    color: Color(0xff2C2D33),
                    borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
                  padding: EdgeInsets.all(26),
                  width: double.infinity,
                  child: MultiLineChart(),
                ),
                SizedBox(height: 20,),
                ChartLegends(),
                SizedBox(height: 26,),
                SensorStatusTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
