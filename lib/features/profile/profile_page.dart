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
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF1877F2),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 12,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget profilePhoto() {
    final hasPhoto =
        photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync();

    return Stack(
      children: [
        CircleAvatar(
          radius: 58,
          backgroundColor: const Color(0xFFE7F0FF),
          backgroundImage:
              hasPhoto ? FileImage(File(photoPath!)) : null,
          child: hasPhoto
              ? null
              : const Icon(
                  Icons.person,
                  size: 65,
                  color: Color(0xFF1877F2),
                ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: const Color(0xFF1877F2),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: selectPhoto,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    permanentAddressController.dispose();
    educationController.dispose();
    occupationController.dispose();
    workplaceController.dispose();
    designationController.dispose();
    emergencyContactController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (profileId != null)
            IconButton(
              onPressed: clearProfile,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Profile',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  profilePhoto(),

                  const SizedBox(height: 12),

                  const Text(
                    'Personal Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'All profile information is optional.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 25),

                  sectionTitle('Basic Information'),

                  textField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline,
                    controller: nameController,
                  ),

                  InkWell(
                    onTap: selectBirthDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Birth Date',
                        prefixIcon: const Icon(
                          Icons.cake_outlined,
                          color: Color(0xFF1877F2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        formattedBirthDate(),
                        style: TextStyle(
                          color: birthDate == null
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(
                        Icons.wc_outlined,
                        color: Color(0xFF1877F2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Male',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem(
                        value: 'Female',
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  textField(
                    label: 'Mobile Number',
                    hint: 'Enter mobile number',
                    icon: Icons.phone_outlined,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),

                  textField(
                    label: 'Email Address',
                    hint: 'Enter email address',
                    icon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  sectionTitle('Address'),

                  textField(
                    label: 'Current Address',
                    hint: 'Enter current address',
                    icon: Icons.location_on_outlined,
                    controller: addressController,
                    maxLines: 3,
                  ),

                  textField(
                    label: 'Permanent Address',
                    hint: 'Enter permanent address',
                    icon: Icons.home_outlined,
                    controller: permanentAddressController,
                    maxLines: 3,
                  ),

                  sectionTitle('Education & Work'),

                  textField(
                    label: 'Education',
                    hint: 'Example: Bachelor / Master',
                    icon: Icons.school_outlined,
                    controller: educationController,
                  ),

                  textField(
                    label: 'Occupation',
                    hint: 'Enter your occupation',
                    icon: Icons.work_outline,
                    controller: occupationController,
                  ),

                  textField(
                    label: 'Workplace',
                    hint: 'Enter workplace',
                    icon: Icons.business_outlined,
                    controller: workplaceController,
                  ),

                  textField(
                    label: 'Designation',
                    hint: 'Enter your designation',
                    icon: Icons.badge_outlined,
                    controller: designationController,
                  ),

                  sectionTitle('Other Information'),

                  DropdownButtonFormField<String>(
                    value: bloodGroup,
                    decoration: InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: const Icon(
                        Icons.bloodtype_outlined,
                        color: Color(0xFF1877F2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'A+',
                        child: Text('A+'),
                      ),
                      DropdownMenuItem(
                        value: 'A-',
                        child: Text('A-'),
                      ),
                      DropdownMenuItem(
                        value: 'B+',
                        child: Text('B+'),
                      ),
                      DropdownMenuItem(
                        value: 'B-',
                        child: Text('B-'),
                      ),
                      DropdownMenuItem(
                        value: 'AB+',
                        child: Text('AB+'),
                      ),
                      DropdownMenuItem(
                        value: 'AB-',
                        child: Text('AB-'),
                      ),
                      DropdownMenuItem(
                        value: 'O+',
                        child: Text('O+'),
                      ),
                      DropdownMenuItem(
                        value: 'O-',
                        child: Text('O-'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        bloodGroup = value;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  textField(
                    label: 'Emergency Contact',
                    hint: 'Enter emergency contact number',
                    icon: Icons.contact_phone_outlined,
                    controller: emergencyContactController,
                    keyboardType: TextInputType.phone,
                  ),

                  textField(
                    label: 'About Me',
                    hint: 'Write something about yourself',
                    icon: Icons.info_outline,
                    controller: aboutController,
                    maxLines: 5,
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveProfile,
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isSaving
                            ? 'Saving...'
                            : 'Save Profile',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
