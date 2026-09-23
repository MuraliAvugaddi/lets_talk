import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage1_screen.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:path_provider/path_provider.dart';

class HindiStage1Screen extends StatefulWidget {
  const HindiStage1Screen({super.key});

  @override
  State<HindiStage1Screen> createState() => _HindiStage1ScreenState();
}

class _HindiStage1ScreenState extends State<HindiStage1Screen> {
  // Pull-to-refresh handler for the entire screen view
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceSoft = isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft;
    final text = isDark ? AppColors.darkText : AppColors.text;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final List<Map<String, dynamic>> daysData = [
      {
        "day": "Day 1",
        "title": "Stage 1 Foundation Orientation & Demo",
        "subtitle": "Overview of foundation rules and basic structure",
        "pdfPath": null,
        "isPractice": false,
      },
      {
        "day": "Day 2",
        "title": "Past BE Form (+) (था/थी/थे)",
        "subtitle": "Affirmative sentences using past BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-2_Foundation_Hin (+Sta Past BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 3",
        "title": "Past BE Form (-) (था/थी/थे)",
        "subtitle": "Negative sentences using past BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-3_Foundation_Hin (- Sta Past BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 4",
        "title": "Past BE Form Yes/No Questions (+/-)",
        "subtitle": "Asking and answering past BE form confirmations",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-4_Foundation_Hin (+_- Y_N Past BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 5",
        "title": "Past BE Form W.H. Questions (+/-)",
        "subtitle": "Information questions with past BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-5_Foundation_Hin (+_- W.H Past BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 6",
        "title": "Present BE Form (+) (है/हैं/हूँ)",
        "subtitle": "Affirmative sentences using present BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-6_Foundation_Hin (+Sta Present BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 7",
        "title": "Present BE Form (-) (है/हैं/हूँ)",
        "subtitle": "Negative sentences using present BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-7_Foundation_Hin (-Sta Present BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 8",
        "title": "Present BE Form Yes/No Questions (+)",
        "subtitle": "Positive confirmation questions in present BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-8_Foundation_Hin (+Y_N Que Present BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 9",
        "title": "Present BE Form Yes/No Questions (-)",
        "subtitle": "Negative confirmation questions in present BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-9_Foundation_Hin (-Y_N Que Present BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 10",
        "title": "Present BE Form W.H. Questions (+)",
        "subtitle": "Positive information questions in present BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-10_Foundation_Hin (+W.H Que Present BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 11",
        "title": "Present BE Form W.H. Questions (-)",
        "subtitle": "Negative information questions in present BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-11_Foundation_Hin (-W.H Que Present BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 12",
        "title": "Future BE Form (+) (होगा/होगी/होंगे)",
        "subtitle": "Affirmative sentences using future BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-12_Foundation_Hin (+Sta Future BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 13",
        "title": "Future BE Form (-) (होगा/होगी/होंगे)",
        "subtitle": "Negative sentences using future BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-13_Foundation_Hin (-Sta Future BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 14",
        "title": "Future BE Form Yes/No Questions (+)",
        "subtitle": "Positive confirmation questions in future BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-14_Foundation_Hin (+ Y_N Que Future BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 15",
        "title": "Future BE Form Yes/No Questions (-)",
        "subtitle": "Negative confirmation questions in future BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-15_Foundation_Hin (- Y_N Que Future BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 16",
        "title": "Future BE Form W.H. Questions (+)",
        "subtitle": "Positive information questions in future BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-16_Foundation_Hin (+ W.H Que Future BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 17",
        "title": "Future BE Form W.H. Questions (-)",
        "subtitle": "Negative information questions in future BE form",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-17_Foundation_Hin (- W.H Que Future BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 18",
        "title": "There & Here Sentences (+/-)",
        "subtitle": "Usage of introductory 'There' and 'Here' structures",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-18_Foundation_Hin (+_- Sta There & Here).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 19",
        "title": "There & Here Yes/No Questions (+/-)",
        "subtitle": "Forming Yes/No interrogatives with There & Here",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-19_Foundation_Hin (+_- Y_N Que There & Here).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 20",
        "title": "There & Here W.H. Questions (+/-)",
        "subtitle": "W.H. interrogatives with introductory structures",
        "pdfPath":
            "assets/images/Hindi/stagehindiStage1/Day-20_Foundation_Hin (+_- W.H Que There & Here).pdf",
        "isPractice": false,
      },
    ];

    final systemBarColor = AppColors.navy;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: systemBarColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Fixed app bar (clean, with back button and title only)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 46,
                        child: Row(
                          children: [
                            _HeaderButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: Get.back,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Learning Materials',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stage 1 • 20 lessons',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 34,
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.teal.withValues(alpha: 0.28),
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.yellow,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Stage 1 — Foundation (Hindi)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 58),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Text(
                                '20 days',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pinned / Non-scrolling Attendance Widget
              const StageAttendanceWidget(stageName: 'Stage 1'),

              // Scrollable area for Course Hero and Lessons wrapped with RefreshIndicator
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.teal,
                  backgroundColor: surface,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                        sliver: SliverToBoxAdapter(
                          child: _CourseHero(
                            isDark: isDark,
                            title: 'Your learning library',
                            subtitle:
                                'Open a lesson to study foundation rules and build your Hindi-English base step by step.',
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Stage 1 Lessons',
                                  style: GoogleFonts.poppins(
                                    color: text,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(
                                    alpha: isDark ? 0.16 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '20 lessons',
                                  style: GoogleFonts.poppins(
                                    color: isDark
                                        ? AppColors.teal
                                        : AppColors.deepNavy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                        sliver: SliverList.separated(
                          itemCount: daysData.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final dayItem = daysData[index];
                            final String day = dayItem['day'];
                            final String title = dayItem['title'];
                            final String subtitle = dayItem['subtitle'];
                            final String? pdfPath = dayItem['pdfPath'];
                            final bool isPractice =
                                dayItem['isPractice'] ?? false;
                            final bool isPdfAvailable = pdfPath != null;

                            return _LessonCard(
                              day: day,
                              title: title,
                              subtitle: subtitle,
                              isPractice: isPractice,
                              isPdfAvailable: isPdfAvailable,
                              isDark: isDark,
                              surface: surface,
                              surfaceSoft: surfaceSoft,
                              text: text,
                              secondary: secondary,
                              border: border,
                              onTap: () {
                                if (isPdfAvailable) {
                                  Get.to(
                                    () => PdfViewerScreen(
                                      title: '$day: $title',
                                      assetPath: pdfPath,
                                    ),
                                  );
                                } else {
                                  _showDemoDialog(
                                    context,
                                    isDark,
                                    text,
                                    secondary,
                                    surface,
                                    border,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showDemoDialog(
    BuildContext context,
    bool isDark,
    Color text,
    Color secondary,
    Color surface,
    Color border,
  ) {
    Get.dialog(
      Dialog(
        backgroundColor: surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_lesson_rounded,
                  color: AppColors.navy,
                  size: 27,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Day 1 Demo Class',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Day 1 is an interactive Foundation Orientation & Demo session conducted live by the teacher. No PDF reading is required.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: secondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: Get.back,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.70 : 0.35),
    );
  }
}

// --- STAGE ATTENDANCE WIDGET ---
const double instituteLat = 17.729417;
const double instituteLng = 83.32231;
const double allowedRadius = 40.0;

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
          "Out of Range",
          "You are ${distance.toInt()}m away. You must be inside the institute (${allowedRadius.toInt()}m) to check in.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

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
          colorText: _primaryText(context),
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
      final String userMode = (authController.userData['mode'] ?? "online")
          .toString()
          .toLowerCase();

      if (userMode != "offline") {
        return const SizedBox.shrink();
      }

      if (isMarkedToday) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

      if (currentBatchSlot != null) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  icon: Icon(
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

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _CourseHero extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _CourseHero({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface2, AppColors.deepNavy]
              : [AppColors.blue, AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: isDark ? 0.20 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STAGE 1',
                  style: GoogleFonts.poppins(
                    color: AppColors.deepNavy,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'COURSE MATERIAL',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String day;
  final String title;
  final String subtitle;
  final bool isPractice;
  final bool isPdfAvailable;
  final bool isDark;
  final Color surface;
  final Color surfaceSoft;
  final Color text;
  final Color secondary;
  final Color border;
  final VoidCallback onTap;

  const _LessonCard({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.isPractice,
    required this.isPdfAvailable,
    required this.isDark,
    required this.surface,
    required this.surfaceSoft,
    required this.text,
    required this.secondary,
    required this.border,
    required this.onTap,
  });

  String get dayNumber {
    final match = RegExp(r'\d+').firstMatch(day);
    return match?.group(0) ?? day;
  }

  @override
  Widget build(BuildContext context) {
    final accent = isPractice ? AppColors.yellow : AppColors.navy;
    final cardBorder = isPractice
        ? AppColors.yellow.withValues(alpha: 0.55)
        : border;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.navy).withValues(
                  alpha: isDark ? 0.14 : 0.055,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 54,
                decoration: BoxDecoration(
                  gradient: isPractice
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.yellow, AppColors.warning],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.blue, AppColors.deepNavy],
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DAY',
                      style: GoogleFonts.poppins(
                        color: isPractice ? AppColors.deepNavy : Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dayNumber,
                      style: GoogleFonts.poppins(
                        color: isPractice ? AppColors.deepNavy : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (isPractice) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PRACTICE',
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? AppColors.yellow
                                    : AppColors.deepNavy,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: text,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isPdfAvailable
                              ? Icons.picture_as_pdf_rounded
                              : Icons.play_circle_outline_rounded,
                          color: isPractice ? accent : AppColors.teal,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPdfAvailable ? 'PDF lesson' : 'Live demo class',
                          style: GoogleFonts.poppins(
                            color: secondary.withValues(alpha: 0.9),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isPdfAvailable
                      ? Icons.arrow_forward_rounded
                      : Icons.play_arrow_rounded,
                  color: AppColors.teal,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
