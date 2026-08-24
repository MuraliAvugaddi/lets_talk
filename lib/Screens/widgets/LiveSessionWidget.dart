import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

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

  String? meetLink;
  bool isLoading = true;
  String? activeAttendanceId;
  DateTime? joinedTimestamp;
  int minutesSpent = 0;
  bool isSessionActive = false;

  // --- BRAND PALETTE ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color pureWhite = const Color(0xffFFFFFF);
  final Color cardFill = const Color(0xffF8FAFC);
  final Color textDark = const Color(0xff0F172A);
  final Color textMuted = const Color(0xff64748B);
  final Color borderLight = const Color(0xffE2E8F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        isSessionActive &&
        activeAttendanceId != null) {
      _syncAttendanceOnReturn();
    }
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

  Future<void> fetchLink() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiEndpoints.baseUrl}/live/user/get?language=${widget.language}&stage=${widget.stage}&type=${widget.type}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            meetLink = data['link'];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            meetLink = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _recordJoinAndLaunch() async {
    if (meetLink == null) return;

    final user = authController.userData;
    final String currentBatch = _calculateCurrentBatch();
    final now = DateTime.now();

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.joinOnlineClass),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": user['id'] ?? user['_id'],
          "language": widget.language,
          "stage": widget.stage.toUpperCase(),
          "batchTime": currentBatch,
          "joinTime": now.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          activeAttendanceId = data['attendanceId'];
          joinedTimestamp = now;
          isSessionActive = true;
          minutesSpent = data['totalMinutes'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Join Online Error: $e");
    }

    final Uri url = Uri.parse(meetLink!);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _syncAttendanceOnReturn() async {
    if (activeAttendanceId == null || joinedTimestamp == null) return;

    final returnTime = DateTime.now();

    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.syncOnlineClass),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "attendanceId": activeAttendanceId,
          "returnTime": returnTime.toIso8601String(),
        }),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            minutesSpent = body['minutesSpent'] ?? minutesSpent;
          });
        }
      }
    } catch (e) {
      debugPrint("Attendance sync error: $e");
    }
  }

  Future<void> _endSessionAndLeave() async {
    if (activeAttendanceId == null) return;

    final exitTime = DateTime.now();
    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.leaveOnlineClass),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "attendanceId": activeAttendanceId,
          "leaveTime": exitTime.toIso8601String(),
        }),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          isSessionActive = false;
          minutesSpent = body['minutesSpent'] ?? minutesSpent;
        });

        Get.snackbar(
          "Class Ended",
          "Session recorded: $minutesSpent mins (${body['status']})",
          backgroundColor: tealMist,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Leave error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: meetLink != null
                            ? deepOceanBlue.withOpacity(0.08)
                            : cardFill,
                        border: Border.all(
                          color: meetLink != null
                              ? deepOceanBlue.withOpacity(0.2)
                              : borderLight,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        meetLink != null
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        size: 56,
                        color: meetLink != null ? deepOceanBlue : textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      meetLink != null
                          ? "Live Session is Active"
                          : "No Session Active",
                      style: GoogleFonts.poppins(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meetLink != null
                          ? "Tap below to join your Google Meet class. Time spent is accurately calculated when you return to the app."
                          : "Your instructor has not started the live session yet. Please check back at your scheduled batch time.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: textMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (minutesSpent > 0 || isSessionActive) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tealMist.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: tealMist.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: tealMist,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSessionActive
                                  ? "Current Attendance: $minutesSpent mins"
                                  : "Completed Attendance: $minutesSpent mins",
                              style: GoogleFonts.poppins(
                                color: deepOceanBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),
                    if (meetLink != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _recordJoinAndLaunch,
                          icon: const Icon(
                            Icons.video_call_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            isSessionActive
                                ? "RE-ENTER CLASS"
                                : "JOIN LIVE CLASS",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deepOceanBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (isSessionActive) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _endSessionAndLeave,
                            icon: const Icon(
                              Icons.exit_to_app_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            label: Text(
                              "LEAVE & SAVE ATTENDANCE",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        fetchLink();
                        if (isSessionActive) _syncAttendanceOnReturn();
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: tealMist,
                        size: 18,
                      ),
                      label: Text(
                        "Sync & Refresh",
                        style: GoogleFonts.poppins(
                          color: tealMist,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
