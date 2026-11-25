import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/language_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LanguageService.load();

  runApp(const LifeMateApp());
}
