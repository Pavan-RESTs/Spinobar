class TelemetryModel {
  String? f1, f2, f3, f4, rf, ta, bt, ws, temp;

  TelemetryModel.fromRaw(String raw) {
    final pairs = raw.split(",");
    for (var p in pairs) {
      final kv = p.split(":");
      if (kv.length != 2) continue;

      final key = kv[0].trim().toLowerCase();
      final val = kv[1].trim();

      switch (key) {
        case "f1":
          f1 = val;
          break;
        case "f2":
          f2 = val;
          break;
        case "f3":
          f3 = val;
          break;
        case "f4":
          f4 = val;
          break;
        case "rf":
          rf = val;
          break;
        case "ta":
          ta = val;
          break;
        case "bt":
          bt = val;
          break;
        case "ws":
          ws = val;
          break;
        case "temp":
          temp = val;
          break;
      }
    }
  }
}
