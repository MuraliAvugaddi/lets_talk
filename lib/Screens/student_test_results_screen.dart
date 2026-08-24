import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
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

  // --- BRAND COLORS ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color backgroundColor = const Color(0xff0A0A0E);
  final Color cardColor = const Color(0xff14141E);

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    final userData = controller.userData;
    final userId = userData['id'] ?? userData['_id'];
    if (userId == null) return;

    if (mounted) setState(() => isLoading = true);

    String lang = selectedTab == 0 ? "English" : "Hindi";

    try {
      final response = await http.get(
        Uri.parse("${ApiEndpoints.myResults}?userId=$userId&language=$lang"),
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
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Summary Metrics
  int get passedCount => resultsList.where((r) {
    final score = r['score'] ?? 0;
    final total = r['totalQuestions'] ?? 1;
    return (score / total) >= 0.5;
  }).length;

  double get averageScore {
    if (resultsList.isEmpty) return 0.0;
    int totalScore = 0;
    int totalQuestions = 0;
    for (var r in resultsList) {
      totalScore += (r['score'] as num? ?? 0).toInt();
      totalQuestions += (r['totalQuestions'] as num? ?? 1).toInt();
    }
    return totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
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
          "Test Results & Performance",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchResults,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- 1. LANGUAGE SELECTOR TABS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    0,
                    "English Assessments",
                    deepOceanBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTabButton(1, "Hindi Assessments", tealMist),
                ),
              ],
            ),
          ),

          // --- 2. SUMMARY STATS BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatPill(
                  "Completed",
                  "${resultsList.length}",
                  Colors.white70,
                  const Color(0xff1E1E2C),
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  "Passed (≥50%)",
                  "$passedCount",
                  goldenYellow,
                  goldenYellow.withOpacity(0.15),
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  "Avg Score",
                  "${averageScore.toStringAsFixed(0)}%",
                  tealMist,
                  tealMist.withOpacity(0.15),
                ),
              ],
            ),
          ),

          // --- 3. RESULTS LIST ---
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: goldenYellow))
                : resultsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No submitted test results yet for ${selectedTab == 0 ? 'English' : 'Hindi'}.",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchResults,
                    color: goldenYellow,
                    backgroundColor: cardColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: resultsList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = resultsList[index];
                        return _buildResultCard(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, Color color) {
    final bool isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = index);
        fetchResults();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xff0A0A0E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? goldenYellow : tealMist.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.white60,
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
          border: Border.all(color: textColor.withOpacity(0.25)),
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

  Widget _buildResultCard(dynamic item) {
    final String stage = (item['stage'] ?? "stage1").toString().toUpperCase();
    final int score = item['score'] ?? 0;
    final int total = item['totalQuestions'] ?? 0;
    final double percentage = total > 0 ? (score / total) * 100 : 0.0;
    final bool isPassed = percentage >= 50.0;

    String dateFormatted = "Completed";
    if (item['createdAt'] != null) {
      try {
        final parsed = DateTime.parse(item['createdAt']).toLocal();
        dateFormatted = DateFormat('d MMM yyyy • hh:mm a').format(parsed);
      } catch (_) {}
    }

    final Color statusColor = isPassed ? goldenYellow : const Color(0xffF04438);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tealMist.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Circular Score Percentage
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                "${percentage.toStringAsFixed(0)}%",
                style: GoogleFonts.poppins(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$stage Evaluation",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormatted,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Marks and Status Tag
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$score / $total",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  isPassed ? "PASSED" : "NEEDS PRACTICE",
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
