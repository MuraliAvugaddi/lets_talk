import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/auth/forgot_password_screen.dart';
import 'package:lets_talk/Screens/auth/signup_screen1.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // ==============================================================
  // BRAND COLORS
  // ==============================================================

  static const Color navy = Color(0xFF155A88);
  static const Color deepNavy = Color(0xFF0E466D);
  static const Color blue = Color(0xFF2C6F9F);
  static const Color teal = Color(0xFF28C2C2);
  static const Color yellow = Color(0xFFF7DF55);
  static const Color periwinkle = Color(0xFF7CA4D8);

  // Light
  static const Color lightBackground = Color(0xFFE8F2F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSoft = Color(0xFFF4F9FC);
  static const Color lightBorder = Color(0xFFD5E5EE);
  static const Color lightText = Color(0xFF173A52);
  static const Color lightSecondary = Color(0xFF678196);

  // Dark
  static const Color darkBackground = Color(0xFF08141D);
  static const Color darkSurface = Color(0xFF102330);
  static const Color darkSoft = Color(0xFF153247);
  static const Color darkBorder = Color(0xFF24465D);
  static const Color darkText = Color(0xFFF5FAFD);
  static const Color darkSecondary = Color(0xFFAEC1CE);

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    final RxBool obscurePassword = true.obs;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background = isDark ? darkBackground : lightBackground;

    final Color surface = isDark ? darkSurface : lightSurface;

    final Color soft = isDark ? darkSoft : lightSoft;

    final Color border = isDark ? darkBorder : lightBorder;

    final Color text = isDark ? darkText : lightText;

    final Color secondary = isDark ? darkSecondary : lightSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double height = constraints.maxHeight;
            final double width = constraints.maxWidth;

            final bool smallScreen = height < 680;
            final bool verySmallScreen = height < 610;

            final double horizontalPadding = width < 360 ? 17 : 21;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Stack(
                children: [
                  // ==================================================
                  // BACKGROUND DECORATION
                  // ==================================================
                  Positioned(
                    top: -70,
                    right: -60,
                    child: _circle(
                      size: 170,
                      color: teal,
                      opacity: isDark ? 0.06 : 0.08,
                    ),
                  ),

                  // ==================================================
                  // MAIN CONTENT
                  // ==================================================
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      smallScreen ? 10 : 14,
                      horizontalPadding,
                      10,
                    ),
                    child: Column(
                      children: [
                        // ============================================
                        // TOP BAR
                        // ============================================
                        SizedBox(
                          height: 42,
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Back button stays on the left
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _backButton(
                                  surface: surface,
                                  border: border,
                                  text: text,
                                ),
                              ),

                              // LET'S SPEAK stays exactly in the center
                              Align(
                                alignment: Alignment.center,
                                child: _brandBadge(
                                  surface: surface,
                                  border: border,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: verySmallScreen
                              ? 12
                              : smallScreen
                              ? 15
                              : 18,
                        ),

                        // ============================================
                        // TITLE
                        // ============================================
                        Text(
                          "Welcome back",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: smallScreen ? 24 : 27,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "Sign in to continue your learning journey.",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: secondary,
                            fontSize: smallScreen ? 11.5 : 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(
                          height: verySmallScreen
                              ? 13
                              : smallScreen
                              ? 16
                              : 19,
                        ),

                        // ============================================
                        // LOGIN CARD
                        // ============================================
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            verySmallScreen ? 14 : 16,
                            16,
                            verySmallScreen ? 14 : 16,
                          ),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: border),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.18)
                                    : navy.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --------------------------------------
                              // FORM HEADER
                              // --------------------------------------
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [navy, blue],
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      Icons.lock_open_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Account Login",
                                          style: GoogleFonts.poppins(
                                            color: text,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "Enter your registered details",
                                          style: GoogleFonts.poppins(
                                            color: secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Small brand accent
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: yellow,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: verySmallScreen ? 14 : 17),

                              // --------------------------------------
                              // PHONE
                              // --------------------------------------
                              _buildInput(
                                controller: controller.loginPhoneController,
                                label: "Phone Number",
                                hint: "10-digit phone number",
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                text: text,
                                secondary: secondary,
                                soft: soft,
                                border: border,
                                smallScreen: smallScreen,
                              ),

                              SizedBox(height: verySmallScreen ? 11 : 14),

                              // --------------------------------------
                              // PASSWORD
                              // --------------------------------------
                              Obx(
                                () => _buildInput(
                                  controller:
                                      controller.loginPasswordController,
                                  label: "Password",
                                  hint: "Enter your password",
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: obscurePassword.value,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      obscurePassword.toggle();
                                    },
                                    splashRadius: 18,
                                    icon: Icon(
                                      obscurePassword.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: secondary,
                                      size: 19,
                                    ),
                                  ),
                                  text: text,
                                  secondary: secondary,
                                  soft: soft,
                                  border: border,
                                  smallScreen: smallScreen,
                                ),
                              ),

                              // --------------------------------------
                              // FORGOT PASSWORD
                              // --------------------------------------
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Get.to(() => const ForgotPasswordScreen());
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 5,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.poppins(
                                      color: teal,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: verySmallScreen ? 7 : 10),

                              // --------------------------------------
                              // SIGN IN
                              // --------------------------------------
                              Obx(
                                () => SizedBox(
                                  width: double.infinity,
                                  height: smallScreen ? 47 : 49,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [deepNavy, navy, blue],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: navy.withOpacity(0.18),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : () => controller.loginUser(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        disabledBackgroundColor:
                                            Colors.transparent,
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: Colors.white,
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: controller.isLoading.value
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Sign In",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 25,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 15,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ============================================
                        // SECURITY
                        // ============================================
                        SizedBox(height: verySmallScreen ? 11 : 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: teal.withOpacity(isDark ? 0.07 : 0.06),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: teal.withOpacity(isDark ? 0.18 : 0.13),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: teal.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: teal,
                                  size: 16,
                                ),
                              ),

                              const SizedBox(width: 9),

                              Expanded(
                                child: Text(
                                  "Your account information is secure.",
                                  style: GoogleFonts.poppins(
                                    color: secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const Icon(
                                Icons.check_circle_rounded,
                                color: teal,
                                size: 16,
                              ),
                            ],
                          ),
                        ),

                        // ============================================
                        // CREATE ACCOUNT
                        // ============================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.poppins(
                                color: secondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(width: 5),

                            GestureDetector(
                              onTap: () {
                                Get.to(() => const SignupStep1());
                              },
                              child: Text(
                                "Create one",
                                style: GoogleFonts.poppins(
                                  color: teal,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ============================================
                        // FOOTER
                        // ============================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(teal),

                            const SizedBox(width: 6),

                            Text(
                              "Learn • Speak • Grow",
                              style: GoogleFonts.poppins(
                                color: secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),

                            const SizedBox(width: 6),

                            _dot(yellow),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==============================================================
  // BACK BUTTON
  // ==============================================================

  Widget _backButton({
    required Color surface,
    required Color border,
    required Color text,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: IconButton(
        onPressed: () => Get.back(),
        padding: EdgeInsets.zero,
        icon: Icon(Icons.arrow_back_rounded, color: text, size: 19),
      ),
    );
  }

  // ==============================================================
  // BRAND BADGE
  // ==============================================================

  Widget _brandBadge({required Color surface, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: yellow,
                size: 13,
              ),
            ),
          ),

          const SizedBox(width: 6),

          Text(
            "LET'S SPEAK",
            style: GoogleFonts.poppins(
              color: navy,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // INPUT FIELD
  // ==============================================================

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color text,
    required Color secondary,
    required Color soft,
    required Color border,
    required bool smallScreen,
    bool isPassword = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
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

        SizedBox(
          height: smallScreen ? 48 : 50,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              color: text,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: soft,

              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: secondary.withOpacity(0.65),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),

              prefixIcon: SizedBox(
                width: 44,
                child: Icon(icon, color: navy, size: 18),
              ),

              suffixIcon: suffixIcon,

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: border, width: 1),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: teal, width: 1.4),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // DECORATIVE CIRCLE
  // ==============================================================

  Widget _circle({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  // ==============================================================
  // FOOTER DOT
  // ==============================================================

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
