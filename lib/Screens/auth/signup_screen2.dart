import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class SignupStep2 extends GetView<AuthController> {
  const SignupStep2({super.key});

  @override
  Widget build(BuildContext context) {
    // --- BRAND PALETTE ---
    final Color deepOceanBlue = const Color(0xff065381);
    final Color tealMist = const Color(0xff508F97);
    final Color pureWhite = const Color(0xffFFFFFF);
    final Color textDark = const Color(0xff0F172A);
    final Color textMuted = const Color(0xff64748B);
    final Color cardFill = const Color(0xffF8FAFC);
    final Color borderLight = const Color(0xffE2E8F0);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textDark),
        centerTitle: true,
        title: Text(
          "Select Mode",
          style: GoogleFonts.poppins(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How do you want\nto learn?",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Choose your preferred class mode. An SMS OTP will be sent to verify your number.",
                style: GoogleFonts.poppins(
                  color: textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // --- ONLINE CARD ---
              _buildSelectionCard(
                context,
                title: "Online Mode",
                subtitle: "Attend live classes via internet",
                icon: Icons.wifi_rounded,
                accentColor: deepOceanBlue,
                bgColor: cardFill,
                borderColor: borderLight,
                onTap: () => controller.initiateSignupOtp("online"),
              ),

              const SizedBox(height: 16),

              // --- OFFLINE CARD ---
              _buildSelectionCard(
                context,
                title: "Offline Mode",
                subtitle: "Attend classes on-site at the institute",
                icon: Icons.location_on_rounded,
                accentColor: tealMist,
                bgColor: cardFill,
                borderColor: borderLight,
                onTap: () => controller.initiateSignupOtp("offline"),
              ),

              const SizedBox(height: 40),
              
              // Loading Indicator
              Center(
                child: Obx(
                  () => controller.isLoading.value
                      ? CircularProgressIndicator(color: deepOceanBlue)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: accentColor.withOpacity(0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}