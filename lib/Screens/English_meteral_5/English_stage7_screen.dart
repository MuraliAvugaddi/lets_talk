import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';

class EnglishStage7Screen extends StatelessWidget {
  const EnglishStage7Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff7F56D9),
        title: const Text("English Material 7"),
      ),
      body: Column(
        children: [
          const StageAttendanceWidget(stageName: "Stage 7"),
          const Expanded(
            child: Center(child: Text("Learn Material for Stage ...")),
          ),
        ],
      ),
    );
  }
}
