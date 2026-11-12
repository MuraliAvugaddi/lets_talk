import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/apis/api_endpoint.dart';

/// 🔔 Push notifications from the server (notices, special class, attendance,
/// stage unlocked, fee …).
///
///   main():               await PushService.init();
///   after login / start:  PushService.register();     (called from initSocket)
///   logout:               await PushService.unregister();
class PushService {
  static final FirebaseMessaging _fm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static bool _inited = false;
  static String? _sentToken;

  // Same id as the server uses (utils/push.js → channelId)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'letsspeak_alerts',
    "Let's Speak alerts",
    description: 'Class, attendance, fee and notice notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (kIsWeb || _inited) return;
    _inited = true;
    try {
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // iOS shows banners itself while the app is open
      await _fm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      // Android: app is open → Firebase does NOT show it, so we show it
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null || !Platform.isAndroid) return;
        _local.show(
          id: m.hashCode & 0x7fffffff,
          title: n.title,
          body: n.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(n.body ?? ''),
            ),
          ),
        );
      });

      _fm.onTokenRefresh.listen((t) => _send(t));
    } catch (e) {
      debugPrint('PushService init failed: $e');
    }
  }

  /// Ask permission once and give this phone's token to the server. Safe to call often.
  static Future<void> register() async {
    if (kIsWeb) return;
    try {
      final login = (GetStorage().read('token') ?? '').toString();
      if (login.isEmpty) return;
      final perm = await _fm.requestPermission(alert: true, badge: true, sound: true);
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
      if (Platform.isIOS) {
        // iOS needs the APNs token first (can take a moment after install)
        for (var i = 0; i < 5 && await _fm.getAPNSToken() == null; i++) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      final t = await _fm.getToken();
      if (t != null) await _send(t);
    } catch (e) {
      debugPrint('Push register error: $e');
    }
  }

  static Future<void> _send(String fcmToken) async {
    final login = (GetStorage().read('token') ?? '').toString();
    if (login.isEmpty || fcmToken == _sentToken) return;
    final res = await http
        .post(
          Uri.parse('${ApiEndpoints.baseUrl}/user/push-token'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $login'},
          body: jsonEncode({'token': fcmToken}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) _sentToken = fcmToken;
  }

  /// Logout: stop notifications for this account on this phone.
  static Future<void> unregister() async {
    if (kIsWeb) return;
    try {
      final login = (GetStorage().read('token') ?? '').toString();
      final t = await _fm.getToken();
      if (login.isNotEmpty && t != null) {
        await http
            .delete(
              Uri.parse('${ApiEndpoints.baseUrl}/user/push-token'),
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $login'},
              body: jsonEncode({'token': t}),
            )
            .timeout(const Duration(seconds: 8));
      }
      await _fm.deleteToken();
    } catch (_) {}
    _sentToken = null;
  }
}
