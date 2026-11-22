class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> translations = {
    'en': {
      'home': 'Home',
      'todo': 'To-Do',
      'finance': 'Finance',
      'notes': 'Notes',
      'events': 'Events',
      'statistics': 'Statistics',
      'budget': 'Budget Planning',
      'profile': 'Profile',
      'settings': 'Settings',
      'coming_soon': 'Coming soon',
    },
    'bn': {
      'home': 'হোম',
      'todo': 'করণীয়',
      'finance': 'আয়-ব্যয়',
      'notes': 'নোট',
      'events': 'অনুষ্ঠান',
      'statistics': 'পরিসংখ্যান',
      'budget': 'বাজেট পরিকল্পনা',
      'profile': 'প্রোফাইল',
      'settings': 'সেটিংস',
      'coming_soon': 'শীঘ্রই আসছে',
    },
  };

  static String get(
    String key, {
    String language = 'en',
  }) {
    return translations[language]?[key] ??
        translations['en']?[key] ??
        key;
  }
}
