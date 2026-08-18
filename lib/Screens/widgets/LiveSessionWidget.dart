import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

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

class _LiveSessionWidgetState extends State<LiveSessionWidget> with WidgetsBindingObserver {
  final AuthController authController = Get.find<AuthController>();

  String? meetLink;
  bool isLoading = true;
  String? activeAttendanceId;
  int minutesSpent = 0;
  Timer? _heartbeatTimer;

  final String baseUrl = "http://192.168.1.4:5000/api";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  String _calculateCurrentBatch() {
    final now = DateTime.now();
    final int currentMinutes = now.hour * 60 + now.minute;

    if (currentMinutes >= 330 && currentMinutes < 420) return "5:30 AM - 7:00 AM";
    if (currentMinutes >= 420 && currentMinutes < 510) return "7:00 AM - 8:30 AM";
    if (currentMinutes >= 540 && currentMinutes < 630) return "9:00 AM - 10:30 AM";
    if (currentMinutes >= 630 && currentMinutes < 720) return "10:30 AM - 12:00 PM";
    if (currentMinutes >= 930 && currentMinutes < 1020) return "3:30 PM - 5:00 PM";
    if (currentMinutes >= 1020 && currentMinutes < 1110) return "5:00 PM - 6:30 PM";
    if (currentMinutes >= 1110 && currentMinutes < 1400) return "6:30 PM - 8:00 PM";
    return "Custom Session";
  }

  Future<void> fetchLink() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/live/user/get?language=${widget.language}&stage=${widget.stage}&type=${widget.type}"),
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

    try {
      // 1. Send Join Log to Backend
      final response = await http.post(
        Uri.parse("$baseUrl/user/join-online-class"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": user['id'] ?? user['_id'],
          "language": widget.language,
          "stage": widget.stage.toUpperCase(),
          "batchTime": currentBatch,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        activeAttendanceId = data['attendanceId'];

        // 2. Start Periodic 60s Heartbeat
        _startHeartbeat();
      }
    } catch (e) {
      debugPrint("Join Error: $e");
    }

    // 3. Open Google Meet
    final Uri url = Uri.parse(meetLink!);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (activeAttendanceId == null) return;

      try {
        final res = await http.post(
          Uri.parse("$baseUrl/user/online-heartbeat"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"attendanceId": activeAttendanceId}),
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (mounted) {
            setState(() {
              minutesSpent = body['minutesSpent'] ?? (minutesSpent + 1);
            });
          }
        }
      } catch (e) {
        debugPrint("Heartbeat sync error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xff14141E);
    const Color accentBlue = Color(0xff158DFE);

    return Scaffold(
      backgroundColor: const Color(0xff0A0A0E),
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          "${widget.language} • ${widget.stage.toUpperCase()}",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: accentBlue)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: meetLink != null ? accentBlue.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: meetLink != null ? accentBlue.withOpacity(0.3) : Colors.white10,
                        ),
                      ),
                      child: Icon(
                        meetLink != null ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        size: 64,
                        color: meetLink != null ? accentBlue : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      meetLink != null ? "Live Session is Active" : "No Session Active",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meetLink != null
                          ? "Tap below to join the Google Meet session. Your attendance will be tracked automatically."
                          : "Your instructor has not started the session yet. Please check back at your scheduled batch time.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                    ),
                    if (minutesSpent > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          "Active Class Time: $minutesSpent mins",
                          style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),
                    if (meetLink != null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _recordJoinAndLaunch,
                          icon: const Icon(Icons.video_call_rounded, color: Colors.white),
                          label: Text(
                            "JOIN CLASS",
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: fetchLink,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                      label: Text("Refresh Link", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}