import 'package:flutter/material.dart';

import 'package:lets_talk/Screens/Test_screens/TestTaking_widgetScreen.dart';

// ============================================================
// TEST ENTRY SCREENS
// Every stage opens the real test screen directly. That screen shows the REAL
// question count, duration and marks from the server (the old instruction page
// showed a fixed "25 min / 30 questions" that was often wrong).
// All old class names are kept so existing navigation keeps working.
// ============================================================

class _StageTest extends StatelessWidget {
  final String language;
  final int stage;
  const _StageTest(this.language, this.stage);

  @override
  Widget build(BuildContext context) => TestTakingScreen(language: language, stage: 'stage$stage');
}

// ---------------- ENGLISH ----------------

class EnglishTestStageoneScreen extends StatelessWidget {
  const EnglishTestStageoneScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 1);
}

class EnglishTestStage1Screen extends StatelessWidget {
  const EnglishTestStage1Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 1);
}

class EnglishTestStagetwoScreen extends StatelessWidget {
  const EnglishTestStagetwoScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 2);
}

class EnglishTestStage2Screen extends StatelessWidget {
  const EnglishTestStage2Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 2);
}

class EnglishTestStagethreeScreen extends StatelessWidget {
  const EnglishTestStagethreeScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 3);
}

class EnglishTestStage3Screen extends StatelessWidget {
  const EnglishTestStage3Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 3);
}

class EnglishTestStagefoureScreen extends StatelessWidget {
  const EnglishTestStagefoureScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 4);
}

class EnglishTestStage4Screen extends StatelessWidget {
  const EnglishTestStage4Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 4);
}

class EnglishTestStagefiveScreen extends StatelessWidget {
  const EnglishTestStagefiveScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 5);
}

class EnglishTestStage5Screen extends StatelessWidget {
  const EnglishTestStage5Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 5);
}

class EnglishTestStagesixScreen extends StatelessWidget {
  const EnglishTestStagesixScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 6);
}

class EnglishTestStage6Screen extends StatelessWidget {
  const EnglishTestStage6Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 6);
}

class EnglishTestStagesevenScreen extends StatelessWidget {
  const EnglishTestStagesevenScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 7);
}

class EnglishTestStage7Screen extends StatelessWidget {
  const EnglishTestStage7Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('English', 7);
}

// ---------------- HINDI ----------------

class HindiTestStageoneScreen extends StatelessWidget {
  const HindiTestStageoneScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 1);
}

class HindiTestStage1Screen extends StatelessWidget {
  const HindiTestStage1Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 1);
}

class HindiTestStagetwoScreen extends StatelessWidget {
  const HindiTestStagetwoScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 2);
}

class HindiTestStage2Screen extends StatelessWidget {
  const HindiTestStage2Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 2);
}

class HindiTestStagethreeScreen extends StatelessWidget {
  const HindiTestStagethreeScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 3);
}

class HindiTestStage3Screen extends StatelessWidget {
  const HindiTestStage3Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 3);
}

class HindiTestStagefoureScreen extends StatelessWidget {
  const HindiTestStagefoureScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 4);
}

class HindiTestStage4Screen extends StatelessWidget {
  const HindiTestStage4Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 4);
}

class HindiTestStagefiveScreen extends StatelessWidget {
  const HindiTestStagefiveScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 5);
}

class HindiTestStage5Screen extends StatelessWidget {
  const HindiTestStage5Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 5);
}

class HindiTestStagesixScreen extends StatelessWidget {
  const HindiTestStagesixScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 6);
}

class HindiTestStage6Screen extends StatelessWidget {
  const HindiTestStage6Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 6);
}

class HindiTestStagesevenScreen extends StatelessWidget {
  const HindiTestStagesevenScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 7);
}

class HindiTestStage7Screen extends StatelessWidget {
  const HindiTestStage7Screen({super.key});

  @override
  Widget build(BuildContext context) => const _StageTest('Hindi', 7);
}
