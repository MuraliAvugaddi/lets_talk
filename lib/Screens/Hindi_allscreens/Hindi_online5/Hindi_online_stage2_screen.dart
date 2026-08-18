import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiOnlineStage2Screen extends StatelessWidget {
  const HindiOnlineStage2Screen({super.key});

  @override
  Widget build(BuildContext context) {
   return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage2", 
      type: "class", // ✅ CORRECT: Must be exactly "class"
    );
  }
}