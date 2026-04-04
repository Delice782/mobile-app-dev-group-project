import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // get FCM token
    String? token = await _fcm.getToken();
    print('FCM Token: $token');

    // setup local notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotif.initialize(initSettings);

    // show notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'WasteJustice',
          message.notification!.body ?? '',
        );
      }
    });
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'waste_justice_channel',
      'WasteJustice Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotif.show(0, title, body, notifDetails);
  }
}