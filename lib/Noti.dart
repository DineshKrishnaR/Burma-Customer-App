
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Noti {
  static const String _channelId = 'bus_alerts_channel_v2';
  static const String _channelName = 'Bus Alerts';
  static const String _channelDescription =
      'Important bus movement alerts with sound';

  static Future initialize(FlutterLocalNotificationsPlugin fln) async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iOSInit,
  );

  await fln.initialize(initSettings);

  // Android custom channel
  await fln
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('bussound'),
        ),
      );
}


  static Future showBigTextNotification({
    int id = 0,
    required String title,
    required String body,
    var payload,
    required FlutterLocalNotificationsPlugin fln,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('bussound'),
    );

    const notiDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
      presentAlert: true,   // 👈 show alert banner
      presentBadge: true,   // 👈 update badge
      presentSound: true,   // 👈 play sound
      sound: 'bussound.wav',
    ),
    );

    await fln.show(id, title, body, notiDetails, payload: payload);
  }
}
