import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, String> _memoryCache = {};
  
  static const String _cacheKeyPrefix = 'trans_cache_';

  /// Translates a single piece of text to the target language.
  /// Uses memory cache first, then persistent cache, then the API.
  Future<String> translate(String text, String targetLang) async {
    if (text.isEmpty || targetLang == 'en' || text.trim() == '') return text;
    
    final cacheKey = '${_cacheKeyPrefix}${targetLang}_${text.hashCode}';
    
    // 1. Check Memory Cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }
    
    try {
      // 2. Check Persistent Cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        _memoryCache[cacheKey] = cached;
        return cached;
      }
      
      // 3. Translate using API
      final translation = await _translator.translate(text, to: targetLang);
      final translatedText = translation.text;
      
      // 4. Save to Caches
      _memoryCache[cacheKey] = translatedText;
      await prefs.setString(cacheKey, translatedText);
      
      return translatedText;
    } catch (e) {
      debugPrint('Translation error for "$text": $e');
      return text; // Fallback to original text
    }
  }

  /// Batch translates a list of strings.
  Future<Map<String, String>> translateBatch(List<String> texts, String targetLang) async {
    final Map<String, String> results = {};
    if (targetLang == 'en') {
      for (var t in texts) { results[t] = t; }
      return results;
    }

    // Process in parallel with some concurrency limit if needed, 
    // but for now, we'll just do a simple Future.wait
    await Future.wait(texts.map((t) async {
      results[t] = await translate(t, targetLang);
    }));
    
    return results;
  }
}
