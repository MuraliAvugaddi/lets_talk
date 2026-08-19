import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:lets_talk/Screens/MainNavigationScreen.dart';
import 'package:lets_talk/Screens/auth/otp_verification_screen.dart';
import 'package:lets_talk/Screens/auth/reset_password_screen.dart';
import 'package:lets_talk/Screens/auth/signup_screen2.dart';
import 'package:lets_talk/Screens/auth/welcome_screen.dart';

enum OtpFlowType { registration, forgotPassword }

class AuthController extends GetxController {
  final signupFormKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final loginPhoneController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final forgotPhoneController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final otpController = TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final box = GetStorage();
  IO.Socket? socket;

  var isLoading = false.obs;
  var verificationId = ''.obs;
  int? resendToken;
  var currentOtpFlow = OtpFlowType.registration.obs;
  String selectedMode = "online";

  final String baseUrl = "http://192.168.1.4:5000/api";
  final String socketUrl = "http://192.168.1.4:5000";
  var userData = {}.obs;

  @override
  void onInit() {
    super.onInit();
    if (box.hasData('user')) {
      userData.value = box.read('user');
      initSocket();
    }
  }

  @override
  void onClose() {
    socket?.dispose();
    super.onClose();
  }

  String _formatPhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return "+91$clean";
    } else if (!clean.startsWith('+')) {
      return "+$clean";
    }
    return phone;
  }

  // ==========================================
  // REAL-TIME SOCKET & PERMISSION LISTENERS
  // ==========================================
  void initSocket() {
    final user = box.read('user');
    final String? userId = user != null ? (user['id'] ?? user['_id']) : null;
    if (userId == null) return;

    socket?.disconnect();

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      socket!.emit('join_user_room', userId.toString());
    });

    // ⚡ LIVE PERMISSION & MODE UPDATE FROM ADMIN
    socket!.on('permissions_updated', (data) {
      if (data is Map) {
        var current = Map<String, dynamic>.from(userData.value);
        if (data.containsKey('englishAccess')) {
          current['englishAccess'] = data['englishAccess'];
        }
        if (data.containsKey('hindiAccess')) {
          current['hindiAccess'] = data['hindiAccess'];
        }
        if (data.containsKey('mode')) {
          current['mode'] = data['mode']; // ⚡ Live updates Online/Offline mode
        }

        // Force reactive update across all screens immediately
        userData.value = current;
        userData.refresh();
        box.write('user', current);

        Get.snackbar(
          "Profile Updated",
          "Your access permissions & mode have been updated live!",
          backgroundColor: const Color(0xff7F56D9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });

    // 🛑 SINGLE DEVICE KICK LOGOUT
    socket!.on('force_logout', (data) {
      String reason = "Logged in from another device";
      if (data is Map && data['message'] != null) {
        reason = data['message'];
      }
      forceLogout(reason);
    });
  }

  void handleApiResponse(http.Response response) {
    if (response.statusCode == 401) {
      try {
        final data = jsonDecode(response.body);
        if (data['code'] == 'SESSION_EXPIRED' || data['message'] != null) {
          forceLogout(data['message'] ?? 'Logged in from another device');
          return;
        }
      } catch (_) {}
      forceLogout('Session expired. Please log in again.');
    }
  }

  void forceLogout(String reason) async {
    socket?.disconnect();
    await _firebaseAuth.signOut();
    box.erase();
    userData.value = {};
    Get.offAll(() => const WelcomeScreen());
    Get.snackbar(
      'Logged Out',
      reason,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // ==========================================
  // FIREBASE PHONE OTP SEND & VERIFY
  // ==========================================
  Future<void> sendOtp({
    required String rawPhone,
    required OtpFlowType flowType,
  }) async {
    isLoading.value = true;
    currentOtpFlow.value = flowType;
    String formattedPhone = _formatPhone(rawPhone);

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
          _handleOtpSuccess();
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          Get.snackbar(
            "OTP Failed",
            e.message ?? "Verification failed",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        },
        codeSent: (String verId, int? resendTok) {
          isLoading.value = false;
          verificationId.value = verId;
          resendToken = resendTok;
          Get.to(() => OtpVerificationScreen(phoneNumber: formattedPhone));
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> verifyOtp(String code) async {
    if (code.length < 6) {
      Get.snackbar(
        "Invalid OTP",
        "Please enter 6-digit code",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: code,
      );

      UserCredential userCred = await _firebaseAuth.signInWithCredential(
        credential,
      );
      if (userCred.user != null) {
        _handleOtpSuccess();
      }
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Verification Failed",
        e.message ?? "Invalid Code",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _handleOtpSuccess() {
    isLoading.value = false;
    otpController.clear();

    if (currentOtpFlow.value == OtpFlowType.registration) {
      _executeBackendRegistration();
    } else {
      Get.off(() => const ResetPasswordScreen());
    }
  }

  // ==========================================
  // SIGNUP & LOGIN
  // ==========================================
  void submitStep1() {
    if (signupFormKey.currentState!.validate()) {
      Get.to(() => const SignupStep2());
    } else {
      Get.snackbar(
        "Error",
        "Please fix errors",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void initiateSignupOtp(String mode) {
    selectedMode = mode;
    sendOtp(
      rawPhone: phoneController.text.trim(),
      flowType: OtpFlowType.registration,
    );
  }

  Future<void> _executeBackendRegistration() async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "phone": phoneController.text.trim(),
          "password": passwordController.text,
          "mode": selectedMode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        box.write('token', data['token']);
        box.write('user', data['user']);
        userData.value = data['user'];

        initSocket();

        Get.offAll(() => const MainNavigationScreen());
        Get.snackbar(
          "Success",
          "Account created successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Failed",
          data['message'] ?? "Error",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Connection failed",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginUser() async {
    if (loginPhoneController.text.isEmpty ||
        loginPasswordController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter phone and password",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": loginPhoneController.text.trim(),
          "password": loginPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        box.write('token', data['token']);
        box.write('user', data['user']);
        userData.value = data['user'];

        initSocket();

        Get.offAll(() => const MainNavigationScreen());
        Get.snackbar(
          "Success",
          "Welcome back!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        loginPhoneController.clear();
        loginPasswordController.clear();
      } else {
        Get.snackbar(
          "Login Failed",
          data['message'] ?? "Invalid credentials",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Connection failed. Check Server/IP.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void startForgotPassword() {
    if (forgotPhoneController.text.trim().length < 10) {
      Get.snackbar(
        "Error",
        "Enter a valid 10-digit phone number",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    sendOtp(
      rawPhone: forgotPhoneController.text.trim(),
      flowType: OtpFlowType.forgotPassword,
    );
  }

  Future<void> resetPassword() async {
    if (newPasswordController.text.length < 6) {
      Get.snackbar(
        "Error",
        "Password must be 6+ characters",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar(
        "Error",
        "Passwords do not match",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": forgotPhoneController.text.trim(),
          "newPassword": newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.offAll(() => const WelcomeScreen());
        Get.snackbar(
          "Success",
          "Password updated! Please login.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        newPasswordController.clear();
        confirmPasswordController.clear();
        forgotPhoneController.clear();
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Reset failed",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Connection failed",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    String? token = box.read('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userData.value = data;
        userData.refresh();
        box.write('user', data);
      } else {
        handleApiResponse(response);
      }
    } catch (e) {
      print("Background refresh failed: $e");
    }
  }

  void logout() {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Are you sure you want to logout?",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      backgroundColor: const Color(0xff1E1E1E),
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      onConfirm: () async {
        socket?.disconnect();
        await _firebaseAuth.signOut();
        box.erase();
        userData.value = {};
        Get.back();
        Get.offAll(() => const WelcomeScreen());
      },
    );
  }
}