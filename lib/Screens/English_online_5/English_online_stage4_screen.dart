import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class EnglishOnlineStage4Screen extends StatelessWidget {
  const EnglishOnlineStage4Screen({super.key});

  @override
  Widget build(BuildContext context) {
return const LiveSessionWidget(
      language: "English", 
      stage: "stage4", // ✅ CORRECT: Lowercase, no space (matches database)
      type: "class",   // ✅ CORRECT: Must be "class" (not "Online class")
    );
  }
}