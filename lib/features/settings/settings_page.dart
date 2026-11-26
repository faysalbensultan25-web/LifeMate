import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/language_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String language = 'English';
  String theme = 'Light';
  String currency = 'BDT (৳)';
  bool notifications = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final savedLanguage = prefs.getString('language') ?? 'English';

    setState(() {
      language = LanguageService.languages.contains(savedLanguage)
          ? savedLanguage
          : 'English';

      theme = prefs.getString('theme') ?? 'Light';
      currency = prefs.getString('currency') ?? 'BDT (৳)';
      notifications = prefs.getBool('notifications') ?? true;
      loading = false;
    });
  }

  Future<void> save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  Future<void> changeTheme(String value) async {
    setState(() {
      theme = value;
    });

    lifeMateThemeMode.value = value == 'Dark'
        ? ThemeMode.dark
        : value == 'System Default'
            ? ThemeMode.system
            : ThemeMode.light;

    await save('theme', value);
  }

  Future<void> changeLanguage(String value) async {
    await LanguageService.setLanguage(value);

    if (!mounted) return;

    setState(() {
      language = value;
    });
  }

  String t({
    required String english,
    required String bangla,
    required String hindi,
    required String arabic,
  }) {
    return LanguageService.text(
      english: english,
      bangla: bangla,
      hindi: hindi,
      arabic: arabic,
    );
  }

  Future<void> backup() async {
    try {
      final path = await BackupService.backup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? t(
                    english: 'Backup cancelled',
                    bangla: 'ব্যাকআপ বাতিল করা হয়েছে',
                    hindi: 'बैकअप रद्द कर दिया गया',
                    arabic: 'تم إلغاء النسخ الاحتياطي',
                  )
                : t(
                    english: 'Backup completed successfully',
                    bangla: 'ব্যাকআপ সফলভাবে সম্পন্ন হয়েছে',
                    hindi: 'बैकअप सफलतापूर्वक पूरा हुआ',
                    arabic: 'اكتمل النسخ الاحتياطي بنجاح',
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${t(
              english: 'Backup failed',
              bangla: 'ব্যাকআপ ব্যর্থ হয়েছে',
              hindi: 'बैकअप विफल हुआ',
              arabic: 'فشل النسخ الاحتياطي',
            )}: $e',
          ),
        ),
      );
    }
  }

  Future<void> restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            t(
              english: 'Restore Data?',
              bangla: 'ডেটা পুনরুদ্ধার করবেন?',
              hindi: 'डेटा पुनर्स्थापित करें?',
              arabic: 'هل تريد استعادة البيانات؟',
            ),
          ),
          content: Text(
            t(
              english:
                  'Restoring will replace your existing app data. Continue?',
              bangla:
                  'পুনরুদ্ধার করলে বর্তমান অ্যাপের ডেটা পরিবর্তিত হবে। চালিয়ে যাবেন?',
              hindi:
                  'पुनर्स्थापित करने से मौजूदा ऐप डेटा बदल जाएगा। क्या जारी रखें?',
              arabic:
                  'ستؤدي الاستعادة إلى استبدال بيانات التطبيق الحالية. هل تريد المتابعة؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                t(
                  english: 'Cancel',
                  bangla: 'বাতিল',
                  hindi: 'रद्द करें',
                  arabic: 'إلغاء',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                t(
                  english: 'Restore',
                  bangla: 'পুনরুদ্ধার',
                  hindi: 'पुनर्स्थापित करें',
                  arabic: 'استعادة',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final ok = await BackupService.restore();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? t(
                    english: 'Restore completed successfully',
                    bangla: 'ডেটা সফলভাবে পুনরুদ্ধার হয়েছে',
                    hindi: 'डेटा सफलतापूर्वक पुनर्स्थापित हुआ',
                    arabic: 'تمت استعادة البيانات بنجاح',
                  )
                : t(
                    english: 'Restore cancelled',
                    bangla: 'পুনরুদ্ধার বাতিল করা হয়েছে',
                    hindi: 'पुनर्स्थापना रद्द कर दी गई',
                    arabic: 'تم إلغاء الاستعادة',
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${t(
              english: 'Restore failed',
              bangla: 'পুনরুদ্ধার ব্যর্থ হয়েছে',
              hindi: 'पुनर्स्थापना विफल हुई',
              arabic: 'فشلت الاستعادة',
            )}: $e',
          ),
        ),
      );
    }
  }

  Widget sectionTitle({
    required String english,
    required String bangla,
    required String hindi,
    required String arabic,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        t(
          english: english,
          bangla: bangla,
          hindi: hindi,
          arabic: arabic,
        ),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget settingCard({
    required IconData icon,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.language,
      builder: (context, currentLanguage, child) {
        final bool isArabic = currentLanguage == 'Arabic';

        return Directionality(
          textDirection:
              isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                t(
                  english: 'Settings',
                  bangla: 'সেটিংস',
                  hindi: 'सेटिंग्स',
                  arabic: 'الإعدادات',
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =========================
                // APPEARANCE
                // =========================

                sectionTitle(
                  english: 'Appearance',
                  bangla: 'চেহারা',
                  hindi: 'दिख
