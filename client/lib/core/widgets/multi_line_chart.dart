import 'package:client/core/utils/screen_dimension.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/telemetry_model.dart';
import '../../data/providers/telemetry_provider.dart';

class MultiLineChart extends StatefulWidget {
  const MultiLineChart({Key? key}) : super(key: key);

  @override
  State<MultiLineChart> createState() => _MultiLineChartState();
}

class _MultiLineChartState extends State<MultiLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  Set<String> selectedLines = {'All'};

  final Map<String, Color> lineColors = {
    'F1': Color(0xFF6366F1),
    'F2': Color(0xFFEC4899),
    'F3': Color(0xFF8B5CF6),
    'F4': Color(0xFF10B981),
    'RF': Color(0xFFF59E0B),
  };

  final int maxDataPoints = 20;
  Map<String, List<FlSpot>> chartData = {
    'F1': [],
    'F2': [],
    'F3': [],
    'F4': [],
    'RF': [],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TelemetryProvider>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  TelemetryModel? _lastTelemetry;

  void _updateChartData(TelemetryModel? telemetry) {
    if (telemetry == null) return;

    if (_lastTelemetry == telemetry) return;
    _lastTelemetry = telemetry;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        final f1Val = double.tryParse(telemetry.f1 ?? '0') ?? 0;
        final f2Val = double.tryParse(telemetry.f2 ?? '0') ?? 0;
        final f3Val = double.tryParse(telemetry.f3 ?? '0') ?? 0;
        final f4Val = double.tryParse(telemetry.f4 ?? '0') ?? 0;
        final rfVal = double.tryParse(telemetry.rf ?? '0') ?? 0;

        final currentX = chartData['F1']!.isEmpty
            ? 0.0
            : chartData['F1']!.last.x + 1;

        chartData['F1']!.add(FlSpot(currentX, f1Val));
        chartData['F2']!.add(FlSpot(currentX, f2Val));
        chartData['F3']!.add(FlSpot(currentX, f3Val));
        chartData['F4']!.add(FlSpot(currentX, f4Val));
        chartData['RF']!.add(FlSpot(currentX, rfVal));

        chartData.forEach((key, spots) {
          if (spots.length > maxDataPoints) {
            chartData[key] = spots.sublist(spots.length - maxDataPoints);
          }
        });
      });
    });
  }

  double get minX {
    if (chartData['F1']!.isEmpty) return 0;
    return chartData['F1']!.first.x;
  }

  double get maxX {
    if (chartData['F1']!.isEmpty) return maxDataPoints.toDouble();
    return chartData['F1']!.last.x;
  }

  List<LineChartBarData> _getLines() {
    List<LineChartBarData> lines = [];

    chartData.forEach((key, spots) {
      if (spots.isEmpty) return;

      if (selectedLines.contains('All') || selectedLines.contains(key)) {
        lines.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColors[key],
            barWidth: 1.2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    });

    return lines;
  }

  void _toggleLine(String line) {
    setState(() {
      if (line == 'All') {
        selectedLines = {'All'};
      } else {
        selectedLines.remove('All');
        if (selectedLines.contains(line)) {
          selectedLines.remove(line);
        } else {
          selectedLines.add(line);
        }

        if (selectedLines.isEmpty) {
          selectedLines = {'All'};
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetryProvider, child) {
        _updateChartData(telemetryProvider.telemetry);

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterButton('All', Colors.white),
                _buildFilterButton('F1', lineColors['F1']!),
                _buildFilterButton('F2', lineColors['F2']!),
                _buildFilterButton('F3', lineColors['F3']!),
                _buildFilterButton('F4', lineColors['F4']!),
                _buildFilterButton('RF', lineColors['RF']!),
              ],
            ),
            SizedBox(height: 40),

            Expanded(
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: 255,
                  lineBarsData: _getLines(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 51,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 51,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: EdgeInsetsGeometry.all(16),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.white),
                      bottom: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterButton(String label, Color color) {
    final isSelected =
        selectedLines.contains(label) ||
        (label != 'All' && selectedLines.contains('All'));

    return GestureDetector(
      onTap: () => _toggleLine(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ChartLegends extends StatelessWidget {
  final Map<String, Color> lineColors = {
    'F1': Color(0xFF6366F1),
    'F2': Color(0xFFEC4899),
    'F3': Color(0xFF8B5CF6),
    'F4': Color(0xFF10B981),
    'RF': Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: EdgeInsets.only(left: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: ScreenDimension.screenWidth * 0.45,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: lineColors['F1'],
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        child: Text(
                          "Shoulder Right (F1)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: lineColors['F3'],
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        child: Text(
                          "Abdomen (F3)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: ScreenDimension.screenWidth * 0.45,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: lineColors['F2'],
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        child: Text(
                          "Shoulder Left (F2)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: lineColors['F4'],
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        child: Text(
                          "Back (F4)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: lineColors['RF'],
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        child: Text(
                          "Resultant Force",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
