  import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';

class EnglishStage1Screen extends StatelessWidget {
  const EnglishStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff7F56D9),
        title: const Text("English Material 1"),
      ),
      body: Column(
        children: [
          // This adds the attendance logic specifically for Stage 1
          const StageAttendanceWidget(stageName: "Stage 1"),
          
          const Expanded(
            child: Center(child: Text("Learn Material for Stage 1...")),
          ),
        ],
      ),
    );
  }
}