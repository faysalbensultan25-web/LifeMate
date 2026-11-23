
import 'package:flutter/material.dart';

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

  int? profileId;
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

      profileId = profile['id'] as int;
      nameController.text = profile['name']?.toString() ?? '';
      phoneController.text = profile['phone']?.toString() ?? '';
      emailController.text = profile['email']?.toString() ?? '';
      addressController.text = profile['address']?.toString() ?? '';
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty &&
        phone.isEmpty &&
        email.isEmpty &&
        address.isEmpty) {
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

    final db = await AppDatabase.database;

    final data = {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };

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

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved successfully'),
      ),
    );
  }

  Future<void> clearProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Profile'),
        content: const Text(
          'Are you sure you want to clear your profile information?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
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

    if (!mounted) return;

    setState(() {
      profileId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile information cleared'),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Widget profileField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: Color(0xFFE7F0FF),
                    child: Icon(
                      Icons.person,
                      size: 55,
                      color: Color(0xFF1877F2),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Personal Profile',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Your profile is completely optional.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 28),

                  profileField(
                    label: 'Full Name',
                    hint: 'Enter your name',
                    icon: Icons.person_outline,
                    controller: nameController,
                  ),

                  profileField(
                    label: 'Mobile Number',
                    hint: 'Enter your mobile number',
                    icon: Icons.phone_outlined,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),

                  profileField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  profileField(
                    label: 'Address',
                    hint: 'Enter your address',
                    icon: Icons.location_on_outlined,
                    controller: addressController,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveProfile,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        isSaving ? 'Saving...' : 'Save Profile',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
