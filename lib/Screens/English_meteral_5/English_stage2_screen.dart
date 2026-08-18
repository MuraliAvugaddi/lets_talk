import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';

class EnglishStage2Screen extends StatelessWidget {
  const EnglishStage2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff7F56D9),
        title: const Text("English Material 2"),
      ),
      body: Column(
        children: [
          // This adds the attendance logic specifically for Stage 2
          const StageAttendanceWidget(stageName: "Stage 2"),

          const Expanded(child: Center(child: Text("Leerial for Stage 2..."))),
        ],
      ),
    );
  }
}
