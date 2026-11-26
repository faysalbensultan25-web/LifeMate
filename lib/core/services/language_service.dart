import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  LanguageService._();

  static const String _key = 'language';

  static final ValueNotifier<String> language =
      ValueNotifier<String>('English');

  static const List<String> languages = [
    'English',
    'Bangla',
    'Hindi',
    'Arabic',
  ];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(_key);

    language.value = languages.contains(saved)
        ? saved!
        : 'English';
  }

  static Future<void> setLanguage(String value) async {
    final newLanguage = languages.contains(value)
        ? value
        : 'English';

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key, newLanguage);

    language.value = newLanguage;
  }

  static bool get isBangla =>
      language.value == 'Bangla';

  static bool get isHindi =>
      language.value == 'Hindi';

  static bool get isArabic =>
      language.value == 'Arabic';

  static bool get isEnglish =>
      language.value == 'English';

  static String text({
    required String english,
    required String bangla,
    required String hindi,
    required String arabic,
  }) {
    switch (language.value) {
      case 'Bangla':
        return bangla;

      case 'Hindi':
        return hindi;

      case 'Arabic':
        return arabic;

      case 'English':
      default:
        return english;
    }
  }
}
