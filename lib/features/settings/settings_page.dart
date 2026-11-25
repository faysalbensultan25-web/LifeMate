import 'package:flutter/material.dart';

import '../../core/services/backup_service.dart';
import '../../app.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> backup() async {
    try {
      final path = await BackupService.backup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'Backup cancelled' : 'Backup saved successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> restore() async {
    try {
      final ok = await BackupService.restore();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Restore completed successfully' : 'Restore cancelled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),

          ValueListenableBuilder<ThemeMode>(
            valueListenable: lifeMateThemeMode,
            builder: (context, mode, _) {
              return DropdownButtonFormField<ThemeMode>(
                value: mode,
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setLifeMateTheme(value);
                  }
                },
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Language',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: 'English',
            decoration: const InputDecoration(
              labelText: 'App Language',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'English',
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: 'Bangla',
                child: Text('বাংলা'),
              ),
            ],
            onChanged: (_) {},
          ),

          const SizedBox(height: 24),

          const Text(
            'Backup & Restore',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup Data'),
              subtitle: const Text('Save all LifeMate data as a file'),
              trailing: const Icon(Icons.chevron_right),
              onTap: backup,
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore Data'),
              subtitle: const Text('Restore data from a backup file'),
              trailing: const Icon(Icons.chevron_right),
              onTap: restore,
            ),
          ),
        ],
      ),
    );
  }
}
