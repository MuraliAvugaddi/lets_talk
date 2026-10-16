import 'dart:convert';
import 'dart:io' as IO;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Use standard http package
import 'package:lets_talk/Screens/MainNavigationScreen.dart';
import 'package:lets_talk/Screens/app_colors.dart'; // 🚀 Added missing AppColors import
import 'package:lets_talk/Screens/auth/otp_verification_screen.dart';
import 'package:lets_talk/Screens/auth/reset_password_screen.dart';
import 'package:lets_talk/Screens/auth/signup_batch_screen.dart';
import 'package:lets_talk/Screens/auth/signup_screen2.dart';
import 'package:lets_talk/Screens/auth/welcome_screen.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/apis/batch_slots.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


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
var selectedBatch = ''.obs; // canonical label, e.g. "05:30 AM - 07:00 AM"
var isSavingBatch = false.obs;

var userData = {}.obs;

var adminMessage = RxnString();
var isMessageVisible = false.obs;

@override
void onInit() {
super.onInit();
if (box.hasData('user')) {
userData.value = box.read('user');
initSocket();
refreshProfile(); // Sync latest state on cold start
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

void clearLocalUserData() {
socket?.disconnect();
box.erase();
userData.value = {};
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
  ApiEndpoints.socketUrl,
  IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': box.read('token') ?? ''})
      .enableAutoConnect()
      .build(),
);

socket!.connect();

socket!.onConnect((_) {
  debugPrint("🔌 Student connected to Socket.io server");
  socket!.emit('join_user_room', userId.toString());
});

socket!.onReconnect((_) {
  debugPrint("🔄 Reconnected to Socket.io server");
  socket!.emit('join_user_room', userId.toString());
});

// ⚡ LIVE PERMISSION & MODE UPDATE FROM ADMIN
socket!.on('permissions_updated', (data) async {
  debugPrint("⚡ Real-time permission update received from Admin");
  // Instantly pull fresh profile from backend so all stage locks update live
  await refreshProfile();

  Get.snackbar(
    "Access Synchronized",
    "Your institute permissions have been updated live!",
    backgroundColor: AppColors.teal,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    snackPosition: SnackPosition.BOTTOM,
  );
});

// 🚀 FIXED: Isolated real-time announcement listener
socket!.on('new_notification', (data) {
  if (data is Map) {
    // Resolve current student's mode
    final rawStudentMode =
        (userData['mode'] ?? box.read('user')?['mode'] ?? 'online')
            .toString()
            .toLowerCase()
            .trim();
    final String studentMode =
        (rawStudentMode == 'offline') ? 'offline' : 'online';

    // Check broadcast targetMode
    final String targetMode =
        (data['targetMode'] ?? 'all').toString().toLowerCase().trim();

    // Process only if the broadcast applies to this student's mode or "all"
    if (targetMode == studentMode || targetMode == 'all') {
      if (data['hasNotification'] == true &&
          data['message'] != null &&
          data['message'].toString().trim().isNotEmpty) {
        adminMessage.value = data['message'].toString();
        isMessageVisible.value = true;
      } else {
        adminMessage.value = null;
        isMessageVisible.value = false;
      }
    }
  }
});

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
clearLocalUserData();
await _firebaseAuth.signOut();
Get.offAll(() => const WelcomeScreen());
Get.snackbar(
'Logged Out',
reason,
backgroundColor: Colors.redAccent,
colorText: Colors.white,
duration: const Duration(seconds: 4),
);
}

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

// Step 2 → Step 3: remember the mode, then ask for the class timing
void initiateSignupOtp(String mode) {
selectedMode = mode;
Get.to(() => const SignupBatchScreen());
}

// Step 3 → OTP: timing chosen, verify the phone number
void confirmBatchAndSendOtp() {
if (BatchSlots.find(selectedBatch.value) == null) {
Get.snackbar(
"Choose a timing",
"Please select the batch you will attend.",
backgroundColor: Colors.redAccent,
colorText: Colors.white,
);
return;
}
sendOtp(
rawPhone: phoneController.text.trim(),
flowType: OtpFlowType.registration,
);
}

Future<void> _executeBackendRegistration() async {
isLoading.value = true;
try {
final response = await http.post(
Uri.parse(ApiEndpoints.register),
headers: {"Content-Type": "application/json"},
body: jsonEncode({
"name": nameController.text.trim(),
"phone": phoneController.text.trim(),
"password": passwordController.text,
"mode": selectedMode,
"batchTime": selectedBatch.value,
}),
);

  final data = jsonDecode(response.body);

  if (response.statusCode == 201) {
    box.write('token', data['token']);
    box.write('user', data['user']);
    userData.value = data['user'];

    initSocket();
    selectedBatch.value = '';

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
    Uri.parse(ApiEndpoints.login),
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
  // Proof of the OTP the user just verified — the server checks it with Firebase
  final String? idToken = await _firebaseAuth.currentUser?.getIdToken(true);
  if (idToken == null) {
    Get.snackbar(
      "Verification expired",
      "Please verify your phone number again.",
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
    return;
  }

  final response = await http.post(
    Uri.parse(ApiEndpoints.resetPassword),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "phone": forgotPhoneController.text.trim(),
      "newPassword": newPasswordController.text,
      "idToken": idToken,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    await _firebaseAuth.signOut();
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
    Uri.parse(ApiEndpoints.profile),
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
  debugPrint("Background refresh failed: $e");
}

}

// ==========================================
// CLASS TIMING (student changes own batch)
// ==========================================
/// language + stage → timing for that stage only (e.g. English stage2).
/// Without them → the default timing chosen at signup.
Future<bool> updateBatchTime(String batchLabel, {String? language, String? stage}) async {
final String? token = box.read('token');
if (token == null || BatchSlots.find(batchLabel) == null) return false;

isSavingBatch.value = true;
try {
  final response = await http.put(
    Uri.parse("${ApiEndpoints.baseUrl}/user/batch-time"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "batchTime": batchLabel,
      if (stage != null) "stage": stage,
      if (language != null) "language": language,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final updated = Map<String, dynamic>.from(userData);
    updated['batchTime'] = data['batchTime'] ?? updated['batchTime'];
    if (data['englishBatch'] != null) updated['englishBatch'] = data['englishBatch'];
    if (data['hindiBatch'] != null) updated['hindiBatch'] = data['hindiBatch'];
    userData.value = updated;
    userData.refresh();
    box.write('user', updated);

    Get.snackbar(
      "Timing Updated",
      "Your class timing is now ${BatchSlots.shortOf(batchLabel)}.",
      backgroundColor: AppColors.teal,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    return true;
  }

  handleApiResponse(response);
  String msg = "Could not update timing. Please try again.";
  try {
    final data = jsonDecode(response.body);
    if (data is Map && data['message'] != null) msg = data['message'].toString();
  } catch (_) {}
  Get.snackbar("Error", msg, backgroundColor: Colors.redAccent, colorText: Colors.white);
  return false;
} catch (e) {
  Get.snackbar(
    "Error",
    "Connection failed",
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
  );
  return false;
} finally {
  isSavingBatch.value = false;
}
}

Future<void> deleteAccount() async {
final user = box.read('user');
final String? userId = user != null ? (user['id'] ?? user['_id']) : null;
String? token = box.read('token');
if (userId == null || token == null) return;

Get.defaultDialog(
  title: "Delete Account",
  titleStyle: GoogleFonts.poppins(
    color: Colors.redAccent,
    fontWeight: FontWeight.bold,
  ),
  middleText:
      "Are you sure you want to permanently delete your account? This action cannot be undone.",
  middleTextStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
  backgroundColor: const Color(0xff14141E),
  radius: 16,
  textConfirm: "Delete Forever",
  textCancel: "Cancel",
  confirmTextColor: Colors.white,
  buttonColor: Colors.redAccent,
  onConfirm: () async {
    Get.back();
    isLoading.value = true;
    try {
      final response = await http.delete(
        Uri.parse("${ApiEndpoints.baseUrl}/users/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        clearLocalUserData();
        await _firebaseAuth.signOut();
        Get.offAll(() => const WelcomeScreen());
        Get.snackbar(
          "Account Deleted",
          "Your account has been deleted permanently.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Error",
          "Could not delete account. Please try again.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Connection failed: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  },
);

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
clearLocalUserData();
await _firebaseAuth.signOut();
Get.back();
Get.offAll(() => const WelcomeScreen());
},
);
}
}

