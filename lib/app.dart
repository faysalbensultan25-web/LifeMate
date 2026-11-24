import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

class LifeMateApp extends StatefulWidget {
  const LifeMateApp({super.key});

  @override
  State<LifeMateApp> createState() => _LifeMateAppState();
}

class _LifeMateAppState extends State<LifeMateApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final theme = prefs.getString('theme') ?? 'system';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeMate',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      // আপনার বর্তমান AppTheme-এ darkTheme নেই,
      // তাই আপাতত Material-এর dark theme ব্যবহার করা হচ্ছে।
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryBlue,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: _themeMode,

      home: const HomePage(),
    );
  }
}
