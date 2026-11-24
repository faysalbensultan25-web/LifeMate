import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'email': TextEditingController(),
    'address': TextEditingController(),
    'permanent_address': TextEditingController(),
    'birth_date': TextEditingController(),
    'gender': TextEditingController(),
    'blood_group': TextEditingController(),
    'emergency_contact': TextEditingController(),
    'occupation': TextEditingController(),
    'workplace': TextEditingController(),
    'designation': TextEditingController(),
    'career_objective': TextEditingController(),
    'about': TextEditingController(),
  };

  bool isLoading = true;
  bool isSaving = false;

  int? profileId;
  String? photoPath;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final db = await AppDatabase.database;

      final result = await db.query(
        'profiles',
        orderBy: 'id ASC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        final data = result.first;

        profileId = data['id'] as int?;
        photoPath = data['photo_path'] as String?;

        for (final key in controllers.keys) {
          controllers[key]!.text = data[key]?.toString() ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage('Profile load failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final db = await AppDatabase.database;

      final data = <String, Object?>{
        'name': controllers['name']!.text.trim(),
        'phone': controllers['phone']!.text.trim(),
        'email': controllers['email']!.text.trim(),
        'address': controllers['address']!.text.trim(),
        'permanent_address':
            controllers['permanent_address']!.text.trim(),
        'birth_date': controllers['birth_date']!.text.trim(),
        'gender': controllers['gender']!.text.trim(),
        'blood_group': controllers['blood_group']!.text.trim(),
        'emergency_contact':
            controllers['emergency_contact']!.text.trim(),
        'occupation': controllers['occupation']!.text.trim(),
        'workplace': controllers['workplace']!.text.trim(),
        'designation': controllers['designation']!.text.trim(),
        'career_objective':
            controllers['career_objective']!.text.trim(),
        'about': controllers['about']!.text.trim(),
        'photo_path': photoPath,
      };

      data.removeWhere(
        (key, value) =>
            value == null || (value is String && value.isEmpty),
      );

      if (profileId == null) {
        data['created_at'] = DateTime.now().toIso8601String();

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
      }
    } catch (e) {
      if (mounted) {
        showMessage('Save failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      setState(() {
        photoPath = result.files.single.path;
      });
    } catch (e) {
      showMessage('Could not select photo: $e');
    }
  }

  Future<void> removePhoto() async {
    setState(() {
      photoPath = null;
    });
  }

  Future<void> clearProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Profile?'),
        content: const Text(
          'Do you want to delete your personal profile information? '
          'Education, training and other records will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = await AppDatabase.database;

      if (profileId != null) {
        await db.delete(
          'profiles',
          where: 'id = ?',
          whereArgs: [profileId],
        );
      }

      profileId = null;
      photoPath = null;

      for (final controller in controllers.values) {
        controller.clear();
      }

      if (mounted) {
        setState(() {});
        showMessage('Personal profile cleared.');
      }
    } catch (e) {
      showMessage('Could not clear profile: $e');
    }
  }

  Future<void> selectBirthDate() async {
    final initialDate = DateTime.tryParse(
          controllers['birth_date']!.text,
        ) ??
        DateTime(2000);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      controllers['birth_date']!.text =
          DateFormat('yyyy-MM-dd').format(selected);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
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

  Widget textField(
    String key,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controllers[key],
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget personalInformation() {
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.blue.shade50,
                backgroundImage:
                    photoPath != null && File(photoPath!).existsSync()
                        ? FileImage(File(photoPath!))
                        : null,
                child: photoPath == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blue,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.photo),
                    label: const Text('Change Photo'),
                  ),
                  if (photoPath != null)
                    TextButton(
                      onPressed: removePhoto,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),

        textField('name', 'Full Name'),
        textField(
          'birth_date',
          'Date of Birth',
          readOnly: true,
          onTap: selectBirthDate,
        ),
        textField('gender', 'Gender'),
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
        textField('address', 'Present Address', maxLines: 2),
        textField('permanent_address', 'Permanent Address', maxLines: 2),
        textField('blood_group', 'Blood Group'),
        textField(
          'emergency_contact',
          'Emergency Contact',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget careerInformation() {
    return Column(
      children: [
        textField(
          'career_objective',
          'Career Objective',
          maxLines: 4,
        ),
        textField('occupation', 'Current Occupation'),
        textField('workplace', 'Current Workplace'),
        textField('designation', 'Current Designation'),
        textField('about', 'About Me', maxLines: 4),
      ],
    );
  }

  Widget multiRecordSection({
    required String title,
    required IconData icon,
    required String table,
    required List<RecordField> fields,
    required String titleKey,
  }) {
    return RecordSection(
      title: title,
      icon: icon,
      table: table,
      fields: fields,
      titleKey: titleKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: clearProfile,
            tooltip: 'Clear Personal Profile',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sectionTitle('Personal Information', Icons.person),
            personalInformation(),

            sectionTitle('Career Information', Icons.work),
            careerInformation(),

            const Divider(height: 30),

            multiRecordSection(
              title: 'Education',
              icon: Icons.school,
              table: 'profile_education',
              titleKey: 'qualification',
              fields: [
                RecordField('qualification', 'Degree / Qualification', required: true),
                RecordField('institution', 'Institution'),
                RecordField('subject', 'Subject / Group'),
                RecordField('result', 'Result / GPA'),
                RecordField('passing_year', 'Passing Year'),
                RecordField('start_year', 'Start Year'),
                RecordField('end_year', 'End Year'),
              ],
            ),

            multiRecordSection(
              title: 'Training & Certifications',
              icon: Icons.workspace_premium,
              table: 'profile_training',
              titleKey: 'title',
              fields: [
                RecordField('title', 'Training / Certificate Title', required: true),
                RecordField('institution', 'Training Institute'),
                RecordField('duration', 'Duration'),
                RecordField('completion_year', 'Completion Year'),
                RecordField('certificate_details', 'Certificate Details', multiline: true),
              ],
            ),

            multiRecordSection(
              title: 'Work Experience',
              icon: Icons.business_center,
              table: 'profile_experience',
              titleKey: 'designation',
              fields: [
                RecordField('designation', 'Job Title / Designation', required: true),
                RecordField('workplace', 'Company / Workplace'),
                RecordField('location', 'Job Location'),
                RecordField('employment_type', 'Employment Type'),
                RecordField('start_date', 'Joining Date'),
                RecordField('end_date', 'Ending Date'),
                RecordField('responsibilities', 'Responsibilities', multiline: true),
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
                RecordField('description', 'Description', multiline: true),
                RecordField('achievement_date', 'Date / Year'),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: isSaving ? null : saveProfile,
                icon: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(isSaving ? 'Saving...' : 'Save Profile'),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Record field configuration
class RecordField {
  final String key;
  final String label;
  final bool required;
  final bool multiline;

  const RecordField(
    this.key,
    this.label, {
    this.required = false,
    this.multiline = false,
  });
}

// Reusable multiple-record section
class RecordSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String table;
  final String titleKey;
  final List<RecordField> fields;

  const RecordSection({
    super.key,
    required this.title,
    required this.icon,
    required this.table,
    required this.titleKey,
    required this.fields,
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

  Future<void> loadRecords() async {
    try {
      final db = await AppDatabase.database;

      final result = await db.query(
        widget.table,
        where: 'profile_id = ?',
        whereArgs: [1],
        orderBy: 'id DESC',
      );

      if (mounted) {
        setState(() {
          records = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        showMessage('Could not load ${widget.title}: $e');
      }
    }
  }

  Future<void> openRecordForm({Map<String, Object?>? record}) async {
    final formKey = GlobalKey<FormState>();

    final Map<String, TextEditingController> formControllers = {};

    for (final field in widget.fields) {
      formControllers[field.key] = TextEditingController(
        text: record?[field.key]?.toString() ?? '',
      );
    }

    bool isSaving = false;

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
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final db = await AppDatabase.database;

                            final data = <String, Object?>{
                              'profile_id': 1,
                              'created_at':
                                  DateTime.now().toIso8601String(),
                            };

                            for (final field in widget.fields) {
                              final value =
                                  formControllers[field.key]!.text.trim();

                              data[field.key] =
                                  value.isEmpty ? null : value;
                            }

                            if (record == null) {
                              await db.insert(widget.table, data);
                            } else {
                              data.remove('created_at');

                              await db.update(
                                widget.table,
                                data,
                                where: 'id = ? AND profile_id = ?',
                                whereArgs: [
                                  record['id'],
                                  1,
                                ],
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Save failed: $e'),
                              ),
                            );
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

  Future<void> deleteRecord(Map<String, Object?> record) async {
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
      final db = await AppDatabase.database;

      await db.delete(
        widget.table,
        where: 'id = ? AND profile_id = ?',
        whereArgs: [record['id'], 1],
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
                    .where((field) =>
                        field.key != widget.titleKey &&
                        record[field.key] != null &&
                        record[field.key].toString().isNotEmpty)
                    .map((field) =>
                        '${field.label}: ${record[field.key]}')
                    .join('\n');

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
                    subtitle: subtitle.isEmpty
                        ? null
                        : Text(subtitle),
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
