import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      _checkLoginAndNavigate();
    });
  }

  void _checkLoginAndNavigate() {
    final bool hasToken = box.hasData('token');

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
    // 🚀 Force light theme colors regardless of system or app dark mode
    const Color background = Colors.white;
    const Color titleColor = Color(0xFF173A52);

    return Theme(
      data: ThemeData.light(), // Forces light mode theme data on children
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: background,
          statusBarIconBrightness:
              Brightness.dark, // Dark icons for light background
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/images/navy blue logo let's speak.png",
                      width: 170,
                      height: 170,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "Let's Speak With Surendra",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
