import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiOnlineStage6Screen extends StatelessWidget {
  const HindiOnlineStage6Screen({super.key});

  @override
  Widget build(BuildContext context) {
 return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage6", 
      type: "class", // ✅ CORRECT: Must be exactly "class"
    );
  }
}