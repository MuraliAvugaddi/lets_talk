import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class SignupStep2 extends GetView<AuthController> {
  const SignupStep2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Select Mode"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                "How do you want to learn?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Choose your preferred class mode. An SMS OTP will be sent to verify your number.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Online Card
              _buildSelectionCard(
                context,
                title: "Online",
                subtitle: "Class via internet",
                icon: Icons.wifi,
                color: Colors.blueAccent,
                onTap: () => controller.initiateSignupOtp("online"),
              ),

              const SizedBox(height: 20),

              // Offline Card
              _buildSelectionCard(
                context,
                title: "Offline",
                subtitle: "Class on-site locally",
                icon: Icons.location_on_outlined,
                color: Colors.orangeAccent,
                onTap: () => controller.initiateSignupOtp("offline"),
              ),

              const SizedBox(height: 40),
              Obx(
                () => controller.isLoading.value
                    ? const CircularProgressIndicator(color: Color(0xff158DFE))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[700], size: 16),
          ],
        ),
      ),
    );
  }
}