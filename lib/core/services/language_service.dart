import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  LanguageService._();

  static const String _key = 'language';

  static final ValueNotifier<String> language =
      ValueNotifier<String>('English');

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(_key);

    language.value =
        saved == 'Bangla' ? 'Bangla' : 'English';
  }

  static Future<void> setLanguage(String value) async {
    final newLanguage =
        value == 'Bangla' ? 'Bangla' : 'English';

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key, newLanguage);

    language.value = newLanguage;
  }

  static bool get isBangla =>
      language.value == 'Bangla';

  static String text(
    String english,
    String bangla,
  ) {
    return isBangla ? bangla : english;
  }
}
