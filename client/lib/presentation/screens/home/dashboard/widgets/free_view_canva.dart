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

  const FreeViewCanva({
    super.key,
    this.hasAlert = false,
    this.alertLevel = "safe",
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

    if (oldWidget.alertLevel != widget.alertLevel && _modelLoaded) {
      _updateModelColor();
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
              _logMaterials();
              _modelLoaded = true;
              _updateModelColor();
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

  Future<void> _logMaterials() async {
    if (_controller == null) return;
    const js = """
      (function(){
        const mv = document.querySelector('model-viewer');
        if (!mv || !mv.model) return;
        console.log("⚪ MATERIALS FOUND:", mv.model.materials.length);
        mv.model.materials.forEach((m,i)=>console.log("•", m.name, "(index", i + ")"));
      })();
    """;
    try {
      await _controller!.runJavaScript(js);
    } catch (_) {}
  }

  Future<void> _updateModelColor() async {
    Color targetColor;

    switch (widget.alertLevel) {
      case "safe":
        targetColor = AppColors.accent;
        break;
      case "warning":
        targetColor = AppColors.warning;
        break;
      case "alert":
        targetColor = Colors.red;
        break;
      default:
        targetColor = AppColors.warning;
        break;
    }

    await changePartColor("Default", targetColor);
  }

  Future<void> changePartColor(String materialName, Color color) async {
    if (_controller == null) return;

    final r = color.red / 255;
    final g = color.green / 255;
    final b = color.blue / 255;

    final js =
        """
      (function(){
        const mv = document.querySelector('model-viewer');
        if (!mv || !mv.model) return;
        mv.model.materials.forEach(m => {
          if (m.name === "$materialName") {
            m.pbrMetallicRoughness.setBaseColorFactor([$r,$g,$b,1]);
          }
        });
      })();
    """;

    try {
      await _controller!.runJavaScript(js);
    } catch (_) {}
  }
}
