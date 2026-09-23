import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

class StudentTestResultsScreen extends StatefulWidget {
  const StudentTestResultsScreen({super.key});

  @override
  State<StudentTestResultsScreen> createState() =>
      _StudentTestResultsScreenState();
}

class _StudentTestResultsScreenState extends State<StudentTestResultsScreen> {
  final AuthController controller = Get.find<AuthController>();

  int selectedTab = 0; // 0 = English, 1 = Hindi
  bool isLoading = false;
  List<dynamic> resultsList = [];

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  // ============================================================
  // API
  // ============================================================

  Future<void> fetchResults() async {
    final userData = controller.userData;
    final userId = userData['id'] ?? userData['_id'];

    if (userId == null) return;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final String language = selectedTab == 0 ? "English" : "Hindi";

    try {
      final response = await http.get(
        Uri.parse(
          "${ApiEndpoints.myResults}?userId=$userId&language=$language",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            resultsList = data['results'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Results Error: $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  int get passedCount {
    return resultsList.where((result) {
      final score = num.tryParse(result['score']?.toString() ?? '0') ?? 0;

      final total =
          num.tryParse(result['totalQuestions']?.toString() ?? '0') ?? 0;

      if (total <= 0) return false;

      return (score / total) >= 0.5;
    }).length;
  }

  double get averageScore {
    if (resultsList.isEmpty) return 0.0;

    double totalScore = 0;
    double totalQuestions = 0;

    for (final result in resultsList) {
      totalScore += num.tryParse(result['score']?.toString() ?? '0') ?? 0;

      totalQuestions +=
          num.tryParse(result['totalQuestions']?.toString() ?? '0') ?? 0;
    }

    if (totalQuestions <= 0) return 0.0;

    return (totalScore / totalQuestions) * 100;
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = isDark ? AppColors.darkBackground : AppColors.background;

    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final textColor = isDark ? AppColors.darkText : AppColors.text;

    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 19,
          ),
          onPressed: () => Get.back(),
        ),

        title: Text(
          "Test Results",
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ==================================================
            // ENGLISH / HINDI
            // ==================================================
            _buildLanguageSelector(
              context,
              surface: surface,
              border: border,
              textColor: textColor,
              secondaryText: secondaryText,
            ),

            // ==================================================
            // SCROLLABLE CONTENT
            // ==================================================
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchResults,
                color: AppColors.teal,
                backgroundColor: surface,

                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),

                  children: [
                    // PERFORMANCE
                    _buildPerformanceHero(
                      context,
                      surface: surface,
                      border: border,
                      textColor: textColor,
                      secondaryText: secondaryText,
                    ),

                    const SizedBox(height: 14),

                    // STATS
                    _buildStatsRow(
                      context,
                      surface: surface,
                      border: border,
                      textColor: textColor,
                      secondaryText: secondaryText,
                    ),

                    const SizedBox(height: 22),

                    // HISTORY HEADER
                    _buildSectionHeader(
                      context,
                      textColor: textColor,
                      secondaryText: secondaryText,
                    ),

                    const SizedBox(height: 10),

                    // CONTENT
                    if (isLoading)
                      _buildLoadingState(surface: surface)
                    else if (resultsList.isEmpty)
                      _buildEmptyState(
                        context,
                        surface: surface,
                        border: border,
                        textColor: textColor,
                        secondaryText: secondaryText,
                      )
                    else
                      ...List.generate(resultsList.length, (index) {
                        final item = resultsList[index];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == resultsList.length - 1 ? 0 : 12,
                          ),
                          child: _buildResultCard(
                            context,
                            item,
                            surface: surface,
                            border: border,
                            textColor: textColor,
                            secondaryText: secondaryText,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LANGUAGE SELECTOR
  // ============================================================

  Widget _buildLanguageSelector(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color textColor,
    required Color secondaryText,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.85)),
      ),

      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              context,
              index: 0,
              title: "English",
              icon: Icons.translate_rounded,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _buildTabButton(
              context,
              index: 1,
              title: "Hindi",
              icon: Icons.language_rounded,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
    required Color textColor,
    required Color secondaryText,
  }) {
    final bool isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        if (selectedTab == index) return;

        setState(() {
          selectedTab = index;
        });

        fetchResults();
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),

        curve: Curves.easeOut,

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),

        decoration: BoxDecoration(
          // YOUR BLUE BRAND COLOR
          color: isSelected ? AppColors.navy : Colors.transparent,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: isSelected ? AppColors.navy : Colors.transparent,
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : secondaryText,
            ),

            const SizedBox(width: 7),

            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : secondaryText,

                  fontSize: 12.5,

                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PERFORMANCE HERO
  // ============================================================

  Widget _buildPerformanceHero(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color textColor,
    required Color secondaryText,
  }) {
    final double percentage = averageScore.clamp(0, 100).toDouble();

    final bool hasResults = resultsList.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: AppColors.teal.withValues(alpha: 0.24)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Row(
        children: [
          // ==================================================
          // CIRCLE
          // ==================================================
          SizedBox(
            width: 92,
            height: 92,

            child: Stack(
              alignment: Alignment.center,

              children: [
                SizedBox(
                  width: 88,
                  height: 88,

                  child: CircularProgressIndicator(
                    value: hasResults ? percentage / 100 : 0,

                    strokeWidth: 8,

                    backgroundColor: AppColors.teal.withValues(alpha: 0.10),

                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.teal,
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      hasResults ? "${percentage.toStringAsFixed(0)}%" : "--",

                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    Text(
                      "Average",

                      style: GoogleFonts.poppins(
                        color: secondaryText,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ==================================================
          // DESCRIPTION
          // ==================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),

                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),

                      child: const Icon(
                        Icons.insights_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Flexible(
                      child: Text(
                        "Performance Overview",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  hasResults
                      ? "Keep going. Your test performance is improving with every assessment."
                      : "Your completed assessments will appear here.",

                  style: GoogleFonts.poppins(
                    color: secondaryText,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),

                if (hasResults) ...[
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildMiniMetric(
                        label: "Passed",
                        value: "$passedCount",
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MINI METRIC
  // ============================================================

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Container(
          width: 7,
          height: 7,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 5),

        Text(
          "$value $label",

          style: GoogleFonts.poppins(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATS ROW
  // ============================================================

  Widget _buildStatsRow(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color textColor,
    required Color secondaryText,
  }) {
    return Row(
      children: [
        // COMPLETED
        Expanded(
          child: _buildStatCard(
            label: "Completed",
            value: resultsList.length.toString(),
            icon: Icons.assignment_turned_in_rounded,
            color: AppColors.navy,
            surface: surface,
            border: border,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
        ),

        const SizedBox(width: 8),

        // PASSED
        Expanded(
          child: _buildStatCard(
            label: "Passed",
            value: passedCount.toString(),
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            surface: surface,
            border: border,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
        ),

        const SizedBox(width: 8),

        // AVERAGE
        Expanded(
          child: _buildStatCard(
            label: "Average",
            value: "${averageScore.toStringAsFixed(0)}%",
            icon: Icons.trending_up_rounded,
            color: AppColors.teal,
            surface: surface,
            border: border,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color surface,
    required Color border,
    required Color textColor,
    required Color secondaryText,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),

      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: border.withValues(alpha: 0.85)),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            padding: const EdgeInsets.all(5),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),

            child: Icon(icon, color: color, size: 15),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,

            child: Text(
              value,
              maxLines: 1,

              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 1),

          FittedBox(
            fit: BoxFit.scaleDown,

            child: Text(
              label,
              maxLines: 1,

              style: GoogleFonts.poppins(
                color: secondaryText,
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY HEADER
  // ============================================================

  Widget _buildSectionHeader(
    BuildContext context, {
    required Color textColor,
    required Color secondaryText,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Assessment History",

                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                "Your latest test performance",

                style: GoogleFonts.poppins(
                  color: secondaryText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.10),

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: AppColors.teal.withValues(alpha: 0.20)),
          ),

          child: Text(
            "${resultsList.length} tests",

            style: GoogleFonts.poppins(
              color: AppColors.teal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState({required Color surface}) {
    return Container(
      height: 180,

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),

      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.teal,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color textColor,
    required Color secondaryText,
  }) {
    final language = selectedTab == 0 ? "English" : "Hindi";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: border.withValues(alpha: 0.85)),
      ),

      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),

            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.assignment_rounded,
              color: AppColors.teal,
              size: 30,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            "No test results yet",

            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Your submitted $language assessments will appear here.",

            textAlign: TextAlign.center,

            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget _buildResultCard(
    BuildContext context,
    dynamic item, {
    required Color surface,
    required Color border,
    required Color textColor,
    required Color secondaryText,
  }) {
    final String stage = (item['stage'] ?? "stage1").toString().toUpperCase();

    final int score =
        num.tryParse(item['score']?.toString() ?? '0')?.toInt() ?? 0;

    final int total =
        num.tryParse(item['totalQuestions']?.toString() ?? '0')?.toInt() ?? 0;

    final double percentage = total > 0 ? (score / total) * 100 : 0.0;

    final bool isPassed = percentage >= 50.0;

    // ----------------------------------------------------------
    // DATE
    // ----------------------------------------------------------

    String dateFormatted = "Completed";

    if (item['createdAt'] != null) {
      try {
        final parsed = DateTime.parse(item['createdAt'].toString()).toLocal();

        dateFormatted = DateFormat('d MMM yyyy • hh:mm a').format(parsed);
      } catch (_) {}
    }

    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    final Color statusColor = isPassed ? AppColors.success : AppColors.warning;

    final String statusText = isPassed ? "PASSED" : "KEEP PRACTICING";

    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: border.withValues(alpha: 0.85)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        children: [
          // ====================================================
          // TOP
          // ====================================================
          Row(
            children: [
              // SCORE CIRCLE
              _buildScoreCircle(
                percentage: percentage,
                color: statusColor,
                textColor: textColor,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "$stage Evaluation",

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 14,

                              // FIXED
                              // w750 -> w700
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        _buildStatusBadge(text: statusText, color: statusColor),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: secondaryText,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            dateFormatted,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: GoogleFonts.poppins(
                              color: secondaryText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ====================================================
          // DIVIDER
          // ====================================================
          Container(height: 1, color: border.withValues(alpha: 0.55)),

          const SizedBox(height: 12),

          // ====================================================
          // RESULT INFORMATION
          // ====================================================
          Row(
            children: [
              Expanded(
                child: _buildResultInfo(
                  icon: Icons.checklist_rounded,
                  label: "Score",
                  value: "$score / $total",
                  color: AppColors.navy,
                  textColor: textColor,
                  secondaryText: secondaryText,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildResultInfo(
                  icon: Icons.percent_rounded,
                  label: "Percentage",
                  value: "${percentage.toStringAsFixed(0)}%",
                  color: AppColors.teal,
                  textColor: textColor,
                  secondaryText: secondaryText,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildResultInfo(
                  icon: isPassed
                      ? Icons.verified_rounded
                      : Icons.auto_stories_rounded,

                  label: "Result",

                  value: isPassed ? "Passed" : "Practice",

                  color: statusColor,

                  textColor: textColor,

                  secondaryText: secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCORE CIRCLE
  // ============================================================

  Widget _buildScoreCircle({
    required double percentage,
    required Color color,
    required Color textColor,
  }) {
    return SizedBox(
      width: 64,
      height: 64,

      child: Stack(
        alignment: Alignment.center,

        children: [
          SizedBox(
            width: 62,
            height: 62,

            child: CircularProgressIndicator(
              value: (percentage / 100).clamp(0, 1),

              strokeWidth: 5,

              backgroundColor: color.withValues(alpha: 0.10),

              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          Text(
            "${percentage.toStringAsFixed(0)}%",

            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),

      child: Text(
        text,

        style: GoogleFonts.poppins(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.15,
        ),
      ),
    );
  }

  // ============================================================
  // RESULT INFO
  // ============================================================

  Widget _buildResultInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),

        borderRadius: BorderRadius.circular(11),
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 16),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,

            child: Text(
              value,
              maxLines: 1,

              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 1),

          FittedBox(
            fit: BoxFit.scaleDown,

            child: Text(
              label,
              maxLines: 1,

              style: GoogleFonts.poppins(
                color: secondaryText,
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
