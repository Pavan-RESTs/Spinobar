import 'package:client/core/utils/navigation_helper.dart';
import 'package:flutter/material.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({
    super.key,
    required this.options,
    required this.assets,
    this.nextPages,
  });

  final List<String> options;
  final List<String> assets;
  final List<Widget>? nextPages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 26),
      margin: EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        color: Color(0xff2B2D33),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < options.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (nextPages != null) {
                  NavigationHelper.push(context, nextPages![i]);
                }
              },
              child: Container(
                padding: EdgeInsetsGeometry.only(
                  bottom: i != options.length - 1 ? 26 : 0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: EdgeInsetsGeometry.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xff222222),
                        borderRadius: BorderRadius.all(Radius.circular(48)),
                      ),
                      child: Center(
                        child: SizedBox(
                          child: Image.asset(assets[i], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  options[i],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  color: Color(0xffffffff).withOpacity(0.2),
                                ),
                              ],
                            ),
                            Transform.translate(
                              offset: Offset(0, 4),
                              child: Divider(
                                color: Color(0xffffffff).withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
