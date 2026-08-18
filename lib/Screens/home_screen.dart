import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Controllers/connectivityController.dart';

// --- SCREEN IMPORTS ---
import 'package:lets_talk/Screens/English_club5/English_club_stage1_screen.dart';
import 'package:lets_talk/Screens/English_club5/English_club_stage2_screen.dart';
import 'package:lets_talk/Screens/English_club5/English_club_stage3_screen.dart';
import 'package:lets_talk/Screens/English_club5/English_club_stage4_screen.dart';
import 'package:lets_talk/Screens/English_club5/English_club_stage5_screen.dart';
import 'package:lets_talk/Screens/English_club5/English_club_stage6_screen.dart';
import 'package:lets_talk/Screens/English_club5/English_club_stage7_screen.dart';

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

// Placeholder screens for Stage 6 & 7


class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final AuthController authController = Get.find<AuthController>();
  final ConnectivityController netController =
      Get.find<ConnectivityController>();

  String? adminMessage;
  bool isMessageVisible = true;
  final String baseUrl = "http://192.168.1.4:5000/api";

  @override
  void initState() {
    super.initState();
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
      final response = await http.get(Uri.parse("$baseUrl/user/notification"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasNotification'] == true) {
          if (mounted) {
            setState(() {
              adminMessage = data['message'];
              isMessageVisible = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching notification: $e");
    }
  }

  void showAccessDeniedDialog(String title) {
    Get.defaultDialog(
      title: "Access Restricted",
      titlePadding: const EdgeInsets.only(top: 24, bottom: 8),
      titleStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      middleText: "Please contact Admin to unlock $title",
      middleTextStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
      backgroundColor: const Color(0xff14141E),
      radius: 18,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      confirm: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 120,
        height: 44,
        child: ElevatedButton(
          onPressed: () => Get.back(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff7F56D9),
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
              fontSize: 13,
            ),
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
    const Color backgroundColor = Color(0xff0A0A0E);
    const Color headerColor = Color(0xff14141E);
    const Color cardColor = Color(0xff14141E);
    const Color accentPurple = Color(0xff7F56D9);
    const Color accentBlue = Color(0xff158DFE);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentPurple.withOpacity(0.18),
                          border: Border.all(
                            color: accentPurple.withOpacity(0.4),
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
                              color: accentPurple,
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
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _refreshAllData,
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Learning Area with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              color: accentPurple,
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

                  final List<Map<String, dynamic>> clubData = [
                    {
                      "label": "Stage 1",
                      "dest": const EnglishClubStage1Screen(),
                      "isLocked": _isStageLocked('stage1'),
                    },
                    {
                      "label": "Stage 2",
                      "dest": const EnglishClubStage2Screen(),
                      "isLocked": _isStageLocked('stage2'),
                    },
                    {
                      "label": "Stage 3",
                      "dest": const EnglishClubStage3Screen(),
                      "isLocked": _isStageLocked('stage3'),
                    },
                    {
                      "label": "Stage 4",
                      "dest": const EnglishClubStage4Screen(),
                      "isLocked": _isStageLocked('stage4'),
                    },
                    {
                      "label": "Stage 5",
                      "dest": const EnglishClubStage5Screen(),
                      "isLocked": _isStageLocked('stage5'),
                    },
                    {
                      "label": "Stage 6",
                      "dest": const EnglishClubStage6Screen(),
                      "isLocked": _isStageLocked('stage6'),
                    },
                    {
                      "label": "Stage 7",
                      "dest": const EnglishClubStage7Screen(),
                      "isLocked": _isStageLocked('stage7'),
                    },
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin Broadcast Announcement
                      if (adminMessage != null && isMessageVisible) ...[
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
                                      adminMessage!,
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
                                    setState(() => isMessageVisible = false),
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
                              color: accentPurple,
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
                            accentColor: accentPurple,
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Online Classes & Live Interactive Group
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
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
                                    color: accentBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.live_tv_rounded,
                                    color: accentBlue,
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
                                    accentBlue,
                                    item["dest"],
                                    isLocked: item["isLocked"],
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 18),
                            Divider(color: Colors.white.withOpacity(0.06)),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: accentPurple.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    color: accentPurple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Let's Speak in Club",
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
                                children: clubData.map((item) {
                                  return _buildClubButton(
                                    context,
                                    item["label"],
                                    item["dest"],
                                    isLocked: item["isLocked"],
                                    accentColor: accentPurple,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
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

  // Modern Stage Grid Card
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
                : accentColor.withOpacity(0.35),
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
                        : accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLocked
                          ? Colors.white.withOpacity(0.08)
                          : accentColor.withOpacity(0.35),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "0$stageNum",
                      style: GoogleFonts.poppins(
                        color: isLocked ? Colors.white38 : accentColor,
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
                        : accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                    color: isLocked ? Colors.amber : accentColor,
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

  // Modern Class Circle Avatar Widget
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
                      color: isLocked ? Colors.white12 : color.withOpacity(0.6),
                      width: 1.5,
                    ),
                    color: isLocked
                        ? const Color(0xff0D0D14)
                        : color.withOpacity(0.15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.videocam_rounded,
                      color: isLocked ? Colors.white24 : color,
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

  // Modern Club Button Widget
  Widget _buildClubButton(
    BuildContext context,
    String label,
    Widget destination, {
    required bool isLocked,
    required Color accentColor,
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
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocked ? Colors.white10 : accentColor.withOpacity(0.4),
          ),
          color: isLocked ? Colors.transparent : accentColor.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isLocked ? Colors.white30 : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_rounded, color: Colors.amber, size: 12),
            ],
          ],
        ),
      ),
    );
  }
}
