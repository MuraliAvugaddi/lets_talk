import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Controllers/connectivityController.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:in_app_update/in_app_update.dart';

// ============================================================
// ENGLISH STAGE SCREENS
// ============================================================

import 'package:lets_talk/Screens/English_meteral_5/English_stage1_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage2_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage3_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage4_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage5_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage6_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage7_screen.dart';

// ============================================================
// ENGLISH ONLINE STAGE SCREENS
// ============================================================

import 'package:lets_talk/Screens/English_online_5/English_online_stage1_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage2_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage3_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage4_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage5_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage6_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage7_screen.dart';

// ============================================================
// INTERNET CONNECTION CHECKER HELPER
// ============================================================

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
    "No Internet Connection",
    "Your internet is not working. Please check your connection.",
    backgroundColor: AppColors.error,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
  );
}

// ============================================================
// IN-APP UPDATE
// ============================================================

class UpdateController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    checkAppUpdate();
  }

  Future<void> checkAppUpdate() async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          InAppUpdate.performImmediateUpdate().catchError((e) {
            Get.snackbar(
              'Update Failed',
              e.toString(),
              snackPosition: SnackPosition.BOTTOM,
            );
            return AppUpdateResult.userDeniedUpdate;
          });
        } else if (updateInfo.flexibleUpdateAllowed) {
          InAppUpdate.startFlexibleUpdate().then((result) {
            if (result == AppUpdateResult.success) {
              InAppUpdate.completeFlexibleUpdate();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('In-App Update error: $e');
    }
  }
}

// ============================================================
// ENGLISH LEARN SCREEN
// ============================================================

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final AuthController authController = Get.find<AuthController>();
  final ConnectivityController netController =
      Get.find<ConnectivityController>();

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<UpdateController>()) {
      Get.put(UpdateController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    final bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
      return;
    }

    await Future.wait([
      authController.refreshProfile(),
      fetchAdminNotification(),
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> fetchAdminNotification() async {
    try {
      final String userMode = (authController.userData['mode'] ?? 'online')
          .toString()
          .toLowerCase();

      final response = await http.get(
        Uri.parse('${ApiEndpoints.userNotification}?mode=$userMode'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['hasNotification'] == true) {
          authController.adminMessage.value = data['message']?.toString();
          authController.isMessageVisible.value = true;
        } else {
          authController.adminMessage.value = null;
          authController.isMessageVisible.value = false;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification: $e');
    }
  }

  bool _isStageLocked(String stageKey) {
    final english = authController.userData['englishAccess'];

    if (english == null || english is! Map) {
      return true;
    }

    return english[stageKey] != true;
  }

  int _unlockedStages() {
    int count = 0;

    for (int i = 1; i <= 7; i++) {
      if (!_isStageLocked('stage$i')) {
        count++;
      }
    }

    return count;
  }

  void _showAccessDeniedDialog(String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color surface = isDark ? AppColors.darkSurface : AppColors.surface;

    final Color text = isDark ? AppColors.darkText : AppColors.text;

    final Color secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    Get.dialog(
      Dialog(
        backgroundColor: surface,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.yellow15,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.yellow,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Please contact your institute admin to unlock $title.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: secondary,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Understood',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

  Future<void> _openStage(
    BuildContext context,
    Widget destination,
    String title,
    bool isLocked,
  ) async {
    final bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
      return;
    }

    if (isLocked) {
      _showAccessDeniedDialog(title);
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
  }

  Future<void> _openOnlineStage(
    BuildContext context,
    Widget destination,
    bool isLocked,
  ) async {
    final bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
      return;
    }

    if (isLocked) {
      _showAccessDeniedDialog('Online Class');
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background = isDark
        ? AppColors.darkBackground
        : AppColors.background;

    final Color surface = isDark ? AppColors.darkSurface : AppColors.surface;

    final Color surfaceSoft = isDark
        ? AppColors.darkSurface2
        : AppColors.surfaceSoft;

    final Color text = isDark ? AppColors.darkText : AppColors.text;

    final Color secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final Color border = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          // ==================================================
          // FIXED / NON-SCROLLING APP BAR
          // ==================================================
          _buildFixedHeader(
            context: context,
            isDark: isDark,
            text: text,
            secondary: secondary,
          ),

          // ==================================================
          // FIXED OFFLINE BAR
          // ==================================================
          Obx(() {
            if (netController.isConnected.value) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.error10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.error,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'No internet connection',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),

          // ==================================================
          // SCROLLABLE CONTENT ONLY
          // ==================================================
          Expanded(
            child: RefreshIndicator(
              color: AppColors.navy,
              backgroundColor: surface,
              onRefresh: _refreshAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                child: Obx(
                  () => _buildLearningContent(
                    context: context,
                    isDark: isDark,
                    surface: surface,
                    surfaceSoft: surfaceSoft,
                    text: text,
                    secondary: secondary,
                    border: border,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIXED HEADER
  // ============================================================

  Widget _buildFixedHeader({
    required BuildContext context,
    required bool isDark,
    required Color text,
    required Color secondary,
  }) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.deepNavy, AppColors.navy]
              : const [AppColors.deepNavy, AppColors.navy],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Obx(() {
        final rawName = authController.userData['name']?.toString().trim();
        final name = (rawName == null || rawName.isEmpty) ? 'Learner' : rawName;
        final initial = name.substring(0, 1).toUpperCase();

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good to see you',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        color: AppColors.teal,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'English',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.yellow,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  'English Learning',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '7 stages',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  // ============================================================
  // MAIN LEARNING CONTENT
  // ============================================================

  Widget _buildLearningContent({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color surfaceSoft,
    required Color text,
    required Color secondary,
    required Color border,
  }) {
    final bool isOnlineStudent =
        (authController.userData['mode'] ?? 'online')
            .toString()
            .toLowerCase() ==
        'online';

    final int unlocked = _unlockedStages();
    final int progressPercent = ((unlocked / 7) * 100).round();

    final List<Map<String, dynamic>> stagesData = [
      {
        'title': 'Stage 1 – Foundation',
        'subtitle': 'Foundational English',
        'description': 'Build your basic English foundation',
        'stageNum': 1,
        'destination': EnglishStage1Screen(),
        'isLocked': _isStageLocked('stage1'),
      },
      {
        'title': 'Stage 2 – Accuracy',
        'subtitle': 'Basic Grammar',
        'description': 'Learn essential grammar patterns',
        'stageNum': 2,
        'destination': const EnglishStage2Screen(),
        'isLocked': _isStageLocked('stage2'),
      },
      {
        'title': 'Stage 3 – Progression',
        'subtitle': 'Conversational Skills',
        'description': 'Speak naturally in daily situations',
        'stageNum': 3,
        'destination': const EnglishStage3Screen(),
        'isLocked': _isStageLocked('stage3'),
      },
      {
        'title': 'Stage 4 – Correctness',
        'subtitle': 'Vocabulary Expansion',
        'description': 'Grow your vocabulary and confidence',
        'stageNum': 4,
        'destination': EnglishStage4Screen(),
        'isLocked': _isStageLocked('stage4'),
      },
      {
        'title': 'Stage 5 – Confidence',
        'subtitle': 'Fluency Practice',
        'description': 'Improve your speaking fluency',
        'stageNum': 5,
        'destination': const EnglishStage5Screen(),
        'isLocked': _isStageLocked('stage5'),
      },
      {
        'title': 'Stage 6 – Fluency',
        'subtitle': 'Advanced Speaking',
        'description': 'Strengthen advanced communication',
        'stageNum': 6,
        'destination': const EnglishStage6Screen(),
        'isLocked': _isStageLocked('stage6'),
      },
      {
        'title': 'Stage 7 – Mastery',
        'subtitle': 'Mastery & Accent',
        'description': 'Polish your English communication',
        'stageNum': 7,
        'destination': const EnglishStage7Screen(),
        'isLocked': _isStageLocked('stage7'),
      },
    ];

    final List<Map<String, dynamic>> onlineClassesData = [
      {
        'label': 'Stage 1',
        'stageNum': 1,
        'dest': const EnglishOnlineStage1Screen(),
        'isLocked': _isStageLocked('stage1'),
      },
      {
        'label': 'Stage 2',
        'stageNum': 2,
        'dest': const EnglishOnlineStage2Screen(),
        'isLocked': _isStageLocked('stage2'),
      },
      {
        'label': 'Stage 3',
        'stageNum': 3,
        'dest': const EnglishOnlineStage3Screen(),
        'isLocked': _isStageLocked('stage3'),
      },
      {
        'label': 'Stage 4',
        'stageNum': 4,
        'dest': const EnglishOnlineStage4Screen(),
        'isLocked': _isStageLocked('stage4'),
      },
      {
        'label': 'Stage 5',
        'stageNum': 5,
        'dest': const EnglishOnlineStage5Screen(),
        'isLocked': _isStageLocked('stage5'),
      },
      {
        'label': 'Stage 6',
        'stageNum': 6,
        'dest': const EnglishOnlineStage6Screen(),
        'isLocked': _isStageLocked('stage6'),
      },
      {
        'label': 'Stage 7',
        'stageNum': 7,
        'dest': const EnglishOnlineStage7Screen(),
        'isLocked': _isStageLocked('stage7'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // ADMIN NOTICE
        // ======================================================
        if (authController.adminMessage.value != null &&
            authController.isMessageVisible.value)
          _buildAdminNotice(
            context: context,
            isDark: isDark,
            surface: surface,
            text: text,
            secondary: secondary,
          ),

        // ======================================================
        // PROGRESS CARD
        // ======================================================
        _buildJourneyCard(
          context: context,
          isDark: isDark,
          surface: surface,
          text: text,
          secondary: secondary,
          unlocked: unlocked,
          progressPercent: progressPercent,
        ),

        const SizedBox(height: 18),

        // ======================================================
        // INTERACTIVE ONLINE CLASSES
        // ======================================================
        if (isOnlineStudent)
          _buildInteractiveClasses(
            context: context,
            isDark: isDark,
            surface: surface,
            secondary: secondary,
            onlineClassesData: onlineClassesData,
          ),

        if (isOnlineStudent) const SizedBox(height: 20),

        // ======================================================
        // LEARNING PATH HEADER
        // ======================================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'English Learning Path',
                    style: GoogleFonts.poppins(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Learn step by step and build your confidence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: secondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unlocked unlocked',
                style: GoogleFonts.poppins(
                  color: AppColors.blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ======================================================
        // STAGES
        // ======================================================
        ...stagesData.map(
          (stage) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _buildStageCard(
              context: context,
              isDark: isDark,
              surface: surface,
              border: border,
              text: text,
              secondary: secondary,
              title: stage['title'] as String,
              subtitle: stage['subtitle'] as String,
              description: stage['description'] as String,
              stageNum: stage['stageNum'] as int,
              destination: stage['destination'] as Widget,
              isLocked: stage['isLocked'] as bool,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADMIN NOTICE
  // ============================================================

  Widget _buildAdminNotice({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color text,
    required Color secondary,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.yellow,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notice from Manager',
                  style: GoogleFonts.poppins(
                    color: AppColors.yellow,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  authController.adminMessage.value ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: secondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            onPressed: () {
              authController.isMessageVisible.value = false;
            },
            icon: Icon(Icons.close_rounded, color: secondary, size: 18),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // JOURNEY / PROGRESS CARD
  // ============================================================

  Widget _buildJourneyCard({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color text,
    required Color secondary,
    required int unlocked,
    required int progressPercent,
  }) {
    final bool hasStarted = unlocked > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.deepNavy, AppColors.navy],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.yellow,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasStarted
                          ? 'Keep your English journey going'
                          : 'Start your English journey',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 14,
                        height: 1.18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasStarted
                          ? 'You have $unlocked of 7 stages unlocked.'
                          : 'Your learning path starts here.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: secondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '$progressPercent%',
                  style: GoogleFonts.poppins(
                    color: AppColors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: unlocked / 7,
              backgroundColor: AppColors.teal.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTERACTIVE CLASSES
  // ============================================================

  Widget _buildInteractiveClasses({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color secondary,
    required List<Map<String, dynamic>> onlineClassesData,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.70)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.teal,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Classes',
                      style: GoogleFonts.poppins(
                        color: isDark ? AppColors.darkText : AppColors.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Join your online learning stages',
                      style: GoogleFonts.poppins(
                        color: secondary,
                        fontSize: 8.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'ONLINE',
                  style: GoogleFonts.poppins(
                    color: AppColors.deepNavy,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: onlineClassesData.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = onlineClassesData[index];

                return _buildOnlineClassItem(
                  context: context,
                  isDark: isDark,
                  label: item['label'] as String,
                  stageNum: item['stageNum'] as int,
                  destination: item['dest'] as Widget,
                  isLocked: item['isLocked'] as bool,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineClassItem({
    required BuildContext context,
    required bool isDark,
    required String label,
    required int stageNum,
    required Widget destination,
    required bool isLocked,
  }) {
    final Color iconColor = isLocked ? AppColors.textSecondary : AppColors.navy;

    return SizedBox(
      width: 56,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await _openOnlineStage(context, destination, isLocked);
        },
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? (isDark
                              ? AppColors.darkSurface2
                              : AppColors.surfaceSoft)
                        : AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLocked
                          ? (isDark ? AppColors.darkBorder : AppColors.border)
                          : AppColors.teal.withValues(alpha: 0.35),
                      width: 1.1,
                    ),
                  ),
                  child: Icon(
                    isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.videocam_rounded,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                if (!isLocked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: isLocked ? AppColors.textSecondary : AppColors.deepNavy,
                fontSize: 8.5,
                fontWeight: isLocked ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAGE CARD
  // ============================================================

  Widget _buildStageCard({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color border,
    required Color text,
    required Color secondary,
    required String title,
    required String subtitle,
    required String description,
    required int stageNum,
    required Widget destination,
    required bool isLocked,
  }) {
    final Color iconBackground = isLocked
        ? (isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft)
        : AppColors.teal.withValues(alpha: 0.08);

    final Color iconBorder = isLocked
        ? (isDark ? AppColors.darkBorder : AppColors.border)
        : AppColors.teal.withValues(alpha: 0.30);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await _openStage(context, destination, title, isLocked);
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLocked
                ? border.withValues(alpha: 0.85)
                : AppColors.teal.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.045),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: iconBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stageNum.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      color: isLocked ? secondary : AppColors.teal,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Icon(
                    _stageIcon(stageNum),
                    color: isLocked ? secondary : AppColors.teal,
                    size: 17,
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
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isLocked && stageNum == 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'START',
                            style: GoogleFonts.poppins(
                              color: AppColors.teal,
                              fontSize: 6.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: isLocked ? secondary : AppColors.teal,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isLocked ? 'Locked' : description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: isLocked ? secondary : AppColors.teal,
                            fontSize: 8.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isLocked
                    ? (isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft)
                    : AppColors.navy.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                color: isLocked ? secondary : AppColors.navy,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _stageIcon(int stageNum) {
    switch (stageNum) {
      case 1:
        return Icons.translate_rounded;
      case 2:
        return Icons.menu_book_rounded;
      case 3:
        return Icons.forum_rounded;
      case 4:
        return Icons.auto_stories_rounded;
      case 5:
        return Icons.record_voice_over_rounded;
      case 6:
        return Icons.mic_rounded;
      case 7:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
