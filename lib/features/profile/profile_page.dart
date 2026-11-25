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
          entry.value.text = profile[entry.key]?.toString() ?? '';
        }

        photoPath = profile['photo_path']?.toString();
        gender = profile['gender']?.toString() ?? '';
        bloodGroup = profile['blood_group']?.toString() ?? '';
      }
    } catch (e) {
      showMessage('Could not load profile: $e');
    }
