import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:lets_talk/apis/batch_slots.dart';

/// ⏰ CLASS REMINDER
/// 5 minutes before each of the student's class timings (Mon–Sat) the phone
/// shows "Your class starts in 5 minutes" with the normal notification sound,
/// even when the app is closed.
///
/// • Timings come from the student's profile (per stage: englishBatch / hindiBatch,
///   else the signup timing). When the admin changes a timing, the reminders
///   are rescheduled automatically (AuthController.userData changes).
/// • Logout → all reminders are cancelled.
class ClassReminder {
  ClassReminder._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String _lastSignature = '';

  static const int minutesBefore = 5;
  static const String _channelId = 'class_reminder';
  static const String _channelName = 'Class reminders';

  /// Call once in main() before runApp().
  static Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // class timings are IST
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('ClassReminder init failed: $e');
    }
  }

  /// Schedules (or clears) reminders for this user. Safe to call often.
  static Future<void> sync(Map<dynamic, dynamic>? user) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    if (!_ready) return;

    final slots = _timingsOf(user);
    final signature = slots.map((s) => s.number).join(',');
    if (signature == _lastSignature) return; // nothing changed
    _lastSignature = signature;

    try {
      // Clear old reminders (7 timings × 7 days)
      for (var b = 1; b <= 7; b++) {
        for (var d = 1; d <= 7; d++) {
          await _plugin.cancel(id: _id(b, d));
        }
      }
      if (slots.isEmpty) return; // logged out / no timing yet

      final exact = await _askPermissions();
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminds you 5 minutes before your live class',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, // show even while the app is open
          presentBanner: true,
          presentList: true,
          presentSound: true,
        ),
      );

      for (final slot in slots) {
        final remindAt = slot.startMinutes - minutesBefore;
        for (var day = DateTime.monday; day <= DateTime.saturday; day++) {
          await _plugin.zonedSchedule(
            id: _id(slot.number, day),
            title: 'Your class starts in $minutesBefore minutes ⏰',
            body: 'Live class at ${slot.shortLabel}. Open Let\'s Speak and join on time.',
            scheduledDate: _next(day, remindAt ~/ 60, remindAt % 60),
            notificationDetails: details,
            androidScheduleMode: mode,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
      debugPrint('⏰ Class reminders set for: ${slots.map((s) => s.shortLabel).join(', ')}'
          '${exact ? ' (on time)' : ' (Android: "Alarms & reminders" is off → may be a few minutes late)'}');
    } catch (e) {
      _lastSignature = ''; // try again next time
      debugPrint('ClassReminder schedule failed: $e');
    }
  }

  /// Asks for notification permission (both phones) and, on Android 12+,
  /// for "Alarms & reminders" so the reminder comes at the exact minute.
  /// Returns true when reminders will be on time.
  static Future<bool> _askPermissions() async {
    // 🍎 iPhone: one "Allow notifications?" popup. iPhone has no exact/approximate
    // difference — when allowed, reminders always come on time.
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      try {
        final ok = await ios?.requestPermissions(alert: true, badge: true, sound: true);
        return ok ?? true;
      } catch (_) {
        return true;
      }
    }

    // 🤖 Android
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    try {
      await android.requestNotificationsPermission(); // Android 13+ popup
      var exact = (await android.canScheduleExactNotifications()) ?? false;

      // Android 12+ "Alarms & reminders": opens Settings — ask only ONCE, not on every sync
      final box = GetStorage();
      if (!exact && box.read('asked_exact_alarm') != true) {
        await box.write('asked_exact_alarm', true);
        await android.requestExactAlarmsPermission();
        exact = (await android.canScheduleExactNotifications()) ?? false;
      }
      return exact;
    } catch (e) {
      debugPrint('ClassReminder permission error: $e');
      return false;
    }
  }

  /// The student turned "Alarms & reminders" on later (back from Settings) →
  /// call this to reschedule with exact times. Safe to call on app resume.
  static Future<void> refresh(Map<dynamic, dynamic>? user) async {
    _lastSignature = '';
    await sync(user);
  }

  /// Turn reminders off (e.g. on logout).
  static Future<void> clear() => sync(const {});

  // -------------------------------------------------------------------
  static int _id(int batch, int weekday) => 7000 + batch * 10 + weekday;

  static tz.TZDateTime _next(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (t.weekday != weekday || !t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// Every timing this student attends (one per enabled stage), no duplicates.
  static List<BatchSlot> _timingsOf(Map<dynamic, dynamic>? user) {
    if (user == null || user.isEmpty) return [];
    if ((user['role'] ?? 'student').toString() != 'student') return [];
    if (GetStorage().read('class_reminders_off') == true) return [];

    final found = <int, BatchSlot>{};
    void addFrom(String accessKey, String batchKey) {
      final access = user[accessKey];
      final batches = user[batchKey];
      if (access is! Map) return;
      access.forEach((stage, on) {
        if (on != true) return;
        final perStage = batches is Map ? batches[stage] : null;
        final slot = BatchSlots.find(perStage) ?? BatchSlots.find(user['batchTime']);
        if (slot != null) found[slot.number] = slot;
      });
    }

    addFrom('englishAccess', 'englishBatch');
    addFrom('hindiAccess', 'hindiBatch');
    // New student, no stage enabled yet → remind for the signup timing
    if (found.isEmpty) {
      final s = BatchSlots.find(user['batchTime']);
      if (s != null) found[s.number] = s;
    }
    final list = found.values.toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return list;
  }
}