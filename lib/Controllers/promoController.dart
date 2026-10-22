import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';
import 'package:lets_talk/Screens/widgets/promo_popup.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

/// Posters & reels the admin posted (e.g. "Dussehra — 10 days to go").
/// • Shown once as a popup each time the student opens the app (X closes it).
/// • ⚡ LIVE: when the admin uploads a new poster / reel, it pops up on every
///   student's home screen right away — no refresh needed.
///   (Never on top of a live class, a test or any other page — then it waits
///   until the student is back on the home screen.)
class PromoController extends GetxController {
  static PromoController get to =>
      Get.isRegistered<PromoController>() ? Get.find<PromoController>() : Get.put(PromoController(), permanent: true);

  static const Duration reopenAfter = Duration(minutes: 5);

  final RxList<Map<String, dynamic>> promos = <Map<String, dynamic>>[].obs;

  bool _shownThisOpen = false;
  bool _showing = false;
  DateTime? _pausedAt;

  // live updates
  dynamic _socket; // the AuthController socket we listen on
  Timer? _attachTimer;
  Timer? _liveDebounce;
  Timer? _waitTimer; // new post waiting for the student to come back to home
  BuildContext? _homeContext; // the home screen that called showIfNeeded
  String _mode = 'online';
  final Set<String> _seenIds = <String>{}; // posts this student already saw
  bool _pendingNew = false; // new post arrived while the student was on another page
  final Random _rnd = Random();

  @override
  void onInit() {
    super.onInit();
    attachSocket();
    // The socket is re-created after login / reconnect → keep listening on the current one
    _attachTimer = Timer.periodic(const Duration(seconds: 10), (_) => attachSocket());
  }

  @override
  void onClose() {
    _attachTimer?.cancel();
    _liveDebounce?.cancel();
    _waitTimer?.cancel();
    try {
      _socket?.off('promo_updated', _onPromoUpdated);
    } catch (_) {}
    super.onClose();
  }

  /// Listen on the app's socket (safe to call many times).
  void attachSocket() {
    if (!Get.isRegistered<AuthController>()) return;
    final s = Get.find<AuthController>().socket;
    if (s == null || identical(s, _socket)) return;
    try {
      _socket?.off('promo_updated', _onPromoUpdated);
    } catch (_) {}
    _socket = s;
    s.on('promo_updated', _onPromoUpdated);
  }

  /// Admin posted / edited / deleted a poster or reel
  void _onPromoUpdated(dynamic data) {
    final deleted = data is Map && data['deleted'] == true;
    _liveDebounce?.cancel();
    // small random delay → 2,500 phones don't download at the same second
    _liveDebounce = Timer(Duration(milliseconds: 400 + _rnd.nextInt(2500)), () async {
      await fetch(_mode);
      if (deleted) return; // removed posts just disappear from the list
      final hasNew = promos.any((p) => !_seenIds.contains(p['_id']?.toString()));
      if (hasNew) {
        _pendingNew = true;
        _showLiveIfPossible();
      }
    });
  }

  bool get _busyElsewhere => StreamManager.inCall; // in a live class → don't interrupt

  /// Pop the new post up now if the student is on the home screen.
  void _showLiveIfPossible() {
    final ctx = _homeContext;
    if (!_pendingNew || _showing || ctx == null || !ctx.mounted) return;
    final route = ModalRoute.of(ctx);
    if (_busyElsewhere || (route != null && !route.isCurrent)) {
      // In a class / test / other page → check again every 5 s and show it once they're back home
      _waitTimer ??= Timer.periodic(const Duration(seconds: 5), (t) {
        if (!_pendingNew) {
          t.cancel();
          _waitTimer = null;
          return;
        }
        final c = _homeContext;
        final r = (c != null && c.mounted) ? ModalRoute.of(c) : null;
        if (c != null && c.mounted && !_busyElsewhere && (r == null || r.isCurrent)) {
          t.cancel();
          _waitTimer = null;
          _showLiveIfPossible();
        }
      });
      return;
    }
    final fresh = promos.where((p) => !_seenIds.contains(p['_id']?.toString())).toList();
    if (fresh.isEmpty) {
      _pendingNew = false;
      return;
    }
    _pendingNew = false;
    _open(ctx, [...fresh, ...promos.where((p) => _seenIds.contains(p['_id']?.toString()))]);
  }

  Future<void> _open(BuildContext context, List<Map<String, dynamic>> list) async {
    if (list.isEmpty) return;
    _showing = true;
    _shownThisOpen = true;
    for (final p in list) {
      final id = p['_id']?.toString();
      if (id != null) _seenIds.add(id);
    }
    try {
      await PromoPopup.show(context, list);
    } finally {
      _showing = false;
    }
  }

  /// Call when the app goes to the background.
  void onPaused() => _pausedAt ??= DateTime.now();

  /// Call when the app comes back. After 5+ minutes away it counts as "opening the app again".
  void onResumed() {
    attachSocket();
    final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
    if (away >= reopenAfter) _shownThisOpen = false;
    _pausedAt = null;
  }

  Future<void> fetch(String mode) async {
    _mode = mode;
    try {
      final res = await http
          .get(Uri.parse('${ApiEndpoints.activePromos}?mode=$mode'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body)['promos'] as List? ?? []);
        promos.assignAll(list.map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      debugPrint('Promo fetch error: $e');
    }
  }

  /// Home screen calls this when it opens / refreshes.
  /// Shows the popup if there is a live post and it wasn't shown since the app was opened,
  /// or if a new post arrived while the student was on another page.
  Future<void> showIfNeeded(BuildContext context, {required String mode}) async {
    _homeContext = context;
    _mode = mode;
    attachSocket();
    if (_showing) return;
    if (_shownThisOpen && !_pendingNew) return;
    await fetch(mode);
    if (promos.isEmpty || !context.mounted || _busyElsewhere) return;

    // Only on the home screen — never on top of a live class or another page
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    _pendingNew = false;
    await _open(context, promos.toList());
  }
}
