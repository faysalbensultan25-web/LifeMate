import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  LanguageService._();

  static final ValueNotifier<String> language =
      ValueNotifier<String>('English');

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    language.value = prefs.getString('language') ?? 'English';
  }

  static Future<void> setLanguage(String value) async {
    language.value = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
  }

  static bool get isBangla => language.value == 'Bangla';

  static String text(
    String english,
    String bangla,
  ) {
    return isBangla ? bangla : english;
  }
}
