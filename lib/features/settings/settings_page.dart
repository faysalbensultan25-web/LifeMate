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

    setState(() => language = value);
  }

  Future<void> backup() async {
    try {
      final path = await BackupService.backup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Backup cancelled'
                : 'Backup completed successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
        ),
      );
    }
  }

  Future<void> restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
          'Restoring will replace your existing app data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
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
                ? 'Restore completed successfully'
                : 'Restore cancelled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              trailing: DropdownButton<String>(
                value: theme,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'Light',
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: 'Dark',
                    child: Text('Dark'),
                  ),
                  DropdownMenuItem(
                    value: 'System Default',
                    child: Text('System Default'),
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

          const Text(
            'Language',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('App Language'),
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

          const Text(
            'Currency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Currency'),
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
              title: const Text('Notifications'),
              subtitle: const Text(
                'Enable app notifications',
              ),
              value: notifications,
              onChanged: (value) async {
                setState(() => notifications = value);
                await save('notifications', value);
              },
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Backup & Restore',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.backup_outlined,
              ),
              title: const Text('Backup Data'),
              subtitle: const Text(
                'Save LifeMate data to a file',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: backup,
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.restore_outlined,
              ),
              title: const Text('Restore Data'),
              subtitle: const Text(
                'Restore data from a backup file',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: restore,
            ),
          ),
        ],
      ),
    );
  }
}
