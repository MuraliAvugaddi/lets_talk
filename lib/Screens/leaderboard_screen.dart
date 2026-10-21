import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/widgets/best_students_view.dart';

/// 🏆 Hall of Fame (student app): best student of the month
/// — your class, best of all English / all Hindi, and every class. Students only, no trainers.
/// (Class name kept so the existing "Hall of Fame" button keeps working.)
class StudentLeaderboardScreen extends StatelessWidget {
  const StudentLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Best Students',
          style: GoogleFonts.poppins(color: theme.colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: const SafeArea(top: false, child: BestStudentsView(audience: 'student')),
    );
  }
}
