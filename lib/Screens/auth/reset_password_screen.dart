import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class ResetPasswordScreen extends GetView<AuthController> {
  const ResetPasswordScreen({super.key});

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: tealMist.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "SECURITY",
                  style: GoogleFonts.poppins(
                    color: deepOceanBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Create New Password",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Set a strong and secure password for your account.",
                style: GoogleFonts.poppins(
                  color: textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // New Password Input
              _buildInputField(
                controller: controller.newPasswordController,
                label: "New Password",
                hintText: "Minimum 6 characters",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                fillColor: cardFill,
                borderColor: borderLight,
                accentColor: deepOceanBlue,
                textColor: textDark,
                mutedColor: textMuted,
              ),

              const SizedBox(height: 18),

              // Confirm Password Input
              _buildInputField(
                controller: controller.confirmPasswordController,
                label: "Confirm New Password",
                hintText: "Re-enter new password",
                icon: Icons.lock_reset_rounded,
                isPassword: true,
                fillColor: cardFill,
                borderColor: borderLight,
                accentColor: deepOceanBlue,
                textColor: textDark,
                mutedColor: textMuted,
              ),

              const SizedBox(height: 36),

              // Submit Action Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.resetPassword(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepOceanBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Save & Login",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required Color fillColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
    required Color mutedColor,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.poppins(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accentColor.withOpacity(0.7), size: 20),
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(color: mutedColor.withOpacity(0.7), fontSize: 13),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}