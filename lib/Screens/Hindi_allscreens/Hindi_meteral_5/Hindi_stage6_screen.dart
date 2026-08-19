import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';

class HindiStage6Screen extends StatelessWidget {
  const HindiStage6Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xff7F56D9),
        title: const Text("Hindi Material 6"),
      ),
      body: Column(
        children: const [
          StageAttendanceWidget(stageName: "Stage 6"),
          Expanded(child: Center(child: Text("Hindi Stage 6 Content...", style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }
}