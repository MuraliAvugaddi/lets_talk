import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class ResetPasswordScreen extends GetView<AuthController> {
  const ResetPasswordScreen({super.key});

  // ============================================================
  // BRAND COLORS
  // ============================================================

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // Important:
      // Allows the body to resize when the keyboard opens.
      resizeToAvoidBottomInset: true,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Get.back(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: text,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              // Extra space when keyboard is visible.
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),

              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),

                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // BRAND
                      // ==================================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 23,
                              height: 23,
                              decoration: BoxDecoration(
                                color: navy,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: yellow,
                                size: 14,
                              ),
                            ),

                            const SizedBox(width: 7),

                            Text(
                              "Let's Speak",
                              style: GoogleFonts.poppins(
                                color: navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // ICON
                      // ==================================================
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: teal.withOpacity(0.25)),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: teal.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: navy,
                            size: 25,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // TITLE
                      // ==================================================
                      Text(
                        "Create New Password",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: text,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Choose a strong password for your account.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // PASSWORD CARD
                      // ==================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              color: navy.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ==================================================
                            // CARD HEADER
                            // ==================================================
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: navy.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.password_rounded,
                                    color: navy,
                                    size: 19,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Password Setup",
                                      style: GoogleFonts.poppins(
                                        color: text,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    Text(
                                      "Minimum 6 characters",
                                      style: GoogleFonts.poppins(
                                        color: textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // ==================================================
                            // NEW PASSWORD
                            // ==================================================
                            _passwordField(
                              controller: controller.newPasswordController,
                              label: "New Password",
                              hint: "Enter new password",
                              icon: Icons.lock_outline_rounded,
                            ),

                            const SizedBox(height: 13),

                            // ==================================================
                            // CONFIRM PASSWORD
                            // ==================================================
                            _passwordField(
                              controller: controller.confirmPasswordController,
                              label: "Confirm Password",
                              hint: "Re-enter password",
                              icon: Icons.lock_reset_rounded,
                            ),

                            const SizedBox(height: 14),

                            // ==================================================
                            // PASSWORD TIP
                            // ==================================================
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: teal,
                                  size: 16,
                                ),

                                const SizedBox(width: 7),

                                Expanded(
                                  child: Text(
                                    "Use a password you can remember but others cannot guess.",
                                    style: GoogleFonts.poppins(
                                      color: textSecondary,
                                      fontSize: 9.8,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // ==================================================
                            // SAVE BUTTON
                            // ==================================================
                            Obx(
                              () => SizedBox(
                                width: double.infinity,
                                height: 48,

                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () {
                                          controller.resetPassword();
                                        },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: navy,
                                    disabledBackgroundColor: navy.withOpacity(
                                      0.5,
                                    ),
                                    foregroundColor: Colors.white,
                                    elevation: 0,

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),

                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          width: 19,
                                          height: 19,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Save & Login",
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),

                                            const SizedBox(width: 7),

                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 17,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // FOOTER
                      // ==================================================
                      //
                      // Spacer() was removed here.
                      // Spacer inside a Column causes the overflow when
                      // the keyboard reduces the available height.
                      //
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: teal,
                            size: 14,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            "Your password is kept secure",
                            style: GoogleFonts.poppins(
                              color: textSecondary,
                              fontSize: 9.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Text(
                        "Learn • Speak • Grow",
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================================
        // LABEL
        // ==========================================================
        Text(
          label,
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        // ==========================================================
        // TEXT FIELD
        // ==========================================================
        SizedBox(
          height: 47,

          child: TextField(
            controller: controller,

            // Important for keyboard scrolling.
            scrollPadding: const EdgeInsets.only(bottom: 140),

            obscureText: true,

            style: GoogleFonts.poppins(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),

            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: navy, size: 19),

              hintText: hint,

              hintStyle: GoogleFonts.poppins(
                color: textSecondary.withOpacity(0.65),
                fontSize: 11.5,
              ),

              filled: true,
              fillColor: surfaceSoft,

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: border),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: navy, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
