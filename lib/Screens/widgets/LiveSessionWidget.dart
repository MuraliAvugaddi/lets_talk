import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

// 🌐 Safe Global Overlay Controller with Direct Audio Control
class GlobalAudioOverlayController {
  static OverlayEntry? _overlayEntry;
  static Call? currentCall;
  static String? currentUserId;
  static String? currentClassName;

  static void showOverlay(
    BuildContext context,
    Call call,
    String userId,
    String className,
  ) {
    if (_overlayEntry != null) return;
    currentCall = call;
    currentUserId = userId;
    currentClassName = className;

    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

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
  Offset _position = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    final call = GlobalAudioOverlayController.currentCall;
    final userId = GlobalAudioOverlayController.currentUserId;

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
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff14141E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xff2E90FA), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: StreamBuilder<CallState>(
              stream: call.state.asStream(),
              builder: (context, snapshot) {
                final callState = snapshot.data;
                final rawParticipants = callState?.callParticipants ?? [];

                final seenIds = <String>{};
                final participants = rawParticipants.where((p) {
                  if (seenIds.contains(p.userId)) return false;
                  seenIds.add(p.userId);
                  return true;
                }).toList();

                final localParticipant = participants.firstWhereOrNull(
                  (p) => p.userId == userId,
                );
                final bool isMuted = localParticipant != null
                    ? !localParticipant.isAudioEnabled
                    : true;
                final speaker = participants.firstWhereOrNull(
                  (p) => p.isSpeaking,
                );

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
                                color: const Color(0xff12B76A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                GlobalAudioOverlayController.removeOverlay();
                                Get.to(
                                  () => StudentAudioRoomScreen(
                                    call: call,
                                    widgetRef: null,
                                    userId: userId,
                                    initialMuted: isMuted,
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                WakelockPlus.disable();
                                await call.leave();
                                GlobalAudioOverlayController.removeOverlay();
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        speaker != null
                            ? "🗣️ ${speaker.name} is speaking"
                            : "Audio Connected",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              if (isMuted) {
                                await call.setMicrophoneEnabled(enabled: true);
                              } else {
                                await call.setMicrophoneEnabled(enabled: false);
                              }
                            } catch (e) {
                              debugPrint("PiP Audio Toggle Error: $e");
                            }
                          },
                          icon: Icon(
                            isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          label: Text(
                            isMuted ? "UNMUTE" : "MUTE",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMuted
                                ? const Color(0xff2E90FA)
                                : Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
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

class LiveSessionWidget extends StatefulWidget {
  final String language; // "English" or "Hindi"
  final String stage; // "stage1" ... "stage7"
  final String type; // "class" or "club"

  const LiveSessionWidget({
    super.key,
    required this.language,
    required this.stage,
    required this.type,
  });

  @override
  State<LiveSessionWidget> createState() => _LiveSessionWidgetState();
}

class _LiveSessionWidgetState extends State<LiveSessionWidget>
    with WidgetsBindingObserver {
  final AuthController authController = Get.find<AuthController>();

  bool isLoading = false;
  static Call? activeCall;

  final Color deepOceanBlue = const Color(0xff065381);
  final Color pureWhite = const Color(0xffFFFFFF);
  final Color textDark = const Color(0xff0F172A);
  final Color textMuted = const Color(0xff64748B);
  final Color cardColor = const Color(0xff14141E);
  final Color accentBlue = const Color(0xff2E90FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _calculateCurrentBatch() {
    final now = DateTime.now();
    final int currentMinutes = now.hour * 60 + now.minute;
    if (currentMinutes >= 330 && currentMinutes < 420)
      return "5:30 AM - 7:00 AM";
    if (currentMinutes >= 420 && currentMinutes < 510)
      return "7:00 AM - 8:30 AM";
    if (currentMinutes >= 540 && currentMinutes < 630)
      return "9:00 AM - 10:30 AM";
    if (currentMinutes >= 630 && currentMinutes < 720)
      return "10:30 AM - 12:00 PM";
    if (currentMinutes >= 930 && currentMinutes < 1020)
      return "3:30 PM - 5:00 PM";
    if (currentMinutes >= 1020 && currentMinutes < 1110)
      return "5:00 PM - 6:30 PM";
    if (currentMinutes >= 1110 && currentMinutes < 1400)
      return "6:30 PM - 8:00 PM";
    return "Custom Session";
  }

  void _showPreJoinPermissionDialog() {
    bool joinMuted = true;

    Get.dialog(
      Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.mic_off_rounded,
                          color: accentBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Join Audio Session",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Configure your entry preference",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "You can join muted and use the floating mini-player to browse home notes while listening.",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff1E1E2D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Join Muted",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentBlue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "RECOMMENDED",
                                      style: GoogleFonts.poppins(
                                        color: accentBlue,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Unmute anytime to speak.",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: joinMuted,
                          activeColor: accentBlue,
                          onChanged: (val) {
                            setDialogState(() => joinMuted = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Get.back();
                            _joinAudioClassStream(initialMuted: joinMuted);
                          },
                          child: Text(
                            "Connect",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _joinAudioClassStream({required bool initialMuted}) async {
    setState(() => isLoading = true);
    final user = authController.userData;
    final userId = (user['id'] ?? user['_id']).toString();
    final userName = user['name'] ?? 'Student';
    final String section = (user['onlineSection'] ?? user['section'] ?? 'A')
        .toString()
        .toLowerCase();
    final currentBatch = _calculateCurrentBatch();
    final now = DateTime.now();

    try {
      final tokenRes = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/stream/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "name": userName, "role": "user"}),
      );

      if (tokenRes.statusCode != 200) throw Exception("Failed to get token");
      final tokenData = jsonDecode(tokenRes.body);
      final token = tokenData['token'];

      await StreamVideo.reset(disconnect: true);
      final client = StreamVideo(
        'urzyyp7kctqv',
        user: User.regular(userId: userId, name: userName),
        userToken: token,
      );

      final callId = widget.language.toLowerCase() == "english"
          ? "${widget.language.toLowerCase()}_${widget.stage.toLowerCase()}_sec${section}_${widget.type}"
          : "${widget.language.toLowerCase()}_${widget.stage.toLowerCase()}_${widget.type}";

      final call = client.makeCall(
        callType: StreamCallType.defaultType(),
        id: callId,
      );

      await call.join();
      await call.setMicrophoneEnabled(enabled: !initialMuted);

      activeCall = call;

      Get.to(
        () => StudentAudioRoomScreen(
          call: call,
          widgetRef: widget,
          userId: userId,
          initialMuted: initialMuted,
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not join audio class: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "${widget.language} • ${widget.stage.toUpperCase()}",
          style: GoogleFonts.poppins(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator(color: deepOceanBlue)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: deepOceanBlue.withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.headset_mic_rounded,
                        size: 56,
                        color: deepOceanBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Live Audio Classroom",
                      style: GoogleFonts.poppins(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap below to connect directly to your instructor's live voice session securely.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: textMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : _showPreJoinPermissionDialog,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          isLoading ? "CONNECTING..." : "JOIN LIVE AUDIO CLASS",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deepOceanBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

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
  String? _attendanceId;
  bool _isAttendanceStarted = false;

  final Color backgroundColor = const Color(0xff09090C);
  final Color cardColor = const Color(0xff14141E);
  final Color accentBlue = const Color(0xff2E90FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    // 🚀 Record online class join for attendance tracking
    _recordOnlineJoin();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        await widget.call.setMicrophoneEnabled(enabled: !widget.initialMuted);

        await Future.delayed(const Duration(seconds: 3));
        if (mounted && widget.initialMuted) {
          await widget.call.setMicrophoneEnabled(enabled: false);
        }
      } catch (e) {
        debugPrint("Initial Mute Enforcement Error: $e");
      }
    });

    widget.call.state.asStream().listen((callState) {
      final participants = callState.callParticipants;
      if (participants.isNotEmpty) {
        final stillInCall = participants.any((p) => p.userId == widget.userId);
        if (!stillInCall && mounted) {
          _recordOnlineLeave();
          WakelockPlus.disable();
          GlobalAudioOverlayController.removeOverlay();
          Get.until((route) => route.isFirst);
          Get.snackbar(
            "Removed from Class",
            "You have been removed from the session by the instructor.",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🚀 Record Join API call
  Future<void> _recordOnlineJoin() async {
    if (_isAttendanceStarted) return;
    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.joinOnlineClass),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": widget.userId,
          "language": widget.widgetRef?.language ?? "English",
          "stage": widget.widgetRef?.stage.toUpperCase() ?? "STAGE 1",
          "batchTime": widget.widgetRef != null
              ? _calculateCurrentBatchStatic()
              : "Custom Session",
          "joinTime": DateTime.now().toIso8601String(),
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _attendanceId = data['attendanceId'];
        _isAttendanceStarted = true;
      }
    } catch (e) {
      debugPrint("Record Join Error: $e");
    }
  }

  // 🚀 Record Leave API call to compute total accumulated time
  Future<void> _recordOnlineLeave() async {
    if (_attendanceId == null) return;
    try {
      await http.post(
        Uri.parse(ApiEndpoints.leaveOnlineClass),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "attendanceId": _attendanceId,
          "leaveTime": DateTime.now().toIso8601String(),
        }),
      );
      _attendanceId = null;
    } catch (e) {
      debugPrint("Record Leave Error: $e");
    }
  }

  String _calculateCurrentBatchStatic() {
    final now = DateTime.now();
    final int currentMinutes = now.hour * 60 + now.minute;
    if (currentMinutes >= 330 && currentMinutes < 420)
      return "5:30 AM - 7:00 AM";
    if (currentMinutes >= 420 && currentMinutes < 510)
      return "7:00 AM - 8:30 AM";
    if (currentMinutes >= 540 && currentMinutes < 630)
      return "9:00 AM - 10:30 AM";
    if (currentMinutes >= 630 && currentMinutes < 720)
      return "10:30 AM - 12:00 PM";
    if (currentMinutes >= 930 && currentMinutes < 1020)
      return "3:30 PM - 5:00 PM";
    if (currentMinutes >= 1020 && currentMinutes < 1110)
      return "5:00 PM - 6:30 PM";
    if (currentMinutes >= 1110 && currentMinutes < 1400)
      return "6:30 PM - 8:00 PM";
    return "Custom Session";
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
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
              "⚠️ Warning: Leaving Class",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Text(
              "Switching away or opening another app (like Instagram) will logout or disrupt your live class session. Do you want to exit the class?",
              style: GoogleFonts.poppins(
                color: Colors.white70,
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
                    color: accentBlue,
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
                  await _recordOnlineLeave();
                  WakelockPlus.disable();
                  GlobalAudioOverlayController.removeOverlay();
                  await widget.call.leave();
                  Get.until((route) => route.isFirst);
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
    }
  }

  Future<void> _toggleMic(bool isCurrentlyMuted) async {
    setState(() => isToggling = true);
    try {
      if (isCurrentlyMuted) {
        await widget.call.setMicrophoneEnabled(enabled: true);
      } else {
        await widget.call.setMicrophoneEnabled(enabled: false);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint("Mic Toggle Error: $e");
      Get.snackbar(
        "Audio Error",
        "Could not change microphone state.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isToggling = false);
    }
  }

  void _confirmLeaveClass() {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Leave Classroom",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          "Are you sure you want to exit this live audio session?",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: Colors.white54,
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
              await _recordOnlineLeave();
              WakelockPlus.disable();
              GlobalAudioOverlayController.removeOverlay();
              await widget.call.leave();
              Get.until((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.until((route) => route.isFirst);
        GlobalAudioOverlayController.showOverlay(
          context,
          widget.call,
          widget.userId,
          "Live Class",
        );
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          title: Text(
            "Classroom Session",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.picture_in_picture_alt_rounded,
                color: Colors.white,
              ),
              tooltip: "Minimize (Read Notes)",
              onPressed: () {
                Get.until((route) => route.isFirst);
                GlobalAudioOverlayController.showOverlay(
                  context,
                  widget.call,
                  widget.userId,
                  "Live Class",
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<CallState>(
          stream: widget.call.state.asStream(),
          builder: (context, snapshot) {
            final callState = snapshot.data;
            final rawParticipants = callState?.callParticipants ?? [];

            final seenUserIds = <String>{};
            final participants = rawParticipants.where((p) {
              if (seenUserIds.contains(p.userId)) return false;
              seenUserIds.add(p.userId);
              return true;
            }).toList();

            final localParticipant = participants.firstWhereOrNull(
              (p) => p.userId == widget.userId,
            );
            final bool isCurrentlyMuted = localParticipant != null
                ? !localParticipant.isAudioEnabled
                : widget.initialMuted;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Participants (${participants.length})",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff12B76A).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "LIVE AUDIO ACTIVE",
                          style: TextStyle(
                            color: Color(0xff12B76A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: participants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      final participantMuted = !p.isAudioEnabled;
                      final isSpeaking = p.isSpeaking;
                      final bool isTeacher = p.roles.contains('admin');

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSpeaking
                                  ? const Color(0xff12B76A)
                                  : accentBlue,
                              child: Text(
                                (p.name.isNotEmpty ? p.name[0] : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.name,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSpeaking) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xff12B76A,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            "TALKING",
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    isTeacher
                                        ? "INSTRUCTOR / ADMIN"
                                        : "STUDENT",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: participantMuted
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.green.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                participantMuted
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                                color: participantMuted
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: const Border(
                      top: BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: isToggling
                                ? null
                                : () => _toggleMic(isCurrentlyMuted),
                            icon: Icon(
                              isCurrentlyMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              isCurrentlyMuted ? "UNMUTE MIC" : "MUTE MIC",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentlyMuted
                                  ? accentBlue
                                  : Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _confirmLeaveClass,
                            icon: const Icon(
                              Icons.exit_to_app_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              "LEAVE",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
