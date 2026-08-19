import 'package:flutter/material.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';

class HindiStage7Screen extends StatelessWidget {
  const HindiStage7Screen({super.key});

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xff7F56D9),
        title: const Text("Hindi Material 7"),
      ),
      body: Column(
        children: const [
          StageAttendanceWidget(stageName: "Stage 7"),
          Expanded(
            child: Center(
              child: Text(
                "Hindi Stage 7 Content...",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
