import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

class LifeMateApp extends StatefulWidget {
  const LifeMateApp({super.key});

  @override
  State<LifeMateApp> createState() => _LifeMateAppState();
}

class _LifeMateAppState extends State<LifeMateApp>
    with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final theme = prefs.getString('theme') ?? 'system';
    final language = prefs.getString('language') ?? 'en';

    ThemeMode selectedTheme;

    switch (theme) {
      case 'light':
        selectedTheme = ThemeMode.light;
        break;

      case 'dark':
        selectedTheme = ThemeMode.dark;
        break;

      default:
        selectedTheme = ThemeMode.system;
    }

    if (!mounted) return;

    setState(() {
      _themeMode = selectedTheme;
      _language = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeMate',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      home: HomePage(
        language: _language,
        onSettingsChanged: _loadSettings,
      ),
    );
  }
}
