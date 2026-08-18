import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiOnlineStage1Screen extends StatelessWidget {
  const HindiOnlineStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage1", 
      type: "class", // ✅ CORRECT: Must be exactly "class"
    );
  }
}