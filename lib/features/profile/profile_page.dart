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
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final permanentAddressController = TextEditingController();
  final educationController = TextEditingController();
  final occupationController = TextEditingController();
  final workplaceController = TextEditingController();
  final designationController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final aboutController = TextEditingController();

  int? profileId;

  String? birthDate;
  String? gender;
  String? bloodGroup;
  String? photoPath;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'profiles',
      orderBy: 'id ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final profile = result.first;

      profileId = profile['id'] as int?;

      nameController.text = profile['name']?.toString() ?? '';
      phoneController.text = profile['phone']?.toString() ?? '';
      emailController.text = profile['email']?.toString() ?? '';
      addressController.text = profile['address']?.toString() ?? '';
      permanentAddressController.text =
          profile['permanent_address']?.toString() ?? '';
      educationController.text =
          profile['education']?.toString() ?? '';
      occupationController.text =
          profile['occupation']?.toString() ?? '';
      workplaceController.text =
          profile['workplace']?.toString() ?? '';
      designationController.text =
          profile['designation']?.toString() ?? '';
      emergencyContactController.text =
          profile['emergency_contact']?.toString() ?? '';
      aboutController.text = profile['about']?.toString() ?? '';

      birthDate = profile['birth_date']?.toString();
      gender = profile['gender']?.toString();
      bloodGroup = profile['blood_group']?.toString();
      photoPath = profile['photo_path']?.toString();

      if (photoPath != null && photoPath!.isEmpty) {
        photoPath = null;
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> selectPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selectedPath = result.files.single.path;

    if (selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    setState(() {
      photoPath = selectedPath;
    });
  }

  Future<void> selectBirthDate() async {
    DateTime initialDate = DateTime(2000);

    if (birthDate != null && birthDate!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(birthDate!);
      } catch (_) {}
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) return;

    setState(() {
      birthDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    });
  }

  String formattedBirthDate() {
    if (birthDate == null || birthDate!.isEmpty) {
      return 'Select birth date';
    }

    try {
      final date = DateTime.parse(birthDate!);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (_) {
      return birthDate!;
    }
  }

  Future<void> saveProfile() async {
    final db = await AppDatabase.database;

    final data = {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'address': addressController.text.trim(),
      'photo_path': photoPath,
      'birth_date': birthDate,
      'gender': gender,
      'permanent_address':
          permanentAddressController.text.trim(),
      'education': educationController.text.trim(),
      'occupation': occupationController.text.trim(),
      'workplace': workplaceController.text.trim(),
      'designation': designationController.text.trim(),
      'blood_group': bloodGroup,
      'emergency_contact':
          emergencyContactController.text.trim(),
      'about': aboutController.text.trim(),
    };

    final hasData = data.values.any(
      (value) => value != null && value.toString().trim().isNotEmpty,
    );

    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one profile detail'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (profileId == null) {
        profileId = await db.insert(
          'profiles',
          data,
        );
      } else {
        await db.update(
          'profiles',
          data,
          where: 'id = ?',
          whereArgs: [profileId],
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
        ),
      );

      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> clearProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Profile'),
          content: const Text(
            'Are you sure you want to delete all profile information?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final db = await AppDatabase.database;

    if (profileId != null) {
      await db.delete(
        'profiles',
        where: 'id = ?',
        whereArgs: [profileId],
      );
    }

    nameController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    permanentAddressController.clear();
    educationController.clear();
    occupationController.clear();
    workplaceController.clear();
    designationController.clear();
    emergencyContactController.clear();
    aboutController.clear();

    setState(() {
      profileId = null;
      birthDate = null;
      gender = null;
      bloodGroup = null;
      photoPath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile information cleared'),
      ),
    );
  }

  Widget textField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
         
