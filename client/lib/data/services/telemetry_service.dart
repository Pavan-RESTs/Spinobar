import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class TelemetryService {
  static const _deviceName = "ESP32_Newrons";

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription<List<int>>? _subscription;

  Future<void> connect(void Function(String raw) onData) async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.name == _deviceName) {
          _device = r.device;
          FlutterBluePlus.stopScan();
          await _connectAndListen(onData);
        }
      }
    });
  }

  Future<void> _connectAndListen(void Function(String raw) onData) async {
    if (_device == null) return;
    await _device!.connect(autoConnect: false, license: License.free);

    var services = await _device!.discoverServices();
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.properties.notify) {
          _rxChar = c;
          await c.setNotifyValue(true);
          _subscription = c.onValueReceived.listen((data) {
            final raw = utf8.decode(data);
            onData(raw);
          });
          return;
        }
      }
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    if (_device != null) await _device!.disconnect();
  }
}
