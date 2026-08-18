import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiOnlineStage5Screen extends StatelessWidget {
  const HindiOnlineStage5Screen({super.key});

  @override
  Widget build(BuildContext context) {
 return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage5", 
      type: "class", // ✅ CORRECT: Must be exactly "class"
    );
  }
}