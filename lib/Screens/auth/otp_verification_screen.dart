import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends GetView<AuthController> {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  // ============================================================
  // BRAND COLORS
  // ============================================================

  static const Color navy = Color(0xFF155A88);
  static const Color deepNavy = Color(0xFF0E466D);
  static const Color blue = Color(0xFF2C6F9F);
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

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
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
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 2,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 2,
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        color: navy,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: yellow,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "LET'S SPEAK",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // VERIFICATION ICON
                    // ==================================================
                    Container(
                      width: 62,
                      height: 62,
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
                          size: 26,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // TITLE
                    // ==================================================
                    Text(
                      "Verify Your Number",
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
                      "Enter the 6-digit code sent to your phone.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // PHONE NUMBER
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: navy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.phone_rounded,
                              color: navy,
                              size: 17,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "CODE SENT TO",
                                  style: GoogleFonts.poppins(
                                    color: textSecondary,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.7,
                                  ),
                                ),

                                const SizedBox(height: 1),

                                Text(
                                  phoneNumber,
                                  style: GoogleFonts.poppins(
                                    color: text,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: teal.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: teal,
                                  size: 12,
                                ),

                                const SizedBox(width: 3),

                                Text(
                                  "SENT",
                                  style: GoogleFonts.poppins(
                                    color: navy,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // OTP TITLE
                    // ==================================================
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Enter 6-digit code",
                        style: GoogleFonts.poppins(
                          color: text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    // ==================================================
                    // OTP
                    // ==================================================
                    Center(
                      child: Pinput(
                        length: 6,

                        controller: controller.otpController,

                        keyboardType: TextInputType.number,

                        autofocus: true,

                        scrollPadding: const EdgeInsets.only(bottom: 120),

                        defaultPinTheme: _defaultPinTheme(),

                        focusedPinTheme: _focusedPinTheme(),

                        submittedPinTheme: _submittedPinTheme(),

                        errorPinTheme: _errorPinTheme(),

                        onCompleted: (pin) {
                          controller.verifyOtp(pin);
                        },
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      "Please enter the code exactly as received.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 9.8,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // VERIFY BUTTON
                    // ==================================================
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  controller.verifyOtp(
                                    controller.otpController.text.trim(),
                                  );
                                },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            disabledBackgroundColor: navy.withOpacity(0.55),
                            foregroundColor: Colors.white,
                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 19,
                                  width: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Verify & Continue",
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

                    const SizedBox(height: 12),

                    // ==================================================
                    // SECURITY INFO
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: yellow.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: deepNavy,
                              size: 16,
                            ),
                          ),

                          const SizedBox(width: 9),

                          Expanded(
                            child: Text(
                              "Never share your verification code with anyone.",
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 9.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // FOOTER
                    // ==================================================
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: teal,
                          size: 13,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          "Learn • Speak • Grow",
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
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
  // DEFAULT PIN THEME
  // ============================================================

  PinTheme _defaultPinTheme() {
    return PinTheme(
      width: 43,
      height: 49,

      textStyle: GoogleFonts.poppins(
        color: text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border, width: 1.1),
      ),
    );
  }

  // ============================================================
  // FOCUSED PIN THEME
  // ============================================================

  PinTheme _focusedPinTheme() {
    return PinTheme(
      width: 43,
      height: 49,

      textStyle: GoogleFonts.poppins(
        color: navy,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),

        border: Border.all(color: navy, width: 1.6),

        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMITTED PIN THEME
  // ============================================================

  PinTheme _submittedPinTheme() {
    return PinTheme(
      width: 43,
      height: 49,

      textStyle: GoogleFonts.poppins(
        color: deepNavy,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),

      decoration: BoxDecoration(
        color: teal.withOpacity(0.07),
        borderRadius: BorderRadius.circular(11),

        border: Border.all(color: teal.withOpacity(0.55), width: 1.2),
      ),
    );
  }

  // ============================================================
  // ERROR PIN THEME
  // ============================================================

  PinTheme _errorPinTheme() {
    return PinTheme(
      width: 43,
      height: 49,

      textStyle: GoogleFonts.poppins(
        color: const Color(0xFFE45757),
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFE45757).withOpacity(0.05),
        borderRadius: BorderRadius.circular(11),

        border: Border.all(color: const Color(0xFFE45757), width: 1.4),
      ),
    );
  }
}
