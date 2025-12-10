import 'dart:io';

import 'package:client/core/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/widgets/multi_line_chart.dart';
import '../../../../data/models/sensor_readings.dart';
import '../../../../data/services/sensor_db_service.dart';

class DataLogs extends StatefulWidget {
  const DataLogs({super.key});

  @override
  State<DataLogs> createState() => _DataLogsState();
}

class _DataLogsState extends State<DataLogs> {
  DateTimeRange? _customRange;

  final SensorDataService _dataService = SensorDataService();
  List<SensorReading> _readings = [];
  bool _isLoading = true;
  String _filterType = 'today';
  Map<String, dynamic>? _statistics;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      List<SensorReading> readings;

      switch (_filterType) {
        case 'today':
          readings = await _dataService.getTodayReadings();
          break;
        case 'week':
          readings = await _dataService.getReadingsByDateRange(
            startDate: DateTime.now().subtract(Duration(days: 7)),
            endDate: DateTime.now(),
          );
          break;
        case 'month':
          readings = await _dataService.getReadingsByDateRange(
            startDate: DateTime.now().subtract(Duration(days: 30)),
            endDate: DateTime.now(),
          );
          break;
        case 'custom':
          readings = _customRange == null
              ? []
              : await _dataService.getReadingsByDateRange(
                  startDate: _customRange!.start,
                  endDate: _customRange!.end,
                );
          break;
        default:
          readings = await _dataService.getRecentReadings(limit: 500);
      }

      _statistics = _calculateRangeStatistics(_readings);

      setState(() {
        _readings = readings;
        _statistics = _calculateRangeStatistics(readings);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackbar.error("Error loading data: $e");
    }
  }

  Map<String, dynamic> _calculateRangeStatistics(List<SensorReading> list) {
    final total = list.length;
    final alerts = list.where((r) => r.hasAlert).length;
    final safe = total - alerts;

    return {'totalReadings': total, 'alertCount': alerts, 'safeCount': safe};
  }

  Future<void> _exportData() async {
    try {
      List<Map<String, dynamic>> readings;

      if (_filterType == 'custom' && _customRange != null) {
        readings = await _dataService.exportDataByDateRange(
          startDate: _customRange!.start,
          endDate: _customRange!.end,
        );
      } else if (_filterType == 'today') {
        final now = DateTime.now();
        readings = await _dataService.exportDataByDateRange(
          startDate: DateTime(now.year, now.month, now.day),
          endDate: now,
        );
      } else if (_filterType == 'week') {
        readings = await _dataService.exportDataByDateRange(
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        );
      } else if (_filterType == 'month') {
        readings = await _dataService.exportDataByDateRange(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );
      } else {
        readings = await _dataService.exportAllData();
      }

      if (readings.isEmpty) {
        CustomSnackbar.warning('No data in this range');
        return;
      }

      StringBuffer csv = StringBuffer();
      csv.writeln(
        'Timestamp,F1,F2,F3,F4,RF,TA,Has Alert,Alerting Sensors,Alert Level',
      );

      for (var reading in readings) {
        final timestamp = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(DateTime.fromMillisecondsSinceEpoch(reading['timestamp']));
        csv.writeln(
          '$timestamp,${reading['f1']},${reading['f2']},${reading['f3']},'
          '${reading['f4']},${reading['rf']},${reading['ta']},'
          '${reading['hasAlert'] == 1 ? 'Yes' : 'No'},'
          '"${reading['alertingSensors']}",${reading['alertLevel']}',
        );
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/sensor_data_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Sensor Data Export',
        text: 'Filtered data exported from Spinobar',
      );

      CustomSnackbar.success('Range export successful');
    } catch (e) {
      CustomSnackbar.error('Export failed: $e');
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xff0F0F10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomDateTimePicker(
        initialRange: _customRange,
        onApply: (range) => Navigator.pop(context, range),
      ),
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _filterType = 'custom';
      });
      _loadData();
    }
  }

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => NavigationHelper.pop(context),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xff1E1F26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        SizedBox(width: 16),
        Text(
          "Data Logs",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Spacer(),
        ElevatedButton.icon(
          onPressed: _exportData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(Icons.file_upload_outlined, color: Colors.white),
          label: Text("Export", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _filterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip("Today", "today"),
          SizedBox(width: 8),
          _filterChip("This Week", "week"),
          SizedBox(width: 8),
          _filterChip("This Month", "month"),
          SizedBox(width: 8),
          _filterChip("All Time", "all"),
          SizedBox(width: 8),
          _filterChip("Custom", "custom"),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool selected = _filterType == value;
    return ElevatedButton(
      onPressed: () async {
        if (value == "custom") {
          await _pickCustomRange();
        } else {
          setState(() => _filterType = value);
          _loadData();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? AppColors.primary : Color(0xff242528),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: TextStyle(color: Colors.white)),
    );
  }

  Widget _customRangeChip() {
    if (_filterType != "custom" || _customRange == null) return SizedBox();

    final start = DateFormat('MMM dd • HH:mm').format(_customRange!.start);
    final end = DateFormat('MMM dd • HH:mm').format(_customRange!.end);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xff1E1F26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, color: Colors.white),
            SizedBox(width: 8),

            Row(
              children: [
                Text(
                  start,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(end, style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _customRange = null;
                  _filterType = "today";
                });
                _loadData();
              },
              child: Icon(Icons.close, color: Colors.grey[400], size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticsCards() {
    if (_statistics == null) return SizedBox();

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Total',
            _statistics!['totalReadings'],
            Icons.analytics,
            AppColors.primary,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Alerts',
            _statistics!['alertCount'],
            Icons.warning_rounded,
            Color(0xFFE74C3C),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Safe',
            _statistics!['safeCount'],
            Icons.check_circle,
            Color(0xFF27AE60),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xff151516),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          SizedBox(height: 10),
          Text(
            "$value",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _chart() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      height: 480,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: MultiLineChart(
        isLiveMode: false,
        staticData: _readings,
        showControlBar: false,
      ),
    );
  }

  Widget _legends() {
    return ChartLegends();
  }

  Widget _table() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_readings.isEmpty) {
      return _emptyState();
    }

    return EnhancedSensorStatusTable(
      readings: _readings,
      expandedIndex: _expandedIndex,
      onExpand: (i) {
        setState(() => _expandedIndex = _expandedIndex == i ? -1 : i);
      },
    );
  }

  Widget _emptyState() {
    return Container(
      padding: EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 58, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No data available",
            style: TextStyle(color: Colors.grey[300], fontSize: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _topBar(),
              SizedBox(height: 20),
              _statisticsCards(),
              SizedBox(height: 20),
              _filterButtons(),
              _customRangeChip(),
              _chart(),
              SizedBox(height: 20),
              _legends(),
              SizedBox(height: 20),
              _table(),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDateTimePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final void Function(DateTimeRange) onApply;

  const CustomDateTimePicker({
    Key? key,
    this.initialRange,
    required this.onApply,
  }) : super(key: key);

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  DateTimeRange? _pickedRange;
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  @override
  void initState() {
    super.initState();
    _pickedRange = widget.initialRange;
    if (widget.initialRange != null) {
      _startTime = TimeOfDay(
        hour: widget.initialRange!.start.hour,
        minute: widget.initialRange!.start.minute,
      );
      _endTime = TimeOfDay(
        hour: widget.initialRange!.end.hour,
        minute: widget.initialRange!.end.minute,
      );
    }
  }

  Future<void> _pickRangeCalendar() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 5);
    final last = now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange:
          _pickedRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 1)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color(0xff1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xff121212),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _pickedRange = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (t != null) setState(() => _endTime = t);
  }

  void _apply() {
    if (_pickedRange == null) {
      CustomSnackbar.info('Please pick a date range');
      return;
    }

    final start = DateTime(
      _pickedRange!.start.year,
      _pickedRange!.start.month,
      _pickedRange!.start.day,
      _startTime.hour,
      _startTime.minute,
    );

    final end = DateTime(
      _pickedRange!.end.year,
      _pickedRange!.end.month,
      _pickedRange!.end.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (end.isBefore(start)) {
      CustomSnackbar.warning('End must be after start');
      return;
    }

    widget.onApply(DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    final displayRangeText = _pickedRange == null
        ? 'No dates selected'
        : '${DateFormat('MMM dd, yyyy').format(_pickedRange!.start)} → ${DateFormat('MMM dd, yyyy').format(_pickedRange!.end)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xff0F0F10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select date & time range',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickRangeCalendar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff121214),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.02)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayRangeText,
                        style: TextStyle(color: Colors.grey[200]),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff121214),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start time',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _startTime.format(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEndTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff121214),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End time',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _endTime.format(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _pickedRange = null;
                        _startTime = const TimeOfDay(hour: 0, minute: 0);
                        _endTime = const TimeOfDay(hour: 23, minute: 59);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withOpacity(0.06)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Apply range',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ChartLegends extends StatelessWidget {
  const ChartLegends({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('F1', const Color(0xFF4A90E2)),
        _buildLegendItem('F2', const Color(0xFF50C878)),
        _buildLegendItem('F3', const Color(0xFFFFB84D)),
        _buildLegendItem('F4', const Color(0xFFE74C3C)),
        _buildLegendItem('RF', const Color(0xFF9B59B6)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 13)),
      ],
    );
  }
}

class EnhancedSensorStatusTable extends StatelessWidget {
  final List<SensorReading> readings;
  final int expandedIndex;
  final Function(int) onExpand;

  const EnhancedSensorStatusTable({
    Key? key,
    required this.readings,
    required this.expandedIndex,
    required this.onExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D33),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_chart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent Readings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${readings.length > 20 ? 20 : readings.length} entries',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readings.length > 20 ? 20 : readings.length,
            itemBuilder: (context, index) {
              final reading = readings[index];
              final isExpanded = expandedIndex == index;
              return _buildEnhancedDataRow(reading, index, isExpanded);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDataRow(
    SensorReading reading,
    int index,
    bool isExpanded,
  ) {
    final timeAgo = _getTimeAgo(reading.timestamp);
    final formattedTime = DateFormat('HH:mm:ss').format(reading.timestamp);
    final formattedDate = DateFormat('MMM dd').format(reading.timestamp);

    Color alertColor;
    Color alertBgColor;
    IconData alertIcon;

    switch (reading.alertLevel) {
      case 'alert':
        alertColor = const Color(0xFFE74C3C);
        alertBgColor = const Color(0xFFE74C3C).withOpacity(0.15);
        alertIcon = Icons.error_rounded;
        break;
      case 'warning':
        alertColor = const Color(0xFFFFB84D);
        alertBgColor = const Color(0xFFFFB84D).withOpacity(0.15);
        alertIcon = Icons.warning_rounded;
        break;
      default:
        alertColor = const Color(0xFF27AE60);
        alertBgColor = const Color(0xFF27AE60).withOpacity(0.15);
        alertIcon = Icons.check_circle_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onExpand(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isExpanded ? const Color(0xFF363740) : Colors.transparent,
            border: const Border(
              bottom: BorderSide(color: Color(0xFF3D3D3D), width: 1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: Color(0xFF4A90E2),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$formattedDate • $timeAgo',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1F26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickSensorValue(
                            'F1',
                            reading.f1,
                            const Color(0xFF4A90E2),
                          ),
                          _buildQuickSensorValue(
                            'F2',
                            reading.f2,
                            const Color(0xFF50C878),
                          ),
                          _buildQuickSensorValue(
                            'F3',
                            reading.f3,
                            const Color(0xFFFFB84D),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: alertBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: alertColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(alertIcon, color: alertColor, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              reading.alertLevel.toUpperCase(),
                              style: TextStyle(
                                color: alertColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),

              if (isExpanded) ...[
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1F26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Sensor Values',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildDetailedSensorChip(
                            'F1',
                            reading.f1,
                            const Color(0xFF4A90E2),
                          ),
                          _buildDetailedSensorChip(
                            'F2',
                            reading.f2,
                            const Color(0xFF50C878),
                          ),
                          _buildDetailedSensorChip(
                            'F3',
                            reading.f3,
                            const Color(0xFFFFB84D),
                          ),
                          _buildDetailedSensorChip(
                            'F4',
                            reading.f4,
                            const Color(0xFFE74C3C),
                          ),
                          _buildDetailedSensorChip(
                            'RF',
                            reading.rf,
                            const Color(0xFF9B59B6),
                          ),
                          _buildDetailedSensorChip(
                            'TA',
                            reading.ta,
                            const Color(0xFF1ABC9C),
                          ),
                        ],
                      ),

                      if (reading.alertingSensors.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 14),
                        Row(
                          children: const [
                            Icon(
                              Icons.notification_important_rounded,
                              color: Color(0xFFE74C3C),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Alerting Sensors:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: reading.alertingSensors
                              .split(',')
                              .map(
                                (sensor) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE74C3C,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE74C3C,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    sensor,
                                    style: const TextStyle(
                                      color: Color(0xFFE74C3C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSensorValue(String label, double? value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value?.toInt().toString() ?? '--',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedSensorChip(String label, double? value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value?.toStringAsFixed(2) ?? '--',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';

    return '${difference.inDays}d ago';
  }
}

class HeaderCell extends StatelessWidget {
  final String text;

  const HeaderCell({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
