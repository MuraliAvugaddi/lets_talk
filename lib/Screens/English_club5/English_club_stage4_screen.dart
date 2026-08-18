import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class EnglishClubStage4Screen extends StatelessWidget {
  const EnglishClubStage4Screen({super.key});

  @override
  Widget build(BuildContext context) {
return const LiveSessionWidget(
      language: "English", 
      stage: "stage4", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: 'club' for Speaking Clubs
    );
  }
}