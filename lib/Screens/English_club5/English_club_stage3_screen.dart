import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/LiveSessionWidget.dart';

class EnglishClubStage3Screen extends StatelessWidget {
  const EnglishClubStage3Screen({super.key});

  @override
  Widget build(BuildContext context) {
 return const LiveSessionWidget(
      language: "English", 
      stage: "stage3", // ✅ CORRECT: Lowercase, no space
      type: "club",    // ✅ CORRECT: 'club' for Speaking Clubs
    );
  }
}