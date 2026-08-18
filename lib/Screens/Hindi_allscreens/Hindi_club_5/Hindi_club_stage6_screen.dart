import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart'; // Ensure this path matches where you saved the file

class HindiClubStage6Screen extends StatelessWidget {
  const HindiClubStage6Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage6", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: Must be "club" (not "Online class")
    );
  }
}