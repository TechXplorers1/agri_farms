import 'package:agriculture/services/api_service.dart';
import 'package:agriculture/utils/moderation_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportApi extends ApiService {
  ReportApi({this.fail = false});
  final bool fail;
  Map<String, dynamic>? submitted;
  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    if (fail) throw Exception('Server unavailable');
    submitted = data;
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final encrypted = <String, String>{};
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    encrypted.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final key = args['key'] as String;
          switch (call.method) {
            case 'read':
              return encrypted[key];
            case 'write':
              encrypted[key] = args['value'] as String;
              return null;
            case 'delete':
              encrypted.remove(key);
              return null;
          }
          throw UnimplementedError(call.method);
        });
  });

  test(
    'Migrates all legacy native tokens without replacing newer secure tokens',
    () async {
      SharedPreferences.setMockInitialValues({
        'secure_access_token': 'legacy',
        'secure_refresh_token': 'refresh',
        'secure_access_token_expiry': 'expiry',
      });
      encrypted['access_token'] = 'newer';
      await ApiService().migrateLegacyTokens();
      expect(encrypted, {
        'access_token': 'newer',
        'refresh_token': 'refresh',
        'access_token_expiry': 'expiry',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.startsWith('secure_')), isEmpty);
      await ApiService().clearTokens();
      expect(encrypted, isEmpty);
    },
  );

  test(
    'Failed report remains retryable and does not hide the listing',
    () async {
      SharedPreferences.setMockInitialValues({'user_id': 'review-user'});
      await expectLater(
        ModerationHelper.submitReport(
          itemId: 'failed-item',
          itemName: 'Tractor',
          providerId: 'failed-provider',
          reason: 'Fraud',
          apiService: ReportApi(fail: true),
        ),
        throwsException,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('ugc_reported_items'), isNull);
      expect(
        ModerationHelper.isBlockedOrReported('failed-provider', 'failed-item'),
        isFalse,
      );
    },
  );

  test('Accepted report reaches backend before listing is hidden', () async {
    SharedPreferences.setMockInitialValues({'user_id': 'review-user'});
    final api = ReportApi();
    await ModerationHelper.submitReport(
      itemId: 'accepted-item',
      itemName: 'Tractor',
      providerId: 'accepted-provider',
      reason: 'Fraud',
      apiService: api,
    );
    expect(api.submitted?['reporterUserId'], 'review-user');
    expect(
      ModerationHelper.isBlockedOrReported(
        'accepted-provider',
        'accepted-item',
      ),
      isTrue,
    );
  });
}
