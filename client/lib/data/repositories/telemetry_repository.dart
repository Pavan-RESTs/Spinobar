import 'package:client/data/services/udp_telemetry_service.dart';

class TelemetryRepository {
  final UdpTelemetryService _udp = UdpTelemetryService();

  void startListening(void Function(String raw) onUpdate) {
    _udp.listen(onUpdate);
  }

  void dispose() {
    _udp.dispose();
  }
}
