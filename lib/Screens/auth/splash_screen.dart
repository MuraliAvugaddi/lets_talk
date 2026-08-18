import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lets_talk/Screens/MainNavigationScreen.dart'; // Ensure this path is correct
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
      backgroundColor: const Color(0xff0D0D0D),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO CONTAINER ---
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff1E1E1E),
                  border: Border.all(color: const Color(0xff158DFE), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff158DFE).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                // ⬇️ UPDATED IMAGE PATH HERE
                child: Image.asset(
                  "assets/images/logo4x.png",
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "Let's Talk",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Master English & Hindi",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 50),

              const CircularProgressIndicator(color: Color(0xff158DFE)),
            ],
          ),
        ),
      ),
    );
  }
}
