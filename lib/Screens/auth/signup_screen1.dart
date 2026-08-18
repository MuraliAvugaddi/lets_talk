import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';

class SignupStep1 extends GetView<AuthController> {
  const SignupStep1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff158DFE),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Step 1 of 2: Basic Details",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              Form(
                key: controller.signupFormKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller.nameController,
                      "Full Name",
                      Icons.person,
                      capitalization: TextCapitalization.words,
                      validator: (value) =>
                          value!.trim().isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller.phoneController,
                      "Phone Number (10 Digits)",
                      Icons.phone,
                      type: TextInputType.phone,
                      validator: (value) => value!.trim().length < 10
                          ? "Enter valid 10-digit number"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller.passwordController,
                      "Create Password",
                      Icons.lock,
                      isPass: true,
                      validator: (value) => value!.length < 6
                          ? "Password must be 6+ chars"
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => controller.submitStep1(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff158DFE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Next Step",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isPass = false,
    TextInputType type = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: type,
      textCapitalization: capitalization,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}