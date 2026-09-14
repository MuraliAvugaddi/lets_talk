import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Controllers/connectivityController.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:in_app_update/in_app_update.dart';

// --- SCREEN IMPORTS ---
// import 'package:lets_talk/Screens/English_club5/English_club_stage1_screen.dart';
// import 'package:lets_talk/Screens/English_club5/English_club_stage2_screen.dart';
// import 'package:lets_talk/Screens/English_club5/English_club_stage3_screen.dart';
// import 'package:lets_talk/Screens/English_club5/English_club_stage4_screen.dart';
// import 'package:lets_talk/Screens/English_club5/English_club_stage5_screen.dart';
// import 'package:lets_talk/Screens/English_club5/English_club_stage6_screen.dart';
// import 'package:lets_talk/Screens/English_club5/English_club_stage7_screen.dart';

import 'package:lets_talk/Screens/English_meteral_5/English_stage1_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage2_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage3_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage4_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage5_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage6_screen.dart';
import 'package:lets_talk/Screens/English_meteral_5/English_stage7_screen.dart';

import 'package:lets_talk/Screens/English_online_5/English_online_stage1_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage2_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage3_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage4_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage5_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage6_screen.dart';
import 'package:lets_talk/Screens/English_online_5/English_online_stage7_screen.dart';

// --- IN-APP UPDATE CONTROLLER ---
class UpdateController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    checkAppUpdate();
  }

  Future<void> checkAppUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          InAppUpdate.performImmediateUpdate().catchError((e) {
            Get.snackbar("Update Failed", e.toString());
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
      debugPrint("In-App Update error: $e");
    }
  }
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final AuthController authController = Get.find<AuthController>();
  final ConnectivityController netController =
      Get.find<ConnectivityController>();

  // --- BRAND COLORS ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color cardColor = const Color(0xff14141E);
  final Color backgroundColor = const Color(0xff0A0A0E);

  @override
  void initState() {
    super.initState();
    Get.put(UpdateController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      authController.refreshProfile(),
      fetchAdminNotification(),
    ]);
  }

  Future<void> fetchAdminNotification() async {
    try {
      final String userMode = (authController.userData['mode'] ?? "online")
          .toString()
          .toLowerCase();
      final response = await http.get(
        Uri.parse("${ApiEndpoints.userNotification}?mode=$userMode"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasNotification'] == true) {
          authController.adminMessage.value = data['message'];
          authController.isMessageVisible.value = true;
        } else {
          authController.adminMessage.value = null;
          authController.isMessageVisible.value = false;
        }
      }
    } catch (e) {
      debugPrint("Error fetching notification: $e");
    }
  }

  void showAccessDeniedDialog(String title) {
    Get.dialog(
      Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tealMist.withOpacity(0.3), width: 1.2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Access Restricted",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Please contact your institute admin to unlock $title.",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepOceanBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Understood",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.3,
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

  bool _isStageLocked(String stageKey) {
    final english = authController.userData['englishAccess'];
    if (english == null || english is! Map) return true;
    return english[stageKey] != true;
  }

  @override
  Widget build(BuildContext context) {
    const Color headerColor = Color(0xff14141E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Offline Banner Indicator
          Obx(
            () => !netController.isConnected.value
                ? Container(
                    width: double.infinity,
                    color: Colors.redAccent.shade700,
                    padding: const EdgeInsets.only(top: 45, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "No Internet Connection",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Custom Ambient Header
          Obx(
            () => Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: !netController.isConnected.value ? 15 : 55,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tealMist.withOpacity(0.18),
                      border: Border.all(
                        color: tealMist.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (authController.userData['name'] ?? 'L').isNotEmpty
                            ? (authController.userData['name'] ?? 'L')[0]
                                  .toUpperCase()
                            : 'L',
                        style: GoogleFonts.poppins(
                          color: goldenYellow,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "English Curriculum",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        authController.userData['name'] ?? 'Learner',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Learning Area with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              color: goldenYellow,
              backgroundColor: cardColor,
              onRefresh: _refreshAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Obx(() {
                  final bool isOnlineStudent =
                      (authController.userData['mode'] ?? "online")
                          .toString()
                          .toLowerCase() ==
                      "online";

                  final List<Map<String, dynamic>> stagesData = [
                    {
                      "title": "Stage 1",
                      "subtitle": "Foundational English",
                      "stageNum": 1,
                      "destination": const EnglishStage1Screen(),
                      "isLocked": _isStageLocked('stage1'),
                    },
                    {
                      "title": "Stage 2",
                      "subtitle": "Basic Grammar",
                      "stageNum": 2,
                      "destination": const EnglishStage2Screen(),
                      "isLocked": _isStageLocked('stage2'),
                    },
                    {
                      "title": "Stage 3",
                      "subtitle": "Conversational Skills",
                      "stageNum": 3,
                      "destination": const EnglishStage3Screen(),
                      "isLocked": _isStageLocked('stage3'),
                    },
                    {
                      "title": "Stage 4",
                      "subtitle": "Vocabulary Expansion",
                      "stageNum": 4,
                      "destination": const EnglishStage4Screen(),
                      "isLocked": _isStageLocked('stage4'),
                    },
                    {
                      "title": "Stage 5",
                      "subtitle": "Fluency Practice",
                      "stageNum": 5,
                      "destination": const EnglishStage5Screen(),
                      "isLocked": _isStageLocked('stage5'),
                    },
                    {
                      "title": "Stage 6",
                      "subtitle": "Advanced Speaking",
                      "stageNum": 6,
                      "destination": const EnglishStage6Screen(),
                      "isLocked": _isStageLocked('stage6'),
                    },
                    {
                      "title": "Stage 7",
                      "subtitle": "Mastery & Accent",
                      "stageNum": 7,
                      "destination": const EnglishStage7Screen(),
                      "isLocked": _isStageLocked('stage7'),
                    },
                  ];

                  final List<Map<String, dynamic>> onlineClassesData = [
                    {
                      "label": "Stage 1",
                      "dest": const EnglishOnlineStage1Screen(),
                      "isLocked": _isStageLocked('stage1'),
                    },
                    {
                      "label": "Stage 2",
                      "dest": const EnglishOnlineStage2Screen(),
                      "isLocked": _isStageLocked('stage2'),
                    },
                    {
                      "label": "Stage 3",
                      "dest": const EnglishOnlineStage3Screen(),
                      "isLocked": _isStageLocked('stage3'),
                    },
                    {
                      "label": "Stage 4",
                      "dest": const EnglishOnlineStage4Screen(),
                      "isLocked": _isStageLocked('stage4'),
                    },
                    {
                      "label": "Stage 5",
                      "dest": const EnglishOnlineStage5Screen(),
                      "isLocked": _isStageLocked('stage5'),
                    },
                    {
                      "label": "Stage 6",
                      "dest": const EnglishOnlineStage6Screen(),
                      "isLocked": _isStageLocked('stage6'),
                    },
                    {
                      "label": "Stage 7",
                      "dest": const EnglishOnlineStage7Screen(),
                      "isLocked": _isStageLocked('stage7'),
                    },
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ⚡ Real-Time Admin Broadcast Announcement Banner
                      if (authController.adminMessage.value != null &&
                          authController.isMessageVisible.value) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2C2211), Color(0xFF1E1910)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.shade600.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.campaign_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Notice from Admin",
                                      style: GoogleFonts.poppins(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      authController.adminMessage.value!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    authController.isMessageVisible.value =
                                        false,
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 🚀 ONLINE CLASSES PLACED AT THE TOP (UX BOOST)
                      if (isOnlineStudent) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tealMist.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: deepOceanBlue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.live_tv_rounded,
                                      color: goldenYellow,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Interactive Online Classes",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: onlineClassesData.map((item) {
                                    return _buildClassAvatar(
                                      context,
                                      item["label"],
                                      deepOceanBlue,
                                      item["dest"],
                                      isLocked: item["isLocked"],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Learning Stages Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "English Material Stages",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${stagesData.length} Stages",
                            style: GoogleFonts.poppins(
                              color: goldenYellow,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Grid of 7 Stages
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stagesData.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.15,
                            ),
                        itemBuilder: (context, index) {
                          final stage = stagesData[index];
                          return _buildModernStageCard(
                            context: context,
                            title: stage["title"],
                            subtitle: stage["subtitle"],
                            stageNum: stage["stageNum"],
                            destination: stage["destination"],
                            isLocked: stage["isLocked"],
                            cardColor: cardColor,
                            accentColor: deepOceanBlue,
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int stageNum,
    required Widget destination,
    required bool isLocked,
    required Color cardColor,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          showAccessDeniedDialog(title);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLocked
                ? Colors.white.withOpacity(0.05)
                : tealMist.withOpacity(0.4),
            width: isLocked ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.white.withOpacity(0.05)
                        : accentColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLocked
                          ? Colors.white.withOpacity(0.08)
                          : tealMist.withOpacity(0.45),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "0$stageNum",
                      style: GoogleFonts.poppins(
                        color: isLocked ? Colors.white38 : goldenYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? const Color(0xff2A1C1C)
                        : tealMist.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                    color: isLocked ? Colors.amber : goldenYellow,
                    size: 14,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassAvatar(
    BuildContext context,
    String label,
    Color color,
    Widget destination, {
    required bool isLocked,
  }) {
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          showAccessDeniedDialog("Admin approval required");
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLocked
                          ? Colors.white12
                          : tealMist.withOpacity(0.6),
                      width: 1.5,
                    ),
                    color: isLocked
                        ? const Color(0xff0D0D14)
                        : color.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.videocam_rounded,
                      color: isLocked ? Colors.white24 : goldenYellow,
                      size: 22,
                    ),
                  ),
                ),
                if (isLocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xff0A0A0E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.amber,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isLocked ? Colors.white30 : Colors.white70,
                fontSize: 11,
                fontWeight: isLocked ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
