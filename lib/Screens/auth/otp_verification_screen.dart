import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends GetView<AuthController> {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

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

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight, width: 1.2),
      ),
    );

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
            mainAxisSize: MainAxisSize.min, // <-- Fixed unbounded height bug
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: tealMist.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "VERIFICATION",
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
                "Verification Code",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  text: "We sent a 6-digit code to ",
                  style: GoogleFonts.poppins(color: textMuted, fontSize: 13.5),
                  children: [
                    TextSpan(
                      text: phoneNumber,
                      style: GoogleFonts.poppins(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // PIN Input View
              Center(
                child: Pinput(
                  length: 6,
                  controller: controller.otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: BoxDecoration(
                      color: pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: deepOceanBlue, width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: deepOceanBlue.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: BoxDecoration(
                      color: tealMist.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tealMist.withOpacity(0.5), width: 1.2),
                    ),
                  ),
                  onCompleted: (pin) => controller.verifyOtp(pin),
                ),
              ),

              const SizedBox(height: 36),

              // Verify Action Button wrapped cleanly to avoid layout evaluation loops
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.verifyOtp(controller.otpController.text.trim()),
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
                            "Verify & Continue",
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
}