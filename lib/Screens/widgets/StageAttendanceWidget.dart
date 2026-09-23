import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/Screens/app_colors.dart';

// --- UPDATED INSTITUTE LOCATION (Visakhapatnam Rama Talkies Road) ---
const double instituteLat = 17.729417;
const double instituteLng = 83.312231;

const double allowedRadius =
    40.0; // Optimized radius: covers classroom & handles indoor GPS drift

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

  // --- SHARED APP BRAND COLORS ---
  Color _deepOceanBlue(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.teal : AppColors.navy;
  }

  Color _tealMist(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.teal : AppColors.teal;
  }

  Color _goldenYellow(BuildContext context) => AppColors.yellow;

  Color _cardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSurface : AppColors.surface;
  }

  Color _primaryText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkText : AppColors.text;
  }

  Color _secondaryText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  }

  Color _borderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : AppColors.border;
  }

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
            color: _primaryText(context),
          ),
          middleText:
              "Your device GPS is turned off. Please turn it on to check in.",
          middleTextStyle: GoogleFonts.poppins(
            color: _secondaryText(context),
            fontSize: 13,
          ),
          backgroundColor: _cardColor(context),
          radius: 16,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          confirm: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () async {
                Get.back();
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepOceanBlue(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Open Settings",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          cancel: SizedBox(
            height: 40,
            child: TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: _secondaryText(context)),
              ),
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
            backgroundColor: AppColors.error,
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
            color: _primaryText(context),
          ),
          middleText:
              "Location permission is permanently blocked. Please allow location in App Settings.",
          middleTextStyle: GoogleFonts.poppins(
            color: _secondaryText(context),
            fontSize: 13,
          ),
          backgroundColor: _cardColor(context),
          radius: 16,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          confirm: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () async {
                Get.back();
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepOceanBlue(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Open Settings",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          cancel: SizedBox(
            height: 40,
            child: TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: _secondaryText(context)),
              ),
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
          backgroundColor: _tealMist(context),
          colorText: Colors.white,
        );
      } else {
        final body = jsonDecode(response.body);
        Get.snackbar(
          "Notice",
          body['message'] ?? "Attendance already marked.",
          backgroundColor: AppColors.yellow,
          colorText: AppColors.text,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Check-in failed: $e",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isAttendanceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🚀 Explicitly reference authController.userData to ensure Obx tracks changes when admin updates profile/mode
      final userData = authController.userData;
      final String userMode = (userData['mode'] ?? "online")
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
            color: _tealMist(context).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _tealMist(context).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: _goldenYellow(context),
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendanceStatusText,
                      style: GoogleFonts.poppins(
                        color: _goldenYellow(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${widget.stageName} • ${currentBatchSlot ?? 'Active Session'}",
                      style: GoogleFonts.poppins(
                        color: _secondaryText(context),
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
            color: _cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Mark Classroom Attendance",
                style: GoogleFonts.poppins(
                  color: _primaryText(context),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Current Batch: $currentBatchSlot",
                style: GoogleFonts.poppins(
                  color: _secondaryText(context),
                  fontSize: 12,
                ),
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
                            color: _goldenYellow(context),
                          ),
                        )
                      : Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: _goldenYellow(context),
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
                    backgroundColor: _deepOceanBlue(context),
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
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor(context)),
        ),
        child: Text(
          "Class check-in will open when your scheduled batch starts.",
          style: GoogleFonts.poppins(
            color: _secondaryText(context),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}
