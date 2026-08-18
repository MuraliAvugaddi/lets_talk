import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';

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

  final String baseUrl = "http://192.168.1.4:5000/api/test";
  final box = GetStorage();

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
          "$baseUrl/user/get-test?language=${widget.language}&stage=${widget.stage}&userId=$userId",
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
        backgroundColor: const Color(0xff2A1C11),
        colorText: Colors.orangeAccent,
        borderColor: Colors.orangeAccent.withOpacity(0.5),
        borderWidth: 1,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
        ),
      );
      return;
    }

    final userData = box.read('user');
    if (userData == null) {
      Get.snackbar(
        "Error",
        "User not logged in.",
        backgroundColor: const Color(0xff2A1C24),
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
        Uri.parse("$baseUrl/user/submit-test"),
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

        Get.defaultDialog(
          title: "Assessment Completed!",
          backgroundColor: const Color(0xff181824),
          titleStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          radius: 16,
          content: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                "Great job finishing the exam!",
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text(
                "Your Final Score",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                "$myScore / $totalQs",
                style: GoogleFonts.poppins(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          textConfirm: "Done",
          confirmTextColor: Colors.white,
          buttonColor: const Color(0xff7F56D9),
          onConfirm: () => Get.back(),
        );
      } else {
        Get.snackbar("Error", "Submission error: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Submission Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xff0D0D12);
    final Color cardColor = const Color(0xff181824);
    final Color accentPurple = const Color(0xff7F56D9);

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: accentPurple)),
      );
    }

    // --- VIEW 1: ALREADY TAKEN ---
    if (isAlreadyTaken) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    "assets/images/tick1.png",
                    height: 90,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Test Already Submitted",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You have already completed this test assessment.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Achieved Score",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$myScore / $totalQs",
                        style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Back to Dashboard",
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

    // --- VIEW 2: NOT SCHEDULED ---
    if (!isTestActive) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
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
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Colors.amber,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Test Scheduled Soon",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "There is no active test available for ${widget.language} (${widget.stage}) right now.",
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

    // --- VIEW 3: TAKING TEST (Enhanced Modern UI) ---
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
                  backgroundColor: accentPurple,
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
                    color: Colors.white,
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
          // Progress bar tracker indicator
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xff1E1E2C),
            valueColor: AlwaysStoppedAnimation<Color>(accentPurple),
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
                          ? accentPurple.withOpacity(0.4)
                          : Colors.white.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentPurple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Q${index + 1}",
                              style: GoogleFonts.poppins(
                                color: accentPurple,
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
                                  ? accentPurple.withOpacity(0.2)
                                  : const Color(0xff12121A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? accentPurple
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
                                          ? accentPurple
                                          : Colors.white38,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? accentPurple
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.circle,
                                            color: Colors.white,
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
                                          ? FontWeight.w500
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
