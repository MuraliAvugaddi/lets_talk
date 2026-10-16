import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final AuthController controller = Get.find<AuthController>();

  // 0 = English
  // 1 = Hindi
  int selectedCategory = 0;

  DateTime selectedMonth = DateTime.now();

  bool isLoading = false;

  List<dynamic> allRecords = [];

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  // ============================================================
  // FETCH ATTENDANCE
  // ============================================================

  Future<void> fetchAttendance() async {
    final userData = controller.userData;

    final userId = userData['id'] ?? userData['_id'];

    if (userId == null) return;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final token = (GetStorage().read('token') ?? '').toString();
      final response = await http.get(
        Uri.parse(
          "${ApiEndpoints.myAttendance}"
          "?userId=$userId",
        ),
        headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            allRecords = data['records'] ?? [];
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
      debugPrint("Attendance Error: $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MONTH & LANGUAGE FILTER
  // ============================================================

  List<dynamic> get monthlyFilteredRecords {
    final targetMonth = selectedMonth.month;
    final targetYear = selectedMonth.year;
    final String targetLanguage = selectedCategory == 0 ? "English" : "Hindi";

    return allRecords.where((item) {
      // Filter by Language safely (defaulting to English if not specified)
      final itemLang = (item['language'] ?? 'English').toString().trim();
      if (!itemLang.toLowerCase().contains(targetLanguage.toLowerCase())) {
        return false;
      }

      final dateStr = (item['date'] ?? '').toString();
      final parts = dateStr.split('-');

      if (parts.length == 3) {
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        return month == targetMonth && year == targetYear;
      }

      return false;
    }).toList();
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get totalCount {
    return monthlyFilteredRecords.length;
  }

  int get presentCount {
    return monthlyFilteredRecords
        .where(
          (record) => record['status']?.toString().toLowerCase() == 'present',
        )
        .length;
  }

  int get lateCount {
    return monthlyFilteredRecords.where((record) {
      final status = record['status']?.toString().toLowerCase();

      return status == 'late' || status == 'partial';
    }).length;
  }

  // 🎤 Classes where the trainer marked speaking practice
  int get practicedCount {
    return monthlyFilteredRecords
        .where((record) => record['practiced'] == true)
        .length;
  }

  int get absentCount {
    return monthlyFilteredRecords
        .where(
          (record) => record['status']?.toString().toLowerCase() == 'absent',
        )
        .length;
  }

  // ============================================================
  // MONTH CHANGE
  // ============================================================

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
        1,
      );
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final background = theme.scaffoldBackgroundColor;

    final surface = theme.colorScheme.surface;

    final textColor = theme.colorScheme.onSurface;

    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final monthTitle = DateFormat('MMMM yyyy').format(selectedMonth);

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
          "My Attendance",
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        centerTitle: false,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        top: false,

        child: RefreshIndicator(
          onRefresh: fetchAttendance,

          color: AppColors.teal,

          backgroundColor: surface,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // MONTH SELECTOR
                // ==================================================
                _buildMonthSelector(context, monthTitle),

                const SizedBox(height: 10),

                // ==================================================
                // ENGLISH / HINDI
                // SAME DESIGN AS TEST RESULTS
                // ==================================================
                _buildLanguageSelector(
                  context,
                  surface: surface,
                  textColor: textColor,
                  secondaryText: secondaryText,
                  isDark: isDark,
                ),

                const SizedBox(height: 10),

                // ==================================================
                // STATS
                // ==================================================
                _buildStatsRow(context),

                const SizedBox(height: 20),

                // ==================================================
                // HISTORY HEADER
                // ==================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Attendance History",

                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            "Your latest attendance records",

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.surface,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),

                      child: Text(
                        "${monthlyFilteredRecords.length} "
                        "${monthlyFilteredRecords.length == 1 ? 'class' : 'classes'}"
                        "${practicedCount > 0 ? ' • $practicedCount 🎤' : ''}",

                        style: GoogleFonts.poppins(
                          color: AppColors.teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ==================================================
                // LOADING
                // ==================================================
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 60, bottom: 60),

                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 26,
                            height: 26,

                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.teal,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Loading attendance...",

                            style: GoogleFonts.poppins(
                              color: secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                // ==================================================
                // EMPTY
                // ==================================================
                else if (monthlyFilteredRecords.isEmpty)
                  _buildEmptyState(context, monthTitle)
                // ==================================================
                // ATTENDANCE LIST
                // ==================================================
                else
                  Column(
                    children: monthlyFilteredRecords
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),

                            child: _buildAttendanceCard(context, item),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MONTH SELECTOR
  // ============================================================

  Widget _buildMonthSelector(BuildContext context, String monthTitle) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;

    final textColor = theme.colorScheme.onSurface;

    return Container(
      height: 54,

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.035),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // LEFT
          SizedBox(
            width: 52,

            child: IconButton(
              onPressed: () => _changeMonth(-1),

              icon: Icon(
                Icons.chevron_left_rounded,
                color: textColor,
                size: 25,
              ),
            ),
          ),

          // MONTH
          Expanded(
            child: Center(
              child: Text(
                monthTitle,

                textAlign: TextAlign.center,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // RIGHT
          SizedBox(
            width: 52,

            child: IconButton(
              onPressed: () => _changeMonth(1),

              icon: Icon(
                Icons.chevron_right_rounded,
                color: textColor,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LANGUAGE SELECTOR
  // SAME DESIGN AS TEST RESULTS
  // ============================================================

  Widget _buildLanguageSelector(
    BuildContext context, {
    required Color surface,
    required Color textColor,
    required Color secondaryText,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),

      child: Row(
        children: [
          // ==================================================
          // ENGLISH
          // ==================================================
          Expanded(
            child: _buildLanguageTab(
              context,

              index: 0,

              title: "English Class",

              icon: Icons.menu_book_rounded,

              textColor: textColor,

              secondaryText: secondaryText,
            ),
          ),

          const SizedBox(width: 4),

          // ==================================================
          // HINDI
          // ==================================================
          Expanded(
            child: _buildLanguageTab(
              context,

              index: 1,

              title: "Hindi Class",

              icon: Icons.translate_rounded,

              textColor: textColor,

              secondaryText: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LANGUAGE TAB
  // ============================================================

  Widget _buildLanguageTab(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
    required Color textColor,
    required Color secondaryText,
  }) {
    final bool isSelected = selectedCategory == index;

    return GestureDetector(
      onTap: () {
        if (selectedCategory == index) {
          return;
        }

        setState(() {
          selectedCategory = index;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),

        curve: Curves.easeOut,

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),

        decoration: BoxDecoration(
          // ================================================
          // SAME BLUE AS RESULTS SCREEN
          // ================================================
          color: isSelected ? AppColors.navy : Colors.transparent,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: isSelected ? AppColors.navy : Colors.transparent,
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.18),

                    blurRadius: 10,

                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              size: 16,

              color: isSelected ? Colors.white : secondaryText,
            ),

            const SizedBox(width: 7),

            Flexible(
              child: Text(
                title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : textColor,

                  fontSize: 11.5,

                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATS ROW
  // ============================================================

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,

            label: "Total",

            value: totalCount,

            icon: Icons.calendar_month_rounded,

            iconColor: AppColors.navy,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _buildStatCard(
            context,

            label: "Present",

            value: presentCount,

            icon: Icons.check_circle_rounded,

            iconColor: AppColors.success,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _buildStatCard(
            context,

            label: "Late",

            value: lateCount,

            icon: Icons.access_time_rounded,

            iconColor: AppColors.warning,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _buildStatCard(
            context,

            label: "Absent",

            value: absentCount,

            icon: Icons.cancel_rounded,

            iconColor: AppColors.error,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;

    final textColor = theme.colorScheme.onSurface;

    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Container(
      height: 82,

      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.025),

            blurRadius: 9,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            width: 29,
            height: 29,

            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.14 : 0.09),

              borderRadius: BorderRadius.circular(9),
            ),

            child: Icon(icon, color: iconColor, size: 15),
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,

                  child: Text(
                    value.toString(),

                    maxLines: 1,

                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,

                  child: Text(
                    label,

                    maxLines: 1,

                    style: GoogleFonts.poppins(
                      color: secondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget _buildAttendanceCard(BuildContext context, dynamic item) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;

    final textColor = theme.colorScheme.onSurface;

    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final String stage = item['stage']?.toString() ?? "General";

    final String date = item['date']?.toString() ?? "N/A";

    final String status = item['status']?.toString() ?? "Present";

    final int totalMins =
        int.tryParse(item['totalMinutesSpent']?.toString() ?? '0') ?? 0;

    final String batchTime = item['batchTime']?.toString() ?? "Live Stream";

    final bool practiced = item['practiced'] == true;

    // ==========================================================
    // STATUS COLOR
    // ==========================================================

    Color statusColor;

    switch (status.toLowerCase()) {
      case "absent":
        statusColor = AppColors.error;
        break;

      case "late":
      case "partial":
        statusColor = AppColors.warning;
        break;

      default:
        statusColor = AppColors.success;
    }

    // ==========================================================
    // STATUS ICON
    // ==========================================================

    IconData statusIcon;

    switch (status.toLowerCase()) {
      case "absent":
        statusIcon = Icons.close_rounded;
        break;

      case "late":
      case "partial":
        statusIcon = Icons.access_time_rounded;
        break;

      default:
        statusIcon = Icons.check_rounded;
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.035),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // ====================================================
          // STATUS ICON
          // ====================================================
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.14 : 0.09),

              borderRadius: BorderRadius.circular(13),
            ),

            child: Icon(statusIcon, color: statusColor, size: 23),
          ),

          const SizedBox(width: 11),

          // ====================================================
          // DETAILS
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  stage.toUpperCase(),

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                // DATE
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,

                      size: 11,

                      color: secondary,
                    ),

                    const SizedBox(width: 4),

                    Flexible(
                      child: Text(
                        date,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: GoogleFonts.poppins(
                          color: secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // BATCH TIME
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked_rounded,

                      size: 10,

                      color: secondary,
                    ),

                    const SizedBox(width: 4),

                    Flexible(
                      child: Text(
                        batchTime,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: GoogleFonts.poppins(
                          color: secondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // SPEAKING PRACTICE
                if (practiced) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.record_voice_over_rounded,
                          size: 11,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Speaking practice done",
                          style: GoogleFonts.poppins(
                            color: AppColors.teal,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ====================================================
          // STATUS + MINUTES
          // ====================================================
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 48),

                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.12 : 0.07),

                  borderRadius: BorderRadius.circular(8),

                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),

                child: Text(
                  status,

                  textAlign: TextAlign.center,

                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (totalMins > 0) ...[
                const SizedBox(height: 5),

                Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.navy, size: 11),

                    const SizedBox(width: 3),

                    Text(
                      "$totalMins min",

                      style: GoogleFonts.poppins(
                        color: isDark ? AppColors.darkText : AppColors.navy,

                        fontSize: 9.5,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(BuildContext context, String monthTitle) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final textColor = theme.colorScheme.onSurface;

    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(top: 10),

      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 20),

      decoration: BoxDecoration(
        color: theme.colorScheme.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.navy,
              size: 27,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "No attendance yet",

            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            "No attendance records found for\n$monthTitle.",

            textAlign: TextAlign.center,

            style: GoogleFonts.poppins(
              color: secondary,
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}