import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/auth/signin_screen.dart';
import 'signup_screen1.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- BRAND PALETTE ---
    final Color deepOceanBlue = const Color(0xff065381);
    final Color tealMist = const Color(0xff508F97);
    final Color goldenYellow = const Color(0xffF2C94C);
    final Color darkCanvas = const Color(0xff0A0A0E);

    return Scaffold(
      backgroundColor: darkCanvas,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              deepOceanBlue.withOpacity(0.35),
              darkCanvas,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // 1. APP / LOGO BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: tealMist.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tealMist.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: goldenYellow),
                      const SizedBox(width: 6),
                      Text(
                        "Language Learning Platform",
                        style: GoogleFonts.poppins(
                          color: goldenYellow,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. HEADLINE & SUBTITLE
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "Start your journey to speak English and Hindi with confidence.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                const Spacer(),

                // 3. LOGO IMAGE WITH SUBTLE AMBIENT GLOW
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: deepOceanBlue.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      "assets/images/logo4x.png",
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.school_rounded,
                        size: 110,
                        color: goldenYellow,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // 4. ACTION BUTTONS
                _buildButton(
                  text: "Sign In",
                  bg: deepOceanBlue,
                  textColor: Colors.white,
                  borderColor: tealMist.withOpacity(0.5),
                  onTap: () => Get.to(() => const LoginScreen()),
                ),

                const SizedBox(height: 12),

                _buildButton(
                  text: "Create Account",
                  bg: const Color(0xff14141E),
                  textColor: goldenYellow,
                  borderColor: goldenYellow.withOpacity(0.4),
                  isOutlined: true,
                  onTap: () => Get.to(() => const SignupStep1()),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color bg,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: bg,
                side: BorderSide(color: borderColor, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
    );
  }
}