import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await deleteDatabase(await getDatabasesPath() + '/sensor_data.db');
  runApp(App());
}
