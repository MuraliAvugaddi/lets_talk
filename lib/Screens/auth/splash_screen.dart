import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lets_talk/Screens/MainNavigationScreen.dart';
import 'package:lets_talk/Screens/auth/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final box = GetStorage();

  // --- BRAND COLORS ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color darkCanvas = const Color(0xff0A0A0E);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      _checkLoginAndNavigate();
    });
  }

  void _checkLoginAndNavigate() {
    bool hasToken = box.hasData('token');

    if (hasToken) {
      Get.offAll(() => const MainNavigationScreen());
    } else {
      Get.offAll(() => const WelcomeScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO CONTAINER WITH AMBIENT GLOW ---
                Container(
                  height: 130,
                  width: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff14141E),
                    border: Border.all(color: goldenYellow, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: deepOceanBlue.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Image.asset(
                    "assets/images/logo4x.png",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.school_rounded,
                      size: 54,
                      color: goldenYellow,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  "Let's Talk",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Master English & Hindi",
                  style: GoogleFonts.poppins(
                    color: tealMist,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 48),

                CircularProgressIndicator(
                  color: goldenYellow,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}