import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/language_provider.dart';
import 'screens/splash_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and Notifications
  try {
    await Firebase.initializeApp();
    await NotificationService().init();
  } catch (e) {
    debugPrint('Firebase/Notifications initialization failed: $e');
  }
  
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider(initialLanguage: savedLanguage)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Agri Farms',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00AA55)),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
          ),
          locale: languageProvider.locale,
          home: const SplashScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
