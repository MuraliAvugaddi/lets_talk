import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/rtc/live_room.dart'; // 🎧 LiveKit audio classes (same names as before)
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart' show StreamManager;
import 'package:lets_talk/Screens/widgets/assembly_join_screen.dart';

enum AssemblyPhase { idle, preparing, waiting, joining, live, error }

/// 🎙 Keeps the Surendra Sir special class running even when the student
/// leaves the class page (minimize) to read notes.
/// While minimized a small floating bubble stays on top of every screen:
///   tap it → back to the class, 🎤 → mute/unmute, the class audio never stops.
class AssemblyCallController extends GetxController {
  static AssemblyCallController get to => Get.isRegistered<AssemblyCallController>()
      ? Get.find<AssemblyCallController>()
      : Get.put(AssemblyCallController(), permanent: true);

  final Random _rnd = Random();

  final phase = AssemblyPhase.idle.obs;
  final errorText = ''.obs;
  final micBusy = false.obs;
  final minimized = false.obs;
  final tick = 0.obs; // bumps once a second → UI refresh (not on every audio change)

  String title = 'Surendra Sir Special Class';
  String startTime = '';
  Call? call;
  String? attendanceId;
  Timer? _retry;
  Timer? _sync;
  Timer? _tick;
  bool _socketOn = false;

  OverlayEntry? _bubble;
  Offset bubblePos = const Offset(12, 120);

  AuthController get _auth => Get.find<AuthController>();
  String get userId => (_auth.userData['id'] ?? _auth.userData['_id'] ?? '').toString();
  String get _userName => (_auth.userData['name'] ?? 'Student').toString();

  /// in the class or waiting for Sir (so leaving the page should minimize, not leave)
  bool get isActive =>
      phase.value == AssemblyPhase.preparing ||
      phase.value == AssemblyPhase.waiting ||
      phase.value == AssemblyPhase.joining ||
      phase.value == AssemblyPhase.live;

  Map<String, String> _headers({bool json = false}) {
    final token = (GetStorage().read('token') ?? '').toString();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // =========================================================
  // start / connect
  // =========================================================
  /// Called when the class page opens. Does nothing if already in the class.
  void start({required String title, required String startTime}) {
    if (isActive) return;
    this.title = title;
    this.startTime = startTime;
    WakelockPlus.enable();
    if (!_socketOn) {
      // ⚡ Sir went live → join now (random delay so 2,500 phones don't hit at the same second)
      _auth.socket?.on('assembly_live', _onLiveEvent);
      _socketOn = true;
    }
    connect();
  }

  void _onLiveEvent(dynamic _) {
    if (phase.value != AssemblyPhase.waiting) return;
    _retry?.cancel();
    _retry = Timer(Duration(milliseconds: 300 + _rnd.nextInt(4000)), connect);
  }

  Future<void> connect() async {
    _retry?.cancel();
    phase.value = AssemblyPhase.preparing;
    try {
      final res = await http
          .post(
            Uri.parse("${ApiEndpoints.baseUrl}/rtc/prepare-call"),
            headers: _headers(json: true),
            body: jsonEncode({"userId": userId, "type": "assembly"}),
          )
          .timeout(const Duration(seconds: 25));
      final data = jsonDecode(res.body);
      if (phase.value == AssemblyPhase.idle) return; // left meanwhile

      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'Server busy (${res.statusCode}). Try again.');
      }
      if (data['assembly'] == false) {
        _fail('The special class has finished.');
        return;
      }
      if (data['started'] != true) {
        // not live yet → the socket wakes us up; also check every ~30 s just in case
        phase.value = AssemblyPhase.waiting;
        _retry = Timer(Duration(seconds: 25 + _rnd.nextInt(10)), connect);
        return;
      }

      phase.value = AssemblyPhase.joining;
      final client = await StreamManager.clientFor(userId: userId, userName: _userName);
      final c = client.makeCall(callType: StreamCallType.defaultType(), id: data['callId'].toString());
      final joined = await c.join(
        connectOptions: CallConnectOptions(
          camera: TrackOption.disabled(),
          microphone: TrackOption.disabled(), // always join muted
        ),
      );
      if (joined.isFailure) throw Exception('Could not connect. Please try again.');
      if (phase.value == AssemblyPhase.idle) {
        // student left while we were connecting
        try {
          await c.leave();
        } catch (_) {}
        return;
      }
      StreamManager.inCall = true;
      call = c;
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
      phase.value = AssemblyPhase.live;
      _markAttendance();
    } catch (e) {
      if (phase.value == AssemblyPhase.idle) return;
      _fail(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _fail(String text) {
    errorText.value = text;
    phase.value = AssemblyPhase.error;
    // minimized and it failed → close the bubble and tell the student
    if (minimized.value) {
      _hideBubble();
      minimized.value = false;
      Get.snackbar('Special class', text,
          backgroundColor: const Color(0xFFE45757), colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
  }

  // =========================================================
  // Sir's mic rules (from the call's custom data)
  // =========================================================
  ({bool locked, Set<String> allowed}) _rules() {
    final custom = call?.state.value.custom ?? const <String, Object>{};
    final packed = custom['state'];
    if (packed is String && packed.isNotEmpty) {
      try {
        final m = jsonDecode(packed);
        if (m is Map) {
          final a = m['allowed'];
          return (
            locked: m['micLocked'] != false,
            allowed: a is List ? a.map((e) => e.toString()).toSet() : <String>{},
          );
        }
      } catch (_) {}
    }
    return (locked: true, allowed: <String>{}); // no rules yet → stay muted
  }

  bool get canSpeak {
    final r = _rules();
    return !r.locked || r.allowed.contains(userId);
  }

  bool get micOn {
    final me = call?.state.value.callParticipants.where((p) => p.isLocal).toList() ?? const [];
    return me.isNotEmpty && me.first.isAudioEnabled;
  }

  List<CallParticipantState> get participants => call?.state.value.callParticipants ?? const [];

  String get speakingName {
    final s = participants.where((p) => p.isSpeaking && !p.isLocal).toList();
    return s.isEmpty ? '' : s.first.name;
  }

  void _onTick() {
    final c = call;
    if (c == null) return;
    // Sir tapped "End for everyone" (or the connection is gone for good)
    if (c.state.value.endedAt != null || c.state.value.status.isDisconnected) {
      _classEnded();
      return;
    }
    // Sir locked the mics while mine was on → turn it off
    if (micOn && !canSpeak) c.setMicrophoneEnabled(enabled: false);
    tick.value++;
  }

  Future<void> _classEnded() async {
    final wasMinimized = minimized.value;
    await leave();
    if (wasMinimized) {
      Get.snackbar('Class finished', '$title has ended. Thank you!',
          backgroundColor: const Color(0xFF0E466D), colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } else {
      errorText.value = '$title has ended. Thank you!';
      phase.value = AssemblyPhase.error;
    }
  }

  Future<void> toggleMic() async {
    final c = call;
    if (c == null || micBusy.value) return;
    if (!micOn && !canSpeak) {
      Get.snackbar('Mic is locked', 'Sir has muted everyone. You can talk when Sir allows.',
          backgroundColor: const Color(0xFF0E466D), colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }
    micBusy.value = true;
    try {
      await c.setMicrophoneEnabled(enabled: !micOn);
    } catch (e) {
      Get.snackbar('Microphone', 'Could not change the microphone. Allow mic permission and try again.',
          backgroundColor: const Color(0xFFE45757), colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } finally {
      micBusy.value = false;
      tick.value++;
    }
  }

  // =========================================================
  // attendance: join once (server marks every stage), sync every minute, leave
  // =========================================================
  Future<void> _markAttendance() async {
    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.joinOnlineClass),
        headers: _headers(json: true),
        body: jsonEncode({"userId": userId, "assembly": true}),
      );
      if (res.statusCode == 200) {
        attendanceId = jsonDecode(res.body)['attendanceId']?.toString();
        _sync?.cancel();
        // spread the 2,500 syncs over the minute
        Future.delayed(Duration(seconds: _rnd.nextInt(60)), () {
          if (attendanceId == null || call == null) return;
          _sync?.cancel();
          _sync = Timer.periodic(const Duration(seconds: 60), (_) => _post(ApiEndpoints.syncOnlineClass));
        });
      }
    } catch (e) {
      debugPrint('Special class attendance error: $e');
    }
  }

  Future<void> _post(String url) async {
    final id = attendanceId;
    if (id == null) return;
    try {
      await http.post(Uri.parse(url), headers: _headers(json: true), body: jsonEncode({"attendanceId": id}));
    } catch (_) {}
  }

  /// Really leave the class (Leave button, class ended, error page closed)
  Future<void> leave() async {
    phase.value = AssemblyPhase.idle;
    _retry?.cancel();
    _sync?.cancel();
    _tick?.cancel();
    if (_socketOn) {
      _auth.socket?.off('assembly_live', _onLiveEvent);
      _socketOn = false;
    }
    _hideBubble();
    minimized.value = false;
    WakelockPlus.disable();
    final c = call;
    call = null;
    StreamManager.inCall = false;
    if (c != null) {
      try {
        await c.leave();
      } catch (_) {}
    }
    await _post(ApiEndpoints.leaveOnlineClass);
    attendanceId = null;
  }

  // =========================================================
  // ➖ minimize / restore
  // =========================================================
  /// The class page closed but the class goes on → show the floating bubble
  void minimize() {
    if (!isActive || minimized.value) return;
    minimized.value = true;
    // insert after this frame (the page is closing right now)
    WidgetsBinding.instance.addPostFrameCallback((_) => _showBubble());
  }

  /// Bubble tapped → open the class page again (nothing reconnects)
  void restore() {
    _hideBubble();
    minimized.value = false;
    Get.to(() => AssemblyJoinScreen(title: title, startTime: startTime));
  }

  /// The class page is open again (e.g. student tapped the home card) → no bubble
  void pageOpened() {
    if (minimized.value) {
      _hideBubble();
      minimized.value = false;
    }
  }

  void _showBubble() {
    if (_bubble != null || !minimized.value) return;
    final overlay = Get.key.currentState?.overlay;
    if (overlay == null) return;
    _bubble = OverlayEntry(builder: (_) => const _AssemblyBubble());
    overlay.insert(_bubble!);
  }

  void _hideBubble() {
    final b = _bubble;
    _bubble = null;
    if (b != null && b.mounted) b.remove();
  }

  void moveBubble(Offset delta, Size screen) {
    bubblePos = Offset(
      (bubblePos.dx + delta.dx).clamp(0.0, max(0.0, screen.width - 250)),
      (bubblePos.dy + delta.dy).clamp(30.0, max(30.0, screen.height - 110)),
    );
    _bubble?.markNeedsBuild();
  }

  @override
  void onClose() {
    leave();
    super.onClose();
  }
}

// =========================================================
// 🫧 floating mini class bar (on top of every screen)
// =========================================================
class _AssemblyBubble extends StatelessWidget {
  const _AssemblyBubble();

  @override
  Widget build(BuildContext context) {
    final ctrl = AssemblyCallController.to;
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: ctrl.bubblePos.dx,
      top: ctrl.bubblePos.dy,
      child: GestureDetector(
        onPanUpdate: (d) => ctrl.moveBubble(d.delta, size),
        onTap: ctrl.restore,
        child: Material(
          color: Colors.transparent,
          child: Obx(() {
            ctrl.tick.value; // refresh once a second
            final live = ctrl.phase.value == AssemblyPhase.live;
            final micOn = live && ctrl.micOn;
            final canSpeak = live && ctrl.canSpeak;
            final speaking = live ? ctrl.speakingName : '';
            final sub = !live
                ? 'Waiting for Sir…'
                : speaking.isNotEmpty
                    ? '🔊 $speaking'
                    : (micOn ? 'You are talking' : 'Listening • tap to open');
            return Container(
              width: 250,
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0B2E47), Color(0xFF155A88)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: speaking.isNotEmpty ? const Color(0xFF28C2C2) : Colors.white24, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 14, offset: Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (live)
                              Container(
                                margin: const EdgeInsets.only(right: 5),
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(color: Color(0xFFE45757), shape: BoxShape.circle),
                              ),
                            Flexible(
                              child: Text(ctrl.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  if (live)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: ctrl.micBusy.value ? null : ctrl.toggleMic,
                      icon: Icon(
                        micOn ? Icons.mic_rounded : (canSpeak ? Icons.mic_off_rounded : Icons.lock_rounded),
                        color: micOn ? const Color(0xFF28C2C2) : Colors.white,
                        size: 20,
                      ),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Open class',
                    onPressed: ctrl.restore,
                    icon: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
