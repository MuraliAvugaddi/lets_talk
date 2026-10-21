import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:http/http.dart' as http;

import 'package:get_storage/get_storage.dart';

import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

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

  // Keeps the submitted test locally so the student can review it again

  // even when the result is opened later.

  List<dynamic> reviewQuestions = [];

  Map<String, int> reviewAnswers = {};

  Map<String, int> reviewCorrectAnswers = {};

  bool reviewDataAvailable = false;

  int timeLeftSeconds = 25 * 60;

  Timer? _timer;

  // Prevents multiple exit confirmation dialogs from being opened at once.
  bool _isExitDialogShowing = false;

  bool _starting = false; // "Start Exam" pressed, waiting for the server clock
  bool _submitting = false; // never submit twice (timer end + button at the same time)
  DateTime? _endsAt; // exam end time from the server → timer can't be cheated by pausing the app

  final box = GetStorage();

  // Login token on every request (server checks who is taking / submitting the test)
  Map<String, String> _headers({bool json = false}) {
    final token = (box.read('token') ?? '').toString();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

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

    // ⚡ Admin publishes / pauses / deletes this test → this screen updates by itself
    try {
      Get.find<AuthController>().socket?.on('test_updated', _onTestUpdated);
    } catch (_) {}

  }

  @override

  void dispose() {

    _timer?.cancel();

    try {
      Get.find<AuthController>().socket?.off('test_updated', _onTestUpdated);
    } catch (_) {}

    super.dispose();

  }

  void _onTestUpdated(dynamic data) {
    if (!mounted || data is! Map) return;
    final sameTest = (data['language'] ?? '').toString() == widget.language &&
        (data['stage'] ?? '').toString().replaceAll(' ', '').toLowerCase() == widget.stage.toLowerCase();
    if (!sameTest) return;
    // Never interrupt a student who is in the middle of answering
    if (hasStarted && isTestActive && !isAlreadyTaken) return;
    setState(() => isLoading = true);
    fetchTest();
    if (data['action'] == 'published') {
      Get.snackbar(
        "New test available",
        "${widget.language} ${_stageLabel()} test was just published.",
        backgroundColor: AppColors.teal,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  /// Start pressed → the SERVER starts the clock (pressing Start again never resets it)
  Future<void> _beginTest() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final res = await http
          .post(
            Uri.parse("${ApiEndpoints.baseUrl}/test/user/start-test"),
            headers: _headers(json: true),
            body: jsonEncode({
              "userId": (box.read('user')?['id'] ?? box.read('user')?['_id'] ?? '').toString(),
              "language": widget.language,
              "stage": widget.stage,
            }),
          )
          .timeout(const Duration(seconds: 20));
      int secondsLeft = durationMinutes * 60;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        secondsLeft = int.tryParse('${data['secondsLeft'] ?? secondsLeft}') ?? secondsLeft;
      } else if (res.statusCode == 404) {
        // admin removed / paused it a moment ago
        if (mounted) setState(() => isLoading = true);
        await fetchTest();
        return;
      }
      _runClock(secondsLeft);
    } catch (_) {
      // offline: still start with the full time; the server checks again on submit
      _runClock(durationMinutes * 60);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _runClock(int secondsLeft) {
    if (!mounted) return;
    if (secondsLeft <= 0) {
      // time already over (started earlier, came back late) → close the test now
      setState(() => hasStarted = true);
      submitTest(forceSubmit: true);
      return;
    }
    setState(() {
      hasStarted = true;
      timeLeftSeconds = secondsLeft;
      _endsAt = DateTime.now().add(Duration(seconds: secondsLeft));
    });
    startTimer();
  }


  String _reviewKey() {

    return "assessment_review_${widget.language}_${widget.stage}";

  }

  Future<void> _saveReviewData({

    required List<dynamic> testQuestions,

    required Map<String, int> answers,

    Map<String, int>? correctAnswers,

  }) async {

    final payload = <String, dynamic>{

      "questions": testQuestions,

      "answers": answers.map((key, value) => MapEntry(key, value)),

      "correctAnswers": (correctAnswers ?? {}).map(

        (key, value) => MapEntry(key, value),

      ),

    };

    await box.write(_reviewKey(), payload);

  }

  void _loadLocalReviewData() {

    final raw = box.read(_reviewKey());

    if (raw is! Map) {

      return;

    }

    final savedQuestions = raw["questions"];

    final savedAnswers = raw["answers"];

    final savedCorrect = raw["correctAnswers"];

    if (savedQuestions is List && savedAnswers is Map) {

      reviewQuestions = List<dynamic>.from(savedQuestions);

      reviewAnswers = savedAnswers.map(

        (key, value) => MapEntry(

          key.toString(),

          int.tryParse(value.toString()) ?? 0,

        ),

      );

      if (savedCorrect is Map) {

        reviewCorrectAnswers = savedCorrect.map(

          (key, value) => MapEntry(

            key.toString(),

            int.tryParse(value.toString()) ?? 0,

          ),

        );

      }

      reviewDataAvailable = reviewQuestions.isNotEmpty;

    }

  }

  Map<String, int> _extractCorrectAnswers(dynamic source) {

    final result = <String, int>{};

    if (source is! List) {

      return result;

    }

    for (final item in source) {

      if (item is! Map) continue;

      final id = (item["_id"] ??

              item["questionId"] ??

              item["id"] ??

              "")

          .toString();

      if (id.isEmpty) continue;

      final raw = item["correctIndex"] ??

          item["correctAnswerIndex"] ??

          item["correctOptionIndex"] ??

          item["correctAnswer"];

      final index = int.tryParse(raw?.toString() ?? "");

      if (index != null) {

        result[id] = index;

      }

    }

    return result;

  }

  Map<String, int> _extractAnswerMap(dynamic source) {

    final result = <String, int>{};

    if (source is! List) {

      return result;

    }

    for (final item in source) {

      if (item is! Map) continue;

      final id = (item["questionId"] ??

              item["_id"] ??

              item["id"] ??

              "")

          .toString();

      if (id.isEmpty) continue;

      final raw = item["selectedIndex"] ??

          item["selectedOption"] ??

          item["answerIndex"] ??

          item["selectedAnswer"];

      final index = int.tryParse(raw?.toString() ?? "");

      if (index != null) {

        result[id] = index;

      }

    }

    return result;

  }

  Future<void> _prepareReviewData({

    dynamic result,

    List<dynamic>? fallbackQuestions,

    Map<String, int>? fallbackAnswers,

  }) async {

    final resultAnswers = result is Map

        ? (result["answers"] ?? result["userAnswers"] ?? result["submittedAnswers"])

        : null;

    final resultQuestions = result is Map

        ? (result["questions"] ?? result["reviewQuestions"])

        : null;

    final resultCorrect = result is Map

        ? (result["correctAnswers"] ?? result["answerKey"] ?? result["review"])

        : null;

    final savedAnswers = _extractAnswerMap(resultAnswers);

    final questionsForReview =

        resultQuestions is List && resultQuestions.isNotEmpty

            ? List<dynamic>.from(resultQuestions)

            : List<dynamic>.from(fallbackQuestions ?? []);

    // The API may return the answer key separately, or the question objects

    // themselves may contain the correct option index.

    final savedCorrect = <String, int>{};

    if (questionsForReview.isNotEmpty) {

      savedCorrect.addAll(_extractCorrectAnswers(questionsForReview));

    }

    if (resultCorrect is List) {

      savedCorrect.addAll(_extractCorrectAnswers(resultCorrect));

    }

    if (resultCorrect is Map) {

      resultCorrect.forEach((key, value) {

        final index = int.tryParse(value.toString());

        if (index != null) {

          savedCorrect[key.toString()] = index;

        }

      });

    }

    final answersForReview = savedAnswers.isNotEmpty

        ? savedAnswers

        : Map<String, int>.from(fallbackAnswers ?? {});

    if (questionsForReview.isEmpty || answersForReview.isEmpty) {

      _loadLocalReviewData();

      return;

    }

    reviewQuestions = questionsForReview;

    reviewAnswers = answersForReview;

    reviewCorrectAnswers = savedCorrect;

    reviewDataAvailable = reviewQuestions.isNotEmpty;

    await _saveReviewData(

      testQuestions: reviewQuestions,

      answers: reviewAnswers,

      correctAnswers: reviewCorrectAnswers,

    );

  }

  bool _isReviewCorrect(String qId, int selectedIndex, Map question) {

    if (reviewCorrectAnswers.containsKey(qId)) {

      return reviewCorrectAnswers[qId] == selectedIndex;

    }

    final rawCorrect = question["correctIndex"] ??

        question["correctAnswerIndex"] ??

        question["correctOptionIndex"];

    final correct = int.tryParse(rawCorrect?.toString() ?? "");

    if (correct != null) {

      return correct == selectedIndex;

    }

    return false;

  }

  bool _hasCorrectAnswer(String qId, Map question) {

    if (reviewCorrectAnswers.containsKey(qId)) return true;

    return question["correctIndex"] != null ||

        question["correctAnswerIndex"] != null ||

        question["correctOptionIndex"] != null;

  }

  String _optionText(Map question, int index) {

    final options = question["options"];

    if (options is List && index >= 0 && index < options.length) {

      return options[index].toString();

    }

    return "Option ${String.fromCharCode(65 + index)}";

  }

  Future<void> _openReviewAnswers() async {

    if (!reviewDataAvailable) {

      _loadLocalReviewData();

    }

    if (!reviewDataAvailable) {

      Get.snackbar(

        "Review unavailable",

        "The answer details are not available for this assessment.",

        backgroundColor: _surface2,

        colorText: _text,

        margin: const EdgeInsets.all(16),

        borderRadius: 14,

      );

      return;

    }

    Get.to(

      () => _ReviewAnswersScreen(

        language: widget.language,

        stage: _stageLabel(),

        questions: reviewQuestions,

        answers: reviewAnswers,

        correctAnswers: reviewCorrectAnswers,

        isDark: _isDark,

      ),

    );

  }

  Future<void> fetchTest() async {

    final userData = box.read('user');

    String userId = userData != null

        ? (userData['id'] ?? userData['_id'] ?? "")

        : "";

    try {

      final url = "${ApiEndpoints.baseUrl}/test/user/get-test?language=${widget.language}&stage=${widget.stage}&userId=$userId";

      debugPrint("🔍 Fetching test from: $url");

      final response = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data['completed'] == true) {

          // Server sends the questions, the student's answers and the answer key →
          // "Review answers" works on any phone, even after reinstalling the app.
          await _prepareReviewData(result: data);

          if (mounted) {

            setState(() {

              isAlreadyTaken = true;

              myScore = int.tryParse('${data['score'] ?? 0}') ?? 0;

              totalQs = int.tryParse('${data['total'] ?? 0}') ?? 0;

              isLoading = false;

            });

          }

        } else {

          if (mounted) {

            setState(() {

              questions = data['questions'] ?? [];

              durationMinutes =

                  int.tryParse((data['durationMinutes'] ?? 25).toString()) ?? 25;

              timeLeftSeconds = durationMinutes * 60;

              isTestActive = questions.isNotEmpty;

              hasStarted = false;

              isLoading = false;

            });

            // Started before (app closed / phone restarted)? → continue with the time LEFT.
            final left = data['secondsLeft'];
            if (data['started'] == true && left != null && questions.isNotEmpty) {
              _runClock(int.tryParse(left.toString()) ?? 0);
              if ((int.tryParse(left.toString()) ?? 0) > 0) {
                Get.snackbar(
                  "Test resumed",
                  "Your timer kept running — ${_formatTime(int.tryParse(left.toString()) ?? 0)} left.",
                  backgroundColor: AppColors.warning,
                  colorText: Colors.black,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(12),
                );
              }
            }

          }

        }

      } else {

        if (mounted) {

          setState(() {

            isTestActive = false;

            isLoading = false;

          });

        }

      }

    } catch (e) {

      debugPrint("❌ Fetch Test Error: $e");

      if (mounted) setState(() => isLoading = false);

    }

  }

  void startTimer() {

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {

      final end = _endsAt;
      final left = end == null ? timeLeftSeconds - 1 : end.difference(DateTime.now()).inSeconds;

      if (left > 0) {

        if (mounted) setState(() => timeLeftSeconds = left);

      } else {

        timer.cancel();
        if (mounted) setState(() => timeLeftSeconds = 0);
        // ⏰ Time is over → submit automatically with whatever is answered
        Get.snackbar(
          "Time is up",
          "Your answers were submitted automatically.",
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
        );
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

    if (_submitting) return;
    _submitting = true;

    _timer?.cancel();

    List<Map<String, dynamic>> formattedAnswers = [];

    userAnswers.forEach((qId, index) {

      formattedAnswers.add({"questionId": qId, "selectedIndex": index});

    });

    try {

      final response = await http.post(

        Uri.parse(ApiEndpoints.submitTest),

        headers: _headers(json: true),

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

        await _prepareReviewData(

          result: result,

          fallbackQuestions: questions,

          fallbackAnswers: userAnswers,

        );

        if (mounted) {

          setState(() {

            isAlreadyTaken = true;

            myScore = result['score'] ?? 0;

            totalQs = result['total'] ?? questions.length;

            isTestActive = false;

          });

        }

        _showSuccessDialog();

      } else {

        Get.snackbar("Error", "Submission error: ${response.statusCode}");

      }

    } catch (e) {

      Get.snackbar("Error", "Submission Failed");

    } finally {

      _submitting = false;

    }

  }

  /// Shows a confirmation before the student can leave an active assessment.
  ///
  /// This is used by both the visible back button and the Android/iOS system
  /// back gesture/button. Leaving an active test without submitting means the
  /// current answers are not submitted and the active timer is stopped.
  Future<void> _handleExamExitAttempt() async {
    if (!mounted || !hasStarted || !isTestActive || isAlreadyTaken) {
      return;
    }

    if (_isExitDialogShowing) return;
    _isExitDialogShowing = true;

    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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
                      color: AppColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Leave the assessment?",
                      style: GoogleFonts.poppins(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "If you leave now, your answers are lost but the TIMER KEEPS RUNNING. When the time ends, the test closes automatically.",
                style: GoogleFonts.poppins(
                  color: _secondary,
                  fontSize: 12.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You can stay here and continue answering the questions.",
                        style: GoogleFonts.poppins(
                          color: _text,
                          fontSize: 10.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                        "Stay",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        "Leave",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    _isExitDialogShowing = false;

    if (confirmed == true && mounted && hasStarted && isTestActive) {
      _timer?.cancel();
      hasStarted = false;
      isTestActive = false;
      userAnswers.clear();
      Get.back();
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

                  ],

                ),

              ),

            ),

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

                  onPressed: _starting ? null : _beginTest,

                  icon: _starting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow_rounded, size: 21),

                  label: Text(

                    _starting ? "Starting…" : "Start Exam • ${_durationLabel()}",

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

    final incorrect = (totalQs - myScore).clamp(0, totalQs);

    return Scaffold(

      backgroundColor: _bg,

      appBar: AppBar(

        backgroundColor: _bg,

        elevation: 0,

        automaticallyImplyLeading: false,

        toolbarHeight: 62,

        titleSpacing: 8,

        title: _topTitle(

          "Assessment Result",

          "${widget.language} • ${_stageLabel()}",

        ),

      ),

      body: SafeArea(

        child: LayoutBuilder(

          builder: (context, constraints) {

            final h = constraints.maxHeight;

            final compact = h < 700;

            return Padding(

              padding: EdgeInsets.fromLTRB(

                14,

                compact ? 2 : 6,

                14,

                6,

              ),

              child: Column(

                children: [

                  // Result hero

                  Expanded(

                    flex: compact ? 42 : 45,

                    child: Container(

                      width: double.infinity,

                      padding: EdgeInsets.symmetric(

                        horizontal: 16,

                        vertical: compact ? 9 : 12,

                      ),

                      decoration: BoxDecoration(

                        gradient: LinearGradient(

                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,

                          colors: _isDark

                              ? [AppColors.deepNavy, AppColors.navy]

                              : [AppColors.navy, AppColors.deepNavy],

                        ),

                        borderRadius: BorderRadius.circular(27),

                      ),

                      child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Container(

                            width: compact ? 48 : 54,

                            height: compact ? 48 : 54,

                            decoration: BoxDecoration(

                              color: statusColor.withValues(alpha: 0.13),

                              shape: BoxShape.circle,

                              border: Border.all(

                                color: statusColor.withValues(alpha: 0.38),

                                width: 1.5,

                              ),

                            ),

                            child: Icon(

                              isPassed

                                  ? Icons.emoji_events_rounded

                                  : Icons.menu_book_rounded,

                              color: isPassed

                                  ? AppColors.yellow

                                  : Colors.white,

                              size: compact ? 25 : 28,

                            ),

                          ),

                          SizedBox(height: compact ? 5 : 7),

                          Text(

                            isPassed

                                ? "Assessment Passed!"

                                : "Assessment Completed",

                            textAlign: TextAlign.center,

                            style: GoogleFonts.poppins(

                              color: Colors.white,

                              fontSize: compact ? 16 : 18,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                          const SizedBox(height: 2),

                          Text(

                            isPassed

                                ? "Excellent work! You completed this assessment."

                                : "Your assessment has been completed.",

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            textAlign: TextAlign.center,

                            style: GoogleFonts.poppins(

                              color: Colors.white.withValues(alpha: 0.60),

                              fontSize: compact ? 8 : 8.5,

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                          SizedBox(height: compact ? 5 : 8),

                          Expanded(

                            child: AspectRatio(

                              aspectRatio: 1,

                              child: Stack(

                                alignment: Alignment.center,

                                children: [

                                  SizedBox.expand(

                                    child: CircularProgressIndicator(

                                      value: (percentage / 100).clamp(0.0, 1.0),

                                      strokeWidth: compact ? 8 : 9,

                                      backgroundColor:

                                          Colors.white.withValues(alpha: 0.10),

                                      valueColor:

                                          AlwaysStoppedAnimation<Color>(

                                        isPassed

                                            ? AppColors.yellow

                                            : AppColors.error,

                                      ),

                                    ),

                                  ),

                                  Container(

                                    width: double.infinity,

                                    height: double.infinity,

                                    margin: const EdgeInsets.all(13),

                                    decoration: BoxDecoration(

                                      shape: BoxShape.circle,

                                      color:

                                          Colors.white.withValues(alpha: 0.045),

                                    ),

                                    child: Column(

                                      mainAxisAlignment:

                                          MainAxisAlignment.center,

                                      children: [

                                        FittedBox(

                                          child: Text(

                                            "${percentage.toStringAsFixed(0)}%",

                                            style: GoogleFonts.poppins(

                                              color: Colors.white,

                                              fontSize: compact ? 27 : 31,

                                              fontWeight: FontWeight.w800,

                                            ),

                                          ),

                                        ),

                                        Text(

                                          "YOUR SCORE",

                                          style: GoogleFonts.poppins(

                                            color: Colors.white

                                                .withValues(alpha: 0.55),

                                            fontSize: 7,

                                            letterSpacing: 1,

                                            fontWeight: FontWeight.w700,

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),

                                ],

                              ),

                            ),

                          ),

                          SizedBox(height: compact ? 4 : 6),

                          Text(

                            "$myScore / $totalQs",

                            style: GoogleFonts.poppins(

                              color: Colors.white.withValues(alpha: 0.85),

                              fontSize: compact ? 11 : 12,

                              fontWeight: FontWeight.w700,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                  const SizedBox(height: 7),

                  // Small score cards

                  Expanded(

                    flex: compact ? 26 : 27,

                    child: Container(

                      width: double.infinity,

                      padding: EdgeInsets.fromLTRB(

                        compact ? 11 : 13,

                        compact ? 8 : 10,

                        compact ? 11 : 13,

                        compact ? 8 : 10,

                      ),

                      decoration: BoxDecoration(

                        color: _surface,

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: _border),

                      ),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            "Score Summary",

                            style: GoogleFonts.poppins(

                              color: _text,

                              fontSize: compact ? 13 : 14,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                          Text(

                            "Your performance in this assessment.",

                            style: GoogleFonts.poppins(

                              color: _secondary,

                              fontSize: compact ? 8 : 8.5,

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                          const SizedBox(height: 6),

                          Expanded(

                            child: Row(

                              children: [

                                Expanded(

                                  child: _resultStatCompact(

                                    icon: Icons.quiz_outlined,

                                    value: "$totalQs",

                                    label: "Questions",

                                    color: AppColors.blue,

                                  ),

                                ),

                                const SizedBox(width: 6),

                                Expanded(

                                  child: _resultStatCompact(

                                    icon: Icons.check_circle_outline_rounded,

                                    value: "$myScore",

                                    label: "Correct",

                                    color: AppColors.success,

                                  ),

                                ),

                                const SizedBox(width: 6),

                                Expanded(

                                  child: _resultStatCompact(

                                    icon: Icons.cancel_outlined,

                                    value: "$incorrect",

                                    label: "Incorrect",

                                    color: AppColors.error,

                                  ),

                                ),

                              ],

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                  const SizedBox(height: 7),

                  // Review button

                  SizedBox(

                    width: double.infinity,

                    height: compact ? 43 : 47,

                    child: OutlinedButton.icon(

                      onPressed: _openReviewAnswers,

                      icon: Icon(

                        Icons.fact_check_outlined,

                        size: compact ? 17 : 18,

                      ),

                      label: Text(

                        "Review Answers",

                        style: GoogleFonts.poppins(

                          fontSize: compact ? 11.5 : 12.5,

                          fontWeight: FontWeight.w800,

                        ),

                      ),

                      style: OutlinedButton.styleFrom(

                        foregroundColor: _primary,

                        side: BorderSide(

                          color: _primary.withValues(alpha: 0.45),

                        ),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(14),

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 7),

                  // Positive feedback

                  Container(

                    width: double.infinity,

                    padding: EdgeInsets.symmetric(

                      horizontal: compact ? 10 : 12,

                      vertical: compact ? 6 : 8,

                    ),

                    decoration: BoxDecoration(

                      color: statusColor.withValues(alpha: 0.075),

                      borderRadius: BorderRadius.circular(17),

                      border: Border.all(

                        color: statusColor.withValues(alpha: 0.18),

                      ),

                    ),

                    child: Row(

                      children: [

                        Container(

                          width: compact ? 32 : 35,

                          height: compact ? 32 : 35,

                          decoration: BoxDecoration(

                            color: statusColor.withValues(alpha: 0.10),

                            borderRadius: BorderRadius.circular(10),

                          ),

                          child: Icon(

                            isPassed

                                ? Icons.auto_awesome_rounded

                                : Icons.menu_book_rounded,

                            color: statusColor,

                            size: compact ? 16 : 18,

                          ),

                        ),

                        const SizedBox(width: 8),

                        Expanded(

                          child: Text(

                            isPassed

                                ? "Keep up the good work!"

                                : "Keep practicing!",

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: GoogleFonts.poppins(

                              color: _text,

                              fontSize: compact ? 10 : 11,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 7),

                  SizedBox(

                    width: double.infinity,

                    height: compact ? 44 : 48,

                    child: ElevatedButton.icon(

                      onPressed: () => Get.back(),

                      icon: const Icon(Icons.arrow_back_rounded, size: 18),

                      label: Text(

                        "Back to Assessments",

                        style: GoogleFonts.poppins(

                          fontSize: compact ? 11.5 : 12.5,

                          fontWeight: FontWeight.w800,

                        ),

                      ),

                      style: ElevatedButton.styleFrom(

                        backgroundColor: _primary,

                        foregroundColor: Colors.white,

                        elevation: 0,

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(14),

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 2),

                  SizedBox(

                    height: 13,

                    child: Text(

                      "${widget.language} • ${_stageLabel()}",

                      textAlign: TextAlign.center,

                      style: GoogleFonts.poppins(

                        color: _secondary,

                        fontSize: 7.5,

                        fontWeight: FontWeight.w500,

                      ),

                    ),

                  ),

                ],

              ),

            );

          },

        ),

      ),

    );

  }

  Widget _resultStatCompact({

    required IconData icon,

    required String value,

    required String label,

    required Color color,

  }) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),

      decoration: BoxDecoration(

        color: _surface2,

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: _border),

      ),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Container(

            width: 29,

            height: 29,

            decoration: BoxDecoration(

              color: color.withValues(alpha: 0.10),

              shape: BoxShape.circle,

              border: Border.all(

                color: color.withValues(alpha: 0.18),

              ),

            ),

            child: Icon(icon, color: color, size: 14),

          ),

          const SizedBox(height: 2),

          Text(

            value,

            style: GoogleFonts.poppins(

              color: _text,

              fontSize: 15,

              fontWeight: FontWeight.w800,

            ),

          ),

          Text(

            label,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: GoogleFonts.poppins(

              color: _secondary,

              fontSize: 7.5,

              fontWeight: FontWeight.w600,

            ),

          ),

        ],

      ),

    );

  }

  Widget _reviewBadge({

    required String text,

    required Color color,

  }) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.09),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: color.withValues(alpha: 0.18)),

      ),

      child: Text(

        text,

        style: GoogleFonts.poppins(

          color: color,

          fontSize: 8,

          fontWeight: FontWeight.w800,

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

    final timerColor = _timerColor();

    return Scaffold(

      backgroundColor: _bg,

      appBar: AppBar(

        backgroundColor: _surface,

        elevation: 0,

        automaticallyImplyLeading: false,

        toolbarHeight: 70,

        leading: IconButton(
          onPressed: _handleExamExitAttempt,
          icon: const Icon(Icons.arrow_back_rounded),
          color: _text,
          tooltip: "Leave assessment",
        ),

        titleSpacing: 0,

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

            // Fixed-width timer area keeps the countdown fully inside the
            // AppBar and prevents it from being pushed/cut off on small screens.
            SizedBox(
              width: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatTime(timeLeftSeconds),
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        color: timerColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "remaining",
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: GoogleFonts.poppins(
                      color: _secondary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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

              // 🚀 Wrapped inside Expanded/SizedBox with explicit constraints to fix infinite width layout crash

              Expanded(

                child: SizedBox(

                  height: 46,

                  child: ElevatedButton.icon(

                    onPressed: _confirmSubmit,

                    icon: const Icon(Icons.send_rounded, size: 17),

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExamExitAttempt();
      },
      child: _liveTestScreen(context),
    );

  }

  void _showSuccessDialog() {

    Get.dialog(

      Dialog(

        backgroundColor: _surface,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),

        child: Padding(

          padding: const EdgeInsets.all(22),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(

                "Exam Finished!",

                textAlign: TextAlign.center,

                style: GoogleFonts.poppins(

                  color: _text,

                  fontWeight: FontWeight.w800,

                  fontSize: 18,

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

                    "See my result",

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

class _ReviewAnswersScreen extends StatelessWidget {

  final String language;

  final String stage;

  final List<dynamic> questions;

  final Map<String, int> answers;

  final Map<String, int> correctAnswers;

  final bool isDark;

  const _ReviewAnswersScreen({

    required this.language,

    required this.stage,

    required this.questions,

    required this.answers,

    required this.correctAnswers,

    required this.isDark,

  });

  @override

  Widget build(BuildContext context) {

    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    final text = isDark ? AppColors.darkText : AppColors.text;

    final secondary =

        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(

      backgroundColor: bg,

      appBar: AppBar(

        backgroundColor: bg,

        elevation: 0,

        foregroundColor: text,

        titleSpacing: 4,

        title: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(

              "Review Answers",

              style: GoogleFonts.poppins(

                color: text,

                fontSize: 16,

                fontWeight: FontWeight.w800,

              ),

            ),

            Text(

              "$language • $stage",

              style: GoogleFonts.poppins(

                color: secondary,

                fontSize: 9.5,

                fontWeight: FontWeight.w500,

              ),

            ),

          ],

        ),

      ),

      body: questions.isEmpty

          ? Center(

              child: Text(

                "No answer details available.",

                style: GoogleFonts.poppins(

                  color: secondary,

                  fontSize: 12,

                ),

              ),

            )

          : ListView.builder(

              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),

              physics: const BouncingScrollPhysics(),

              itemCount: questions.length,

              itemBuilder: (context, index) {

                final question = questions[index];

                final qId = (question["_id"] ??

                        question["questionId"] ??

                        question["id"] ??

                        "")

                    .toString();

                final selected = answers[qId];

                final correct = correctAnswers[qId] ??

                    int.tryParse(

                      (question["correctIndex"] ??

                              question["correctAnswerIndex"] ??

                              question["correctOptionIndex"] ??

                              "")

                          .toString(),

                    );

                final verified = selected != null && correct != null;

                final isCorrect = verified && selected == correct;

                final options = question["options"] is List

                    ? List<dynamic>.from(question["options"])

                    : <dynamic>[];

                return Container(

                  margin: const EdgeInsets.only(bottom: 12),

                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),

                  decoration: BoxDecoration(

                    color: surface,

                    borderRadius: BorderRadius.circular(17),

                    border: Border.all(

                      color: verified

                          ? (isCorrect

                              ? AppColors.success.withValues(alpha: 0.35)

                              : AppColors.error.withValues(alpha: 0.35))

                          : border,

                    ),

                  ),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Row(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Container(

                            padding: const EdgeInsets.symmetric(

                              horizontal: 8,

                              vertical: 5,

                            ),

                            decoration: BoxDecoration(

                              color:

                                  AppColors.navy.withValues(alpha: 0.10),

                              borderRadius: BorderRadius.circular(8),

                            ),

                            child: Text(

                              "Q${index + 1}",

                              style: GoogleFonts.poppins(

                                color: isDark

                                    ? AppColors.teal

                                    : AppColors.navy,

                                fontSize: 9.5,

                                fontWeight: FontWeight.w800,

                              ),

                            ),

                          ),

                          const SizedBox(width: 8),

                          Expanded(

                            child: Text(

                              (question["questionText"] ??

                                      question["question"] ??

                                      "")

                                  .toString(),

                              style: GoogleFonts.poppins(

                                color: text,

                                fontSize: 12.5,

                                fontWeight: FontWeight.w700,

                                height: 1.35,

                              ),

                            ),

                          ),

                          const SizedBox(width: 6),

                          Container(

                            padding: const EdgeInsets.symmetric(

                              horizontal: 7,

                              vertical: 4,

                            ),

                            decoration: BoxDecoration(

                              color: (verified

                                      ? (isCorrect

                                          ? AppColors.success

                                          : AppColors.error)

                                      : AppColors.yellow)

                                  .withValues(alpha: 0.09),

                              borderRadius: BorderRadius.circular(8),

                            ),

                            child: Text(

                              verified

                                  ? (isCorrect ? "CORRECT" : "WRONG")

                                  : "ANSWER",

                              style: GoogleFonts.poppins(

                                color: verified

                                    ? (isCorrect

                                        ? AppColors.success

                                        : AppColors.error)

                                    : AppColors.yellow,

                                fontSize: 7.5,

                                fontWeight: FontWeight.w800,

                              ),

                            ),

                          ),

                        ],

                      ),

                      const SizedBox(height: 9),

                      ...List.generate(options.length, (optionIndex) {

                        final selectedHere = selected == optionIndex;

                        final correctHere = correct == optionIndex;

                        final Color optionColor = correctHere

                            ? AppColors.success

                            : (selectedHere && verified

                                ? AppColors.error

                                : border);

                        return Container(

                          margin: const EdgeInsets.only(bottom: 5),

                          padding: const EdgeInsets.symmetric(

                            horizontal: 9,

                            vertical: 7,

                          ),

                          decoration: BoxDecoration(

                            color: correctHere

                                ? AppColors.success.withValues(alpha: 0.08)

                                : (selectedHere && verified

                                    ? AppColors.error

                                        .withValues(alpha: 0.08)

                                    : (isDark

                                        ? AppColors.darkSurface2

                                        : AppColors.surfaceSoft)),

                            borderRadius: BorderRadius.circular(10),

                            border: Border.all(

                              color: optionColor,

                            ),

                          ),

                          child: Row(

                            children: [

                              Container(

                                width: 23,

                                height: 23,

                                alignment: Alignment.center,

                                decoration: BoxDecoration(

                                  shape: BoxShape.circle,

                                  color: optionColor.withValues(alpha: 0.10),

                                ),

                                child: Text(

                                  String.fromCharCode(65 + optionIndex),

                                  style: GoogleFonts.poppins(

                                    color: text,

                                    fontSize: 8.5,

                                    fontWeight: FontWeight.w800,

                                  ),

                                ),

                              ),

                              const SizedBox(width: 8),

                              Expanded(

                                child: Text(

                                  options[optionIndex].toString(),

                                  style: GoogleFonts.poppins(

                                    color: text,

                                    fontSize: 10.5,

                                    fontWeight: selectedHere || correctHere

                                        ? FontWeight.w700

                                        : FontWeight.w500,

                                  ),

                                ),

                              ),

                              if (correctHere)

                                const Icon(

                                  Icons.check_circle_rounded,

                                  color: AppColors.success,

                                  size: 17,

                                )

                              else if (selectedHere && verified)

                                const Icon(

                                  Icons.cancel_rounded,

                                  color: AppColors.error,

                                  size: 17,

                                ),

                            ],

                          ),

                        );

                      }),

                      if (selected == null)

                        Padding(

                          padding: const EdgeInsets.only(top: 3),

                          child: Text(

                            "Not answered",

                            style: GoogleFonts.poppins(

                              color: AppColors.error,

                              fontSize: 9.5,

                              fontWeight: FontWeight.w700,

                            ),

                          ),

                        ),

                    ],

                  ),

                );

              },

            ),

    );

  }

}

