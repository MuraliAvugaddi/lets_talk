import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class SignupStep1 extends GetView<AuthController> {
  const SignupStep1({super.key});

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
                  "STEP 1 OF 2",
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
                "Create Account",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter your basic details to get started with your learning path.",
                style: GoogleFonts.poppins(
                  color: textMuted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: controller.signupFormKey,
                child: Column(
                  children: [
                    _buildTextField(
                      ctrl: controller.nameController,
                      label: "Full Name",
                      hint: "e.g. Rahul Sharma",
                      icon: Icons.person_outline_rounded,
                      capitalization: TextCapitalization.words,
                      fillColor: cardFill,
                      borderColor: borderLight,
                      accentColor: deepOceanBlue,
                      textColor: textDark,
                      mutedColor: textMuted,
                      validator: (value) =>
                          value!.trim().isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      ctrl: controller.phoneController,
                      label: "Phone Number",
                      hint: "10-digit mobile number",
                      icon: Icons.phone_outlined,
                      type: TextInputType.phone,
                      fillColor: cardFill,
                      borderColor: borderLight,
                      accentColor: deepOceanBlue,
                      textColor: textDark,
                      mutedColor: textMuted,
                      validator: (value) => value!.trim().length < 10
                          ? "Enter valid 10-digit number"
                          : null,
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      ctrl: controller.passwordController,
                      label: "Create Password",
                      hint: "Minimum 6 characters",
                      icon: Icons.lock_outline_rounded,
                      isPass: true,
                      fillColor: cardFill,
                      borderColor: borderLight,
                      accentColor: deepOceanBlue,
                      textColor: textDark,
                      mutedColor: textMuted,
                      validator: (value) => value!.length < 6
                          ? "Password must be 6+ characters"
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => controller.submitStep1(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepOceanBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Next Step",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    required Color fillColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
    required Color mutedColor,
    bool isPass = false,
    TextInputType type = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: ctrl,
          obscureText: isPass,
          keyboardType: type,
          textCapitalization: capitalization,
          validator: validator,
          style: GoogleFonts.poppins(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accentColor.withOpacity(0.7), size: 20),
            hintText: hint,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffEF4444), width: 1.5),
            ),
            errorStyle: GoogleFonts.poppins(color: const Color(0xffEF4444), fontSize: 11),
          ),
        ),
      ],
    );
  }
}