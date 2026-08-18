import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

// --- IMPORT TEST SCREENS ---
import 'package:lets_talk/Screens/Test_screens/English%20Test/English_stage1Test.dart';
import 'package:lets_talk/Screens/Test_screens/English%20Test/English_stage2Test.dart';
import 'package:lets_talk/Screens/Test_screens/English%20Test/English_stage3Test.dart';
import 'package:lets_talk/Screens/Test_screens/English%20Test/English_stage4Test.dart'
    hide EnglishTestStagefoureScreen;
import 'package:lets_talk/Screens/Test_screens/English%20Test/English_stage5Test.dart';
import 'package:lets_talk/Screens/Test_screens/English%20Test/English_stage6Test.dart';
import 'package:lets_talk/Screens/Test_screens/English%20Test/English_stage7Test.dart';

import 'package:lets_talk/Screens/Test_screens/Hindi%20Test/Hindi_stage1Test.dart';
import 'package:lets_talk/Screens/Test_screens/Hindi%20Test/Hindi_stage2Test.dart';
import 'package:lets_talk/Screens/Test_screens/Hindi%20Test/Hindi_stage3Test.dart';
import 'package:lets_talk/Screens/Test_screens/Hindi%20Test/Hindi_stage4Test.dart';
import 'package:lets_talk/Screens/Test_screens/Hindi%20Test/Hindi_stage5Test.dart';
import 'package:lets_talk/Screens/Test_screens/Hindi%20Test/Hindi_stage6Test.dart';
import 'package:lets_talk/Screens/Test_screens/Hindi%20Test/Hindi_stage7Test.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AuthController authController = Get.find<AuthController>();
  final RxInt selectedTab = 0.obs; // 0 = English, 1 = Hindi

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.refreshProfile();
    });
  }

  void _showAccessDeniedDialog(String testName) {
    Get.defaultDialog(
      title: "Access Restricted",
      titlePadding: const EdgeInsets.only(top: 24, bottom: 8),
      titleStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      middleText: "Admin approval required to access $testName.",
      middleTextStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
      backgroundColor: const Color(0xff181824),
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

  bool _isEnglishLocked(String stageKey) {
    final access = authController.userData['englishAccess'];
    if (access == null || access is! Map) return true;
    return access[stageKey] != true;
  }

  bool _isHindiLocked(String stageKey) {
    final access = authController.userData['hindiAccess'];
    if (access == null || access is! Map) return true;
    return access[stageKey] != true;
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xff0A0A0E);
    const Color headerColor = Color(0xff14141E);
    const Color cardColor = Color(0xff14141E);
    const Color accentPurple = Color(0xff7F56D9);
    const Color accentBlue = Color(0xff158DFE);

    final List<Map<String, dynamic>> englishStages = [
      {"stage": 1, "key": "stage1", "dest": const EnglishTestStage1Screen()},
      {"stage": 2, "key": "stage2", "dest": const EnglishTestStage2Screen()},
      {"stage": 3, "key": "stage3", "dest": const EnglishTestStage3Screen()},
      {"stage": 4, "key": "stage4", "dest": const EnglishTestStage4Screen()},
      {"stage": 5, "key": "stage5", "dest": const EnglishTestStage5Screen()},
      {"stage": 6, "key": "stage6", "dest": const EnglishTestStage6Screen()},
      {"stage": 7, "key": "stage7", "dest": const EnglishTestStage7Screen()},
    ];

    final List<Map<String, dynamic>> hindiStages = [
      {"stage": 1, "key": "stage1", "dest": const HindiTestStage1Screen()},
      {"stage": 2, "key": "stage2", "dest": const HindiTestStage2Screen()},
      {"stage": 3, "key": "stage3", "dest": const HindiTestStage3Screen()},
      {"stage": 4, "key": "stage4", "dest": const HindiTestStage4Screen()},
      {"stage": 5, "key": "stage5", "dest": const HindiTestStage5Screen()},
      {"stage": 6, "key": "stage6", "dest": const HindiTestStage6Screen()},
      {"stage": 7, "key": "stage7", "dest": const HindiTestStage7Screen()},
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // --- HEADER SECTION ---
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Assessment Portal 📝",
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Take A Test",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => authController.refreshProfile(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // --- SLIDING LANGUAGE SELECTOR ---
                Obx(
                  () => Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xff0A0A0E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => selectedTab.value = 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: selectedTab.value == 0
                                    ? accentPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.language_rounded,
                                    size: 16,
                                    color: selectedTab.value == 0
                                        ? Colors.white
                                        : Colors.white60,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "English Tests",
                                    style: GoogleFonts.poppins(
                                      color: selectedTab.value == 0
                                          ? Colors.white
                                          : Colors.white60,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => selectedTab.value = 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: selectedTab.value == 1
                                    ? accentBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.translate_rounded,
                                    size: 16,
                                    color: selectedTab.value == 1
                                        ? Colors.white
                                        : Colors.white60,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Hindi Tests",
                                    style: GoogleFonts.poppins(
                                      color: selectedTab.value == 1
                                          ? Colors.white
                                          : Colors.white60,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BODY WITH REFRESH INDICATOR ---
          Expanded(
            child: RefreshIndicator(
              color: accentPurple,
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
                child: Obx(() {
                  final isEnglish = selectedTab.value == 0;
                  final currentList = isEnglish ? englishStages : hindiStages;
                  final activeAccent = isEnglish ? accentPurple : accentBlue;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEnglish
                                ? "English Stage Evaluations"
                                : "Hindi Stage Evaluations",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${currentList.length} Stages",
                            style: GoogleFonts.poppins(
                              color: activeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: currentList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = currentList[index];
                          final int stageNum = item["stage"];
                          final String key = item["key"];
                          final Widget destination = item["dest"];
                          final bool isLocked = isEnglish
                              ? _isEnglishLocked(key)
                              : _isHindiLocked(key);

                          return _buildQuizCard(
                            stageNumber: stageNum,
                            language: isEnglish ? "English" : "Hindi",
                            isLocked: isLocked,
                            accentColor: activeAccent,
                            cardColor: cardColor,
                            onTap: () {
                              if (isLocked) {
                                _showAccessDeniedDialog("Stage $stageNum Test");
                              } else {
                                Get.to(() => destination);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildQuizCard({
    required int stageNumber,
    required String language,
    required bool isLocked,
    required Color accentColor,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked
                ? Colors.white.withOpacity(0.05)
                : accentColor.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Stage Number Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.white.withOpacity(0.04)
                    : accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLocked
                      ? Colors.white.withOpacity(0.08)
                      : accentColor.withOpacity(0.4),
                ),
              ),
              child: Center(
                child: Text(
                  "0$stageNumber",
                  style: GoogleFonts.poppins(
                    color: isLocked ? Colors.white38 : accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stage $stageNumber Assessment",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$language • 25 Minutes Timed Test",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Lock / Start Action Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLocked
                    ? const Color(0xff2A1C1C)
                    : accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                color: isLocked ? Colors.amber : accentColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
