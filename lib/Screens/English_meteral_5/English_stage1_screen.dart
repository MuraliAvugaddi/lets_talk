  import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';

class EnglishStage1Screen extends StatelessWidget {
  const EnglishStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xff7F56D9),
        title: const Text("English Material 1"),
      ),
      body: Column(
        children: const [
          StageAttendanceWidget(stageName: "Stage 1"),
          Expanded(child: Center(child: Text("English Stage 1 Content...", style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }
}