import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final AuthController controller = Get.find<AuthController>();

  int selectedCategory =
      0; // 0: English Class, 1: English Club, 2: Hindi Class, 3: Hindi Club
  DateTime selectedMonth = DateTime.now();
  bool isLoading = false;
  List<dynamic> allRecords = [];

  final String baseUrl = "http://192.168.1.4:5000/api";

  final Color backgroundColor = const Color(0xff0A0A0E);
  final Color cardColor = const Color(0xff14141E);
  final Color accentPurple = const Color(0xff7F56D9);
  final Color accentBlue = const Color(0xff158DFE);

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    final userData = controller.userData;
    final userId = userData['id'] ?? userData['_id'];
    if (userId == null) return;

    if (mounted) setState(() => isLoading = true);

    String lang = (selectedCategory == 2 || selectedCategory == 3)
        ? "Hindi"
        : "English";

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/my-attendance?userId=$userId&language=$lang"),
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
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<dynamic> get monthlyFilteredRecords {
    final targetMonth = selectedMonth.month;
    final targetYear = selectedMonth.year;

    return allRecords.where((item) {
      final dateStr = (item['date'] ?? '').toString();
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        return m == targetMonth && y == targetYear;
      }
      return false;
    }).toList();
  }

  int get presentCount =>
      monthlyFilteredRecords.where((r) => r['status'] == 'Present').length;
  int get partialCount => monthlyFilteredRecords
      .where((r) => r['status'] == 'Partial' || r['status'] == 'Late')
      .length;
  int get absentCount =>
      monthlyFilteredRecords.where((r) => r['status'] == 'Absent').length;

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String monthTitle = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "My Attendance Log",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchAttendance,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _changeMonth(-1),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: accentPurple,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      monthTitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Category Selector
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryPill(0, "English Class"),
                _buildCategoryPill(1, "English Club"),
                _buildCategoryPill(2, "Hindi Class"),
                _buildCategoryPill(3, "Hindi Club"),
              ],
            ),
          ),

          // Stats Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildStatPill(
                  "Total",
                  "${monthlyFilteredRecords.length}",
                  Colors.white70,
                  const Color(0xff1E1E2C),
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  "Present",
                  "$presentCount",
                  const Color(0xff12B76A),
                  const Color(0xff12B76A).withOpacity(0.15),
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  "Partial/Late",
                  "$partialCount",
                  const Color(0xffF79009),
                  const Color(0xffF79009).withOpacity(0.15),
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  "Absent",
                  "$absentCount",
                  const Color(0xffF04438),
                  const Color(0xffF04438).withOpacity(0.15),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Session Records List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: accentPurple))
                : monthlyFilteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No attendance records for $monthTitle.",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchAttendance,
                    color: accentPurple,
                    backgroundColor: cardColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: monthlyFilteredRecords.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = monthlyFilteredRecords[index];
                        return _buildAttendanceCard(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(int index, String title) {
    final bool isSelected = selectedCategory == index;
    final Color activeColor = (index == 0 || index == 1)
        ? accentPurple
        : accentBlue;

    return GestureDetector(
      onTap: () {
        setState(() => selectedCategory = index);
        fetchAttendance();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(
    String label,
    String value,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: textColor.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(dynamic item) {
    final String stage = item['stage'] ?? "General";
    final String date = item['date'] ?? "N/A";
    final String status = item['status'] ?? "Present";
    final int totalMins = item['totalMinutesSpent'] ?? 0;
    final String batchTime = item['batchTime'] ?? "N/A";

    Color statusColor = const Color(0xff12B76A);
    if (status == "Partial" || status == "Late") {
      statusColor = const Color(0xffF79009);
    }
    if (status == "Absent") {
      statusColor = const Color(0xffF04438);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status == "Present"
                  ? Icons.check_circle_rounded
                  : (status == "Absent"
                        ? Icons.cancel_rounded
                        : Icons.access_time_filled_rounded),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Date: $date • $batchTime",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (totalMins > 0) ...[
                const SizedBox(height: 4),
                Text(
                  "$totalMins mins",
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
