import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void _show({
    required String title,
    required String message,
    required Color tint,
    IconData? icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      snackStyle: SnackStyle.FLOATING,

      backgroundColor: tint.withOpacity(0.20),
      colorText: Colors.white,
      borderRadius: 20,
      margin: const EdgeInsets.all(16),

      barBlur: 18,

      borderColor: tint.withOpacity(0.4),
      borderWidth: 1.4,

      icon: icon != null
          ? Icon(icon, color: Colors.white.withOpacity(0.9), size: 24)
          : null,

      duration: const Duration(seconds: 2),
      shouldIconPulse: false,
    );
  }

  static void success(String message, {String title = "Success"}) {
    _show(
      title: title,
      message: message,
      tint: Colors.greenAccent,
      icon: Icons.check_circle,
    );
  }

  static void error(String message, {String title = "Error"}) {
    _show(
      title: title,
      message: message,
      tint: Colors.redAccent,
      icon: Icons.error,
    );
  }

  static void warning(String message, {String title = "Warning"}) {
    _show(
      title: title,
      message: message,
      tint: Colors.orangeAccent,
      icon: Icons.warning,
    );
  }

  static void info(String message, {String title = "Info"}) {
    _show(
      title: title,
      message: message,
      tint: Colors.blueAccent,
      icon: Icons.info,
    );
  }
}
