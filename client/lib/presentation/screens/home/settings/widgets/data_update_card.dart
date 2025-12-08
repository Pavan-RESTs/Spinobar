import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/screen_dimension.dart';

class DataUpdateCard extends StatefulWidget {
  const DataUpdateCard({
    super.key,
    required this.entities,
    required this.label,
    required this.lastUpdated,
    required this.onValueChanged,
    required this.onSave,
    required this.onReset,
  });

  final List<Map<String, dynamic>> entities;
  final String label;
  final String lastUpdated;

  final void Function(int index, int newValue) onValueChanged;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  State<DataUpdateCard> createState() => _DataUpdateCardState();
}

class _DataUpdateCardState extends State<DataUpdateCard> {
  Timer? _holdTimer;

  void _triggerChange(int index, int delta) {
    int current = widget.entities[index]['value'];
    if (current + delta >= 0) {
      widget.onValueChanged(index, current + delta);
    }
  }

  void _startHold(int index, int delta) {
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      _triggerChange(index, delta);
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 33),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            "Last update ${widget.lastUpdated} ago",
            style: const TextStyle(color: Color(0xff515151), fontSize: 14),
          ),
          Container(
            margin: const EdgeInsets.only(top: 24),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff2C2D33),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (int i = 0; i < widget.entities.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.entities[i]['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xff42464F),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _triggerChange(i, -1),
                                    onLongPressStart: (_) => _startHold(i, -1),
                                    onLongPressEnd: (_) => _stopHold(),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(38),
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: const Icon(Iconsax.minus_copy),
                                    ),
                                  ),

                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      widget.entities[i]['value'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () => _triggerChange(i, 1),
                                    onLongPressStart: (_) => _startHold(i, 1),
                                    onLongPressEnd: (_) => _stopHold(),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(38),
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: const Icon(Iconsax.add_copy),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.entities[i]['unit'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onReset,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          ScreenDimension.screenWidth * 0.35,
                          36,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: widget.onSave,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          ScreenDimension.screenWidth * 0.35,
                          36,
                        ),
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
