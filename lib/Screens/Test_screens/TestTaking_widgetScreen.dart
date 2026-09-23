import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/Screens/app_colors.dart';

class TestTakingScreen extends StatefulWidget {
  final String language; // "English" or "Hindi"
  final String stage; // "stage1", "stage2"...

  const TestTakingScreen({
    super.key,
    required this.language,
    required this.stage,
  });

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  bool isLoading = true;
  bool isTestActive = false;
  bool hasStarted = false;
  int durationMinutes = 25;

  bool isAlreadyTaken = false;
  int myScore = 0;
  int totalQs = 0;

  List<dynamic> questions = [];
  Map<String, int> userAnswers = {};

  int timeLeftSeconds = 25 * 60;
  Timer? _timer;

  final box = GetStorage();

  ThemeData get _theme => Theme.of(context);
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _bg => _isDark ? AppColors.darkBackground : AppColors.background;
  Color get _surface => _isDark ? AppColors.darkSurface : AppColors.surface;
  Color get _surface2 =>
      _isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft;
  Color get _text => _isDark ? AppColors.darkText : AppColors.text;
  Color get _secondary =>
      _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _border => _isDark ? AppColors.darkBorder : AppColors.border;
  Color get _primary => _isDark ? AppColors.teal : AppColors.navy;

  @override
  void initState() {
    super.initState();
    fetchTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchTest() async {
    final userData = box.read('user');
    String userId = userData != null
        ? (userData['id'] ?? userData['_id'] ?? "")
        : "";

    try {
      final response = await http.get(
        Uri.parse(
          "${ApiEndpoints.getTest}?language=${widget.language}&stage=${widget.stage}&userId=$userId",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['completed'] == true) {
          setState(() {
            isAlreadyTaken = true;
            myScore = data['score'];
            totalQs = data['total'];
            isLoading = false;
          });
        } else {
          setState(() {
            questions = data['questions'] ?? [];
            durationMinutes =
                int.tryParse((data['durationMinutes'] ?? 25).toString()) ?? 25;
            timeLeftSeconds = durationMinutes * 60;
            isTestActive = true;
            hasStarted = false;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isTestActive = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeftSeconds > 0) {
        setState(() => timeLeftSeconds--);
      } else {
        submitTest(forceSubmit: true);
      }
    });
  }

  Future<void> submitTest({bool forceSubmit = false}) async {
    if (!forceSubmit && userAnswers.length < questions.length) {
      Get.snackbar(
        "Incomplete Test",
        "Please answer all questions before submitting.",
        backgroundColor: _surface2,
        colorText: _text,
        borderColor: AppColors.yellow.withValues(alpha: 0.45),
        borderWidth: 1,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.yellow),
      );
      return;
    }

    final userData = box.read('user');
    if (userData == null) {
      Get.snackbar(
        "Error",
        "User not logged in.",
        backgroundColor: _surface2,
        colorText: _text,
      );
      return;
    }

    _timer?.cancel();

    List<Map<String, dynamic>> formattedAnswers = [];
    userAnswers.forEach((qId, index) {
      formattedAnswers.add({"questionId": qId, "selectedIndex": index});
    });

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.submitTest),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userData['id'] ?? userData['_id'],
          "userName": userData['name'] ?? "Unknown",
          "userPhone": userData['phone'] ?? "N/A",
          "userMode": userData['mode'] ?? "offline",
          "language": widget.language,
          "stage": widget.stage,
          "answers": formattedAnswers,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          isAlreadyTaken = true;
          myScore = result['score'];
          totalQs = result['total'];
          isTestActive = false;
        });

        _showSuccessDialog();
      } else {
        Get.snackbar("Error", "Submission error: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Submission Failed");
    }
  }

  Future<void> _confirmSubmit() async {
    final answered = userAnswers.length;
    final total = questions.length;

    if (answered < total) {
      await submitTest();
      return;
    }

    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Submit assessment?",
                      style: GoogleFonts.poppins(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "You have answered all $total questions. Once submitted, you cannot change your answers.",
                style: GoogleFonts.poppins(
                  color: _secondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _text,
                        side: BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        "Review",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        "Submit",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await submitTest(forceSubmit: false);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return "$minutes:${remaining.toString().padLeft(2, '0')}";
  }

  Color _timerColor() {
    if (timeLeftSeconds <= 60) return AppColors.error;
    if (timeLeftSeconds <= 5 * 60) return AppColors.warning;
    return AppColors.teal;
  }

  Widget _brandIcon({
    required IconData icon,
    required Color color,
    double size = 44,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }

  Widget _topTitle(String title, String subtitle) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: _text,
          tooltip: "Back",
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: _secondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _stageLabel() {
    final raw = widget.stage.trim();
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match != null) {
      return "Stage ${match.group(1)}";
    }
    if (raw.isEmpty) return "Assessment";
    return raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _durationLabel() {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) return "$hours ${hours == 1 ? 'Hour' : 'Hours'}";
      return "$hours h $minutes min";
    }
    return "$durationMinutes ${durationMinutes == 1 ? 'Minute' : 'Minutes'}";
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppColors.teal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: _secondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: _text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _startExamScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _text,
                    tooltip: "Back",
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      "Assessment",
                      style: GoogleFonts.poppins(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          color: AppColors.teal,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.language,
                          style: GoogleFonts.poppins(
                            color: _text,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: Column(
                  children: [
                    const SizedBox(height: 4),

                    // Hero icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navy.withValues(alpha: 0.16),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isDark
                                ? [AppColors.deepNavy, AppColors.navy]
                                : [AppColors.navy, AppColors.deepNavy],
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: AppColors.teal,
                          size: 38,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "${widget.language} ${_stageLabel()} Test",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _text,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      "Take your time, read each question carefully,\nand complete the assessment before the timer ends.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _secondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Test information card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(
                              alpha: _isDark ? 0.08 : 0.06,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            icon: Icons.timer_outlined,
                            label: "Duration",
                            value: _durationLabel(),
                            iconColor: AppColors.teal,
                          ),
                          Divider(height: 1, color: _border),
                          _infoRow(
                            icon: Icons.quiz_outlined,
                            label: "Questions",
                            value: "${questions.length} Questions",
                            iconColor: AppColors.blue,
                          ),
                          Divider(height: 1, color: _border),
                          _infoRow(
                            icon: Icons.star_outline_rounded,
                            label: "Total Marks",
                            value: "${questions.length} Marks",
                            iconColor: AppColors.yellow,
                          ),
                          Divider(height: 1, color: _border),
                          _infoRow(
                            icon: Icons.warning_amber_rounded,
                            label: "Important",
                            value: "Submit before time ends",
                            iconColor: AppColors.yellow,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick tips
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Once you start, the timer begins immediately. Make sure you have enough time to finish all questions.",
                              style: GoogleFonts.poppins(
                                color: _secondary,
                                fontSize: 10.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
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

            // Start button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      hasStarted = true;
                    });
                    startTimer();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 21),
                  label: Text(
                    "Start Exam",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultScreen(BuildContext context) {
    final percentage = totalQs > 0 ? (myScore / totalQs) * 100 : 0.0;
    final isPassed = percentage >= 50;
    final statusColor = isPassed ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: _topTitle(
          "Assessment Result",
          "${widget.language} • ${widget.stage.toUpperCase()}",
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDark
                        ? [AppColors.deepNavy, AppColors.navy]
                        : [AppColors.navy, AppColors.deepNavy],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(
                        alpha: _isDark ? 0.20 : 0.14,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isPassed
                            ? Icons.emoji_events_rounded
                            : Icons.refresh_rounded,
                        color: isPassed ? AppColors.yellow : Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isPassed ? "Assessment Passed!" : "Assessment Completed",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isPassed
                          ? "Great work! Your result has been recorded."
                          : "Your result has been recorded. Keep practicing and try again when available.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Text(
                      "YOUR SCORE",
                      style: GoogleFonts.poppins(
                        color: _secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$myScore / $totalQs",
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${percentage.toStringAsFixed(0)}% Accuracy",
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    _brandIcon(
                      icon: Icons.language_rounded,
                      color: AppColors.teal,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.language,
                            style: GoogleFonts.poppins(
                              color: _text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.stage.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: _secondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isPassed
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 19),
                  label: Text(
                    "Back to Assessments",
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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

  Widget _unavailableScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: _topTitle(
          "Assessment",
          "${widget.language} • ${widget.stage.toUpperCase()}",
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _brandIcon(
                    icon: Icons.schedule_rounded,
                    color: AppColors.yellow,
                    size: 76,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Test Not Available",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: _text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    "There is currently no active test published for ${widget.language} (${widget.stage.toUpperCase()}).",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: _secondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: BorderSide(
                          color: _primary.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Back to Assessments",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionCard(int index) {
    final q = questions[index];
    final String qId = (q['_id'] ?? '').toString();
    final options = q['options'] is List ? q['options'] as List : <dynamic>[];
    final int? selectedOption = userAnswers[qId];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedOption != null
              ? AppColors.yellow.withValues(alpha: 0.50)
              : _border,
          width: selectedOption != null ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: _isDark ? 0.08 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Q${index + 1}",
                  style: GoogleFonts.poppins(
                    color: _isDark ? AppColors.teal : AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (q['questionText'] ?? '').toString(),
                  style: GoogleFonts.poppins(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(options.length, (optIndex) {
            final optionText = options[optIndex].toString();
            final isSelected = selectedOption == optIndex;
            final letter = String.fromCharCode(65 + optIndex);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      userAnswers[qId] = optIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (_isDark
                                ? AppColors.navy.withValues(alpha: 0.28)
                                : AppColors.navy.withValues(alpha: 0.08))
                          : _surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.yellow : _border,
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.yellow
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? AppColors.yellow : _border,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.deepNavy,
                                  size: 18,
                                )
                              : Text(
                                  letter,
                                  style: GoogleFonts.poppins(
                                    color: _secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            optionText,
                            style: GoogleFonts.poppins(
                              color: isSelected ? _text : _secondary,
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.teal,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _liveTestScreen(BuildContext context) {
    final progress = questions.isNotEmpty
        ? (userAnswers.length / questions.length).clamp(0.0, 1.0)
        : 0.0;
    final answered = userAnswers.length;
    final remaining = questions.length - answered;
    final timerColor = _timerColor();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: timerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: timerColor.withValues(alpha: 0.28)),
              ),
              child: Icon(Icons.timer_rounded, color: timerColor, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.language} • ${widget.stage.toUpperCase()}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "$answered of ${questions.length} answered",
                    style: GoogleFonts.poppins(
                      color: _secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(timeLeftSeconds),
                  style: GoogleFonts.poppins(
                    color: timerColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "remaining",
                  style: GoogleFonts.poppins(color: _secondary, fontSize: 8.5),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: _surface2,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            minHeight: 4,
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: _surface,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    remaining == 0
                        ? "All questions answered"
                        : "$remaining question${remaining == 1 ? '' : 's'} remaining",
                    style: GoogleFonts.poppins(
                      color: _secondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: GoogleFonts.poppins(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
              physics: const BouncingScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) => _questionCard(index),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: _surface,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  answered == questions.length
                      ? "Ready to submit"
                      : "Answer every question",
                  style: GoogleFonts.poppins(
                    color: _secondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _confirmSubmit,
                  icon: Icon(
                    answered == questions.length
                        ? Icons.send_rounded
                        : Icons.arrow_upward_rounded,
                    size: 17,
                  ),
                  label: Text(
                    "Submit",
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: answered == questions.length
                        ? _primary
                        : _surface2,
                    foregroundColor: answered == questions.length
                        ? Colors.white
                        : _secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(17),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Loading assessment...",
                  style: GoogleFonts.poppins(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Please wait",
                  style: GoogleFonts.poppins(color: _secondary, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isAlreadyTaken) {
      return _resultScreen(context);
    }

    if (!isTestActive) {
      return _unavailableScreen(context);
    }

    if (!hasStarted) {
      return _startExamScreen(context);
    }

    return _liveTestScreen(context);
  }

  void _showSuccessDialog() {
    final double percentage = totalQs > 0 ? (myScore / totalQs) * 100 : 0.0;
    final bool isPassed = percentage >= 50;
    final statusColor = isPassed ? AppColors.success : AppColors.error;

    Get.dialog(
      Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                  color: isPassed ? AppColors.yellow : statusColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isPassed ? "Assessment Passed!" : "Exam Finished!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Your score has been updated in your profile.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _secondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface2,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Text(
                      "FINAL SCORE",
                      style: GoogleFonts.poppins(
                        color: _secondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      child: Text(
                        "$myScore / $totalQs",
                        style: GoogleFonts.poppins(
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      "${percentage.toStringAsFixed(0)}% Accuracy",
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Return to Dashboard",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
