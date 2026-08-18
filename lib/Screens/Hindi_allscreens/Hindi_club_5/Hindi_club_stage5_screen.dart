import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart'; // Ensure this path matches where you saved the file

class HindiClubStage5Screen extends StatelessWidget {
  const HindiClubStage5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage5", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: Must be "club" (not "Online class")
    );
  }
}