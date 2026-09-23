import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class SignupStep1 extends StatelessWidget {
  const SignupStep1({super.key});

  // =========================
  // BRAND COLORS
  // =========================
  static const Color navy = Color(0xFF155A88);
  static const Color deepNavy = Color(0xFF0E466D);
  static const Color teal = Color(0xFF28C2C2);
  static const Color yellow = Color(0xFFF7DF55);

  static const Color background = Color(0xFFE8F2F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4F9FC);
  static const Color border = Color(0xFFD5E5EE);
  static const Color text = Color(0xFF173A52);
  static const Color textSecondary = Color(0xFF678196);
  static const Color error = Color(0xFFE45757);

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();
    final RxBool obscurePassword = true.obs;

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 7, bottom: 7),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: border),
            ),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: text,
              padding: EdgeInsets.zero,
            ),
          ),
        ),

        title: Text(
          'Create Account',
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =========================
      // BODY
      // =========================
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Form(
            key: controller.signupFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================
                // BRAND
                // =========================
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: yellow,
                            size: 14,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Text(
                          "Let's Speak",
                          style: GoogleFonts.poppins(
                            color: navy,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // TITLE
                // =========================
                Center(
                  child: Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: text,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Center(
                  child: Text(
                    'Enter your details to get started.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // =========================
                // FORM CARD
                // =========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FULL NAME
                      _field(
                        controller: controller.nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        capitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // PHONE NUMBER
                      _field(
                        controller: controller.phoneController,
                        label: 'Phone Number',
                        hint: 'Enter your 10-digit number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return 'Enter valid 10-digit number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // PASSWORD
                      Obx(
                        () => _field(
                          controller: controller.passwordController,
                          label: 'Create Password',
                          hint: 'Minimum 6 characters',
                          icon: Icons.lock_outline_rounded,
                          obscureText: obscurePassword.value,
                          suffixIcon: IconButton(
                            onPressed: obscurePassword.toggle,
                            icon: Icon(
                              obscurePassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textSecondary,
                              size: 19,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be 6+ characters';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 13),

                // =========================
                // SECURITY MESSAGE
                // =========================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: teal.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: teal,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        'Use at least 6 characters for a secure password.',
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // =========================
                // CONTINUE BUTTON
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.submitStep1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(width: 7),

                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // SIGN IN
                // =========================
                Center(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.poppins(
                              color: textSecondary,
                              fontSize: 11.5,
                            ),
                          ),

                          TextSpan(
                            text: 'Sign In',
                            style: GoogleFonts.poppins(
                              color: navy,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // TEXT FIELD
  // =========================
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          validator: validator,

          scrollPadding: const EdgeInsets.only(bottom: 120),

          style: GoogleFonts.poppins(
            color: text,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),

          decoration: InputDecoration(
            filled: true,
            fillColor: surfaceSoft,

            prefixIcon: Icon(icon, color: navy, size: 19),

            suffixIcon: suffixIcon,

            hintText: hint,

            hintStyle: GoogleFonts.poppins(
              color: textSecondary.withOpacity(0.70),
              fontSize: 11.5,
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 14,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: border),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: navy, width: 1.4),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: error),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: error, width: 1.4),
            ),

            errorStyle: GoogleFonts.poppins(color: error, fontSize: 9.5),
          ),
        ),
      ],
    );
  }
}
