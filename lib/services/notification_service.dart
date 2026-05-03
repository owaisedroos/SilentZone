import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'silent_zone_alerts';
  static const _channelName = 'Silent Zone Alerts';
  static const _channelDesc =
      'Popup alerts when entering or exiting a silent zone';

  // Vibration pattern: wait 0ms, vibrate 400ms, pause 200ms, vibrate 400ms
  static const _vibrationPattern = [0, 400, 200, 400];

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Create notification channel with vibration enabled
    final Int64List vibrationPattern =
        Int64List.fromList(_vibrationPattern);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            enableVibration: true,
            vibrationPattern: vibrationPattern,
            playSound: true,
            showBadge: true,
          ),
        );
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  static Future<void> showZoneEntry({
    required String zoneName,
    required bool autoSilenced,
  }) async {
    final title = autoSilenced
        ? '🔇 Phone Silenced Automatically'
        : '🤫 Silent Zone — Please Silence Your Phone';
    final body = autoSilenced
        ? 'You entered $zoneName. Ringer has been muted.'
        : 'You entered $zoneName. Please mute your phone.';
    await _show(id: 1, title: title, body: body);
  }

  static Future<void> showZoneExit({
    required String zoneName,
    required bool autoSilenced,
  }) async {
    final title =
        autoSilenced ? '🔔 Ringer Restored' : '🔔 Left Silent Zone';
    final body = autoSilenced
        ? 'You left $zoneName. Ringer restored to normal.'
        : 'You have left $zoneName.';
    await _show(id: 2, title: title, body: body);
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    final Int64List vibrationPattern =
        Int64List.fromList(_vibrationPattern);

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern, // ← vibrate on every notification
          visibility: NotificationVisibility.public,
          ticker: 'SilentZone Alert',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
    );
  }
}