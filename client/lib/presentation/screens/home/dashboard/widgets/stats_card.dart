import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String image;
  final String status;
  final String label;
  final Color labelColor;

  const StatsCard({
    Key? key,
    required this.image,
    required this.status,
    required this.label,
    required this.labelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
      width: 140,
      height: 70,
      decoration: BoxDecoration(
        color: Color(0xff42464F),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, width: 24),
          Transform.translate(
            offset: Offset(0, 2),
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: labelColor,
              ),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Color(0xff9E9FA4))),
        ],
      ),
    );
  }
}
