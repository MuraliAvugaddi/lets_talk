import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

// --- STAGE SCREEN IMPORTS ---
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_club_5/Hindi_club_stage1_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_club_5/Hindi_club_stage2_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_club_5/Hindi_club_stage3_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_club_5/Hindi_club_stage4_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_club_5/Hindi_club_stage5_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_club_5/Hindi_club_stage6_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_club_5/Hindi_club_stage7_screen.dart';

import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage1_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage2_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage3_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage4_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage5_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage6_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage7_screen.dart';

import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage1_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage2_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage3_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage4_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage5_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage6_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage7_screen.dart';

class HindiMainScreen extends StatefulWidget {
  const HindiMainScreen({super.key});

  @override
  State<HindiMainScreen> createState() => _HindiMainScreenState();
}

class _HindiMainScreenState extends State<HindiMainScreen> {
  final AuthController authController = Get.find<AuthController>();

  // --- BRAND PALETTE ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color backgroundColor = const Color(0xff0A0A0E);
  final Color headerColor = const Color(0xff14141E);
  final Color cardColor = const Color(0xff14141E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.refreshProfile();
    });
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

  bool _isLocked(String key) {
    final hindi = authController.userData['hindiAccess'];
    if (hindi == null || hindi is! Map) return true;
    return hindi[key] != true;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stagesData = [
      {
        "title": "Stage 1",
        "subtitle": "Foundational Hindi",
        "stageNum": 1,
        "destination": const HindiStage1Screen(),
        "isLocked": _isLocked('stage1'),
      },
      {
        "title": "Stage 2",
        "subtitle": "Basic Grammar",
        "stageNum": 2,
        "destination": const HindiStage2Screen(),
        "isLocked": _isLocked('stage2'),
      },
      {
        "title": "Stage 3",
        "subtitle": "Conversational Skills",
        "stageNum": 3,
        "destination": const HindiStage3Screen(),
        "isLocked": _isLocked('stage3'),
      },
      {
        "title": "Stage 4",
        "subtitle": "Vocabulary Expansion",
        "stageNum": 4,
        "destination": const HindiStage4Screen(),
        "isLocked": _isLocked('stage4'),
      },
      {
        "title": "Stage 5",
        "subtitle": "Fluency Practice",
        "stageNum": 5,
        "destination": const HindiStage5Screen(),
        "isLocked": _isLocked('stage5'),
      },
      {
        "title": "Stage 6",
        "subtitle": "Advanced Speaking",
        "stageNum": 6,
        "destination": const HindiStage6Screen(),
        "isLocked": _isLocked('stage6'),
      },
      {
        "title": "Stage 7",
        "subtitle": "Mastery & Expression",
        "stageNum": 7,
        "destination": const HindiStage7Screen(),
        "isLocked": _isLocked('stage7'),
      },
    ];

    final List<Map<String, dynamic>> onlineData = [
      {
        "label": "Stage 1",
        "dest": const HindiOnlineStage1Screen(),
        "isLocked": _isLocked('stage1'),
      },
      {
        "label": "Stage 2",
        "dest": const HindiOnlineStage2Screen(),
        "isLocked": _isLocked('stage2'),
      },
      {
        "label": "Stage 3",
        "dest": const HindiOnlineStage3Screen(),
        "isLocked": _isLocked('stage3'),
      },
      {
        "label": "Stage 4",
        "dest": const HindiOnlineStage4Screen(),
        "isLocked": _isLocked('stage4'),
      },
      {
        "label": "Stage 5",
        "dest": const HindiOnlineStage5Screen(),
        "isLocked": _isLocked('stage5'),
      },
      {
        "label": "Stage 6",
        "dest": const HindiOnlineStage6Screen(),
        "isLocked": _isLocked('stage6'),
      },
      {
        "label": "Stage 7",
        "dest": const HindiOnlineStage7Screen(),
        "isLocked": _isLocked('stage7'),
      },
    ];

    final List<Map<String, dynamic>> clubData = [
      {
        "label": "Stage 1",
        "dest": const HindiClubStage1Screen(),
        "isLocked": _isLocked('stage1'),
      },
      {
        "label": "Stage 2",
        "dest": const HindiClubStage2Screen(),
        "isLocked": _isLocked('stage2'),
      },
      {
        "label": "Stage 3",
        "dest": const HindiClubStage3Screen(),
        "isLocked": _isLocked('stage3'),
      },
      {
        "label": "Stage 4",
        "dest": const HindiClubStage4Screen(),
        "isLocked": _isLocked('stage4'),
      },
      {
        "label": "Stage 5",
        "dest": const HindiClubStage5Screen(),
        "isLocked": _isLocked('stage5'),
      },
      {
        "label": "Stage 6",
        "dest": const HindiClubStage6Screen(),
        "isLocked": _isLocked('stage6'),
      },
      {
        "label": "Stage 7",
        "dest": const HindiClubStage7Screen(),
        "isLocked": _isLocked('stage7'),
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 55,
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
                      "Hindi Curriculum",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Obx(
                      () => Text(
                        authController.userData['name'] ?? 'Learner',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body with Pull to Refresh
          Expanded(
            child: RefreshIndicator(
              color: goldenYellow,
              backgroundColor: cardColor,
              onRefresh: () async => await authController.refreshProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Hindi Material Stages",
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
                          final bool isLocked = _isLocked(
                            'stage${stage["stageNum"]}',
                          );
                          return _buildModernStageCard(
                            context: context,
                            title: stage["title"],
                            subtitle: stage["subtitle"],
                            stageNum: stage["stageNum"],
                            destination: stage["destination"],
                            isLocked: isLocked,
                            cardColor: cardColor,
                            accentColor: deepOceanBlue,
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Online Classes & Club Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
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
                                children: onlineData.map((item) {
                                  final int index =
                                      onlineData.indexOf(item) + 1;
                                  return _buildClassAvatar(
                                    context,
                                    item["label"],
                                    deepOceanBlue,
                                    item["dest"],
                                    isLocked: _isLocked('stage$index'),
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
                                    color: tealMist.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.groups_rounded,
                                    color: goldenYellow,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Let's Speak in Club (Hindi)",
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
                                  final int index =
                                      clubData.indexOf(item) + 1;
                                  return _buildClubButton(
                                    context,
                                    item["label"],
                                    item["dest"],
                                    isLocked: _isLocked('stage$index'),
                                    accentColor: tealMist,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
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
                      color: isLocked ? Colors.white12 : tealMist.withOpacity(0.6),
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
          color: isLocked ? Colors.transparent : accentColor.withOpacity(0.12),
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