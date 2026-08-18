import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class EnglishClubStage1Screen extends StatelessWidget {
  const EnglishClubStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveSessionWidget(
      language: "English", 
      stage: "stage1", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: 'club' for Speaking Clubs
    );
  }
}