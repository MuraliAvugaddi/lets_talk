import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lets_talk/Screens/MainNavigationScreen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/apis/batch_slots.dart';
import 'package:lets_talk/Screens/app_colors.dart';

// =========================================================================
// 🌐 HELPERS
// =========================================================================
Map<String, String> _authHeaders({bool json = false}) {
  final token = (GetStorage().read('token') ?? '').toString();
  return {
    if (json) 'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

Future<bool> _checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup(
      'google.com',
    ).timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

void _showNoInternetSnackbar() {
  Get.snackbar(
    "Connection Lost",
    "Your internet is not working. Please check your connection.",
    backgroundColor: AppColors.error,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
  );
}

// =========================================================================
// 🎤 CLASS FLAGS — set by the trainer, read from the call's custom data
//   micLocked → nobody can unmute unless the trainer allowed them
//   allowed   → students allowed to speak while locked
//   pCurrent / pNext → speaking practice: who is on now / who is next
// =========================================================================
class ClassFlags {
  final bool micLocked;
  final Set<String> allowed;
  final bool practiceActive;
  final String current;
  final String currentName;
  final String next;
  final String nextName;
  final int done;
  final int total;

  const ClassFlags({
    required this.micLocked,
    required this.allowed,
    required this.practiceActive,
    required this.current,
    required this.currentName,
    required this.next,
    required this.nextName,
    required this.done,
    required this.total,
  });

  factory ClassFlags.from(Map<String, Object> c) {
    String str(String k) => (c[k] ?? '').toString();
    int toInt(String k) {
      final v = c[k];
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse('${v ?? ''}') ?? 0;
    }

    final a = c['allowed'];
    return ClassFlags(
      micLocked: c['micLocked'] == true,
      allowed: a is List ? a.map((e) => e.toString()).toSet() : <String>{},
      practiceActive: c['pActive'] == true,
      current: str('pCurrent'),
      currentName: str('pCurrentName'),
      next: str('pNext'),
      nextName: str('pNextName'),
      done: toInt('pDone'),
      total: toInt('pTotal'),
    );
  }

  bool canSpeak(String me) => !micLocked || allowed.contains(me);
}

// =========================================================================
// 🚀 STREAM MANAGER — token + connection prepared when the class page
// opens, so tapping "Join" only has to join (no 10 second wait).
// =========================================================================
class StreamManager {
  static StreamVideo? _client;
  static String? _userId;
  static String? _token;
  static DateTime? _tokenAt;
  static String _apiKey = 'urzyyp7kctqv';
  static Future<StreamVideo>? _pending;

  /// true while the student is inside a class (never swap the client then)
  static bool inCall = false;

  static bool get _fresh =>
      _token != null &&
      _tokenAt != null &&
      DateTime.now().difference(_tokenAt!) < const Duration(hours: 5);

  static Future<void> _fetchToken(String userId, String userName) async {
    final res = await http
        .post(
          Uri.parse("${ApiEndpoints.baseUrl}/stream/token"),
          headers: _authHeaders(json: true),
          body: jsonEncode({"userId": userId, "name": userName}),
        )
        .timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception("Could not get class access (${res.statusCode})");
    }
    final data = jsonDecode(res.body);
    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) throw Exception("Class token missing");
    _token = token;
    _apiKey = data['apiKey']?.toString() ?? _apiKey;
    _tokenAt = DateTime.now();
  }

  static Future<StreamVideo> clientFor({
    required String userId,
    required String userName,
  }) {
    final c = _client;
    if (c != null && _userId == userId && (_fresh || inCall)) {
      return Future.value(c);
    }
    return _pending ??= _create(userId, userName).whenComplete(() {
      _pending = null;
    });
  }

  static Future<StreamVideo> _create(String userId, String userName) async {
    if (!_fresh || _userId != userId) await _fetchToken(userId, userName);
    try {
      await StreamVideo.reset(disconnect: true);
    } catch (_) {}
    _client = StreamVideo(
      _apiKey,
      user: User.regular(userId: userId, name: userName),
      userToken: _token!,
    );
    _userId = userId;
    return _client!;
  }

  /// Old API (kept so any other screen that still calls it keeps working)
  static Future<StreamVideo> getClient({
    required String userId,
    required String userName,
    required String token,
  }) async {
    if (_client != null && _userId == userId) return _client!;
    _token = token;
    _tokenAt = DateTime.now();
    try {
      await StreamVideo.reset(disconnect: true);
    } catch (_) {}
    _client = StreamVideo(
      _apiKey,
      user: User.regular(userId: userId, name: userName),
      userToken: token,
    );
    _userId = userId;
    return _client!;
  }

  static Future<void> reset() async {
    try {
      await StreamVideo.reset(disconnect: true);
    } catch (_) {}
    _client = null;
    _userId = null;
    _token = null;
    _tokenAt = null;
    inCall = false;
  }
}

// =========================================================================
// 🌐 SAFE GLOBAL OVERLAY CONTROLLER (minimized class bubble)
// =========================================================================
class GlobalAudioOverlayController {
  static OverlayEntry? _overlayEntry;
  static Call? currentCall;
  static String? currentUserId;
  static String? currentClassName;
  static LiveSessionWidget? activeWidgetRef;

  static void showOverlay(
    BuildContext context,
    Call call,
    String userId,
    String className, {
    LiveSessionWidget? widgetRef,
  }) {
    if (_overlayEntry != null) return;
    currentCall = call;
    currentUserId = userId;
    currentClassName = className;
    activeWidgetRef = widgetRef;

    final overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => const FloatingAudioPiPWidget(),
    );

    overlayState.insert(_overlayEntry!);
  }

  static void removeOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
    currentCall = null;
  }
}

class FloatingAudioPiPWidget extends StatefulWidget {
  const FloatingAudioPiPWidget({super.key});

  @override
  State<FloatingAudioPiPWidget> createState() => _FloatingAudioPiPWidgetState();
}

class _FloatingAudioPiPWidgetState extends State<FloatingAudioPiPWidget> {
  Offset _position = const Offset(16, 110);

  @override
  Widget build(BuildContext context) {
    final call = GlobalAudioOverlayController.currentCall;
    final userId = GlobalAudioOverlayController.currentUserId;
    final widgetRef = GlobalAudioOverlayController.activeWidgetRef;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color overlaySurface = isDark ? AppColors.darkSurface : Colors.white;
    final Color overlayText = isDark ? AppColors.darkText : AppColors.text;
    final Color accent = isDark ? AppColors.teal : AppColors.navy;

    if (call == null || userId == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: overlaySurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accent.withOpacity(isDark ? 0.55 : 0.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.38 : 0.16),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: StreamBuilder<CallState>(
              stream: call.state.asStream(),
              initialData: call.state.value,
              builder: (context, snapshot) {
                final callState = snapshot.data ?? call.state.value;
                final participants = callState.callParticipants;
                final flags = ClassFlags.from(callState.custom);
                final bool canSpeak = flags.canSpeak(userId);

                final localParticipant = participants.firstWhereOrNull(
                  (p) => p.userId == userId,
                );
                final bool isMuted = localParticipant != null
                    ? !localParticipant.isAudioEnabled
                    : true;
                final speaker = participants.firstWhereOrNull(
                  (p) => p.isSpeaking,
                );

                String line = speaker != null
                    ? "🗣️ ${speaker.name} is speaking"
                    : "Audio connected";
                if (flags.current == userId) {
                  line = "🎤 Your turn to practice!";
                } else if (flags.current.isNotEmpty) {
                  line = "🎤 ${flags.currentName} is practicing";
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xff12B76A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "LIVE CLASS",
                              style: GoogleFonts.poppins(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            GlobalAudioOverlayController.removeOverlay();
                            Get.to(
                              () => StudentAudioRoomScreen(
                                call: call,
                                widgetRef: widgetRef,
                                userId: userId,
                                initialMuted: isMuted,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              color: accent,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        line,
                        style: GoogleFonts.poppins(
                          color: overlayText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isMuted && !canSpeak) {
                            Get.snackbar(
                              "Mic locked",
                              "Your trainer has muted everyone. Wait until you are allowed to speak.",
                              backgroundColor: AppColors.warning,
                              colorText: Colors.black,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                            );
                            return;
                          }
                          try {
                            await call.setMicrophoneEnabled(enabled: isMuted);
                          } catch (e) {
                            debugPrint("PiP Audio Toggle Error: $e");
                          }
                        },
                        icon: Icon(
                          isMuted
                              ? (canSpeak ? Icons.mic_off_rounded : Icons.lock_rounded)
                              : Icons.mic_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        label: Text(
                          isMuted ? (canSpeak ? "UNMUTE" : "MIC LOCKED") : "MUTE",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMuted
                              ? (canSpeak ? const Color(0xff2E90FA) : Colors.grey)
                              : Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 🚀 LIVE SESSION ENTRY (join page)
// =========================================================================
class LiveSessionWidget extends StatefulWidget {
  final String language;
  final String stage;
  final String type;

  const LiveSessionWidget({
    super.key,
    required this.language,
    required this.stage,
    required this.type,
  });

  @override
  State<LiveSessionWidget> createState() => _LiveSessionWidgetState();
}

class _JoinFailed implements Exception {
  final String reason;
  const _JoinFailed(this.reason);
  @override
  String toString() => reason;
}

class _ClassStatus {
  final String callId;
  final bool started;
  const _ClassStatus(this.callId, this.started);
}

class _PreparedClass {
  final StreamVideo client;
  final String section; // effective section (after merges)
  const _PreparedClass(this.client, this.section);
}

class _LiveSessionWidgetState extends State<LiveSessionWidget> {
  final AuthController authController = Get.find<AuthController>();
  bool isLoading = false;
  bool joinMuted = true;
  Future<_PreparedClass>? _prep;
  bool _ready = false;

  static final Map<String, String> _sectionCache = {};

  bool get isDark => Get.isDarkMode;
  Color get accent => isDark ? AppColors.teal : AppColors.navy;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get surface2 => isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft;
  Color get textMain => isDark ? AppColors.darkText : AppColors.text;
  Color get textMuted =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.border;

  String get _userId {
    final user = authController.userData;
    return (user['id'] ?? user['_id']).toString();
  }

  String get _userName =>
      (authController.userData['name'] ?? 'Student').toString();

  @override
  void initState() {
    super.initState();
    if (GlobalAudioOverlayController.currentCall == null) _startPrepare();
  }

  // ⚡ Token, connection and section are fetched while the student reads
  // this page — in parallel — so "Join" is almost instant.
  void _startPrepare() {
    _ready = false;
    final f = _prepare();
    _prep = f;
    f.then(
      (_) {
        if (mounted) setState(() => _ready = true);
      },
      onError: (e) => debugPrint("Class prepare failed: $e"),
    );
  }

  Future<String> _resolveSection(String rawSection) async {
    final key = "${widget.language}|${widget.stage}|$rawSection";
    final cached = _sectionCache[key];
    if (cached != null) return cached;
    try {
      final res = await http
          .get(
            Uri.parse(
              "${ApiEndpoints.baseUrl}/admin/resolve-section?language=${widget.language}&stage=${widget.stage}&section=$rawSection",
            ),
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final eff = data['effectiveSection']?.toString().toLowerCase();
        if (eff != null && eff.isNotEmpty) {
          _sectionCache[key] = eff;
          return eff;
        }
      }
    } catch (e) {
      debugPrint("Resolve section error (using own section): $e");
    }
    return rawSection;
  }

  Future<_PreparedClass> _prepare() async {
    final user = authController.userData;
    final String rawSection = (user['onlineSection'] ?? user['section'] ?? 'A')
        .toString()
        .toLowerCase();

    final results = await Future.wait<Object>([
      StreamManager.clientFor(userId: _userId, userName: _userName),
      _resolveSection(rawSection),
    ]);
    final client = results[0] as StreamVideo;
    final section = results[1] as String;
    return _PreparedClass(client, section);
  }

  /// Asks the server for today's call id and whether the trainer has started.
  /// Guest sections (merged for the day) get the host section's call.
  Future<_ClassStatus> _classStatus(String section) async {
    final res = await http
        .post(
          Uri.parse("${ApiEndpoints.baseUrl}/stream/prepare-call"),
          headers: _authHeaders(json: true),
          body: jsonEncode({
            "userId": _userId,
            "language": widget.language,
            "stage": widget.stage,
            "section": section,
            "type": widget.type,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw _JoinFailed("Server: ${data['error'] ?? res.statusCode}");
    }
    if (data['memberError'] != null) debugPrint("Server memberError: ${data['memberError']}");
    return _ClassStatus(data['callId'].toString(), data['started'] == true);
  }

  Future<void> _join() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      _PreparedClass p;
      try {
        p = await (_prep ?? _prepare());
      } catch (_) {
        // First try failed (e.g. network blip) → one fresh attempt
        final retry = _prepare();
        _prep = retry;
        p = await retry;
      }

      // Checked at tap time: has the trainer started today's class?
      final status = await _classStatus(p.section);
      if (!status.started) {
        _showNotStartedDialog();
        return;
      }
      final String callId = status.callId;

      final options = CallConnectOptions(
        microphone: joinMuted ? TrackOption.disabled() : TrackOption.enabled(),
      );

      // One step: join + mic setting (no getOrCreate, no mute-after-join)
      var call = p.client.makeCall(
        callType: StreamCallType.defaultType(),
        id: callId,
      );
      var result = await call.join(connectOptions: options);

      if (result.isFailure) {
        debugPrint("Join attempt 1 failed: $result");
        // Stale connection / old call still open on this phone → fresh client, try once more
        try {
          await call.leave();
        } catch (_) {}
        await StreamManager.reset();
        final client = await StreamManager.clientFor(
          userId: _userId,
          userName: _userName,
        );
        call = client.makeCall(
          callType: StreamCallType.defaultType(),
          id: callId,
        );
        result = await call.join();
        if (result.isSuccess) {
          try {
            await call.setMicrophoneEnabled(enabled: !joinMuted);
          } catch (_) {}
        } else {
          debugPrint("Join attempt 2 failed: $result");
        }
      }
      if (result.isFailure) {
        // The real reason is kept in the call's disconnect status
        throw _JoinFailed("${call.state.value.status}");
      }

      GlobalAudioOverlayController.removeOverlay();
      Get.to(
        () => StudentAudioRoomScreen(
          call: call,
          widgetRef: widget,
          userId: _userId,
          initialMuted: joinMuted,
        ),
      );
    } on SocketException {
      _showNoInternetSnackbar();
    } on TimeoutException {
      _showNoInternetSnackbar();
    } catch (e) {
      debugPrint("Join error: $e");
      final live = await _isClassLive();
      if (live == false) {
        // Most common reason: the trainer has not started the class yet
        _showNotStartedDialog();
      } else {
        final reason = e is _JoinFailed ? e.reason : e.toString();
        Get.snackbar(
          "Could not join",
          "Please try again in a moment.\n(${reason.length > 300 ? reason.substring(0, 300) : reason})",
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        );
      }
      _startPrepare();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// true = trainer is live, false = class not started, null = unknown
  Future<bool?> _isClassLive() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              "${ApiEndpoints.baseUrl}/live/user/get?language=${widget.language}&stage=${widget.stage.toLowerCase().replaceAll(' ', '')}&type=${widget.type}",
            ),
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return true;
      if (res.statusCode == 404) return false;
    } catch (_) {}
    return null;
  }

  void _showNotStartedDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.schedule_rounded, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Class not started yet",
                style: GoogleFonts.poppins(
                  color: textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _ownSlot != null
              ? "Your trainer hasn't started the class yet.\nYour class time is ${_ownSlot!.shortLabel}. Please join then."
              : "Your trainer hasn't started the class yet. Please try again when the class starts.",
          style: GoogleFonts.poppins(color: textMuted, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ⏰ Batch time: the student's own timing for this language + stage
  // ---------------------------------------------------------------------
  BatchSlot? get _ownSlot {
    final user = authController.userData;
    final stageKey = widget.stage.toLowerCase().replaceAll(' ', '');
    final field = widget.language.toLowerCase() == 'hindi' ? 'hindiBatch' : 'englishBatch';
    final map = user[field];
    final perStage = map is Map ? map[stageKey] : null;
    return BatchSlots.find(perStage) ?? BatchSlots.find(user['batchTime']);
  }

  /// Same window as the server: 30 min before start → 15 min after the end
  bool get _outsideMyBatch {
    final slot = _ownSlot;
    if (slot == null) return false;
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    return mins < slot.startMinutes - 30 || mins > slot.startMinutes + 90 + 15;
  }

  void _returnToClass(Call call) {
    GlobalAudioOverlayController.removeOverlay();
    final me = call.state.value.callParticipants.firstWhereOrNull(
      (p) => p.userId == _userId,
    );
    final bool muted = !(me?.isAudioEnabled ?? false);
    Get.to(
      () => StudentAudioRoomScreen(
        call: call,
        widgetRef: widget,
        userId: _userId,
        initialMuted: muted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Call? activeCall = GlobalAudioOverlayController.currentCall;
    final bool inCall = activeCall != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textMain, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "${widget.language} • ${widget.stage.toUpperCase()}",
          style: GoogleFonts.poppins(
            color: textMain,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                _heroCard(inCall),
                const SizedBox(height: 14),
                if (!inCall) ...[
                  if (_outsideMyBatch) ...[
                    _otherBatchCard(),
                    const SizedBox(height: 12),
                  ],
                  _micChoice(),
                  const SizedBox(height: 12),
                  _rulesCard(),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            final ac = activeCall;
                            if (ac != null) {
                              _returnToClass(ac);
                            } else {
                              _join();
                            }
                          },
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            inCall
                                ? Icons.arrow_forward_rounded
                                : Icons.headset_mic_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                    label: Text(
                      isLoading
                          ? "Joining…"
                          : inCall
                          ? "Return to live class"
                          : _outsideMyBatch
                          ? "Join anyway (no attendance)"
                          : "Join live class",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inCall ? AppColors.success : accent,
                      disabledBackgroundColor: accent.withOpacity(.7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCard(bool inCall) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navy.withOpacity(.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              inCall ? Icons.headset_rounded : Icons.headset_mic_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            inCall ? "You're in a live class" : "Live audio class",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${widget.language} • ${widget.stage.toUpperCase()}",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: inCall || _ready
                        ? const Color(0xff12B76A)
                        : const Color(0xffF7DF55),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  inCall
                      ? "Connected"
                      : _ready
                      ? "Ready to join"
                      : "Getting ready…",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _otherBatchCard() {
    final slot = _ownSlot;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(isDark ? .16 : .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withOpacity(.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Not your batch time",
                  style: GoogleFonts.poppins(
                    color: textMain,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Your class is ${slot?.shortLabel ?? ''}. You can listen now, but attendance counts only in your own batch.",
                  style: GoogleFonts.poppins(
                    color: textMuted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _micChoice() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              joinMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Join with mic off",
                  style: GoogleFonts.poppins(
                    color: textMain,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Recommended. Unmute when you want to speak.",
                  style: GoogleFonts.poppins(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: joinMuted,
            activeColor: accent,
            onChanged: (v) => setState(() => joinMuted = v),
          ),
        ],
      ),
    );
  }

  Widget _rulesCard() {
    Widget rule(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: textMuted,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          rule(Icons.lock_rounded,
              "Your trainer may mute everyone. You can speak again when the trainer allows."),
          rule(Icons.record_voice_over_rounded,
              "During speaking practice you'll see “Your turn” when it's your chance to speak."),
          rule(Icons.phone_android_rounded,
              "Keep the app open so your attendance minutes are counted."),
        ],
      ),
    );
  }
}

// =========================================================================
// 🎧 STUDENT AUDIO ROOM
// =========================================================================
class StudentAudioRoomScreen extends StatefulWidget {
  final Call call;
  final LiveSessionWidget? widgetRef;
  final String userId;
  final bool initialMuted;

  const StudentAudioRoomScreen({
    super.key,
    required this.call,
    this.widgetRef,
    required this.userId,
    required this.initialMuted,
  });

  @override
  State<StudentAudioRoomScreen> createState() => _StudentAudioRoomScreenState();
}

class _StudentAudioRoomScreenState extends State<StudentAudioRoomScreen>
    with WidgetsBindingObserver {
  bool isToggling = false;
  bool _isAppSwitchWarningShown = false;
  bool _isPoorConnection = false;
  bool _isExiting = false;
  bool _seenSelf = false;

  String? _attendanceId;
  Timer? _syncTimer;
  Timer? _netTimer;
  Timer? _missingTimer;
  StreamSubscription<CallState>? _sub;

  ClassFlags? _lastFlags;
  DateTime? _lastForcedMute;
  String? _outsideBatchOwn; // set when the server says "not your batch"

  bool get isDark => Get.isDarkMode;
  Color get backgroundColor =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get cardColor => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get accent => isDark ? AppColors.teal : AppColors.navy;
  Color get roomText => isDark ? AppColors.darkText : AppColors.text;
  Color get roomSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get roomBorder => isDark ? AppColors.darkBorder : AppColors.border;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    StreamManager.inCall = true;

    _recordOnlineJoin();

    _sub = widget.call.state.asStream().listen(_onCallState);
    _onCallState(widget.call.state.value);

    _netTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      final connected = await _checkInternetConnection();
      if (mounted && connected == _isPoorConnection) {
        setState(() => _isPoorConnection = !connected);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _syncTimer?.cancel();
    _netTimer?.cancel();
    _missingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Call state: end/kick detection, mic-lock enforcement, notifications
  // ---------------------------------------------------------------------
  void _onCallState(CallState s) {
    if (!mounted || _isExiting) return;

    if (s.endedAt != null) {
      _handleClassExit(message: "The trainer ended the class.");
      return;
    }

    final me = s.callParticipants.firstWhereOrNull(
      (p) => p.userId == widget.userId,
    );
    if (me != null) {
      _seenSelf = true;
      _missingTimer?.cancel();
      _missingTimer = null;
    } else if ((_seenSelf || s.status.isDisconnected) && _missingTimer == null) {
      // Short network blips can hide us for a moment — wait before leaving
      _missingTimer = Timer(const Duration(seconds: 5), () {
        final still = widget.call.state.value.callParticipants.any(
          (p) => p.userId == widget.userId,
        );
        if (!still) {
          _handleClassExit(
            message: "You were removed from the class or the connection was lost.",
          );
        }
      });
    }

    final flags = ClassFlags.from(s.custom);
    final canSpeak = flags.canSpeak(widget.userId);

    // 🔒 Locked by the trainer → keep the mic off
    if (!canSpeak && me != null && me.isAudioEnabled) {
      final now = DateTime.now();
      if (_lastForcedMute == null ||
          now.difference(_lastForcedMute!).inMilliseconds > 1500) {
        _lastForcedMute = now;
        widget.call.setMicrophoneEnabled(enabled: false);
      }
    }

    final prev = _lastFlags;
    if (prev != null) {
      final bool couldSpeak = prev.canSpeak(widget.userId);
      if (flags.current == widget.userId && prev.current != widget.userId) {
        HapticFeedback.heavyImpact();
        _notice(
          "Your turn to practice! Tap the mic and speak.",
          Icons.record_voice_over_rounded,
          AppColors.success,
        );
      } else if (flags.next == widget.userId && prev.next != widget.userId) {
        _notice("You're next — get ready.", Icons.hourglass_top_rounded, AppColors.warning);
      } else if (flags.micLocked && !prev.micLocked && !canSpeak) {
        _notice(
          "Trainer muted everyone. You can speak when allowed.",
          Icons.lock_rounded,
          AppColors.warning,
        );
      } else if (!flags.micLocked && prev.micLocked) {
        _notice("Mics unlocked — you can speak now.", Icons.lock_open_rounded, AppColors.success);
      } else if (flags.micLocked && canSpeak && !couldSpeak) {
        _notice("The trainer allowed you to speak. Tap the mic.", Icons.mic_rounded, AppColors.success);
      }
    }
    _lastFlags = flags;
  }

  void _notice(String text, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------
  // Attendance: join → sync every minute → leave (server counts minutes)
  // ---------------------------------------------------------------------
  Future<void> _recordOnlineJoin() async {
    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.joinOnlineClass),
        headers: _authHeaders(json: true),
        body: jsonEncode({
          "userId": widget.userId,
          "language": widget.widgetRef?.language ?? "English",
          "stage": widget.widgetRef?.stage ?? "stage1",
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['outsideBatch'] == true) {
          // Listening only: no attendance in another batch
          if (mounted) {
            setState(() => _outsideBatchOwn = data['ownBatch']?.toString() ?? '');
          }
          return;
        }
        _attendanceId = data['attendanceId']?.toString();
        _syncTimer?.cancel();
        _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) => _syncOnline());
      } else {
        debugPrint("Record Join failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("Record Join Error: $e");
    }
  }

  Future<void> _syncOnline() async {
    final id = _attendanceId;
    if (id == null) return;
    try {
      await http.post(
        Uri.parse(ApiEndpoints.syncOnlineClass),
        headers: _authHeaders(json: true),
        body: jsonEncode({"attendanceId": id}),
      );
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  Future<void> _recordOnlineLeave() async {
    _syncTimer?.cancel();
    final id = _attendanceId;
    _attendanceId = null;
    if (id == null) return;
    try {
      await http.post(
        Uri.parse(ApiEndpoints.leaveOnlineClass),
        headers: _authHeaders(json: true),
        body: jsonEncode({"attendanceId": id}),
      );
    } catch (e) {
      debugPrint("Record Leave Error: $e");
    }
  }

  void _navigateToHome() {
    String lang = widget.widgetRef?.language ?? '';
    if (lang.isEmpty) {
      try {
        lang = Get.find<AuthController>().userData['language']?.toString() ?? 'english';
      } catch (_) {
        lang = 'english';
      }
    }
    final int tabIndex = (lang.toLowerCase() == 'hindi') ? 1 : 0;
    Get.offAll(() => MainNavigationScreen(initialIndex: tabIndex));
  }

  Future<void> _handleClassExit({String? message}) async {
    if (_isExiting) return;
    _isExiting = true;
    _missingTimer?.cancel();

    await _recordOnlineLeave();
    WakelockPlus.disable();
    StreamManager.inCall = false;
    GlobalAudioOverlayController.removeOverlay();
    try {
      await widget.call.leave();
    } catch (_) {}

    if (mounted) {
      _navigateToHome();
      if (message != null) {
        Get.snackbar(
          "Class Ended",
          message,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      if (!_isAppSwitchWarningShown && mounted) {
        _isAppSwitchWarningShown = true;

        Get.dialog(
          AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            title: Text(
              "⚠️ Leaving class?",
              style: GoogleFonts.poppins(
                color: roomText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Text(
              "Switching to another app can disturb your live class. Do you want to exit the class?",
              style: GoogleFonts.poppins(
                color: roomSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  _isAppSwitchWarningShown = false;
                },
                child: Text(
                  "Stay in Class",
                  style: GoogleFonts.poppins(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Get.back();
                  await _handleClassExit();
                },
                child: Text(
                  "Exit Class",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      _isAppSwitchWarningShown = false;
    }
  }

  Future<void> _toggleMic(bool isCurrentlyMuted, bool canSpeak) async {
    if (isCurrentlyMuted && !canSpeak) {
      HapticFeedback.lightImpact();
      _notice(
        "Your trainer has locked the mics. Wait until you're allowed to speak.",
        Icons.lock_rounded,
        AppColors.warning,
      );
      return;
    }
    setState(() => isToggling = true);
    try {
      await widget.call.setMicrophoneEnabled(enabled: isCurrentlyMuted);
    } catch (e) {
      debugPrint("Mic Toggle Error: $e");
    } finally {
      if (mounted) setState(() => isToggling = false);
    }
  }

  void _minimize() {
    Get.until((route) => route.isFirst);
    GlobalAudioOverlayController.showOverlay(
      context,
      widget.call,
      widget.userId,
      "Live Class",
      widgetRef: widget.widgetRef,
    );
  }

  void _confirmLeaveClass() {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Leave class?",
          style: GoogleFonts.poppins(
            color: roomText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          "Are you sure you want to leave this live class?",
          style: GoogleFonts.poppins(color: roomSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: roomSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Get.back();
              await _handleClassExit();
            },
            child: Text(
              "Leave",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final sessionTitle = widget.widgetRef != null
        ? "${widget.widgetRef!.language} • ${widget.widgetRef!.stage.toUpperCase()}"
        : "Live Class";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimize();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: "Minimize",
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: roomText, size: 28),
            onPressed: _minimize,
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sessionTitle,
                style: GoogleFonts.poppins(
                  color: roomText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xff12B76A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Live audio",
                    style: GoogleFonts.poppins(
                      color: AppColors.success,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: StreamBuilder<CallState>(
          stream: widget.call.state.asStream(),
          initialData: widget.call.state.value,
          builder: (context, snapshot) {
            final callState = snapshot.data ?? widget.call.state.value;

            final seen = <String>{};
            final participants = callState.callParticipants
                .where((p) => seen.add(p.userId))
                .toList();

            final flags = ClassFlags.from(callState.custom);
            final bool canSpeak = flags.canSpeak(widget.userId);

            final me = participants.firstWhereOrNull(
              (p) => p.userId == widget.userId,
            );
            final bool isMuted = me != null ? !me.isAudioEnabled : widget.initialMuted;

            final teachers = participants.where((p) => p.roles.contains('admin')).toList();
            final others = participants
                .where((p) => !p.roles.contains('admin') && p.userId != widget.userId)
                .toList()
              ..sort((a, b) {
                if (a.isSpeaking != b.isSpeaking) return a.isSpeaking ? -1 : 1;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });

            return SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      if (_outsideBatchOwn != null)
                        _banner(
                          Icons.info_outline_rounded,
                          "Listening only — your batch is ${BatchSlots.shortOf(_outsideBatchOwn, fallback: 'another time')}. No attendance now.",
                          AppColors.warning,
                        ),
                      if (callState.status.isReconnecting)
                        _banner(Icons.sync_rounded, "Reconnecting…", Colors.orange.shade700)
                      else if (_isPoorConnection)
                        _banner(Icons.wifi_off_rounded,
                            "Your internet is unstable.", Colors.orange.shade800),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          children: [
                            _practiceCard(flags),
                            if (flags.micLocked) ...[
                              _lockCard(canSpeak),
                              const SizedBox(height: 12),
                            ],
                            for (final t in teachers) ...[
                              _trainerCard(t),
                              const SizedBox(height: 14),
                            ],
                            Row(
                              children: [
                                Text(
                                  "Classmates",
                                  style: GoogleFonts.poppins(
                                    color: roomText,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${others.length + 1}",
                                  style: GoogleFonts.poppins(
                                    color: roomSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 12,
                              children: [
                                if (me != null) _personBubble(me, flags, isMe: true),
                                ...others.map((p) => _personBubble(p, flags)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _bottomBar(isMuted, canSpeak),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _banner(IconData icon, String text, Color color) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _practiceCard(ClassFlags f) {
    if (f.current.isEmpty) return const SizedBox.shrink();

    final bool myTurn = f.current == widget.userId;
    final bool imNext = f.next == widget.userId;

    final List<Color> colors = myTurn
        ? [AppColors.success, const Color(0xff0E9384)]
        : imNext
        ? [const Color(0xffF5B83D), const Color(0xffE59E1B)]
        : [AppColors.navy, AppColors.navy.withOpacity(.85)];

    final String title = myTurn
        ? "Your turn to practice!"
        : imNext
        ? "You're next — get ready"
        : "${f.currentName} is practicing";
    final String subtitle = myTurn
        ? "Tap the mic below and speak. Your trainer is listening."
        : imNext
        ? "${f.currentName} is speaking now. You'll be called after."
        : (f.nextName.isNotEmpty ? "Next: ${f.nextName}" : "Listen and learn");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              myTurn
                  ? Icons.mic_rounded
                  : imNext
                  ? Icons.hourglass_top_rounded
                  : Icons.record_voice_over_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.88),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (f.total > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${f.done}/${f.total}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lockCard(bool canSpeak) {
    final Color c = canSpeak ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.withOpacity(isDark ? .16 : .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Row(
        children: [
          Icon(canSpeak ? Icons.lock_open_rounded : Icons.lock_rounded, color: c, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canSpeak
                  ? "The trainer allowed you to speak."
                  : "Mics are locked by the trainer. You can speak when allowed.",
              style: GoogleFonts.poppins(
                color: roomText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trainerCard(CallParticipantState t) {
    final bool speaking = t.isSpeaking;
    final String name = t.name.trim().isEmpty ? 'Trainer' : t.name.trim();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: speaking ? AppColors.teal : roomBorder,
          width: speaking ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _avatar(name, 26, ring: speaking, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: roomText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  speaking ? "Trainer • speaking" : "Trainer",
                  style: GoogleFonts.poppins(
                    color: speaking ? AppColors.teal : roomSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            t.isAudioEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
            color: t.isAudioEnabled ? AppColors.success : AppColors.error,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _personBubble(CallParticipantState p, ClassFlags f, {bool isMe = false}) {
    final String name = isMe
        ? "You"
        : (p.name.trim().isEmpty ? "Student" : p.name.trim().split(' ').first);
    final bool speaking = p.isSpeaking;
    final bool practicing = f.current == p.userId;
    final bool micOn = p.isAudioEnabled;

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _avatar(
                p.name.trim().isEmpty ? "S" : p.name,
                24,
                ring: speaking || practicing,
                ringColor: practicing && !speaking ? const Color(0xffF5B83D) : AppColors.teal,
                color: isMe ? AppColors.teal : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: roomBorder),
                  ),
                  child: Icon(
                    micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    size: 11,
                    color: micOn ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: roomText,
              fontSize: 10.5,
              fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(
    String name,
    double radius, {
    bool ring = false,
    Color? ringColor,
    Color? color,
  }) {
    const palette = [
      Color(0xFF155A88),
      Color(0xFF7A5AF8),
      Color(0xFF0E9384),
      Color(0xFFDD6B20),
      Color(0xFFC11574),
      Color(0xFF4E5BA6),
    ];
    int sum = 0;
    for (final c in name.codeUnits) {
      sum += c;
    }
    final Color base = color ?? palette[sum % palette.length];
    final String initial = name.trim().isEmpty ? "?" : name.trim()[0].toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(ring ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring ? Border.all(color: ringColor ?? AppColors.teal, width: 2.5) : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: base.withOpacity(isDark ? .30 : .14),
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : base,
            fontSize: radius * .78,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(bool isMuted, bool canSpeak) {
    final bool locked = isMuted && !canSpeak;
    final Color micColor = locked
        ? Colors.grey
        : isMuted
        ? accent
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: roomBorder)),
      ),
      child: Row(
        children: [
          _sideButton(Icons.picture_in_picture_alt_rounded, "Minimize", accent, _minimize),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isToggling ? null : () => _toggleMic(isMuted, canSpeak),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: micColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: micColor.withOpacity(.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: isToggling
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            locked
                                ? Icons.lock_rounded
                                : isMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  locked
                      ? "Mic locked"
                      : isMuted
                      ? "Tap to speak"
                      : "You're live — tap to mute",
                  style: GoogleFonts.poppins(
                    color: roomText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _sideButton(Icons.call_end_rounded, "Leave", AppColors.error, _confirmLeaveClass),
        ],
      ),
    );
  }

  Widget _sideButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: roomSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
