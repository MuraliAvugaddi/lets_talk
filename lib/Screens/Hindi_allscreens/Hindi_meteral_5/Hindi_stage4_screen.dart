import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';

class HindiStage4Screen extends StatelessWidget {
  const HindiStage4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xff7F56D9),
        title: const Text("Hindi Material 4"),
      ),
      body: Column(
        children: const [
          StageAttendanceWidget(stageName: "Stage 4"),
          Expanded(child: Center(child: Text("Hindi Stage 4 Content...", style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }
}