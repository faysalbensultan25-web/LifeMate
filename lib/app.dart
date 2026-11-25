
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/services/language_service.dart';
import 'features/home/lifemate_shell.dart';

final ValueNotifier<ThemeMode> lifeMateThemeMode =
    ValueNotifier(ThemeMode.light);

class LifeMateApp extends StatefulWidget {
  const LifeMateApp({super.key});

  @override
  State<LifeMateApp> createState() => _LifeMateAppState();
}

class _LifeMateAppState extends State<LifeMateApp> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'Light';

    switch (theme.toLowerCase()) {
      case 'dark':
        lifeMateThemeMode.value = ThemeMode.dark;
        break;
      case 'system':
      case 'system default':
        lifeMateThemeMode.value = ThemeMode.system;
        break;
      default:
        lifeMateThemeMode.value = ThemeMode.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: lifeMateThemeMode,
      builder: (context, mode, child) {
        return ValueListenableBuilder<String>(
          valueListenable: LanguageService.language,
          builder: (context, language, child) {
            return MaterialApp(
              title: 'LifeMate',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppTheme.primaryBlue,
                  brightness: Brightness.dark,
                ),
              ),
              themeMode: mode,
              home: LifeMateShell(
                language: language,
                onLanguageChanged: LanguageService.setLanguage,
              ),
            );
          },
        );
      },
    );
  }
}
