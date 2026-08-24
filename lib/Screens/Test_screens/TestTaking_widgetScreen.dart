import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

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

  bool isAlreadyTaken = false;
  int myScore = 0;
  int totalQs = 0;

  List<dynamic> questions = [];
  Map<String, int> userAnswers = {};

  int timeLeftSeconds = 25 * 60;
  Timer? _timer;

  final box = GetStorage();

  // --- BRAND COLORS ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color backgroundColor = const Color(0xff0A0A0E);
  final Color cardColor = const Color(0xff14141E);

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
            questions = data['questions'];
            timeLeftSeconds = (data['durationMinutes'] ?? 25) * 60;
            isTestActive = true;
            isLoading = false;
          });
          startTimer();
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
        backgroundColor: cardColor,
        colorText: goldenYellow,
        borderColor: goldenYellow.withOpacity(0.5),
        borderWidth: 1,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(Icons.warning_amber_rounded, color: goldenYellow),
      );
      return;
    }

    final userData = box.read('user');
    if (userData == null) {
      Get.snackbar(
        "Error",
        "User not logged in.",
        backgroundColor: cardColor,
        colorText: Colors.redAccent,
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

  void _showSuccessDialog() {
    final double percentage = totalQs > 0 ? (myScore / totalQs) * 100 : 0.0;
    final bool isPassed = percentage >= 50;

    Get.defaultDialog(
      title: "",
      titlePadding: EdgeInsets.zero,
      backgroundColor: cardColor,
      radius: 20,
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPassed
                  ? goldenYellow.withOpacity(0.15)
                  : Colors.redAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
              color: isPassed ? goldenYellow : Colors.redAccent,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? "Assessment Passed!" : "Exam Finished!",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your score has been updated in your profile.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tealMist.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  "Final Marks",
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "$myScore / $totalQs",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? goldenYellow : Colors.redAccent,
                  ),
                ),
                Text(
                  "${percentage.toStringAsFixed(0)}% Accuracy",
                  style: TextStyle(
                    color: isPassed ? goldenYellow : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: deepOceanBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Return to Dashboard",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: goldenYellow)),
      );
    }

    // --- VIEW 1: ALREADY TAKEN ---
    if (isAlreadyTaken) {
      final double percentage = totalQs > 0 ? (myScore / totalQs) * 100 : 0.0;
      final bool isPassed = percentage >= 50;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
            "${widget.language} • ${widget.stage.toUpperCase()}",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? goldenYellow.withOpacity(0.12)
                        : Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPassed
                          ? goldenYellow.withOpacity(0.35)
                          : Colors.redAccent.withOpacity(0.35),
                    ),
                  ),
                  child: Icon(
                    isPassed
                        ? Icons.check_circle_outline_rounded
                        : Icons.assignment_turned_in_rounded,
                    color: isPassed ? goldenYellow : Colors.redAccent,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Assessment Completed",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You have already submitted your evaluation for this stage.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tealMist.withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Score Achieved",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$myScore / $totalQs",
                        style: GoogleFonts.poppins(
                          color: isPassed ? goldenYellow : Colors.redAccent,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${percentage.toStringAsFixed(0)}% Marks",
                        style: TextStyle(
                          color: isPassed ? goldenYellow : Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepOceanBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Back to Assessments",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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

    // --- VIEW 2: NO TEST SCHEDULED ---
    if (!isTestActive) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: goldenYellow.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: goldenYellow,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Test Not Available",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "There is currently no active test published for ${widget.language} (${widget.stage.toUpperCase()}). Please check back soon.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- VIEW 3: LIVE TEST TAKING ---
    final double progress = questions.isNotEmpty
        ? (userAnswers.length / questions.length)
        : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${timeLeftSeconds ~/ 60}:${(timeLeftSeconds % 60).toString().padLeft(2, '0')}",
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${widget.language} • ${widget.stage.toUpperCase()}",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ElevatedButton(
                onPressed: () => submitTest(forceSubmit: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepOceanBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Submit",
                  style: GoogleFonts.poppins(
                    color: goldenYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xff1E1E2C),
            valueColor: AlwaysStoppedAnimation<Color>(goldenYellow),
            minHeight: 4,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: questions.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final q = questions[index];
                final String qId = q['_id'];
                final int? selectedOption = userAnswers[qId];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedOption != null
                          ? goldenYellow.withOpacity(0.4)
                          : tealMist.withOpacity(0.2),
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
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: deepOceanBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Q${index + 1}",
                              style: GoogleFonts.poppins(
                                color: goldenYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q['questionText'] ?? "",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(4, (optIndex) {
                        if (optIndex >= (q['options'] as List).length) {
                          return const SizedBox.shrink();
                        }

                        final String optionText = q['options'][optIndex];
                        final bool isSelected = selectedOption == optIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              userAnswers[qId] = optIndex;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? deepOceanBlue.withOpacity(0.3)
                                  : const Color(0xff12121A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? goldenYellow
                                    : Colors.white.withOpacity(0.06),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? goldenYellow
                                          : Colors.white38,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? goldenYellow
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.circle,
                                            color: Colors.black,
                                            size: 8,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: GoogleFonts.poppins(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
