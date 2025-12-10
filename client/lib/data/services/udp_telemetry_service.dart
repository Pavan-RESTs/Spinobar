import 'package:udp/udp.dart';

class UdpTelemetryService {
  static const int listenPort = 5000;
  UDP? _socket;

  Future<void> listen(void Function(String raw) onData) async {
    _socket = await UDP.bind(Endpoint.any(port: Port(listenPort)));

    _socket!.asStream().listen(
      (datagram) {
        if (datagram == null) return;
        final raw = String.fromCharCodes(datagram.data).trim();
        if (raw.isNotEmpty) onData(raw);
      },
      onError: (e) {
        print("UDP Listen Error: $e");
      },
    );
  }

  void dispose() {
    _socket?.close();
    _socket = null;
  }
}
