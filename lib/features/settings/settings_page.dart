import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup/backup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String language = 'English';
  String theme = 'System Default';
  String currency = 'BDT (৳)';
  bool notifications = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      language =
          prefs.getString('language') ?? 'English';

      theme =
          prefs.getString('theme') ?? 'System Default';

      currency =
          prefs.getString('currency') ?? 'BDT (৳)';

      notifications =
          prefs.getBool('notifications') ?? true;

      isLoading = false;
    });
  }

  Future<void> saveLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('language', value);

    if (!mounted) return;

    setState(() {
      language = value;
    });

    showMessage(
      value == 'বাংলা'
          ? 'ভাষা বাংলা নির্বাচন করা হয়েছে।'
          : 'English language selected.',
    );
  }

  Future<void> saveTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('theme', value);

    if (!mounted) return;

    setState(() {
      theme = value;
    });

    showMessage(
      'Theme saved. Restart the app to apply everywhere.',
    );
  }

  Future<void> saveCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('currency', value);

    if (!mounted) return;

    setState(() {
      currency = value;
    });

    showMessage('Currency saved.');
  }

  Future<void> saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications', value);

    if (!mounted) return;

    setState(() {
      notifications = value;
    });

    showMessage(
      value
          ? 'Notifications enabled.'
          : 'Notifications disabled.',
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> showLanguageDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Language'),
          children: [
            RadioListTile<String>(
              value: 'English',
              groupValue: language,
              title: const Text('English'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              value: 'বাংলা',
              groupValue: language,
              title: const Text('বাংলা'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await saveLanguage(selected);
    }
  }

  Future<void> showThemeDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Theme'),
          children: [
            RadioListTile<String>(
              value: 'System Default',
              groupValue: theme,
              title: const Text('System Default'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              value: 'Light',
              groupValue: theme,
              title: const Text('Light'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              value: 'Dark',
              groupValue: theme,
              title: const Text('Dark'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await saveTheme(selected);
    }
  }

  Future<void> showCurrencyDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Currency'),
          children: [
            RadioListTile<String>(
              value: 'BDT (৳)',
              groupValue: currency,
              title: const Text('Bangladeshi Taka (৳)'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              value: 'USD (\$)',
              groupValue: currency,
              title: const Text('US Dollar (\$)'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              value: 'EUR (€)',
              groupValue: currency,
              title: const Text('Euro (€)'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            RadioListTile<String>(
              value: 'GBP (£)',
              groupValue: currency,
              title: const Text('British Pound (£)'),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await saveCurrency(selected);
    }
  }

  void showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline),
              SizedBox(width: 10),
              Text('Privacy'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'LifeMate is designed with privacy in mind.\n\n'
              '• Your personal information is stored locally.\n'
              '• Finance, To-Do, Notes and Events are stored '
              'in the app database.\n'
              '• LifeMate does not require unnecessary personal data.\n'
              '• Backup files are controlled by you.\n'
              '• You can delete your stored information at any time.\n\n'
              'Always keep your backup file in a safe place.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'LifeMate',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.favorite,
        color: Colors.blue,
        size: 36,
      ),
      children: const [
        Text(
          'LifeMate is a personal life management application '
          'designed to help you manage your daily life, '
          'tasks, notes, events, finance, profile and reports '
          'in one place.',
        ),
        SizedBox(height: 16),
        Text(
          'Version 1.0.0',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> openBackup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BackupPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.language),
                  ),
                  title: const Text('Language'),
                  subtitle: Text(language),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: showLanguageDialog,
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.palette_outlined),
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(theme),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: showThemeDialog,
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.currency_exchange),
                  ),
                  title: const Text('Currency'),
                  subtitle: Text(currency),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: showCurrencyDialog,
                ),

                const Divider(height: 1),

                SwitchListTile(
                  secondary: const CircleAvatar(
                    child: Icon(Icons.notifications_outlined),
                  ),
                  title: const Text('Notifications'),
                  subtitle: Text(
                    notifications
                        ? 'Notifications are enabled'
                        : 'Notifications are disabled',
                  ),
                  value: notifications,
                  onChanged: saveNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Data & Privacy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.backup),
                  ),
                  title: const Text('Backup & Restore'),
                  subtitle: const Text(
                    'Create, export and restore your data',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: openBackup,
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.lock_outline),
                  ),
                  title: const Text('Privacy'),
                  subtitle: const Text(
                    'Learn how LifeMate handles your data',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: showPrivacyInfo,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.info_outline),
              ),
              title: const Text('About LifeMate'),
              subtitle: const Text(
                'Version 1.0.0',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: showAbout,
            ),
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'LifeMate • Version 1.0.0',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
