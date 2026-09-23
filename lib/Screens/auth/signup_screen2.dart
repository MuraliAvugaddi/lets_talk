import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class SignupStep2 extends GetView<AuthController> {
  const SignupStep2({super.key});

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
      resizeToAvoidBottomInset: true,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 54,

        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Material(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Get.back(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: text,
                size: 20,
              ),
            ),
          ),
        ),

        titleSpacing: 8,

        title: Text(
          "Create Account",
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==================================================
                    // HEADER ICON
                    // ==================================================
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.07),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: navy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: yellow,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // TITLE
                    // ==================================================
                    Text(
                      "How Will You Attend?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // ==================================================
                    // SUBTITLE
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Choose how you attend your classes to continue.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // SECTION TITLE
                    // ==================================================
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select your class mode",
                        style: GoogleFonts.poppins(
                          color: text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // ONLINE CARD
                    // ==================================================
                    _buildModeCard(
                      title: "I am an Online Student",
                      subtitle:
                          "I attend my classes online using the internet.",
                      icon: Icons.wifi_rounded,
                      accentColor: navy,
                      tag: "ONLINE",
                      onTap: () {
                        controller.initiateSignupOtp("online");
                      },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // OFFLINE CARD
                    // ==================================================
                    _buildModeCard(
                      title: "I am an Offline Student",
                      subtitle: "I attend my classes at the institute.",
                      icon: Icons.location_on_rounded,
                      accentColor: teal,
                      tag: "OFFLINE",
                      onTap: () {
                        controller.initiateSignupOtp("offline");
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // OTP INFORMATION
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ICON
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: navy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.sms_outlined,
                              color: navy,
                              size: 18,
                            ),
                          ),

                          const SizedBox(width: 10),

                          // TEXT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Phone Verification",
                                  style: GoogleFonts.poppins(
                                    color: text,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  "After selecting your class mode, "
                                  "we'll send an SMS OTP to verify "
                                  "your phone number.",
                                  style: GoogleFonts.poppins(
                                    color: textSecondary,
                                    fontSize: 9.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // LOADING
                    // ==================================================
                    Obx(() {
                      if (!controller.isLoading.value) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: navy,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Preparing your account...",
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // MODE CARD
  // ============================================================

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String tag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        splashColor: accentColor.withOpacity(0.08),
        highlightColor: accentColor.withOpacity(0.04),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: border, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 29),
              ),

              const SizedBox(width: 14),

              // ==================================================
              // CONTENT
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TAG
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          color: accentColor,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // TITLE
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // DESCRIPTION
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ==================================================
              // ARROW
              // ==================================================
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accentColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
