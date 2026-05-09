import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Must be top-level — runs in a separate isolate
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background FCM message: ${message.messageId}');
  // Show local notification for background messages
  await _NotificationHelper.showLocalNotification(message);
}

/// Helper so background handler can call show
class _NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'agrifarms_channel_id',
    'AgriFarms Notifications',
    description: 'Notifications for AgriFarms booking updates and alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> showLocalNotification(RemoteMessage message) async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final notification = message.notification;
    if (notification == null) return;

    await _plugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'agrifarms_channel_id',
    'AgriFarms Notifications',
    description: 'Notifications for AgriFarms booking updates and alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final String _backendUrl = ApiConfig.baseUrl + ApiConfig.users;

  Future<void> init() async {
    // Register the background handler FIRST (before anything else)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Step 1: Request notification permission
    // On Android 13+, this triggers the system permission dialog
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        print('Notification permission denied.');
        // Still continue — FCM token might be needed for data-only messages
      }
    }

    // Step 2: Request Firebase Messaging permission (iOS + triggers on Android too)
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('FCM permission status: ${settings.authorizationStatus}');

    // Step 3: Create the Android notification channel
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Step 4: Initialize local notifications plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Local notification tapped: ${details.payload}');
      },
    );

    // Step 5: Subscribe to topic
    try {
      // await _firebaseMessaging.subscribeToTopic('all_assets'); // Disabled to prevent broadcast notifications on new service/equipment
      // print('Subscribed to all_assets topic');
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }

    // Step 6: Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground FCM message received: ${message.messageId}');
      print('Title: ${message.notification?.title}, Body: ${message.notification?.body}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Step 7: Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _saveTokenToBackend(newToken);
    });

    print('NotificationService initialized successfully.');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00AA55),
        ),
      ),
    );
  }

  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateFCMToken() async {
    String? token = await getToken();
    if (token != null) {
      await _saveTokenToBackend(token);
    }
  }

  Future<void> clearFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$_backendUrl/$userId/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmToken': ''}), // Empty string to clear it
      );
      if (response.statusCode == 200) {
        print('FCM token forcefully cleared in backend for user $userId');
      }
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      print('No user logged in, skipping FCM token save.');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$_backendUrl/$userId/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        print('FCM token saved to backend for user $userId');
      } else {
        print('Failed to save FCM token: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      print('Error saving FCM token to backend: $e');
    }
  }
}
