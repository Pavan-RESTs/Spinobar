import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/constants/image_strings.dart';
import '../../../../../core/theme/colors.dart';

class FreeViewCanva extends StatefulWidget {
  final bool hasAlert;
  final String alertLevel;
  // Individual sensor statuses
  final String f1Status;
  final String f2Status;
  final String f3Status;
  final String f4Status;

  const FreeViewCanva({
    super.key,
    this.hasAlert = false,
    this.alertLevel = "safe",
    this.f1Status = "Safe",
    this.f2Status = "Safe",
    this.f3Status = "Safe",
    this.f4Status = "Safe",
  });

  @override
  State<FreeViewCanva> createState() => _FreeViewCanvaState();
}

class _FreeViewCanvaState extends State<FreeViewCanva> {
  Key _modelViewerKey = UniqueKey();
  WebViewController? _controller;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(FreeViewCanva oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_modelLoaded &&
        (oldWidget.f1Status != widget.f1Status ||
            oldWidget.f2Status != widget.f2Status ||
            oldWidget.f3Status != widget.f3Status ||
            oldWidget.f4Status != widget.f4Status)) {
      _updateAllSensorColors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModelViewer(
          key: _modelViewerKey,
          src: MediaStrings.vest,
          backgroundColor: Colors.transparent,
          cameraControls: true,
          disablePan: true,
          disableZoom: true,
          loading: Loading.eager,
          interactionPrompt: InteractionPrompt.none,
          onWebViewCreated: (c) {
            _controller = c;
            Future.delayed(const Duration(seconds: 2), () {
              _modelLoaded = true;
              _updateAllSensorColors();
            });
          },
        ),
        Positioned(
          bottom: 6,
          left: 10,
          child: Row(
            children: [
              _indicator(AppColors.success),
              const SizedBox(width: 6),
              _indicator(AppColors.warning),
              const SizedBox(width: 6),
              _indicator(AppColors.error),
            ],
          ),
        ),
        Positioned(
          bottom: 6,
          right: 10,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _modelViewerKey = UniqueKey();
                _modelLoaded = false;
              });
            },
            child: Column(
              children: const [
                Icon(Iconsax.refresh_copy, color: Colors.white, size: 20),
                SizedBox(height: 4),
                Text(
                  "Reset View",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _indicator(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
    );
  }

  Color _getColorFromStatus(String status) {
    switch (status.toLowerCase()) {
      case "alert":
        return Colors.red;
      case "safe":
        return AppColors.accent;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _updateAllSensorColors() async {
    // Update each sensor material individually using their indices
    // F1 is at index 3, F2 at 4, F3 at 5, F4 at 6
    await changePartColorByIndex(3, _getColorFromStatus(widget.f1Status));
    await changePartColorByIndex(4, _getColorFromStatus(widget.f2Status));
    await changePartColorByIndex(5, _getColorFromStatus(widget.f3Status));
    await changePartColorByIndex(6, _getColorFromStatus(widget.f4Status));
  }

  Future<void> changePartColorByIndex(int materialIndex, Color color) async {
    if (_controller == null) return;

    final r = color.red / 255;
    final g = color.green / 255;
    final b = color.blue / 255;

    final js = """
      (function(){
        const mv = document.querySelector('model-viewer');
        if (!mv || !mv.model) return;
        
        const material = mv.model.materials[$materialIndex];
        if (material) {
          material.pbrMetallicRoughness.setBaseColorFactor([$r,$g,$b,1]);
          console.log('✅ Updated material at index $materialIndex to RGB($r,$g,$b)');
        } else {
          console.log('❌ Material at index $materialIndex not found');
        }
      })();
    """;

    try {
      await _controller!.runJavaScript(js);
    } catch (e) {
      print('Error updating material $materialIndex: $e');
    }
  }
}