import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // Constructor
  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language') ?? 'English';
    _setLocaleFromLanguageName(savedLanguage);
  }

  Future<void> setLanguage(String languageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageName);
    _setLocaleFromLanguageName(languageName);
  }

  void _setLocaleFromLanguageName(String languageName) {
    if (languageName == 'Telugu') {
      _locale = const Locale('te');
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }
}
