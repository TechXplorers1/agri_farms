import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Replace with your backend URL
  final String _backendUrl = 'http://10.0.2.2:8080/api/users';

  Future<void> init() async {
    // Request permission for iOS/Android
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // Initialize local notifications for foreground display
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotificationsPlugin.initialize(initializationSettings);

    // Subscribe to all assets broadcast topic
    try {
      await _firebaseMessaging.subscribeToTopic('all_assets');
      print('Subscribed to all_assets topic');
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }

    // Background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messaging handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle token updates
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToBackend(newToken);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'agrifarms_channel_id',
      'AgriFarms Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    return token;
  }

  Future<void> updateFCMToken() async {
    String? token = await getToken();
    if (token != null) {
      await _saveTokenToBackend(token);
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    // Only send if we have a logged-in user
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    if (userId == null) {
      print('No user logged in, postponing FCM token save.');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$_backendUrl/$userId/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmToken': token}),
      );
      
      if (response.statusCode == 200) {
        print('Successfully saved FCM token to backend');
      } else {
        print('Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}
