import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/student_attendance_screen.dart';
import 'package:lets_talk/Screens/student_test_results_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _launchCommunityLink() async {
    final Uri url = Uri.parse(
      "https://chat.whatsapp.com/KEb01Z5HqfOHkCFoztBFsX?mode=hqrc",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        "Could Not Open",
        "Unable to launch WhatsApp link.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    // --- BRAND PALETTE ---
    final Color deepOceanBlue = const Color(0xff065381);
    final Color tealMist = const Color(0xff508F97);
    final Color goldenYellow = const Color(0xffF2C94C);
    final Color darkCard = const Color(0xff14141E);
    final Color backgroundColor = const Color(0xff0A0A0E);
    const Color accentGreen = Color(0xff25D366);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: tealMist,
        backgroundColor: darkCard,
        onRefresh: () async => await controller.refreshProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- 1. HERO PROFILE CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: tealMist.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: tealMist.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: goldenYellow, width: 2),
                            color: deepOceanBlue.withOpacity(0.2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/account1.png",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Obx(() {
                                  String name =
                                      controller.userData['name'] ?? 'U';
                                  return Center(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U',
                                      style: GoogleFonts.poppins(
                                        color: goldenYellow,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Obx(
                      () => Text(
                        controller.userData['name'] ?? "User Name",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

                    Obx(
                      () => Text(
                        controller.userData['phone'] ?? "N/A",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Obx(() {
                      String mode = controller.userData['mode'] ?? "online";
                      bool isOnline = mode.toLowerCase() == "online";
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? tealMist.withOpacity(0.18)
                              : goldenYellow.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOnline
                                ? tealMist.withOpacity(0.5)
                                : goldenYellow.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnline
                                  ? Icons.wifi_rounded
                                  : Icons.location_on_rounded,
                              size: 13,
                              color: isOnline ? tealMist : goldenYellow,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${mode.toUpperCase()} STUDENT",
                              style: GoogleFonts.poppins(
                                color: isOnline ? tealMist : goldenYellow,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 2. ATTENDANCE NAVIGATION CARD ---
              GestureDetector(
                onTap: () => Get.to(() => const StudentAttendanceScreen()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tealMist.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tealMist.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.fact_check_rounded,
                          color: tealMist,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Attendance & Log",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "View monthly classes & club records",
                              style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: tealMist,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // --- 3. TEST RESULTS NAVIGATION CARD ---
              GestureDetector(
                onTap: () => Get.to(() => const StudentTestResultsScreen()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: deepOceanBlue.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: deepOceanBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.leaderboard_rounded,
                          color: goldenYellow,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Test Results & Scores",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Review stage-wise exam marks & percentage",
                              style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: goldenYellow,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // --- 4. COMMUNITY INVITATION CARD ---
              GestureDetector(
                onTap: _launchCommunityLink,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentGreen.withOpacity(0.15),
                        const Color(0xff141E18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accentGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: accentGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Let's Speak Community",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Join student discussions on WhatsApp",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: accentGreen,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- 5. LOGOUT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => controller.logout(),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: Text(
                    "Log Out",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff221417),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
