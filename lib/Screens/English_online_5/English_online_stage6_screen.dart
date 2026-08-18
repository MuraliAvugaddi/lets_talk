import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class EnglishOnlineStage6Screen extends StatelessWidget {
  const EnglishOnlineStage6Screen({super.key});

  @override
  Widget build(BuildContext context) {
  return const LiveSessionWidget(
      language: "English", 
      stage: "stage6", // ✅ CORRECT: Lowercase, no space (matches database)
      type: "class",   // ✅ CORRECT: Must be "class" (not "Online class")
    );
  }
}