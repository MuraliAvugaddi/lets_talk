import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lets_talk/Screens/auth/signin_screen.dart';
import 'signup_screen1.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color navy = Color(0xFF155A88);
  static const Color blue = Color(0xFF2C6F9F);
  static const Color teal = Color(0xFF28C2C2);
  static const Color yellow = Color(0xFFF7DF55);
  static const Color periwinkle = Color(0xFF7CA4D8);

  static const Color lightBackground = Color(0xFFF5FAFD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFDCEAF2);
  static const Color lightText = Color(0xFF173A52);
  static const Color lightSecondary = Color(0xFF6B8292);

  static const Color darkBackground = Color(0xFF08141D);
  static const Color darkSurface = Color(0xFF102330);
  static const Color darkBorder = Color(0xFF24465D);
  static const Color darkText = Color(0xFFF5FAFD);
  static const Color darkSecondary = Color(0xFFAEC1CE);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background = isDark ? darkBackground : lightBackground;
    final Color surface = isDark ? darkSurface : lightSurface;
    final Color border = isDark ? darkBorder : lightBorder;
    final Color text = isDark ? darkText : lightText;
    final Color secondary = isDark ? darkSecondary : lightSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxHeight < 700;
            final double horizontalPadding = constraints.maxWidth < 360
                ? 18
                : 24;
            final double logoSize = constraints.maxWidth < 360 ? 112 : 128;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 42,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: navy,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.record_voice_over_rounded,
                            color: yellow,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          "LET'S SPEAK",
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: compact ? 28 : 42),

                    Container(
                      width: logoSize,
                      height: logoSize,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(isDark ? 0.18 : 0.09),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Image.asset(
                          "assets/images/let's speak.png",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: navy,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.record_voice_over_rounded,
                                color: yellow,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: compact ? 22 : 28),

                    Text(
                      'Speak with confidence.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: compact ? 27 : 30,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(height: 8),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Learn ',
                            style: GoogleFonts.poppins(
                              color: secondary,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: 'English',
                            style: GoogleFonts.poppins(
                              color: navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' & ',
                            style: GoogleFonts.poppins(
                              color: secondary,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: 'Hindi',
                            style: GoogleFonts.poppins(
                              color: teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' with ease.',
                            style: GoogleFonts.poppins(
                              color: secondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: compact ? 24 : 30),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _benefit(
                              icon: Icons.menu_book_rounded,
                              title: 'Learn',
                              color: navy,
                              text: text,
                            ),
                          ),
                          _divider(border),
                          Expanded(
                            child: _benefit(
                              icon: Icons.mic_none_rounded,
                              title: 'Speak',
                              color: teal,
                              text: text,
                            ),
                          ),
                          _divider(border),
                          Expanded(
                            child: _benefit(
                              icon: Icons.trending_up_rounded,
                              title: 'Improve',
                              color: periwinkle,
                              text: text,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: compact ? 28 : 44),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(() => const LoginScreen());
                        },
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
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.to(() => const SignupStep1());
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: surface,
                          foregroundColor: navy,
                          elevation: 0,
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(
                          'Create New Account',
                          style: GoogleFonts.poppins(
                            color: navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(teal),
                        const SizedBox(width: 7),
                        Text(
                          'Learn • Speak • Grow',
                          style: GoogleFonts.poppins(
                            color: secondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 7),
                        _dot(yellow),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _benefit({
    required IconData icon,
    required String title,
    required Color color,
    required Color text,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: text,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Container(width: 1, height: 38, color: color);
  }

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
