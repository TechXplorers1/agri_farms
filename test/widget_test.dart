import 'package:agriculture/l10n/app_localizations.dart';
import 'package:agriculture/screens/terms_privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Privacy policy is accessible without signing in', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TermsPrivacyScreen(),
      ),
    );
    await tester.tap(find.text('Privacy Policy').first);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('https://agrifarms.in/delete-account'),
      findsWidgets,
    );
    expect(find.textContaining('OpenStreetMap Nominatim'), findsOneWidget);
  });
}
