import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/Test_screens/TestTaking_widgetScreen.dart';

class HindiTestStagesevenScreen extends StatelessWidget {
  const HindiTestStagesevenScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // 2. Call the screen and pass the specific data for this stage
    return const TestTakingScreen(
      language: "Hindi", // <--- This tells backend to fetch English
      stage: "stage7", // <--- This tells backend to fetch Stage 1
    );
  }
}

class HindiTestStage7Screen extends StatelessWidget {
  const HindiTestStage7Screen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define UI Colors
    final Color backgroundColor = const Color(0xff0D0D0D);
    final Color cardColor = const Color(0xff1E1E1E);
    final Color accentPurple = const Color(0xff158DFE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center items horizontally
            children: [
              // 1. Icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: accentPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 50,
                  color: accentPurple,
                ),
              ),
              const SizedBox(height: 30),

              // 2. Title & Subtitle (Centered)
              Text(
                "Hindi Stage 5 Test",
                textAlign: TextAlign.center, // Center text alignment
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please read the instructions carefully before starting the exam.",
                textAlign: TextAlign.center, // Center text alignment
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 30),

              // 3. Instructions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.timer, "Duration", "25 Minutes"),
                    const Divider(color: Colors.white10, height: 30),
                    _buildInfoRow(
                      Icons.help_outline,
                      "Questions",
                      "30 Questions",
                    ),
                    const Divider(color: Colors.white10, height: 30),
                    _buildInfoRow(
                      Icons.star_outline,
                      "Total Marks",
                      "30 Marks",
                    ),
                    const Divider(color: Colors.white10, height: 30),
                    _buildInfoRow(
                      Icons.warning_amber_rounded,
                      "Note",
                      "Submit before time ends",
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. Start Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the actual Test Screen Logic
                    Get.to(() => const HindiTestStagesevenScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff158DFE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Start Exam",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
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

  // Helper Widget for Instruction Rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 15),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
