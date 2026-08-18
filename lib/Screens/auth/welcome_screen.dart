import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Screens/auth/signin_screen.dart';
import 'signup_screen1.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E1E1E),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
          child: Column(
            // Changed from MainAxisAlignment.end to start so we can control spacing manually
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TEXT AT THE TOP
              const SizedBox(height: 20), // Little padding from top status bar
              Center(
                child: const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Start your journey to speak english and hindi confidently.",
                  textAlign: TextAlign.center, // Centered text looks better
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),

              // 2. SPACER PUSHES EVERYTHING ELSE DOWN
              const Spacer(),

              // 3. IMAGE IN THE MIDDLE (Optional, removed spacer if you want image top too)
              Center(
                child: Image.asset("assets/images/logo4x.png", height: 240),
              ),

              const Spacer(), // Pushes buttons to the bottom
              // 4. BUTTONS AT THE BOTTOM
              // Sign In Button
              _buildButton(
                context,
                "Sign In",
                const Color(0xFF158DFE),
                Colors.white,
                () => Get.to(() => const LoginScreen()),
              ),

              const SizedBox(height: 16),

              // Sign Up Button (Outlined)
              _buildButton(
                context,
                "Create Account",
                Colors.transparent,
                Colors.white,
                () => Get.to(() => const SignupStep1()),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color bg,
    Color textCol,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  color: textCol,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  color: textCol,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
