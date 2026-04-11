import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Singleton: initialized from [main]. Shows local notifications + haptics when
/// a payment is detected from the API, or when an FCM message arrives (if the
/// server sends one later — no backend change required for the local path).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  int _localNotifIdSeq = 1;

  Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    final token = await _fcm.getToken();
    print('FCM Token: $token');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotif.initialize(initSettings);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    FirebaseMessaging.onMessage.listen(_onRemoteMessage);
  }

  void _onRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final isPaymentEvent = data['type'] == 'payment_completed' ||
        data['event'] == 'payment_completed' ||
        data['event'] == 'payment';

    if (isPaymentEvent) {
      final title = data['title']?.toString().trim().isNotEmpty == true
          ? data['title']!.toString()
          : 'Payment received';
      final body = data['body']?.toString().trim().isNotEmpty == true
          ? data['body']!.toString()
          : 'A payment for your waste submission has been completed.';
      final parsed = int.tryParse(data['paymentID'] ?? '');
      final id = parsed ?? _localNotifIdSeq++;
      showLocalAlert(title: title, body: body, notificationId: id);
      return;
    }

    if (message.notification != null) {
      showLocalAlert(
        title: message.notification!.title ?? 'WasteJustice',
        body: message.notification!.body ?? '',
      );
    } else if (data['title'] != null || data['body'] != null) {
      showLocalAlert(
        title: data['title']?.toString() ?? 'WasteJustice',
        body: data['body']?.toString() ?? '',
      );
    }
  }

  /// Local notification + haptic feedback + channel vibration (Android).
  /// [notificationId] should be stable per payment when possible.
  Future<void> showLocalAlert({
    required String title,
    required String body,
    int? notificationId,
  }) async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();

    final androidDetails = AndroidNotificationDetails(
      'waste_justice_channel',
      'WasteJustice Notifications',
      channelDescription: 'Payments and updates for collectors',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 450, 140, 450, 140, 600]),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final id = notificationId ?? _localNotifIdSeq++;
    await _localNotif.show(id, title, body, notifDetails);
  }

  /// Called when [paymentId] is newly present in earnings (aggregator paid).
  Future<void> notifyNewCompletedPayment({
    required int paymentId,
    required String amountLabel,
    String? plasticType,
  }) async {
    final typeLine =
        plasticType != null && plasticType.isNotEmpty ? ' ($plasticType)' : '';
    await showLocalAlert(
      title: 'Payment received',
      body: 'You were paid $amountLabel$typeLine for a waste submission.',
      notificationId: paymentId,
    );
  }

  /// Right after a successful waste sale submit (no server push required).
  Future<void> notifyWasteSubmissionSent({
    double? weightKg,
    String? plasticTypeLabel,
  }) async {
    final parts = <String>[];
    if (plasticTypeLabel != null && plasticTypeLabel.trim().isNotEmpty) {
      parts.add(plasticTypeLabel.trim());
    }
    if (weightKg != null) {
      parts.add('${weightKg.toStringAsFixed(2)} kg');
    }
    final body = parts.isEmpty
        ? 'Your plastic sale was submitted. An aggregator will review it.'
        : '${parts.join(' · ')} — submitted. An aggregator will review your delivery.';
    final id = DateTime.now().millisecondsSinceEpoch & 0x3FFFFFFF;
    await showLocalAlert(
      title: 'Submission sent',
      body: body,
      notificationId: id,
    );
  }
}