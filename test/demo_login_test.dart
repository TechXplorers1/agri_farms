import 'package:agriculture/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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

  test('Demo Farmer login with 9999999999 and OTP 123456 succeeds', () async {
    final apiService = ApiService();
    
    // Test send OTP (should not throw)
    await apiService.sendMsg91Otp(phoneNumber: '9999999999');

    // Test verify OTP
    final result = await apiService.verifyMsg91Otp(
      phoneNumber: '9999999999',
      otp: '123456',
      role: 'Farmer',
      fullName: 'Demo Farmer',
      isLogin: true,
    );

    expect(result['role'], 'Farmer');
    expect(result['phoneNumber'], '9999999999');
    expect(result['fullName'], 'Demo Farmer');
    expect(encrypted['access_token'], 'demo_access_token_9999999999');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_role'), 'Farmer');
    expect(prefs.getString('user_id'), 'demo_farmer_id');
  });

  test('Demo Provider login with 8888888888 and OTP 123456 succeeds', () async {
    final apiService = ApiService();

    // Test send OTP (should not throw)
    await apiService.sendMsg91Otp(phoneNumber: '8888888888');

    // Test verify OTP
    final result = await apiService.verifyMsg91Otp(
      phoneNumber: '8888888888',
      otp: '123456',
      role: 'Owner',
      fullName: 'Demo Provider',
      isLogin: true,
    );

    expect(result['role'], 'Owner');
    expect(result['phoneNumber'], '8888888888');
    expect(result['fullName'], 'Demo Provider');
    expect(encrypted['access_token'], 'demo_access_token_8888888888');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_role'), 'Owner');
    expect(prefs.getString('user_id'), 'demo_provider_id');
  });

  test('Demo login with wrong OTP fails', () async {
    final apiService = ApiService();
    expect(
      () => apiService.verifyMsg91Otp(
        phoneNumber: '9999999999',
        otp: '000000',
        role: 'Farmer',
        fullName: 'Demo Farmer',
        isLogin: true,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
