
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Map<String, TextEditingController> controllers = {};

  int? profileId;
  String? photoPath;
  String gender = '';
  String bloodGroup = '';

  bool isLoading = true;
  bool isSaving = false;
  bool isPickingPhoto = false;
  bool isLoadingContacts = false;

  List<Map<String, Object?>> socialLinks = [];
  List<Map<String, Object?>> importantContacts = [];
  List<Map<String, Object?>> customDesignations = [];

  String socialSearch = '';

  DateTime calendarMonth = DateTime.now();

  final List<String> genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  final List<String> occupationOptions = [
    'Student',
    'Teacher',
    'Government Employee',
    'Private Employee',
    'Business Owner',
    'Self Employed',
    'Farmer',
    'Freelancer',
    'Homemaker',
    'Unemployed',
  ];

  final List<String> designationOptions = [
    'Student',
    'Assistant',
    'Officer',
    'Senior Officer',
    'Manager',
    'Assistant Manager',
    'Executive',
    'Director',
    'Owner',
    'Other',
  ];

  final List<String> socialPlatforms = [
    'Facebook',
    'LinkedIn',
    'GitHub',
    'Instagram',
    'YouTube',
    'TikTok',
    'Twitter / X',
    'WhatsApp',
    'Telegram',
    'Pinterest',
    'Other',
  ];

  final Map<String, List<String>> templates = {
    'career_objective': [
      'To build a successful career through honesty, hard work, continuous learning and professional development.',
      'To use my knowledge, skills and experience to contribute positively to an organization and society.',
      'To achieve professional growth by accepting responsibilities, learning new skills and working with dedication.',
    ],
    'about': [
      'I am a hardworking, responsible and honest person. I enjoy learning new things and improving my skills.',
      'I am a positive-minded person who values discipline, family, honesty and continuous personal development.',
      'I believe in hard work, responsibility and respect. I always try to learn from experience and do my best.',
    ],
  };

  @override
  void initState() {
    super.initState();

    const fields = [
      'name',
      'phone',
      'email',
      'address',
      'location',
      'permanent_address',
      'birth_date',
      'occupation',
      'workplace',
      'designation',
      'emergency_contact',
      'about',
      'career_objective',
      'facebook',
      'linkedin',
      'github',
      'website',
    ];

    for (final field in fields) {
      controllers[field] = TextEditingController();
    }

    loadProfile();
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<Database> get db async => AppDatabase.database;

  Future<Directory> _photoDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(appDirectory.path, 'profile_photos'),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> _copyPhotoToPermanentStorage(
    String sourcePath,
  ) async {
    final source = File(sourcePath);

    if (!await source.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final directory = await _photoDirectory();

    var extension = p.extension(sourcePath).toLowerCase();

    if (extension.isEmpty || extension.length > 10) {
      extension = '.jpg';
    }

    final fileName =
        'profile_${DateTime.now().microsecondsSinceEpoch}$extension';

    final destination = File(p.join(directory.path, fileName));

    await source.copy(destination.path);

    return destination.path;
  }

  Future<String?> _migrateOldPhotoPath(String? oldPath) async {
    if (oldPath == null || oldPath.trim().isEmpty) {
      return null;
    }

    try {
      final oldFile = File(oldPath);

      if (!await oldFile.exists()) return null;

      final directory = await _photoDirectory();
      final permanentDirectoryPath = p.normalize(directory.path);
      final oldNormalizedPath = p.normalize(oldFile.path);

      if (p.isWithin(permanentDirectoryPath, oldNormalizedPath)) {
        return oldFile.path;
      }

      return await _copyPhotoToPermanentStorage(oldFile.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProfile() async {
    try {
      final database = await db;

      final result = await database.query(
        'profiles',
        limit: 1,
        orderBy: 'id ASC',
      );

      if (result.isNotEmpty) {
        final profile = result.first;
        profileId = profile['id'] as int?;

        for (final entry in controllers.entries) {
          entry.value.text =
              profile[entry.key]?.toString() ?? '';
        }

        gender = profile['gender']?.toString() ?? '';
        bloodGroup = profile['blood_group']?.toString() ?? '';

        final oldPath = profile['photo_path']?.toString();
        final permanentPath = await _migrateOldPhotoPath(oldPath);

        photoPath = permanentPath;

        if (profileId != null && oldPath != permanentPath) {
          await database.update(
            'profiles',
            {'photo_path': permanentPath},
            where: 'id = ?',
            whereArgs: [profileId],
          );
        }

        await loadExtraProfileData();
      }
    } catch (e) {
      showMessage('Could not load profile: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadExtraProfileData() async {
    if (profileId == null) return;

    final database = await db;

    socialLinks = await database.query(
      'profile_social_links',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'id DESC',
    );

    importantContacts = await database.query(
      'profile_important_contacts',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'id DESC',
    );

    customDesignations = await database.query(
      'profile_designations',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'title COLLATE NOCASE ASC',
    );

    if (mounted) setState(() {});
  }

  Future<int> ensureProfileId() async {
    if (profileId != null) return profileId!;

    final database = await db;
    final id = await database.insert(
      'profiles',
      {'name': ''},
    );

    profileId = id;

    if (mounted) setState(() {});

    return id;
  }

  Future<void> saveProfile() async {
    if (isSaving) return;

    setState(() => isSaving = true);

    try {
      final database = await db;
      final data = <String, Object?>{};

      for (final entry in controllers.entries) {
        data[entry.key] = entry.value.text.trim();
      }

      data['gender'] = gender.isEmpty ? null : gender;
      data['blood_group'] =
          bloodGroup.isEmpty ? null : bloodGroup;
      data['photo_path'] = photoPath;

      if (profileId == null) {
        profileId = await database.insert('profiles', data);
      } else {
        await database.update(
          'profiles',
          data,
          where: 'id = ?',
          whereArgs: [profileId],
        );
      }

      if (mounted) {
        showMessage('Profile saved successfully.');
        setState(() {});
      }
    } catch (e) {
      showMessage('Profile save failed: $e');
    }

    if (mounted) setState(() => isSaving = false);
  }

  Future<void> clearProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Profile?'),
        content: const Text(
          'This will clear your personal information. '
          'Your Education, Training, Experience and other '
          'records will remain saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final database = await db;

      if (profileId != null) {
        final data = <String, Object?>{};

        for (final entry in controllers.entries) {
          data[entry.key] = '';
        }

        data['gender'] = null;
        data['blood_group'] = null;
        data['photo_path'] = null;

        await database.update(
          'profiles',
          data,
          where: 'id = ?',
          whereArgs: [profileId],
        );
      }

      for (final controller in controllers.values) {
        controller.clear();
      }

      setState(() {
        photoPath = null;
        gender = '';
        bloodGroup = '';
      });

      showMessage('Personal information cleared.');
    } catch (e) {
      showMessage('Could not clear profile: $e');
    }
  }

  Future<void> pickPhoto() async {
    if (isPickingPhoto) return;

    setState(() => isPickingPhoto = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final sourcePath = result.files.single.path;

      if (sourcePath == null) {
        showMessage('Could not access selected image.');
        return;
      }

      final permanentPath =
          await _copyPhotoToPermanentStorage(sourcePath);

      final database = await db;
      final id = await ensureProfileId();

      await database.update(
        'profiles',
        {'photo_path': permanentPath},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (!mounted) return;

      setState(() => photoPath = permanentPath);

      showMessage('Profile photo saved permanently.');
    } catch (e) {
      showMessage('Image selection failed: $e');
    } finally {
      if (mounted) {
        setState(() => isPickingPhoto = false);
      }
    }
  }

  Widget textField(
    String key,
    String label, {
    bool multiline = false,
    TextInputType? keyboardType,
    TextCapitalization? capitalization,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controllers[key],
        keyboardType: keyboardType,
        textCapitalization: capitalization ??
            (keyboardType == TextInputType.emailAddress ||
                    keyboardType == TextInputType.phone ||
                    keyboardType == TextInputType.url
                ? TextCapitalization.none
                : TextCapitalization.sentences),
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: multiline,
        ),
      ),
    );
  }

  Widget dropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final items = [...options];

    if (value.isNotEmpty && !items.contains(value)) {
      items.insert(0, value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }

  Widget profileDropdown(
    String key,
    String label,
    List<String> options,
  ) {
    final currentValue = controllers[key]!.text;
    final items = [...options];

    for (final designation in customDesignations) {
      final title = designation['title']?.toString() ?? '';
      if (title.isNotEmpty && !items.contains(title)) {
        items.add(title);
      }
    }

    if (currentValue.isNotEmpty && !items.contains(currentValue)) {
      items.insert(0, currentValue);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: currentValue.isEmpty ? null : currentValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  controllers[key]!.text = value;
                });
              }
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: addCustomDesignation,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Custom Designation'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addCustomDesignation() async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Designation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Custom Designation',
            hintText: 'e.g. Head Teacher',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogContext, text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value.isEmpty) return;

    try {
      final id = await ensureProfileId();
      final database = await db;

      final existing = await database.query(
        'profile_designations',
        where: 'profile_id = ? AND title = ?',
        whereArgs: [id, value],
      );

      if (existing.isEmpty) {
        await database.insert('profile_designations', {
          'profile_id': id,
          'title': value,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await loadExtraProfileData();

      setState(() {
        controllers['designation']!.text = value;
      });

      showMessage('Designation added.');
    } catch (e) {
      showMessage('Could not add designation: $e');
    }
  }

  Widget templateField(String key, String label) {
    final options = templates[key]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            PopupMenuButton<int>(
              tooltip: 'Choose a template',
              icon: const Icon(Icons.auto_awesome),
              onSelected: (index) {
                setState(() {
                  controllers[key]!.text = options[index];
                });
              },
              itemBuilder: (context) => List.generate(
                options.length,
                (index) => PopupMenuItem(
                  value: index,
                  child: SizedBox(
                    width: 230,
                    child: Text('Template ${index + 1}'),
                  ),
                ),
              ),
            ),
          ],
        ),
        textField(key, label, multiline: true),
      ],
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Birthday date picker and calendar

  DateTime? get birthday {
    final value = controllers['birth_date']!.text.trim();
    if (value.isEmpty) return null;

    try {
      return DateTime.parse(value);
    } catch (_) {
      try {
        return DateFormat('dd-MM-yyyy').parseStrict(value);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> pickBirthday() async {
    final existing = birthday;
    final selected = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (selected == null) return;

    setState(() {
      controllers['birth_date']!.text =
          DateFormat('yyyy-MM-dd').format(selected);
    });
  }

  Widget birthdayCalendar() {
    final birth = birthday;
    final firstDay = DateTime(
      calendarMonth.year,
      calendarMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      calendarMonth.year,
      calendarMonth.month,
    );
    final offset = firstDay.weekday % 7;

    final cells = <Widget>[];

    for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      cells.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final isBirthday = birth != null && birth.day == day;
      final isToday = DateUtils.isSameDay(
        DateTime.now(),
        DateTime(calendarMonth.year, calendarMonth.month, day),
      );

      cells.add(
        Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isBirthday
                ? Colors.pink.withValues(alpha: 0.2)
                : isToday
                    ? Colors.blue.withValues(alpha: 0.15)
                    : null,
            shape: BoxShape.circle,
            border: isBirthday
                ? Border.all(color: Colors.pink, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: isBirthday || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isBirthday ? Colors.pink : null,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.cake, color: Colors.pink),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Birthday Calendar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      calendarMonth = DateTime(
                        calendarMonth.year,
                        calendarMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('MMM yyyy').format(calendarMonth),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      calendarMonth = DateTime(
                        calendarMonth.year,
                        calendarMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cells,
            ),
            if (birth != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Birthday: ${DateFormat('dd MMMM').format(birth)}',
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Text(
                'Add your date of birth to see your birthday.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // Map location picker

  LatLng get currentMapLocation {
    final value = controllers['location']!.text.trim();
    final parts = value.split(',');

    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }

    return const LatLng(23.8103, 90.4125);
  }

  Future<void> openLocationPicker() async {
    LatLng selected = currentMapLocation;

    final result = await showDialog<LatLng>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Choose Profile Location'),
              contentPadding: const EdgeInsets.all(12),
              content: SizedBox(
                width: 500,
                height: 430,
                child: Column(
                  children: [
                    const Text(
                      'Tap anywhere on the map to select your location.',
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: selected,
                          initialZoom: 12,
                          onTap: (tapPosition, point) {
                            setDialogState(() {
                              selected = point;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selected,
                                width: 45,
                                height: 45,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 42,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${selected.latitude.toStringAsFixed(6)}, '
                      '${selected.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext, selected);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Select Location'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      controllers['location']!.text =
          '${result.latitude.toStringAsFixed(6)}, '
          '${result.longitude.toStringAsFixed(6)}';
    });

    showMessage('Location selected. Save your profile to keep it.');
  }

  // Social links

  Future<void> openSocialLinkForm({
    Map<String, Object?>? link,
  }) async {
    final platformController = TextEditingController(
      text: link?['platform']?.toString() ?? '',
    );
    final urlController = TextEditingController(
      text: link?['url']?.toString() ?? '',
    );
    final labelController = TextEditingController(
      text: link?['label']?.toString() ?? '',
    );

    String search = '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final suggestions = socialPlatforms
                .where(
                  (item) => item.toLowerCase().contains(
                        search.toLowerCase(),
                      ),
                )
                .toList();

            return AlertDialog(
              title: Text(
                link == null ? 'Add Social Link' : 'Edit Social Link',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: platformController,
                        decoration: const InputDecoration(
                          labelText: 'Platform',
                          hintText: 'Search or enter a platform',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setDialogState(() => search = value);
                        },
                      ),
                      if (suggestions.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: suggestions.map((item) {
                            return ActionChip(
                              label: Text(item),
                              onPressed: () {
                                platformController.text = item;
                                setDialogState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Profile URL',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (platformController.text.trim().isEmpty ||
                        urlController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        final id = await ensureProfileId();
        final database = await db;

        final data = {
          'profile_id': id,
          'platform': platformController.text.trim(),
          'label': labelController.text.trim(),
          'url': urlController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        if (link == null) {
          await database.insert('profile_social_links', data);
        } else {
          await database.update(
            'profile_social_links',
            data,
            where: 'id = ? AND profile_id = ?',
            whereArgs: [link['id'], id],
          );
        }

        await loadExtraProfileData();
        showMessage('Social link saved.');
      } catch (e) {
        showMessage('Could not save social link: $e');
      }
    }

    platformController.dispose();
    urlController.dispose();
    labelController.dispose();
  }

  Future<void> deleteSocialLink(
    Map<String, Object?> link,
  ) async {
    final database = await db;

    await database.delete(
      'profile_social_links',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [link['id'], profileId],
    );

    await loadExtraProfileData();
    showMessage('Social link deleted.');
  }

  Widget socialLinksSection() {
    final filtered = socialLinks.where((link) {
      final text =
          '${link['platform']} ${link['label']} ${link['url']}';
      return text.toLowerCase().contains(
            socialSearch.toLowerCase(),
          );
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: Colors.blue),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Social Links',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => openSocialLinkForm(),
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search social links',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => socialSearch = value);
              },
            ),
            const SizedBox(height: 8),
            ...filtered.map((link) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.public),
                ),
                title: Text(
                  link['label']?.toString().isNotEmpty == true
                      ? link['label'].toString()
                      : link['platform'].toString(),
                ),
                subtitle: Text(
                  link['url']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      openSocialLinkForm(link: link);
                    } else if (value == 'delete') {
                      deleteSocialLink(link);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            }),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No social links added yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Important contacts

  Future<void> pickImportantContact() async {
    if (isLoadingContacts) return;

    setState(() => isLoadingContacts = true);

    try {
      final permission =
          await FlutterContacts.requestPermission(readonly: true);

      if (!permission) {
        showMessage('Contacts permission was not granted.');
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      if (!mounted) return;

      if (contacts.isEmpty) {
        showMessage('No contacts found on your phone.');
        return;
      }

      final selected = await showDialog<Contact>(
        context: context,
        builder: (dialogContext) {
          String query = '';

          return StatefulBuilder(
            builder: (context, setDialogState) {
              final filtered = contacts.where((contact) {
                final phoneText = contact.phones
                    .map((phone) => phone.number)
                    .join(' ');

                return '${contact.displayName} $phoneText'
                    .toLowerCase()
                    .contains(query.toLowerCase());
              }).toList();

              return AlertDialog(
                title: const Text('Select Important Contact'),
                content: SizedBox(
                  width: 420,
                  height: 420,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search contacts',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setDialogState(() => query = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final contact = filtered[index];
                            final phone = contact.phones.isNotEmpty
                                ? contact.phones.first.number
                                : '';

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(contact.displayName),
                              subtitle: Text(
                                phone.isEmpty
                                    ? 'No phone number'
                                    : phone,
                              ),
                              enabled: phone.isNotEmpty,
                              onTap: () {
                                Navigator.pop(
                                  dialogContext,
                                  contact,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selected == null) return;

      if (selected.phones.isEmpty) {
        showMessage('This contact has no phone number.');
        return;
      }

      final phone = selected.phones.first.number;
      final relationController = TextEditingController();

      final relation = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Contact Relationship'),
          content: TextField(
            controller: relationController,
            decoration: const InputDecoration(
              labelText: 'Relationship (Optional)',
              hintText: 'e.g. Father, Friend, Doctor',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                relationController.text.trim(),
              ),
              child: const Text('Add Contact'),
            ),
          ],
        ),
      );

      relationController.dispose();

      if (relation == null) return;

      final id = await ensureProfileId();
      final database = await db;

      await database.insert('profile_important_contacts', {
        'profile_id': id,
        'name': selected.displayName,
        'phone': phone,
        'relation': relation,
        'created_at': DateTime.now().toIso8601String(),
      });

      await loadExtraProfileData();
      showMessage('Important contact added.');
    } catch (e) {
      showMessage('Could not access contacts: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingContacts = false);
      }
    }
  }

  Future<void> deleteImportantContact(
    Map<String, Object?> contact,
  ) async {
    final database = await db;

    await database.delete(
      'profile_important_contacts',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [contact['id'], profileId],
    );

    await loadExtraProfileData();
    showMessage('Contact removed.');
  }

  Widget importantContactsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.contacts, color: Colors.blue),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Important Contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      isLoadingContacts ? null : pickImportantContact,
                  icon: isLoadingContacts
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.blue,
                        ),
                ),
              ],
            ),
            ...importantContacts.map((contact) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(contact['name']?.toString() ?? ''),
                subtitle: Text(
                  '${contact['phone'] ?? ''}'
                  '${contact['relation'] == null || contact['relation'] == ''
                      ? ''
                      : ' • ${contact['relation']}'}',
                ),
                trailing: IconButton(
                  onPressed: () => deleteImportantContact(contact),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              );
            }),
            if (importantContacts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Select important numbers from your phone contacts.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget locationField() {
    return Column(
      children: [
        textField('location', 'Location / Coordinates'),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: openLocationPicker,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Select Location from Map'),
          ),
        ),
      ],
    );
  }

  Widget birthdayField() {
    return Column(
      children: [
        TextFormField(
          controller: controllers['birth_date'],
          readOnly: true,
          onTap: pickBirthday,
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: pickBirthday,
              icon: const Icon(Icons.calendar_month),
            ),
          ),
        ),
        const SizedBox(height: 12),
        birthdayCalendar(),
      ],
    );
  }

  Widget multiRecordSection({
    required String title,
    required IconData icon,
    required String table,
    required String titleKey,
    required List<RecordField> fields,
  }) {
    return RecordSection(
      title: title,
      icon: icon,
      table: table,
      titleKey: titleKey,
      fields: fields,
      profileId: profileId,
      onEnsureProfileId: ensureProfileId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasPhoto =
        photoPath != null && File(photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: clearProfile,
            tooltip: 'Clear Profile',
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: hasPhoto
                        ? FileImage(File(photoPath!))
                        : null,
                    child: !hasPhoto
                        ? const Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.blue,
                          )
                        : null,
                  ),
                  TextButton.icon(
                    onPressed: isPickingPhoto ? null : pickPhoto,
                    icon: isPickingPhoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      isPickingPhoto
                          ? 'Saving Photo...'
                          : 'Choose Profile Photo',
                    ),
                  ),
                ],
              ),
            ),

            sectionTitle('Personal Information', Icons.person),

            textField('name', 'Full Name'),
            textField(
              'phone',
              'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            textField(
              'email',
              'Email Address',
              keyboardType: TextInputType.emailAddress,
            ),

            dropdownField(
              label: 'Gender',
              value: gender,
              options: genderOptions,
              onChanged: (value) => setState(() => gender = value),
            ),

            dropdownField(
              label: 'Blood Group',
              value: bloodGroup,
              options: bloodGroups,
              onChanged: (value) =>
                  setState(() => bloodGroup = value),
            ),

            birthdayField(),

            const SizedBox(height: 12),

            textField('address', 'Present Address', multiline: true),
            locationField(),

            textField(
              'permanent_address',
              'Permanent Address',
              multiline: true,
            ),

            textField(
              'emergency_contact',
              'Emergency Contact',
              keyboardType: TextInputType.phone,
            ),

            importantContactsSection(),

            sectionTitle('Professional Information', Icons.work),

            profileDropdown(
              'occupation',
              'Occupation',
              occupationOptions,
            ),

            textField('workplace', 'Workplace'),

            profileDropdown(
              'designation',
              'Designation',
              designationOptions,
            ),

            sectionTitle('Career Objective', Icons.flag),
            templateField('career_objective', 'Career Objective'),

            sectionTitle('About Me', Icons.info_outline),
            templateField('about', 'About Me'),

            sectionTitle('Social Links', Icons.link),

            textField(
              'facebook',
              'Facebook URL',
              keyboardType: TextInputType.url,
              capitalization: TextCapitalization.none,
            ),
            textField(
              'linkedin',
              'LinkedIn URL',
              keyboardType: TextInputType.url,
              capitalization: TextCapitalization.none,
            ),
            textField(
              'github',
              'GitHub URL',
              keyboardType: TextInputType.url,
              capitalization: TextCapitalization.none,
            ),
            textField(
              'website',
              'Website URL',
              keyboardType: TextInputType.url,
              capitalization: TextCapitalization.none,
            ),

            socialLinksSection(),

            multiRecordSection(
              title: 'Education',
              icon: Icons.school,
              table: 'profile_education',
              titleKey: 'qualification',
              fields: [
                RecordField('qualification', 'Qualification', required: true),
                RecordField('institution', 'Institution'),
                RecordField('subject', 'Subject / Group'),
                RecordField('result', 'Result / GPA'),
                RecordField('passing_year', 'Passing Year'),
                RecordField('start_year', 'Start Year'),
                RecordField('end_year', 'End Year'),
              ],
            ),

            multiRecordSection(
              title: 'Training',
              icon: Icons.cast_for_education,
              table: 'profile_training',
              titleKey: 'title',
              fields: [
                RecordField('title', 'Training Title', required: true),
                RecordField('institution', 'Training Institution'),
                RecordField('duration', 'Duration'),
                RecordField('completion_year', 'Completion Year'),
                RecordField(
                  'certificate_details',
                  'Certificate Details',
                  multiline: true,
                ),
              ],
            ),

            multiRecordSection(
              title: 'Work Experience',
              icon: Icons.business_center,
              table: 'profile_experience',
              titleKey: 'designation',
              fields: [
                RecordField(
                  'designation',
                  'Job Title / Designation',
                  required: true,
                ),
                RecordField('workplace', 'Company / Workplace'),
                RecordField('location', 'Job Location'),
                RecordField('employment_type', 'Employment Type'),
                RecordField('start_date', 'Joining Date'),
                RecordField('end_date', 'Ending Date'),
                RecordField(
                  'responsibilities',
                  'Responsibilities',
                  multiline: true,
                ),
                RecordField(
                  'is_current',
                  'Currently Working Here',
                  isSwitch: true,
                ),
              ],
            ),

            multiRecordSection(
              title: 'Skills',
              icon: Icons.psychology,
              table: 'profile_skills',
              titleKey: 'skill_name',
              fields: [
                RecordField('skill_name', 'Skill Name', required: true),
                RecordField('proficiency', 'Proficiency'),
              ],
            ),

            multiRecordSection(
              title: 'Languages',
              icon: Icons.language,
              table: 'profile_languages',
              titleKey: 'language_name',
              fields: [
                RecordField('language_name', 'Language', required: true),
                RecordField('proficiency', 'Proficiency'),
              ],
            ),

            multiRecordSection(
              title: 'Achievements',
              icon: Icons.emoji_events,
              table: 'profile_achievements',
              titleKey: 'title',
              fields: [
                RecordField('title', 'Achievement Title', required: true),
                RecordField(
                  'description',
                  'Description',
                  multiline: true,
                ),
                RecordField('achievement_date', 'Date / Year'),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: isSaving ? null : saveProfile,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Profile',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class RecordField {
  final String key;
  final String label;
  final bool required;
  final bool multiline;
  final bool isSwitch;

  const RecordField(
    this.key,
    this.label, {
    this.required = false,
    this.multiline = false,
    this.isSwitch = false,
  });
}

class RecordSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String table;
  final String titleKey;
  final List<RecordField> fields;
  final int? profileId;
  final Future<int> Function() onEnsureProfileId;

  const RecordSection({
    super.key,
    required this.title,
    required this.icon,
    required this.table,
    required this.titleKey,
    required this.fields,
    required this.profileId,
    required this.onEnsureProfileId,
  });

  @override
  State<RecordSection> createState() => _RecordSectionState();
}

class _RecordSectionState extends State<RecordSection> {
  List<Map<String, Object?>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  @override
  void didUpdateWidget(covariant RecordSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profileId != widget.profileId) {
      loadRecords();
    }
  }

  Future<void> loadRecords() async {
    final id = widget.profileId;

    if (id == null) {
      if (mounted) {
        setState(() {
          records = [];
          isLoading = false;
        });
      }
      return;
    }

    try {
      final database = await AppDatabase.database;

      final result = await database.query(
        widget.table,
        where: 'profile_id = ?',
        whereArgs: [id],
        orderBy: 'id DESC',
      );

      if (!mounted) return;

      setState(() {
        records = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Could not load records: $e');
    }
  }

  Future<void> openRecordForm({
    Map<String, Object?>? record,
  }) async {
    final formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> formControllers = {};

    for (final field in widget.fields) {
      formControllers[field.key] = TextEditingController(
        text: record?[field.key]?.toString() ?? '',
      );
    }

    bool isSaving = false;
    bool currentlyWorking = record?['is_current'] == 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                record == null
                    ? 'Add ${widget.title}'
                    : 'Edit ${widget.title}',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.fields.map((field) {
                        if (field.isSwitch) {
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(field.label),
                            value: currentlyWorking,
                            onChanged: (value) {
                              setDialogState(() {
                                currentlyWorking = value;
                              });
                            },
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: formControllers[field.key],
                            textCapitalization:
                                TextCapitalization.sentences,
                            maxLines: field.multiline ? 4 : 1,
                            decoration: InputDecoration(
                              labelText: field.label,
                              border: const OutlineInputBorder(),
                            ),
                            validator: field.required
                                ? (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'This field is required';
                                    }
                                    return null;
                                  }
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            final database = await AppDatabase.database;
                            final id =
                                await widget.onEnsureProfileId();

                            final data = <String, Object?>{};

                            for (final field in widget.fields) {
                              if (field.isSwitch) {
                                data[field.key] =
                                    currentlyWorking ? 1 : 0;
                              } else {
                                final value =
                                    formControllers[field.key]!
                                        .text
                                        .trim();

                                data[field.key] =
                                    value.isEmpty ? null : value;
                              }
                            }

                            if (widget.table ==
                                    'profile_experience' &&
                                currentlyWorking) {
                              data['end_date'] = null;
                            }

                            if (record == null) {
                              data['profile_id'] = id;
                              data['created_at'] =
                                  DateTime.now().toIso8601String();

                              await database.insert(widget.table, data);
                            } else {
                              await database.update(
                                widget.table,
                                data,
                                where: 'id = ? AND profile_id = ?',
                                whereArgs: [record['id'], id],
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text('Save failed: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in formControllers.values) {
      controller.dispose();
    }

    if (saved == true) {
      await loadRecords();
    }
  }

  Future<void> deleteRecord(
    Map<String, Object?> record,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text(
          'Delete this ${widget.title.toLowerCase()} record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final database = await AppDatabase.database;
      final id = widget.profileId;

      if (id == null) return;

      await database.delete(
        widget.table,
        where: 'id = ? AND profile_id = ?',
        whereArgs: [record['id'], id],
      );

      await loadRecords();
      showMessage('Record deleted.');
    } catch (e) {
      showMessage('Delete failed: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => openRecordForm(),
                  tooltip: 'Add ${widget.title}',
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No records added yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...records.map((record) {
                final title =
                    record[widget.titleKey]?.toString() ?? '';

                final subtitle = widget.fields
                    .where((field) {
                      if (field.key == widget.titleKey ||
                          field.isSwitch) {
                        return false;
                      }

                      final value = record[field.key];

                      return value != null &&
                          value.toString().trim().isNotEmpty;
                    })
                    .map(
                      (field) =>
                          '${field.label}: ${record[field.key]}',
                    )
                    .join('\n');

                final isCurrent = record['is_current'] == 1;

                return Card(
                  color: Theme.of(context).brightness ==
                          Brightness.dark
                      ? null
                      : Colors.grey.shade50,
                  elevation: 0,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitle.isNotEmpty) Text(subtitle),
                        if (isCurrent)
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              'Currently working here',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: subtitle.contains('\n'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          openRecordForm(record: record);
                        } else if (value == 'delete') {
                          deleteRecord(record);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
