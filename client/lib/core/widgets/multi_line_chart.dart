import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sensor_readings.dart';
import '../../data/models/telemetry_model.dart';
import '../../data/providers/telemetry_provider.dart';

class MultiLineChart extends StatefulWidget {
  final List<SensorReading>? staticData;
  final bool isLiveMode;
  final bool showControlBar;

  const MultiLineChart({
    Key? key,
    this.staticData,
    this.isLiveMode = true,
    required this.showControlBar,
  }) : super(key: key);

  @override
  State<MultiLineChart> createState() => _MultiLineChartState();
}

class _MultiLineChartState extends State<MultiLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  Set<String> selectedLines = {'All'};
  String? touchedLine;
  int? touchedIndex;

  late Map<String, List<FlSpot>> chartData;
  List<String> _visibleLineKeys = [];

  bool _showGrid = true;
  bool _showDots = false;
  bool _fillArea = false;
  bool _isPaused = false;
  double _playbackSpeed = 1.0;
  bool _showStats = false;
  bool _autoScale = true;
  double? _customMinY;
  double? _customMaxY;

  final Map<String, Color> lineColors = {
    'F1': Color(0xFF4A90E2),
    'F2': Color(0xFF50C878),
    'F3': Color(0xFFFFB84D),
    'F4': Color(0xFFE74C3C),
    'RF': Color(0xFF9B59B6),
  };

  final Map<String, String> lineLabels = {
    'F1': 'Shoulder Right',
    'F2': 'Shoulder Left',
    'F3': 'Abdomen',
    'F4': 'Back',
    'RF': 'Resultant Force',
  };

  final int maxDataPoints = 20;
  TelemetryModel? lastTelemetry;

  @override
  void initState() {
    super.initState();

    chartData = {for (var key in lineColors.keys) key: []};

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();

    if (widget.isLiveMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<TelemetryProvider>(context, listen: false);
      });
    } else {
      _loadStaticData();
    }
  }

  @override
  void didUpdateWidget(covariant MultiLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLiveMode && widget.staticData != oldWidget.staticData) {
      _loadStaticData();
    }
  }

  List<FlSpot> downsample(List<FlSpot> input, int targetPoints) {
    if (input.length <= targetPoints) return input;

    int bucketSize = (input.length / targetPoints).floor();
    List<FlSpot> output = [];

    for (int i = 0; i < input.length; i += bucketSize) {
      final bucket = input.sublist(
        i,
        (i + bucketSize < input.length) ? i + bucketSize : input.length,
      );

      double avgX =
          bucket.map((s) => s.x).reduce((a, b) => a + b) / bucket.length;
      double avgY =
          bucket.map((s) => s.y).reduce((a, b) => a + b) / bucket.length;

      output.add(FlSpot(avgX, avgY));
    }

    return output;
  }

  void _loadStaticData() {
    final data = widget.staticData;
    if (data == null || data.isEmpty) return;

    const maxPoints = 80;

    Map<String, List<FlSpot>> temp = {for (var key in lineColors.keys) key: []};

    for (int i = 0; i < data.length; i++) {
      final x = i.toDouble();
      final r = data[i];
      temp['F1']!.add(FlSpot(x, r.f1 ?? 0));
      temp['F2']!.add(FlSpot(x, r.f2 ?? 0));
      temp['F3']!.add(FlSpot(x, r.f3 ?? 0));
      temp['F4']!.add(FlSpot(x, r.f4 ?? 0));
      temp['RF']!.add(FlSpot(x, r.rf ?? 0));
    }

    setState(() {
      chartData = {
        for (var key in temp.keys) key: downsample(temp[key]!, maxPoints),
      };
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateLiveData(TelemetryModel? t) {
    if (!widget.isLiveMode || t == null || _isPaused) return;
    if (lastTelemetry == t) return;
    lastTelemetry = t;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        final x = chartData['F1']!.isEmpty ? 0.0 : chartData['F1']!.last.x + 1;

        double v(String? s) => double.tryParse(s ?? '0') ?? 0;

        chartData['F1']!.add(FlSpot(x, v(t.f1)));
        chartData['F2']!.add(FlSpot(x, v(t.f2)));
        chartData['F3']!.add(FlSpot(x, v(t.f3)));
        chartData['F4']!.add(FlSpot(x, v(t.f4)));
        chartData['RF']!.add(FlSpot(x, v(t.rf)));

        chartData.forEach((key, list) {
          if (list.length > maxDataPoints) {
            chartData[key] = list.sublist(list.length - maxDataPoints);
          }
        });
      });
    });
  }

  double get minX => chartData['F1']!.isEmpty ? 0 : chartData['F1']!.first.x;
  double get maxX => chartData['F1']!.isEmpty
      ? maxDataPoints.toDouble()
      : chartData['F1']!.last.x;

  double get minY {
    if (!_autoScale && _customMinY != null) return _customMinY!;
    double min = double.infinity;
    chartData.forEach((key, spots) {
      if (selectedLines.contains('All') || selectedLines.contains(key)) {
        for (final s in spots) {
          if (s.y < min) min = s.y;
        }
      }
    });
    return min == double.infinity ? 0 : min - 10;
  }

  double get maxY {
    if (!_autoScale && _customMaxY != null) return _customMaxY!;
    double max = double.negativeInfinity;
    chartData.forEach((key, spots) {
      if (selectedLines.contains('All') || selectedLines.contains(key)) {
        for (final s in spots) {
          if (s.y > max) max = s.y;
        }
      }
    });
    return max == double.negativeInfinity ? 255 : max + 10;
  }

  void _toggleLine(String k) {
    setState(() {
      if (k == "All") {
        selectedLines = {"All"};
        return;
      }
      selectedLines.remove("All");
      if (selectedLines.contains(k)) {
        selectedLines.remove(k);
      } else {
        selectedLines.add(k);
      }
      if (selectedLines.isEmpty) selectedLines = {"All"};
    });
  }

  Map<String, double> _calculateStats(String key) {
    final spots = chartData[key] ?? [];
    if (spots.isEmpty) return {'avg': 0, 'min': 0, 'max': 0};

    final values = spots.map((s) => s.y).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return {'avg': avg, 'min': min, 'max': max};
  }

  void _resetChart() {
    setState(() {
      chartData = {for (var key in lineColors.keys) key: []};
      selectedLines = {'All'};
      _isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget chart = widget.isLiveMode
        ? Consumer<TelemetryProvider>(
            builder: (_, provider, __) {
              _updateLiveData(provider.telemetry);
              return _buildChart();
            },
          )
        : _buildChart();

    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: 20),
        _buildFilterChips(),
        SizedBox(height: 30),
        Expanded(
          child: Stack(children: [chart, if (_showStats) _buildStatsOverlay()]),
        ),
        SizedBox(height: 14),
        if (widget.showControlBar) _buildControlBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(children: [_buildModeIndicator()]);
  }

  Widget _buildModeIndicator() {
    final telemetry = context.watch<TelemetryProvider>().telemetry;

    final live = widget.isLiveMode;

    String statusText;
    Color color;

    if (!live) {
      statusText = "HISTORICAL";
      color = Colors.blueAccent;
    } else if (telemetry == null) {
      statusText = "DISCONNECTED";
      color = Colors.redAccent;
    } else if (_isPaused) {
      statusText = "PAUSED";
      color = Colors.orangeAccent;
    } else {
      statusText = "LIVE";
      color = Colors.greenAccent;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 6),
          Icon(
            statusText == "DISCONNECTED"
                ? Icons.wifi_off
                : statusText == "LIVE"
                ? Icons.wifi
                : statusText == "PAUSED"
                ? Icons.pause
                : Icons.history,
            size: 14,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip("All", Colors.white),
          ...lineColors.entries.map((e) => _chip(e.key, e.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.isLiveMode) ...[
            _controlButton(
              icon: _isPaused ? Icons.play_arrow : Icons.pause,
              label: _isPaused ? "Resume" : "Pause",
              onPressed: () => setState(() => _isPaused = !_isPaused),
            ),
            SizedBox(width: 8),
            _controlButton(
              icon: Icons.refresh,
              label: "Reset",
              onPressed: _resetChart,
            ),
          ],
          SizedBox(width: 8),
          _controlButton(
            icon: _showStats ? Icons.analytics : Icons.analytics_outlined,
            label: "Stats",
            onPressed: () => setState(() => _showStats = !_showStats),
          ),
          SizedBox(width: 8),
          _controlButton(
            icon: _showGrid ? Icons.grid_on : Icons.grid_off,
            label: "Grid",
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            if (label.isNotEmpty) ...[
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String key, Color color) {
    bool active =
        selectedLines.contains(key) ||
        (selectedLines.contains("All") && key != "All");

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => _toggleLine(key),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 10),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: active ? color : color.withOpacity(.4),
            width: active ? 2 : 1.4,
          ),
          color: active ? color.withOpacity(.22) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? color : color.withOpacity(.4),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              key == 'All' ? key : lineLabels[key] ?? key,
              style: TextStyle(
                color: active ? color : color.withOpacity(.8),
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chartData.entries
              .where((e) {
                return (selectedLines.contains('All') ||
                        selectedLines.contains(e.key)) &&
                    e.value.isNotEmpty;
              })
              .map((e) {
                final stats = _calculateStats(e.key);
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: lineColors[e.key],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            lineLabels[e.key] ?? e.key,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Avg: ${stats['avg']!.toStringAsFixed(1)} | Min: ${stats['min']!.toStringAsFixed(1)} | Max: ${stats['max']!.toStringAsFixed(1)}',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                );
              })
              .toList(),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (chartData['F1']!.isEmpty) {
      return _emptyState();
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          lineBarsData: _buildLines(),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.white24),
              bottom: BorderSide(color: Colors.white24),
            ),
          ),
          gridData: FlGridData(
            show: widget.isLiveMode ? _showGrid : false,
            horizontalInterval: (maxY - minY) / 5,
            verticalInterval: 3,
            getDrawingVerticalLine: (_) => FlLine(
              color: Colors.white.withOpacity(.05),
              dashArray: [5, 5],
              strokeWidth: 1,
            ),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withOpacity(.08),
              dashArray: [5, 5],
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: ((maxY - minY) / 5).clamp(1, double.infinity),
                getTitlesWidget: (value, meta) => Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: widget.isLiveMode
                    ? 5
                    : ((maxX - minX) / 4).clamp(1, double.infinity),
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              setState(() {
                if (response != null &&
                    response.lineBarSpots != null &&
                    response.lineBarSpots!.isNotEmpty) {
                  final first = response.lineBarSpots!.first;
                  final barIdx = first.barIndex;
                  if (barIdx >= 0 && barIdx < _visibleLineKeys.length) {
                    touchedLine = _visibleLineKeys[barIdx];
                  } else {
                    touchedLine = null;
                  }
                  touchedIndex = first.spotIndex;
                } else {
                  touchedLine = null;
                  touchedIndex = null;
                }
              });
            },
            touchTooltipData: LineTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              tooltipMargin: 12,
              tooltipHorizontalAlignment: FLHorizontalAlignment.center,
              tooltipHorizontalOffset: 0,
              maxContentWidth: 160,

              fitInsideHorizontally: true,
              fitInsideVertically: true,

              tooltipBorder: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),

              getTooltipColor: (LineBarSpot spot) {
                return Colors.black.withOpacity(0.85);
              },

              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final barIdx = spot.barIndex;
                  if (barIdx < 0 || barIdx >= _visibleLineKeys.length)
                    return null;

                  final key = _visibleLineKeys[barIdx];

                  return LineTooltipItem(
                    '${lineLabels[key]}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: '${spot.y.toInt()}\n',
                        style: TextStyle(
                          color: lineColors[key],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'Time: ${spot.x.toInt()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLines() {
    _visibleLineKeys = [];
    final lines = <LineChartBarData>[];

    chartData.forEach((key, spots) {
      final active =
          selectedLines.contains('All') || selectedLines.contains(key);
      if (!active) return;
      if (spots.isEmpty) return;

      _visibleLineKeys.add(key);

      final isTouched = touchedLine == key;

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 1,
          color: lineColors[key],
          isStrokeCapRound: true,
          curveSmoothness: .35,
          dotData: FlDotData(
            show: _showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: lineColors[key]!,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: _fillArea || isTouched,
            gradient: LinearGradient(
              colors: [
                lineColors[key]!.withOpacity(_fillArea ? 0.3 : 0.25),
                lineColors[key]!.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    });

    return lines;
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(seconds: 1),
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(.15),
            ),
            child: Icon(
              widget.isLiveMode ? Icons.sensors : Icons.history,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 14),
          Text(
            widget.isLiveMode
                ? "Waiting for live sensor data…"
                : "No data available",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
