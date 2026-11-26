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

    setState(() {
      language = prefs.getString('language') ?? 'English';
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
    setState(() => theme = value);

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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
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
      ),
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
        return Scaffold(
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
              Text(
                t(
                  english: 'Appearance',
                  bangla: 'চেহারা',
                  hindi: 'दिखावट',
                  arabic: 'المظهر',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(
                    t(
                      english: 'Theme',
                      bangla: 'থিম',
                      hindi: 'थीम',
                      arabic: 'السمة',
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: theme,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: 'Light',
                        child: Text(
                          t(
                            english: 'Light',
                            bangla: 'লাইট',
                            hindi: 'लाइट',
                            arabic: 'فاتح',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Dark',
                        child: Text(
                          t(
                            english: 'Dark',
                            bangla: 'ডার্ক',
                            hindi: 'डार्क',
                            arabic: 'داكن',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'System Default',
                        child: Text(
                          t(
                            english: 'System Default',
                            bangla: 'সিস্টেম ডিফল্ট',
                            hindi: 'सिस्टम डिफ़ॉल्ट',
                            arabic: 'افتراضي النظام',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        changeTheme(value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                t(
                  english: 'Language',
                  bangla: 'ভাষা',
                  hindi: 'भाषा',
                  arabic: 'اللغة',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(
                    t(
                      english: 'App Language',
                      bangla: 'অ্যাপের ভাষা',
                      hindi: 'ऐप की भाषा',
                      arabic: 'لغة التطبيق',
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: language,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'Bangla',
                        child: Text('বাংলা'),
                      ),
                      DropdownMenuItem(
                        value: 'Hindi',
                        child: Text('हिन्दी'),
                      ),
                      DropdownMenuItem(
                        value: 'Arabic',
                        child: Text('العربية'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        changeLanguage(value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                t(
                  english: 'Currency',
                  bangla: 'মুদ্রা',
                  hindi: 'मुद्रा',
                  arabic: 'العملة',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: Text(
                    t(
                      english: 'Currency',
                      bangla: 'মুদ্রা',
                      hindi: 'मुद्रा',
                      arabic: 'العملة',
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: currency,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'BDT (৳)',
                        child: Text('BDT (৳)'),
                      ),
                      DropdownMenuItem(
                        value: 'USD (\$)',
                        child: Text('USD (\$)'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;

                      setState(() => currency = value);
                      await save('currency', value);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_outlined,
                  ),
                  title: Text(
                    t(
                      english: 'Notifications',
                      bangla: 'নোটিফিকেশন',
                      hindi: 'सूचनाएँ',
                      arabic: 'الإشعارات',
                    ),
                  ),
                  subtitle: Text(
                    t(
                      english: 'Enable app notifications',
                      bangla: 'অ্যাপের নোটিফিকেশন চালু করুন',
                      hindi: 'ऐप सूचनाएँ चालू करें',
                      arabic: 'تفعيل إشعارات التطبيق',
                    ),
                  ),
                  value: notifications,
                  onChanged: (value) async {
                    setState(() => notifications = value);
                    await save('notifications', value);
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                t(
                  english: 'Backup & Restore',
                  bangla: 'ব্যাকআপ ও পুনরুদ্ধার',
                  hindi: 'बैकअप और पुनर्स्थापना',
                  arabic: 'النسخ الاحتياطي والاستعادة',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(
                    t(
                      english: 'Backup Data',
                      bangla: 'ডেটা ব্যাকআপ',
                      hindi: 'डेटा बैकअप',
                      arabic: 'نسخ البيانات احتياطيًا',
                    ),
                  ),
                  subtitle: Text(
                    t(
                      english: 'Save LifeMate data to a file',
                      bangla: 'LifeMate-এর ডেটা ফাইলে সংরক্ষণ করুন',
                      hindi: 'LifeMate डेटा को फ़ाइल में सहेजें',
                      arabic: 'حفظ بيانات LifeMate في ملف',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: backup,
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: Text(
                    t(
                      english: 'Restore Data',
                      bangla: 'ডেটা পুনরুদ্ধার',
                      hindi: 'डेटा पुनर्स्थापित करें',
                      arabic: 'استعادة البيانات',
                    ),
                  ),
                  subtitle: Text(
                    t(
                      english: 'Restore data from a backup file',
                      bangla: 'ব্যাকআপ ফাইল থেকে ডেটা পুনরুদ্ধার করুন',
                      hindi: 'बैकअप फ़ाइल से डेटा पुनर्स्थापित करें',
                      arabic: 'استعادة البيانات من ملف النسخ الاحتياطي',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: restore,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
