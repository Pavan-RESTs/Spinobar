import 'package:client/core/utils/screen_dimension.dart';
import 'package:client/presentation/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'data/providers/telemetry_provider.dart';
import 'data/providers/threshold_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThresholdProvider()),
        ChangeNotifierProvider(
          create: (ctx) {
            final tp = TelemetryProvider(ctx.read<ThresholdProvider>());
            tp.init();  // <-- start listening ONCE globally
            return tp;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          ScreenDimension.screenWidth = MediaQuery.of(context).size.width;
          ScreenDimension.screenHeight = MediaQuery.of(context).size.height;
          ScreenDimension.topSafeArea = MediaQuery.of(context).padding.top;
          ScreenDimension.bottomSafeArea = MediaQuery.of(
            context,
          ).padding.bottom;
          ScreenDimension.leftSafeArea = MediaQuery.of(context).padding.left;
          ScreenDimension.rightSafeArea = MediaQuery.of(context).padding.right;

          return GetMaterialApp(
            theme: ThemeData(fontFamily: 'Poppins'),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
