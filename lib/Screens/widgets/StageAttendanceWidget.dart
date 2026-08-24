import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

// --- UPDATED INSTITUTE LOCATION (Visakhapatnam Rama Talkies Road) ---
const double instituteLat = 17.729417;
const double instituteLng = 83.312231;
const double allowedRadius = 40.0; // Optimized radius: covers classroom & handles indoor GPS drift

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

  // --- BRAND COLORS ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color darkCard = const Color(0xff14141E);

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
        Uri.parse("${ApiEndpoints.myAttendance}?userId=$userId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List records = data['records'] ?? [];

        final todayRecord = records.firstWhere(
          (r) =>
              r['date'] == todayStr &&
              r['stage']?.toString().toLowerCase() ==
                  widget.stageName.toLowerCase(),
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
      // 1. Check if Device GPS is turned ON
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.defaultDialog(
          title: "Enable GPS",
          titlePadding: const EdgeInsets.only(top: 20, bottom: 8),
          titleStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          middleText: "Your device GPS is turned off. Please turn it on to check in.",
          middleTextStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          backgroundColor: darkCard,
          radius: 16,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          confirm: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () async {
                Get.back();
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: deepOceanBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Open Settings",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          cancel: SizedBox(
            height: 40,
            child: TextButton(
              onPressed: () => Get.back(),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white60)),
            ),
          ),
        );
        return;
      }

      // 2. Check and Request App Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            "Permission Denied",
            "Location permission is required to check in.",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return;
        }
      }

      // 3. If User clicked "Don't ask again" / Denied Forever
      if (permission == LocationPermission.deniedForever) {
        Get.defaultDialog(
          title: "Permission Required",
          titlePadding: const EdgeInsets.only(top: 20, bottom: 8),
          titleStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          middleText:
              "Location permission is permanently blocked. Please allow location in App Settings.",
          middleTextStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          backgroundColor: darkCard,
          radius: 16,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          confirm: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () async {
                Get.back();
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: deepOceanBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Open Settings",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          cancel: SizedBox(
            height: 40,
            child: TextButton(
              onPressed: () => Get.back(),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white60)),
            ),
          ),
        );
        return;
      }

      // 4. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 5. Calculate Distance
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        instituteLat,
        instituteLng,
      );

      if (distance > allowedRadius) {
        Get.snackbar(
          "Out of Range",
          "You are ${distance.toInt()}m away. You must be inside the institute (${allowedRadius.toInt()}m) to check in.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // 6. Submit Check-in
      final userData = authController.userData;
      final response = await http.post(
        Uri.parse(ApiEndpoints.markAttendance),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userData['id'] ?? userData['_id'],
          "stage": widget.stageName,
          "batchTime": currentBatchSlot ?? "General Batch",
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
          "Checked In!",
          "Marked $attendanceStatusText for ${widget.stageName}",
          backgroundColor: tealMist,
          colorText: Colors.white,
        );
      } else {
        final body = jsonDecode(response.body);
        Get.snackbar(
          "Notice",
          body['message'] ?? "Attendance already marked.",
          backgroundColor: goldenYellow.withOpacity(0.9),
          colorText: Colors.black,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Check-in failed: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isAttendanceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String userMode = (authController.userData['mode'] ?? "online")
          .toString()
          .toLowerCase();

      // If student is set to Online, do not show offline GPS check-in button
      if (userMode != "offline") {
        return const SizedBox.shrink();
      }

      // 1. If Marked Today: Teal Mist Confirmation Card with Golden Highlights
      if (isMarkedToday) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tealMist.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tealMist.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: goldenYellow, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendanceStatusText,
                      style: GoogleFonts.poppins(
                        color: goldenYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${widget.stageName} • ${currentBatchSlot ?? 'Active Session'}",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // 2. Active Batch Window: Deep Ocean Blue & Teal Mist GPS Check-In Button
      if (currentBatchSlot != null) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tealMist.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Mark Classroom Attendance",
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
                  icon: isAttendanceLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: goldenYellow,
                          ),
                        )
                      : Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: goldenYellow,
                        ),
                  label: Text(
                    isAttendanceLoading
                        ? "Verifying GPS Location..."
                        : "I Am Here (Check-In)",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
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
            ],
          ),
        );
      }

      // 3. Fallback when outside standard batch windows
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          "Class check-in will open when your scheduled batch starts.",
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}