import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class HindiOnlineStage3Screen extends StatelessWidget {
  const HindiOnlineStage3Screen({super.key});

  @override
  Widget build(BuildContext context) {
 return const LiveSessionWidget(
      language: "Hindi", 
      stage: "stage3", 
      type: "class", // ✅ CORRECT: Must be exactly "class"
    );
  }
}