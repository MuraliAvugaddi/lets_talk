import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class EnglishOnlineStage2Screen extends StatelessWidget {
  const EnglishOnlineStage2Screen({super.key});

  @override
  Widget build(BuildContext context) {
 return const LiveSessionWidget(
      language: "English", 
      stage: "stage2", // ✅ CORRECT: Lowercase, no space (matches database)
      type: "class",   // ✅ CORRECT: Must be "class" (not "Online class")
    );
  }
}