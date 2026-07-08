import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:typed_data'; // For Int64List

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'nudge_channel', // id
    'Nudge Alerts', // name
    description: 'Channel for nudge push notifications',
    importance: Importance.max,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    playSound: true,
  );

  /// Initialize the plugin and create the Android channel.
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
    // Create channel on Android.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Request notification permission (required for Android 13+).
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    // iOS permissions are handled during init.
    return true;
  }

  /// Show a nudge notification with vibration.
  static Future<void> showNudge() async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'nudge_channel',
      'Nudge Alerts',
      channelDescription: 'Channel for nudge push notifications',
      importance: Importance.max,
      priority: Priority.high,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      playSound: true,
    );
    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await _plugin.show(
      0,
      '💕 Chọc ghẹo!',
      'Nửa kia vừa chọc ghẹo bạn!',
      platformDetails,
    );
  }
}
