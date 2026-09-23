import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lets_talk/Screens/Test_screens/TestTaking_widgetScreen.dart';
import 'package:lets_talk/Screens/app_colors.dart';


// ============================================================
// ENGLISH TEST WRAPPERS
// These screens connect the instruction screen to the real test.
// DO NOT REMOVE.
// ============================================================

class EnglishTestStageoneScreen extends StatelessWidget {
  const EnglishTestStageoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "English",
      stage: "stage1",
    );
  }
}


class EnglishTestStagetwoScreen extends StatelessWidget {
  const EnglishTestStagetwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "English",
      stage: "stage2",
    );
  }
}


class EnglishTestStagethreeScreen extends StatelessWidget {
  const EnglishTestStagethreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "English",
      stage: "stage3",
    );
  }
}


// Keeping your old class name so existing navigation does not break.
class EnglishTestStagefoureScreen extends StatelessWidget {
  const EnglishTestStagefoureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "English",
      stage: "stage4",
    );
  }
}


class EnglishTestStagefiveScreen extends StatelessWidget {
  const EnglishTestStagefiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "English",
      stage: "stage5",
    );
  }
}


class EnglishTestStagesixScreen extends StatelessWidget {
  const EnglishTestStagesixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "English",
      stage: "stage6",
    );
  }
}


class EnglishTestStagesevenScreen extends StatelessWidget {
  const EnglishTestStagesevenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "English",
      stage: "stage7",
    );
  }
}


// ============================================================
// HINDI TEST WRAPPERS
// ============================================================

class HindiTestStageoneScreen extends StatelessWidget {
  const HindiTestStageoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "Hindi",
      stage: "stage1",
    );
  }
}


class HindiTestStagetwoScreen extends StatelessWidget {
  const HindiTestStagetwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "Hindi",
      stage: "stage2",
    );
  }
}


class HindiTestStagethreeScreen extends StatelessWidget {
  const HindiTestStagethreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "Hindi",
      stage: "stage3",
    );
  }
}


class HindiTestStagefoureScreen extends StatelessWidget {
  const HindiTestStagefoureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "Hindi",
      stage: "stage4",
    );
  }
}


class HindiTestStagefiveScreen extends StatelessWidget {
  const HindiTestStagefiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "Hindi",
      stage: "stage5",
    );
  }
}


class HindiTestStagesixScreen extends StatelessWidget {
  const HindiTestStagesixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "Hindi",
      stage: "stage6",
    );
  }
}


class HindiTestStagesevenScreen extends StatelessWidget {
  const HindiTestStagesevenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestTakingScreen(
      language: "Hindi",
      stage: "stage7",
    );
  }
}


// ============================================================
// REUSABLE INSTRUCTION SCREEN
// ============================================================

class _StageInstructionScreen extends StatelessWidget {
  final String language;
  final int stage;
  final VoidCallback onStart;

  const _StageInstructionScreen({
    required this.language,
    required this.stage,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.background;

    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.surface;

    final surfaceSoftColor = isDark
        ? AppColors.darkSurface2
        : AppColors.surfaceSoft;

    final borderColor = isDark
        ? AppColors.darkBorder
        : AppColors.border;

    final primaryText = isDark
        ? AppColors.darkText
        : AppColors.text;

    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final languageColor =
        language.toLowerCase() == "hindi"
            ? AppColors.teal
            : AppColors.navy;

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: "Back",
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: primaryText,
            ),
          ),
        ),

        title: Text(
          "Test Instructions",
          style: GoogleFonts.poppins(
            color: primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 700;

            return Column(
              children: [

                // ====================================================
                // SCROLLABLE CONTENT
                // ====================================================

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),

                    padding: EdgeInsets.fromLTRB(
                      20,
                      isSmallHeight ? 8 : 14,
                      20,
                      20,
                    ),

                    child: Column(
                      children: [

                        // ==================================================
                        // HERO
                        // ==================================================

                        _buildHero(
                          context: context,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          languageColor: languageColor,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // TEST INFORMATION
                        // ==================================================

                        _buildInformationCard(
                          context: context,
                          surfaceColor: surfaceColor,
                          surfaceSoftColor: surfaceSoftColor,
                          borderColor: borderColor,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // IMPORTANT NOTE
                        // ==================================================

                        _buildImportantNote(
                          context: context,
                          surfaceColor: surfaceSoftColor,
                          borderColor: borderColor,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // TEST GUIDANCE
                        // ==================================================

                        _buildGuidance(
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // ========================================================
                // START BUTTON
                // ========================================================

                Container(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    16,
                  ),

                  decoration: BoxDecoration(
                    color: backgroundColor,

                    border: Border(
                      top: BorderSide(
                        color: borderColor.withValues(alpha: 0.65),
                        width: 1,
                      ),
                    ),
                  ),

                  child: SizedBox(
                    width: double.infinity,
                    height: 56,

                    child: ElevatedButton(
                      onPressed: onStart,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Text(
                            "Start Stage $stage",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 21,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero({
    required BuildContext context,
    required Color primaryText,
    required Color secondaryText,
    required Color languageColor,
    required bool isDark,
  }) {
    return Column(
      children: [

        // Icon
        Container(
          width: 92,
          height: 92,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.navy,
                AppColors.deepNavy,
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(
                  alpha: isDark ? 0.25 : 0.18,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: const Icon(
            Icons.assignment_rounded,
            color: Colors.white,
            size: 43,
          ),
        ),

        const SizedBox(height: 18),

        // Language chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),

          decoration: BoxDecoration(
            color: languageColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: languageColor.withValues(alpha: 0.20),
            ),
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                language.toLowerCase() == "hindi"
                    ? Icons.translate_rounded
                    : Icons.language_rounded,
                size: 15,
                color: languageColor,
              ),

              const SizedBox(width: 6),

              Text(
                language,
                style: GoogleFonts.poppins(
                  color: languageColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "$language Stage $stage Test",
          textAlign: TextAlign.center,

          style: GoogleFonts.poppins(
            color: primaryText,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Check the details below before starting your assessment.",
          textAlign: TextAlign.center,

          style: GoogleFonts.poppins(
            color: secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }


  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard({
    required BuildContext context,
    required Color surfaceColor,
    required Color surfaceSoftColor,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: surfaceColor,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: borderColor,
        ),

        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(
              alpha: isDark ? 0.06 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Card title
          Row(
            children: [

              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),

                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.navy,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Text(
                "Assessment Details",
                style: GoogleFonts.poppins(
                  color: primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Details
          Row(
            children: [

              Expanded(
                child: _buildInfoItem(
                  icon: Icons.timer_outlined,
                  label: "Duration",
                  value: "25 Min",
                  color: AppColors.teal,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  backgroundColor: surfaceSoftColor,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildInfoItem(
                  icon: Icons.help_outline_rounded,
                  label: "Questions",
                  value: "30",
                  color: AppColors.navy,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  backgroundColor: surfaceSoftColor,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildInfoItem(
                  icon: Icons.star_outline_rounded,
                  label: "Marks",
                  value: "30",
                  color: AppColors.yellow,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  backgroundColor: surfaceSoftColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ============================================================
  // INFORMATION ITEM
  // ============================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color primaryText,
    required Color secondaryText,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        children: [

          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: GoogleFonts.poppins(
              color: primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // IMPORTANT NOTE
  // ============================================================

  Widget _buildImportantNote({
    required BuildContext context,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.28),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.yellow,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Important",
                  style: GoogleFonts.poppins(
                    color: primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Submit your test before the time ends. "
                  "Make sure your answers are completed before submitting.",
                  style: GoogleFonts.poppins(
                    color: secondaryText,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // GUIDANCE
  // ============================================================

  Widget _buildGuidance({
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Before you start",
          style: GoogleFonts.poppins(
            color: primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        _buildGuidanceRow(
          icon: Icons.wifi_rounded,
          text: "Make sure you have a stable internet connection.",
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),

        const SizedBox(height: 8),

        _buildGuidanceRow(
          icon: Icons.timer_outlined,
          text: "The timer will start once you begin the test.",
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),

        const SizedBox(height: 8),

        _buildGuidanceRow(
          icon: Icons.check_circle_outline_rounded,
          text: "Review your answers before submitting.",
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
      ],
    );
  }


  Widget _buildGuidanceRow({
    required IconData icon,
    required String text,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Icon(
          icon,
          size: 17,
          color: AppColors.teal,
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}


// ============================================================
// ENGLISH STAGE 1
// ============================================================

class EnglishTestStage1Screen extends StatelessWidget {
  const EnglishTestStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "English",
      stage: 1,
      onStart: () {
        Get.to(
          () => const EnglishTestStageoneScreen(),
        );
      },
    );
  }
}


// ============================================================
// ENGLISH STAGE 2
// ============================================================

class EnglishTestStage2Screen extends StatelessWidget {
  const EnglishTestStage2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "English",
      stage: 2,
      onStart: () {
        Get.to(
          () => const EnglishTestStagetwoScreen(),
        );
      },
    );
  }
}


// ============================================================
// ENGLISH STAGE 3
// ============================================================

class EnglishTestStage3Screen extends StatelessWidget {
  const EnglishTestStage3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "English",
      stage: 3,
      onStart: () {
        Get.to(
          () => const EnglishTestStagethreeScreen(),
        );
      },
    );
  }
}


// ============================================================
// ENGLISH STAGE 4
// ============================================================

class EnglishTestStage4Screen extends StatelessWidget {
  const EnglishTestStage4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "English",
      stage: 4,
      onStart: () {
        Get.to(
          () => const EnglishTestStagefoureScreen(),
        );
      },
    );
  }
}


// ============================================================
// ENGLISH STAGE 5
// ============================================================

class EnglishTestStage5Screen extends StatelessWidget {
  const EnglishTestStage5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "English",
      stage: 5,
      onStart: () {
        Get.to(
          () => const EnglishTestStagefiveScreen(),
        );
      },
    );
  }
}


// ============================================================
// ENGLISH STAGE 6
// ============================================================

class EnglishTestStage6Screen extends StatelessWidget {
  const EnglishTestStage6Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "English",
      stage: 6,
      onStart: () {
        Get.to(
          () => const EnglishTestStagesixScreen(),
        );
      },
    );
  }
}


// ============================================================
// ENGLISH STAGE 7
// ============================================================

class EnglishTestStage7Screen extends StatelessWidget {
  const EnglishTestStage7Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "English",
      stage: 7,
      onStart: () {
        Get.to(
          () => const EnglishTestStagesevenScreen(),
        );
      },
    );
  }
}


// ============================================================
// HINDI STAGE 1
// ============================================================

class HindiTestStage1Screen extends StatelessWidget {
  const HindiTestStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "Hindi",
      stage: 1,
      onStart: () {
        Get.to(
          () => const HindiTestStageoneScreen(),
        );
      },
    );
  }
}


// ============================================================
// HINDI STAGE 2
// ============================================================

class HindiTestStage2Screen extends StatelessWidget {
  const HindiTestStage2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "Hindi",
      stage: 2,
      onStart: () {
        Get.to(
          () => const HindiTestStagetwoScreen(),
        );
      },
    );
  }
}


// ============================================================
// HINDI STAGE 3
// ============================================================

class HindiTestStage3Screen extends StatelessWidget {
  const HindiTestStage3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "Hindi",
      stage: 3,
      onStart: () {
        Get.to(
          () => const HindiTestStagethreeScreen(),
        );
      },
    );
  }
}


// ============================================================
// HINDI STAGE 4
// ============================================================

class HindiTestStage4Screen extends StatelessWidget {
  const HindiTestStage4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "Hindi",
      stage: 4,
      onStart: () {
        Get.to(
          () => const HindiTestStagefoureScreen(),
        );
      },
    );
  }
}


// ============================================================
// HINDI STAGE 5
// ============================================================

class HindiTestStage5Screen extends StatelessWidget {
  const HindiTestStage5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "Hindi",
      stage: 5,
      onStart: () {
        Get.to(
          () => const HindiTestStagefiveScreen(),
        );
      },
    );
  }
}


// ============================================================
// HINDI STAGE 6
// ============================================================

class HindiTestStage6Screen extends StatelessWidget {
  const HindiTestStage6Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "Hindi",
      stage: 6,
      onStart: () {
        Get.to(
          () => const HindiTestStagesixScreen(),
        );
      },
    );
  }
}


// ============================================================
// HINDI STAGE 7
// ============================================================

class HindiTestStage7Screen extends StatelessWidget {
  const HindiTestStage7Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StageInstructionScreen(
      language: "Hindi",
      stage: 7,
      onStart: () {
        Get.to(
          () => const HindiTestStagesevenScreen(),
        );
      },
    );
  }
}