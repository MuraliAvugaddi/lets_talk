import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

const double instituteLat = 17.744076;
const double instituteLng = 83.246456;
const double allowedRadius = 100.0;
const String baseUrl = "http://192.168.1.4:5000/api";

class StageAttendanceWidget extends StatefulWidget {
  final String stageName;

  const StageAttendanceWidget({super.key, required this.stageName});

  @override
  State<StageAttendanceWidget> createState() => _StageAttendanceWidgetState();
}

class _StageAttendanceWidgetState extends State<StageAttendanceWidget> {
  final authController = Get.find<AuthController>();

  bool isAttendanceLoading = false;
  bool isMarkedToday = false;
  String? currentBatchSlot;
  String attendanceStatusText = "Not Marked";

  final Color cardColor = const Color(0xff14141E);
  final Color accentPurple = const Color(0xff7F56D9);

  @override
  void initState() {
    super.initState();
    _calculateCurrentBatch();
    _checkIfAlreadyMarkedToday();
  }

  void _calculateCurrentBatch() {
    final now = DateTime.now();
    final int currentMinutes = now.hour * 60 + now.minute;

    String? slot;
    if (currentMinutes >= 330 && currentMinutes < 420) {
      slot = "5:30 AM - 7:00 AM";
    } else if (currentMinutes >= 420 && currentMinutes < 510) {
      slot = "7:00 AM - 8:30 AM";
    } else if (currentMinutes >= 540 && currentMinutes < 630) {
      slot = "9:00 AM - 10:30 AM";
    } else if (currentMinutes >= 630 && currentMinutes < 720) {
      slot = "10:30 AM - 12:00 PM";
    } else if (currentMinutes >= 930 && currentMinutes < 1020) {
      slot = "3:30 PM - 5:00 PM";
    } else if (currentMinutes >= 1020 && currentMinutes < 1110) {
      slot = "5:00 PM - 6:30 PM";
    } else if (currentMinutes >= 1110 && currentMinutes < 1400) {
      slot = "6:30 PM - 8:00 PM";
    }

    if (mounted) setState(() => currentBatchSlot = slot);
  }

  Future<void> _checkIfAlreadyMarkedToday() async {
    final userData = authController.userData;
    final userId = userData['id'] ?? userData['_id'];
    if (userId == null) return;

    final now = DateTime.now();
    final todayStr = "${now.day}-${now.month}-${now.year}";

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/my-attendance?userId=$userId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List records = data['records'] ?? [];

        final todayRecord = records.firstWhere(
          (r) => r['date'] == todayStr && r['stage'] == widget.stageName,
          orElse: () => null,
        );

        if (todayRecord != null && mounted) {
          setState(() {
            isMarkedToday = true;
            attendanceStatusText = todayRecord['status'] ?? "Present";
          });
        }
      }
    } catch (_) {}
  }

  Future<void> markAttendance() async {
    setState(() => isAttendanceLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar("Error", "Location permission required");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        instituteLat,
        instituteLng,
      );

      if (distance > allowedRadius) {
        Get.snackbar(
          "Failed",
          "Too far from institute! (${distance.toInt()}m away)",
        );
        return;
      }

      final userData = authController.userData;
      final response = await http.post(
        Uri.parse("$baseUrl/user/mark-attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userData['id'] ?? userData['_id'],
          "stage": widget.stageName,
          "batchTime": currentBatchSlot,
          "lat": position.latitude,
          "lng": position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          isMarkedToday = true;
          attendanceStatusText = body['record']?['status'] ?? "Present";
        });
        Get.snackbar(
          "Success",
          "Marked $attendanceStatusText for ${widget.stageName}",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Notice",
          jsonDecode(response.body)['message'] ?? "Already marked",
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      if (mounted) setState(() => isAttendanceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userMode = (authController.userData['mode'] ?? "online")
        .toString()
        .toLowerCase();

    if (userMode != "offline") {
      return const SizedBox.shrink();
    }

    if (isMarkedToday) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 28,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendanceStatusText,
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "${widget.stageName} • $currentBatchSlot",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (currentBatchSlot != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentPurple.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mark In-Person Attendance",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Current Batch: $currentBatchSlot",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: isAttendanceLoading ? null : markAttendance,
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: Text(
                  isAttendanceLoading
                      ? "Verifying Location..."
                      : "I Am Here (Check-In)",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
