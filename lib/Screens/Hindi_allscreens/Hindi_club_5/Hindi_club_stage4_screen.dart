import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiClubStage4Screen extends StatelessWidget {
  const HindiClubStage4Screen({super.key});

  @override
  Widget build(BuildContext context) {
      return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage4", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: Must be "club" (not "Online class")
    );
  }
}