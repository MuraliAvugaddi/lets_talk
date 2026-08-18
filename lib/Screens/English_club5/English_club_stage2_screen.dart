import 'package:flutter/material.dart';
// Import the widget

import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart'; 

class EnglishClubStage2Screen extends StatelessWidget {
  const EnglishClubStage2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveSessionWidget(
      language: "English", 
      stage: "stage2", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: 'club' for Speaking Clubs
    );
  }
}