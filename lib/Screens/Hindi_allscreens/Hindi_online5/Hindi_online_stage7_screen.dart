import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiOnlineStage7Screen extends StatelessWidget {
  const HindiOnlineStage7Screen({super.key});

  @override
  Widget build(BuildContext context) {
 return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage7", 
      type: "class", // ✅ CORRECT: Must be exactly "class"
    );
  }
}