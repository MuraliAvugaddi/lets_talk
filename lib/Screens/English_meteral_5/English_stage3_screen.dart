import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';
import 'package:path_provider/path_provider.dart';

class EnglishStage3Screen extends StatefulWidget {
  const EnglishStage3Screen({super.key});

  @override
  State<EnglishStage3Screen> createState() => _EnglishStage3ScreenState();
}

class _EnglishStage3ScreenState extends State<EnglishStage3Screen> {
  // Pull-to-refresh handler for the screen view
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
        "title": "Stage 3 Orientation & Demo",
        "subtitle": "Introduction to complex conjunctions & perfect tenses",
        "pdfPath": null,
        "isPractice": false,
      },
      {
        "day": "Day 2",
        "title": "Conjunctions of If & Unless",
        "subtitle": "Conditional clauses and negative condition rules",
        "pdfPath":
            "assets/images/satge3/Day-2_ST-3_Eng (The Conjunctions of If & Unless).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 3",
        "title": "Conjunctions of When, Only When & While",
        "subtitle": "Time-based simultaneous & sequential action clauses",
        "pdfPath":
            "assets/images/satge3/Day-3_ST-3_Eng (The conjunctions of When,Only When & While).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 4",
        "title": "Practice on If, Unless, When, Only When & While",
        "subtitle": "Comprehensive conditional & temporal connective drills",
        "pdfPath":
            "assets/images/satge3/Day-4_ST-3_Eng (🔴 Practice on If, Unless, When, Only When & While).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 5",
        "title": "Conjunctions of Before & After",
        "subtitle": "Chronological sentence structures and connectors",
        "pdfPath":
            "assets/images/satge3/Day-5_ST-3_Eng (The conjunctions of Before & After).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 6",
        "title": "Conjunctions of As soon as, As long as & Till (Until)",
        "subtitle": "Duration and immediate transition connectors",
        "pdfPath":
            "assets/images/satge3/Day-6_ST-3_Eng (The conjunctions of As soon as, As long as & Till [Until]).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 7",
        "title": "Practice on Time Conjunctions",
        "subtitle": "Consolidated time clause sentence practice",
        "pdfPath":
            "assets/images/satge3/Day-7_ST-3_Eng (🔴 Practice on Time conjunctions).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 8",
        "title": "Conjunctions of Reasons & Contrast",
        "subtitle": "But, So, Since, That's why, Hence, Although, Yet",
        "pdfPath":
            "assets/images/satge3/Day-8_ST-3_Eng (The conjunctions of reasons But, So, Since_As, That's why_Hence, because, Although_Though_Even though, Yet,...... (1).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 9",
        "title": "Practice on Conjunctions of Reasons",
        "subtitle": "Cause, effect and contrast sentence formation",
        "pdfPath":
            "assets/images/satge3/Day-9_ST-3_Eng (🔴 Practice on conjunctions of reasons).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 10",
        "title": "Conjunctions of 'Ever' Family",
        "subtitle": "Whatever, Whomever, Whoever, Whenever & Wherever",
        "pdfPath":
            "assets/images/satge3/Day-10_ST-3_Eng (Conjunctions of ever family [Whatever, Whomever, Whoever, Whenever & Wherever]).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 11",
        "title": "Practice on All Conjunctions",
        "subtitle": "Full Stage 3 conjunction review and mixed drills",
        "pdfPath":
            "assets/images/satge3/Day-11_ST-3_Eng (🔴Practice on all the conjunctions).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 12",
        "title": "Present Perfect BE Form",
        "subtitle": "Has been / Have been state of being expressions",
        "pdfPath":
            "assets/images/satge3/Day-12_ST-3_Eng (Present perfect BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 13",
        "title": "Present Perfect THERE Form",
        "subtitle": "There has been / There have been existentials",
        "pdfPath":
            "assets/images/satge3/Day-13_ST-3_Eng (Present Perfect THERE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 14",
        "title": "Present Perfect IT Form",
        "subtitle": "It has been situational & time-lapse structures",
        "pdfPath":
            "assets/images/satge3/Day-14_ST-3_Eng (Present Perfect IT FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 15",
        "title": "Present Perfect HAVE Form",
        "subtitle": "Has had / Have had perfect possession forms",
        "pdfPath":
            "assets/images/satge3/Day-15_ST-3_Eng (Present Perfect HAVE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 16",
        "title": "Practice on Present Perfect BE, THERE, IT & HAVE",
        "subtitle": "Non-action present perfect state drills",
        "pdfPath":
            "assets/images/satge3/Day-16_ST-3_Eng (🔴 Practice on Present Perfect BE, THERE, IT & HAVE forms).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 17",
        "title": "Present Perfect A.V",
        "subtitle": "Active voice completed actions with present relevance",
        "pdfPath":
            "assets/images/satge3/Day-17_ST-3_Eng (Present Perfect A.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 18",
        "title": "Present Perfect P.V",
        "subtitle": "Passive transformations for completed present actions",
        "pdfPath":
            "assets/images/satge3/Day-18_ST-3_Eng (Present Perfect P.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 19",
        "title": "Present Perfect Continuous A.V",
        "subtitle": "Has/Have been + verb-ing since & for usages",
        "pdfPath":
            "assets/images/satge3/Day-19_ST-3_Eng (Present Perfect Continuous A.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 20",
        "title": "Practice on Present Perfect & Simple Tenses",
        "subtitle": "Present perfect vs present simple comparative analysis",
        "pdfPath":
            "assets/images/satge3/Day-20_ST-3_Eng (🔴 Practice on Present Perfect & Simple tenses).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 21",
        "title": "Past Perfect BE Form",
        "subtitle": "Had been state of being before past reference points",
        "pdfPath":
            "assets/images/satge3/Day-21_ST-3_Eng (Past Perfect BE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 22",
        "title": "Past Perfect HAVE Form",
        "subtitle": "Had had past prior possession constructions",
        "pdfPath":
            "assets/images/satge3/Day-22_ST-3_Eng (Past Perfect HAVE FORM).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 23",
        "title": "Past Perfect Active Voice",
        "subtitle": "Earlier past actions preceding another past event",
        "pdfPath":
            "assets/images/satge3/Day-23_ST-3_Eng (Past Perfect ACTIVE VOICE).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 24",
        "title": "Past Perfect Passive Voice",
        "subtitle": "Had been + V3 constructions for antecedent actions",
        "pdfPath":
            "assets/images/satge3/Day-24_ST-3_Eng (Past Perfect PASSIVE VOICE).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 25",
        "title": "Past Perfect Continuous A.V",
        "subtitle": "Ongoing past actions leading up to another point",
        "pdfPath":
            "assets/images/satge3/Day-25_ST-3_Eng (Past Perfect Continuous A.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 26",
        "title": "Practice on the Whole Past Perfect Tense",
        "subtitle": "Comprehensive past perfect active & passive drills",
        "pdfPath":
            "assets/images/satge3/Day-26_ST-3_Eng (🔴Practice on the whole Past Perfect tense).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 27",
        "title": "Future Perfect BE & HAVE Form",
        "subtitle": "Will have been & Will have had expectations",
        "pdfPath":
            "assets/images/satge3/Day-27_ST-3_Eng (Future Perfect BE & HAVE form).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 28",
        "title": "Future Perfect A.V & P.V",
        "subtitle": "Actions completed before a specified future time",
        "pdfPath":
            "assets/images/satge3/Day-28_ST-3_Eng (Future Perfect A.V & P.V).pdf",
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
              // Fixed modern rounded app bar matching Stage 1 & 2
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
                                    'Stage 3 • 28 lessons',
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
                                'Stage 3 — Progression',
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
                                '28 days',
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
              const StageAttendanceWidget(stageName: 'Stage 3'),

              // Scrollable area for Course Hero and Lessons with pull-to-refresh
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
                                'Open a lesson to study the material and build your English step by step.',
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
                                  'Stage 3 Lessons',
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
                                  '28 lessons',
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
                'Day 1 is an interactive Demo Class & Orientation session conducted live by the teacher. No PDF reading is required.',
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
                  'STAGE 3',
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

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFromAsset();
  }

  Future<void> _loadPdfFromAsset() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final filename = widget.assetPath.split('/').last;
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (mounted) {
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final text = isDark ? AppColors.darkText : AppColors.text;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final pdfSystemBarColor = AppColors.navy;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: pdfSystemBarColor,
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
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(color: AppColors.navy),
                child: Row(
                  children: [
                    _HeaderButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: Get.back,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Stage 3  •  Lesson material',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderButton(
                      icon: Icons.refresh_rounded,
                      onTap: _loadPdfFromAsset,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.teal),
                      )
                    : localPath != null
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFF5F8FA),
                              padding: EdgeInsets.zero,
                              child: PDFView(
                                filePath: localPath,
                                enableSwipe: true,
                                swipeHorizontal: false,
                                autoSpacing: false,
                                pageFling: true,
                                pageSnap: true,
                                fitPolicy: FitPolicy.WIDTH,
                                backgroundColor: isDark
                                    ? AppColors.darkBackground
                                    : const Color(0xFFF5F8FA),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 14,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface2
                                      : AppColors.deepNavy,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      color: AppColors.yellow,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Swipe to read lesson',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: AppColors.error10,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Unable to load document',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please try opening the lesson again.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: secondary,
                                  fontSize: 11,
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
    );
  }
}
