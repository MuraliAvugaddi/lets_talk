import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:lets_talk/Screens/MainNavigationScreen.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/Screens/app_colors.dart';

// =========================================================================
// 🌐 INTERNET CONNECTION HELPER
// =========================================================================
Future<bool> _checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } catch (_) {}
  return false;
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
// 🚀 HIGH-SCALE SINGLETON STREAM MANAGER (Eliminates 5-7s Delay)
// =========================================================================
class StreamManager {
  static StreamVideo? _cachedClient;

  static Future<StreamVideo> getClient({
    required String userId,
    required String userName,
    required String token,
  }) async {
    if (_cachedClient != null) {
      return _cachedClient!;
    }
    _cachedClient = StreamVideo(
      'urzyyp7kctqv',
      user: User.regular(userId: userId, name: userName),
      userToken: token,
    );
    return _cachedClient!;
  }
}

// =========================================================================
// 🌐 SAFE GLOBAL OVERLAY CONTROLLER
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
            width: 236,
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
                        speaker != null
                            ? "🗣️ ${speaker.name} is speaking"
                            : "Audio Connected",
                        style: GoogleFonts.poppins(
                          color: overlayText,
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
                              await call.setMicrophoneEnabled(enabled: isMuted);
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

// =========================================================================
// 🚀 LIVE SESSION ENTRY WIDGET
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

class _LiveSessionWidgetState extends State<LiveSessionWidget>
    with WidgetsBindingObserver {
  final AuthController authController = Get.find<AuthController>();
  bool isLoading = false;

  Color get deepOceanBlue => Get.isDarkMode ? AppColors.teal : AppColors.navy;
  Color get pureWhite =>
      Get.isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get textDark => Get.isDarkMode ? AppColors.darkText : AppColors.text;
  Color get textMuted =>
      Get.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get cardColor =>
      Get.isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get accentBlue => Get.isDarkMode ? AppColors.teal : AppColors.navy;

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

  void _showPreJoinPermissionDialog() {
    bool joinMuted = true;
    final bool isDark = Get.isDarkMode;
    final Color dialogText = isDark ? AppColors.darkText : AppColors.text;
    final Color dialogSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final Color dialogSurface2 = isDark
        ? AppColors.darkSurface2
        : AppColors.surfaceSoft;

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
                                color: dialogText,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Configure your entry preference",
                              style: GoogleFonts.poppins(
                                color: dialogSecondary,
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
                    "Join this live session securely with optimized performance.",
                    style: GoogleFonts.poppins(
                      color: dialogSecondary,
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
                      color: dialogSurface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? Colors.white : AppColors.navy)
                            .withOpacity(0.08),
                      ),
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
                                      color: dialogText,
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
                                  color: dialogSecondary,
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
                              color: dialogSecondary,
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
    final bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
      return;
    }

    setState(() => isLoading = true);
    final user = authController.userData;
    final userId = (user['id'] ?? user['_id']).toString();
    final userName = user['name'] ?? 'Student';
    final String rawSection = (user['onlineSection'] ?? user['section'] ?? 'A')
        .toString()
        .toLowerCase();

    try {
      // 🚀 CHECK IF THIS SECTION IS TEMPORARILY MERGED INTO ANOTHER SECTION TODAY
      String effectiveSection = rawSection;
      try {
        final mergeRes = await http.get(
          Uri.parse("${ApiEndpoints.baseUrl}/admin/resolve-section?language=${widget.language}&stage=${widget.stage}&section=$rawSection"),
        );
        if (mergeRes.statusCode == 200) {
          final mergeData = jsonDecode(mergeRes.body);
          if (mergeData['effectiveSection'] != null) {
            effectiveSection = mergeData['effectiveSection'].toString().toLowerCase();
          }
        }
      } catch (e) {
        debugPrint("Resolve section error (falling back to default): $e");
      }

      final tokenRes = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/stream/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "name": userName, "role": "user"}),
      );

      if (tokenRes.statusCode != 200) throw Exception("Failed to get token");
      final tokenData = jsonDecode(tokenRes.body);
      final token = tokenData['token'];

      final client = await StreamManager.getClient(
        userId: userId,
        userName: userName,
        token: token,
      );

      // 🚀 Use effectiveSection so guest sections join the host section's stream call ID seamlessly
      final callId = widget.language.toLowerCase() == "english"
          ? "${widget.language.toLowerCase()}_${widget.stage.toLowerCase()}_sec${effectiveSection}_${widget.type}"
          : "${widget.language.toLowerCase()}_${widget.stage.toLowerCase()}_${widget.type}";

      final call = client.makeCall(
        callType: StreamCallType.defaultType(),
        id: callId,
      );

      await call.getOrCreate();
      await call.join();

      await call.setMicrophoneEnabled(enabled: !initialMuted);

      GlobalAudioOverlayController.removeOverlay();

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
    final Call? activeGlobalCall = GlobalAudioOverlayController.currentCall;
    final bool isAlreadyInCall = activeGlobalCall != null;

    return Scaffold(
      backgroundColor: Get.isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
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
                        isAlreadyInCall
                            ? Icons.headset_rounded
                            : Icons.headset_mic_rounded,
                        size: 56,
                        color: deepOceanBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isAlreadyInCall
                          ? "Active Class Session"
                          : "Live Audio Classroom",
                      style: GoogleFonts.poppins(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAlreadyInCall
                          ? "You are currently connected to an active audio session."
                          : "Tap below to connect securely to your ${widget.language} class (${widget.stage.toUpperCase()}).",
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
                            : () async {
                                final bool hasInternet =
                                    await _checkInternetConnection();
                                if (!hasInternet) {
                                  _showNoInternetSnackbar();
                                  return;
                                }

                                if (isAlreadyInCall) {
                                  GlobalAudioOverlayController.removeOverlay();
                                  final user = authController.userData;
                                  final userId = (user['id'] ?? user['_id'])
                                      .toString();
                                  Get.to(
                                    () => StudentAudioRoomScreen(
                                      call: activeGlobalCall,
                                      widgetRef: widget,
                                      userId: userId,
                                      initialMuted: false,
                                    ),
                                  );
                                } else {
                                  _showPreJoinPermissionDialog();
                                }
                              },
                        icon: Icon(
                          isAlreadyInCall
                              ? Icons.arrow_forward_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          isAlreadyInCall
                              ? "RETURN TO LIVE CLASS"
                              : "JOIN LIVE AUDIO CLASS",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAlreadyInCall
                              ? const Color(0xff12B76A)
                              : deepOceanBlue,
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

// =========================================================================
// 🌐 STUDENT AUDIO ROOM WITH STRICT MUTE ENFORCEMENT & GUARDS
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
  String? _attendanceId;
  bool _isAttendanceStarted = false;
  bool _isPoorConnection = false;
  Timer? _muteGuardTimer;
  bool _isExiting = false;

  Color get backgroundColor =>
      Get.isDarkMode ? AppColors.darkBackground : AppColors.background;
  Color get cardColor =>
      Get.isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get accentBlue =>
      Get.isDarkMode ? AppColors.teal : const Color.fromARGB(255, 0, 0, 0);
  Color get roomText => Get.isDarkMode ? AppColors.darkText : AppColors.text;
  Color get roomSecondary =>
      Get.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get roomBorder =>
      Get.isDarkMode ? AppColors.darkBorder : AppColors.border;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    _recordOnlineJoin();

    if (widget.initialMuted) {
      int checks = 0;
      _muteGuardTimer = Timer.periodic(const Duration(milliseconds: 400), (
        timer,
      ) async {
        checks++;
        try {
          final localPart = widget.call.state.value.callParticipants
              .firstWhereOrNull((p) => p.userId == widget.userId);

          if (localPart != null && localPart.isAudioEnabled) {
            await widget.call.setMicrophoneEnabled(enabled: false);
          }
        } catch (_) {}

        if (checks >= 8 || !mounted) {
          timer.cancel();
        }
      });
    }

    widget.call.state.asStream().listen((callState) {
      if (!mounted || _isExiting) return;

      final participants = callState.callParticipants;
      final bool stillInCall = participants.any((p) => p.userId == widget.userId);

      if (!stillInCall || callState.endedAt != null) {
        _handleClassExit();
      }
    });

    Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final connected = await _checkInternetConnection();
      if (mounted) {
        setState(() {
          _isPoorConnection = !connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _muteGuardTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
          "batchTime": "Live Session",
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

  /// 🚀 Safely determines language from widgetRef or authController to route back to Hindi or English home tab correctly
  void _navigateToHome() {
    String lang = widget.widgetRef?.language ?? '';
    if (lang.isEmpty) {
      try {
        final authController = Get.find<AuthController>();
        lang = authController.userData['language']?.toString() ?? 'english';
      } catch (_) {
        lang = 'english';
      }
    }

    int tabIndex = (lang.toLowerCase() == 'hindi') ? 1 : 0;
    Get.offAll(() => MainNavigationScreen(initialIndex: tabIndex));
  }

  Future<void> _handleClassExit() async {
    if (_isExiting) return;
    _isExiting = true;

    await _recordOnlineLeave();
    WakelockPlus.disable();
    GlobalAudioOverlayController.removeOverlay();
    try {
      await widget.call.leave();
    } catch (_) {}

    if (mounted) {
      _navigateToHome();
      Get.snackbar(
        "Class Ended",
        "The classroom session has ended or you were removed.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
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
              "⚠️ Warning: Leaving Class",
              style: GoogleFonts.poppins(
                color: roomText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Text(
              "Switching away or opening another app will disrupt your live class session. Do you want to exit the class?",
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

  Future<void> _toggleMic(bool isCurrentlyMuted) async {
    final bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
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

  void _confirmLeaveClass() {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Leave Classroom",
          style: GoogleFonts.poppins(
            color: roomText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          "Are you sure you want to exit this live audio session?",
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

  @override
  Widget build(BuildContext context) {
    final sessionTitle = widget.widgetRef != null
        ? "${widget.widgetRef!.language} • ${widget.widgetRef!.stage.toUpperCase()}"
        : "Classroom Session";

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
          widgetRef: widget.widgetRef,
        );
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          title: Text(
            sessionTitle,
            style: GoogleFonts.poppins(
              color: roomText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.picture_in_picture_alt_rounded, color: roomText),
              tooltip: "Minimize",
              onPressed: () {
                Get.until((route) => route.isFirst);
                GlobalAudioOverlayController.showOverlay(
                  context,
                  widget.call,
                  widget.userId,
                  "Live Class",
                  widgetRef: widget.widgetRef,
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

            if (callState != null && callState.endedAt != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  await _handleClassExit();
                }
              });
            }

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
                if (_isPoorConnection)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade800,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Your internet is unstable or not working properly.",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                        "Participants Connected (${participants.length})",
                        style: GoogleFonts.poppins(
                          color: roomSecondary,
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
                          color: AppColors.success.withOpacity(0.12),
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
                          border: Border.all(color: roomBorder),
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
                                            color: roomText,
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
                                              color: AppColors.success,
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
                                      color: roomSecondary,
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
                                    ? AppColors.error
                                    : AppColors.success,
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
                    border: Border(top: BorderSide(color: roomBorder)),
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