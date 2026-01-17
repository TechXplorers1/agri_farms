import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // Constructor
  LanguageProvider({String? initialLanguage}) {
    if (initialLanguage != null) {
      _setLocaleFromLanguageName(initialLanguage);
    } else {
      _loadLanguage();
    }
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
    } else if (languageName == 'Hindi') {
      _locale = const Locale('hi');
    } else if (languageName == 'Tamil') {
      _locale = const Locale('ta');
    } else if (languageName == 'Kannada') {
      _locale = const Locale('kn');
    } else if (languageName == 'Marathi') {
      _locale = const Locale('mr');
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }
}
