import 'package:flutter/material.dart';

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
    this.isRangeSlider = false,
    this.minLimit = 0,
    this.maxLimit = 100,
  });

  final List<Map<String, dynamic>> entities;
  final String label;
  final String lastUpdated;
  final bool isRangeSlider;
  final double minLimit;
  final double maxLimit;

  final void Function(int index, dynamic newValue) onValueChanged;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  State<DataUpdateCard> createState() => _DataUpdateCardState();
}

class _DataUpdateCardState extends State<DataUpdateCard> {
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
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                            Text(
                              widget.isRangeSlider
                                  ? "${widget.entities[i]['min']} - ${widget.entities[i]['max']} ${widget.entities[i]['unit']}"
                                  : "${widget.entities[i]['value']} ${widget.entities[i]['unit']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        widget.isRangeSlider
                            ? _buildRangeSlider(i)
                            : _buildSingleSlider(i),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
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

  Widget _buildSingleSlider(int index) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.secondary,
        inactiveTrackColor: const Color(0xff42464F),
        thumbColor: Colors.white,
        overlayColor: AppColors.secondary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value: widget.entities[index]['value'].toDouble(),
        min: widget.minLimit,
        max: widget.maxLimit,
        onChanged: (value) {
          widget.onValueChanged(index, value.round());
        },
      ),
    );
  }

  Widget _buildRangeSlider(int index) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.secondary,
        inactiveTrackColor: const Color(0xff42464F),
        thumbColor: Colors.white,
        overlayColor: AppColors.secondary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 8,
        ),
      ),
      child: RangeSlider(
        values: RangeValues(
          widget.entities[index]['min'].toDouble(),
          widget.entities[index]['max'].toDouble(),
        ),
        min: widget.minLimit,
        max: widget.maxLimit,
        onChanged: (values) {
          widget.onValueChanged(index, {
            'min': values.start.round(),
            'max': values.end.round(),
          });
        },
      ),
    );
  }
}
