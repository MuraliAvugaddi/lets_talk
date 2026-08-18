import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiClubStage1Screen extends StatelessWidget {
  const HindiClubStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
   return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage1", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: Must be "club" (not "Online class")
    );
  }
}