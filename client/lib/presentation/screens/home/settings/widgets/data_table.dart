import 'package:flutter/material.dart';

class SensorStatusTable extends StatelessWidget {
  const SensorStatusTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 7, child: HeaderCell(text: 'Sensors')),
                Expanded(flex: 5, child: HeaderCell(text: 'Time')),
                Expanded(flex: 3, child: HeaderCell(text: 'N')),
                Expanded(flex: 5, child: HeaderCell(text: 'Alert')),
                Expanded(flex: 5, child: HeaderCell(text: 'WS')),
                Expanded(flex: 5, child: HeaderCell(text: 'Status')),
              ],
            ),
          ),

          _buildDataRow('F1', '2m ago', '2:48', '60', false, 'Active', 'Safe'),
          const Divider(color: Color(0xFF3D3D3D), height: 1),
          _buildDataRow('F2', '2m ago', '2:48', '60', false, 'Active', 'Safe'),
          const Divider(color: Color(0xFF3D3D3D), height: 1),
          _buildDataRow('F3', '2m ago', '2:48', '60', true, 'Active', 'error'),
          const Divider(color: Color(0xFF3D3D3D), height: 1),
          _buildDataRow('F4', '2m ago', '2:48', '60', false, 'Active', 'Safe'),
          const Divider(color: Color(0xFF3D3D3D), height: 1),
          _buildDataRow('RF', '2m ago', '2:48', '60', false, 'Active', 'Safe'),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    String sensor,
    String timestamp,
    String time,
    String n,
    bool alert,
    String ws,
    String status,
  ) {
    final isError = status.toLowerCase() == 'error';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(flex: 5, child: DataCell(text: time)),
          Expanded(flex: 3, child: DataCell(text: n)),
          Expanded(
            flex: 5,
            child: Text(
              alert ? 'Yes' : 'No',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: alert ? const Color(0xFFE74C3C) : Colors.grey[400],
                fontSize: 14,
                fontWeight: alert ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(flex: 5, child: DataCell(text: ws)),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xFFE74C3C).withOpacity(0.2)
                    : const Color(0xFF27AE60).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isError
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFF27AE60),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class DataCell extends StatelessWidget {
  final String text;

  const DataCell({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14));
  }
}
