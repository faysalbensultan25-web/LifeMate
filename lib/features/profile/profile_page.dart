
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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

  final List<String> genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();

    const fields = [
      'name',
      'phone',
      'email',
      'address',
      'permanent_address',
      'birth_date',
      'occupation',
      'workplace',
      'designation',
      'emergency_contact',
      'about',
      'career_objective',
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

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> loadProfile() async {
    try {
      final db = await AppDatabase.database;

      final result = await db.query(
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

        photoPath = profile['photo_path']?.toString();

        gender = profile['gender']?.toString() ?? '';
        bloodGroup =
            profile['blood_group']?.toString() ?? '';
      }
    } catch (e) {
      showMessage('Could not load profile: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================================================
  // ENSURE PROFILE ID
  // =========================================================

  Future<int> ensureProfileId() async {
    if (profileId != null) {
      return profileId!;
    }

    final db = await AppDatabase.database;

    final id = await db.insert(
      'profiles',
      {'name': ''},
    );

    profileId = id;

    if (mounted) {
      setState(() {});
    }

    return id;
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> saveProfile() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final db = await AppDatabase.database;

      final data = <String, Object?>{};

      for (final entry in controllers.entries) {
        data[entry.key] = entry.value.text.trim();
      }

      data['gender'] = gender.isEmpty ? null : gender;
      data['blood_group'] =
          bloodGroup.isEmpty ? null : bloodGroup;
      data['photo_path'] = photoPath;

      if (profileId == null) {
        profileId = await db.insert('profiles', data);
      } else {
        await db.update(
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

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  // =========================================================
  // CLEAR PROFILE
  // =========================================================

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
      final db = await AppDatabase.database;

      if (profileId != null) {
        final data = <String, Object?>{};

        for (final entry in controllers.entries) {
          data[entry.key] = '';
        }

        data['gender'] = null;
        data['blood_group'] = null;
        data['photo_path'] = null;

        await db.update(
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

  // =========================================================
  // PICK PROFILE PHOTO
  // =========================================================

  Future<void> pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;

      if (path == null) {
        showMessage('Could not access selected image.');
        return;
      }

      setState(() {
        photoPath = path;
      });
    } catch (e) {
      showMessage('Image selection failed: $e');
    }
  }

  // =========================================================
  // REUSABLE TEXT FIELD
  // =========================================================

  Widget textField(
    String key,
    String label, {
    bool multiline = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controllers[key],
        keyboardType: keyboardType,
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: multiline,
        ),
      ),
    );
  }

  // =========================================================
  // DROPDOWN
  // =========================================================

  Widget dropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  // =========================================================
  // SECTION HEADER
  // =========================================================

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // =========================================================
  // RECORD SECTION BUILDER
  // =========================================================

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

  // =========================================================
  // BUILD
  // =========================================================

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
            // PROFILE PHOTO

            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage:
                        photoPath != null &&
                                File(photoPath!).existsSync()
                            ? FileImage(File(photoPath!))
                            : null,
                    child: photoPath == null ||
                            !File(photoPath!).existsSync()
                        ? const Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.blue,
                          )
                        : null,
                  ),
                  TextButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Choose Profile Photo'),
                  ),
                ],
              ),
            ),

            // PERSONAL INFORMATION

            sectionTitle(
              'Personal Information',
              Icons.person,
            ),

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
              onChanged: (value) {
                setState(() => gender = value);
              },
            ),

            dropdownField(
              label: 'Blood Group',
              value: bloodGroup,
              options: bloodGroups,
              onChanged: (value) {
                setState(() => bloodGroup = value);
              },
            ),

            textField('birth_date', 'Date of Birth'),
            textField('address', 'Present Address'),
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

            // PROFESSIONAL INFORMATION

            sectionTitle(
              'Professional Information',
              Icons.work,
            ),

            textField('occupation', 'Occupation'),
            textField('workplace', 'Workplace'),
            textField('designation', 'Designation'),

            // CAREER OBJECTIVE

            sectionTitle(
              'Career Objective',
              Icons.flag,
            ),

            textField(
              'career_objective',
              'Career Objective',
              multiline: true,
            ),

            // ABOUT

            sectionTitle(
              'About Me',
              Icons.info_outline,
            ),

            textField(
              'about',
              'About Me',
              multiline: true,
            ),

            // EDUCATION

            multiRecordSection(
              title: 'Education',
              icon: Icons.school,
              table: 'profile_education',
              titleKey: 'qualification',
              fields: [
                RecordField(
                  'qualification',
                  'Qualification',
                  required: true,
                ),
                RecordField('institution', 'Institution'),
                RecordField('subject', 'Subject / Group'),
                RecordField('result', 'Result / GPA'),
                RecordField('passing_year', 'Passing Year'),
                RecordField('start_year', 'Start Year'),
                RecordField('end_year', 'End Year'),
              ],
            ),

            // TRAINING

            multiRecordSection(
              title: 'Training',
              icon: Icons.cast_for_education,
              table: 'profile_training',
              titleKey: 'title',
              fields: [
                RecordField(
                  'title',
                  'Training Title',
                  required: true,
                ),
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

            // EXPERIENCE

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

            // SKILLS

            multiRecordSection(
              title: 'Skills',
              icon: Icons.psychology,
              table: 'profile_skills',
              titleKey: 'skill_name',
              fields: [
                RecordField(
                  'skill_name',
                  'Skill Name',
                  required: true,
                ),
                RecordField('proficiency', 'Proficiency'),
              ],
            ),

            // LANGUAGES

            multiRecordSection(
              title: 'Languages',
              icon: Icons.language,
              table: 'profile_languages',
              titleKey: 'language_name',
              fields: [
                RecordField(
                  'language_name',
                  'Language',
                  required: true,
                ),
                RecordField('proficiency', 'Proficiency'),
              ],
            ),

            // ACHIEVEMENTS

            multiRecordSection(
              title: 'Achievements',
              icon: Icons.emoji_events,
              table: 'profile_achievements',
              titleKey: 'title',
              fields: [
                RecordField(
                  'title',
                  'Achievement Title',
                  required: true,
                ),
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

// ============================================================
// RECORD FIELD MODEL
// ============================================================

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

// ============================================================
// MULTIPLE RECORD SECTION
// ============================================================

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

  // LOAD

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
      final db = await AppDatabase.database;

      final result = await db.query(
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

  // ADD / EDIT

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
                      : () {
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final db = await AppDatabase.database;
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

                              await db.insert(widget.table, data);
                            } else {
                              await db.update(
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
                            setDialogState(() {
                              isSaving = false;
                            });

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

  // DELETE

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
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = await AppDatabase.database;
      final id = widget.profileId;

      if (id == null) return;

      await db.delete(
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

  // MESSAGE

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // BUILD

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
              const Center(
                child: CircularProgressIndicator(),
              )
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
                    .map((field) =>
                        '${field.label}: ${record[field.key]}')
                    .join('\n');

                final isCurrent = record['is_current'] == 1;

                return Card(
                  color: Colors.grey.shade50,
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
                        if (subtitle.isNotEmpty)
                          Text(subtitle),
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
