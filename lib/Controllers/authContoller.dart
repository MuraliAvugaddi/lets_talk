import 'dart:async';
import 'dart:convert';
import 'dart:io' as IO;
import 'dart:ui';

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
import 'package:lets_talk/services/class_reminder.dart'; // ⏰ class reminders
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:smart_auth/smart_auth.dart'; // 📩 Android: read the OTP SMS automatically


enum OtpFlowType { registration, forgotPassword }

class AuthController extends GetxController {
// 🔕 "Access Synchronized" spam guard: admin saves can send several updates in a row
// and old sockets used to stack listeners → the same popup 3–5 times.
Timer? _permDebounce;
Timer? _noticePoll; // 📢 manager notice: safety check every 30 s if a live message is missed
Timer? _noticeDebounce;
DateTime? _selfUpdateAt; // student changed their own timing → no popup for it
DateTime? _lastSyncPopupAt;

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

final box = GetStorage();
IO.Socket? socket;

var isLoading = false.obs;
// 🔐 Phone OTP by SMS (MSG91, sent by our server — no Firebase)
var otpToken = ''; // proof from /api/otp/verify, used once for register / reset
var otpPhone = ''; // 10-digit number the code was sent to
var resendIn = 0.obs; // seconds until "Resend code" is allowed
Timer? _resendTimer;
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
// ⏰ Class reminders follow the student's timings automatically:
// login → set, admin changes timing → updated, logout (userData = {}) → removed
ever(userData, (_) => ClassReminder.sync(userData));
ClassReminder.sync(userData);
if (box.hasData('user')) {
userData.value = box.read('user');
initSocket();
refreshProfile(); // Sync latest state on cold start
}
}

@override
void onClose() {
_resendTimer?.cancel();
cancelOtpAutoRead();
_permDebounce?.cancel();
_noticePoll?.cancel();
_noticeDebounce?.cancel();
socket?.clearListeners();
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
_permDebounce?.cancel();
_noticePoll?.cancel();
_noticeDebounce?.cancel();
adminMessage.value = null;
isMessageVisible.value = false;
socket?.clearListeners();
socket?.disconnect();
socket?.dispose();
socket = null;
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

// Remove the OLD socket and ALL its listeners first. Without this every login /
// app start added one more 'permissions_updated' listener → popup shown many times.
socket?.clearListeners();
socket?.disconnect();
socket?.dispose();

socket = IO.io(
  ApiEndpoints.socketUrl,
  IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': box.read('token') ?? ''})
      .enableForceNew() // fresh socket, never a cached one that still has old listeners
      .enableAutoConnect()
      .build(),
);

socket!.connect();

socket!.onConnect((_) {
  debugPrint("🔌 Student connected to Socket.io server");
  socket!.emit('join_user_room', userId.toString());
  fetchNotice(); // anything posted while we were offline
});

socket!.onReconnect((_) {
  debugPrint("🔄 Reconnected to Socket.io server");
  socket!.emit('join_user_room', userId.toString());
  fetchNotice();
});

_noticePoll?.cancel();
// notices arrive LIVE by socket; this is only a safety net (30 s × 2,500 phones was 80 requests/second)
_noticePoll = Timer.periodic(const Duration(minutes: 3), (_) => fetchNotice());

// ⚡ LIVE PERMISSION & MODE UPDATE FROM ADMIN
// Several updates within 1.5 s (admin saving access + timing + section) → ONE refresh.
socket!.on('permissions_updated', (data) {
  debugPrint("⚡ Real-time permission update received");
  _permDebounce?.cancel();
  _permDebounce = Timer(const Duration(milliseconds: 1500), _applyPermissionUpdate);
});

// 📢 Manager notice — LIVE. Show it at once from the message, then confirm with the server.
socket!.on('new_notification', (data) {
  if (data is Map) applyNotice(Map<String, dynamic>.from(data));
  _noticeDebounce?.cancel();
  _noticeDebounce = Timer(const Duration(milliseconds: 900), fetchNotice);
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
Get.offAll(() => const WelcomeScreen());
Get.snackbar(
'Logged Out',
reason,
backgroundColor: Colors.redAccent,
colorText: Colors.white,
duration: const Duration(seconds: 4),
);
}

String _tenDigits(String phone) {
final d = phone.replaceAll(RegExp(r'\D'), '');
return d.length > 10 ? d.substring(d.length - 10) : d;
}

String _serverMessage(http.Response res, String fallback) {
try {
final d = jsonDecode(res.body);
if (d is Map && d['message'] != null) return d['message'].toString();
} catch (_) {}
return fallback;
}

void _startResendCountdown(int seconds) {
_resendTimer?.cancel();
resendIn.value = seconds;
_resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
if (resendIn.value <= 1) {
resendIn.value = 0;
t.cancel();
} else {
resendIn.value--;
}
});
}

/// 📩 Ask OUR server to send a 6-digit code by SMS (MSG91).
/// openScreen=false → resend from the OTP screen (stay there).
Future<void> sendOtp({
required String rawPhone,
required OtpFlowType flowType,
bool openScreen = true,
}) async {
final phone = _tenDigits(rawPhone);
if (phone.length != 10) {
Get.snackbar("Invalid number", "Enter a valid 10-digit mobile number",
backgroundColor: Colors.redAccent, colorText: Colors.white);
return;
}
isLoading.value = true;
currentOtpFlow.value = flowType;
try {
final res = await http
.post(
Uri.parse("${ApiEndpoints.baseUrl}/otp/send"),
headers: {"Content-Type": "application/json"},
body: jsonEncode({
"phone": phone,
"purpose": flowType == OtpFlowType.registration ? "signup" : "reset",
}),
)
.timeout(const Duration(seconds: 20));
final data = jsonDecode(res.body);

if (res.statusCode == 200) {
otpPhone = phone;
otpToken = '';
otpController.clear();
_startResendCountdown(int.tryParse('${data['resendIn'] ?? 60}') ?? 60);
_listenForSmsCode(); // 📩 fills the boxes when the SMS arrives (Android)
if (openScreen) {
Get.to(() => OtpVerificationScreen(phoneNumber: _formatPhone(phone)));
} else {
Get.snackbar("Code sent", "A new code was sent to +91 $phone",
backgroundColor: Colors.green, colorText: Colors.white);
}
} else {
// 429 = wait before resending → keep the countdown right
if (data is Map && data['resendIn'] != null) {
_startResendCountdown(int.tryParse('${data['resendIn']}') ?? 60);
}
Get.snackbar("OTP not sent", _serverMessage(res, "Could not send the code. Try again."),
backgroundColor: Colors.redAccent, colorText: Colors.white);
}
} on TimeoutException {
Get.snackbar("Slow network", "Could not reach the server. Please try again.",
backgroundColor: Colors.redAccent, colorText: Colors.white);
} catch (e) {
Get.snackbar("Error", "Connection failed. Please try again.",
backgroundColor: Colors.redAccent, colorText: Colors.white);
} finally {
isLoading.value = false;
}
}

/// "Resend code" on the OTP screen
Future<void> resendOtp() async {
if (resendIn.value > 0 || isLoading.value || otpPhone.isEmpty) return;
await sendOtp(rawPhone: otpPhone, flowType: currentOtpFlow.value, openScreen: false);
}

/// ✅ Check the code with OUR server → otpToken
// ============================================================
// 📩 OTP AUTO-FILL
// Android: SMS User Consent API — when the SMS arrives, Android shows
//   "Allow Let's Speak to read this message?" → Allow → the code fills
//   the boxes and is verified automatically. No app hash needed in the SMS.
// iPhone: the code appears above the keyboard ("From Messages 123456") →
//   one tap fills it (autofillHints on the OTP boxes). Nothing to do here.
// ============================================================
bool _smsListening = false;

Future<void> _listenForSmsCode() async {
if (!IO.Platform.isAndroid) return;
cancelOtpAutoRead(); // a resend starts a fresh listener
_smsListening = true;
try {
final res = await SmartAuth.instance.getSmsWithUserConsentApi();
if (!_smsListening) return; // screen closed / verified meanwhile
_smsListening = false;
if (!res.hasData) return; // student tapped "Deny" → they can still type it
final raw = res.requireData.code ?? '';
final code = raw.replaceAll(RegExp(r'\D'), '');
if (code.length != 6) return;
otpController.text = code;
await verifyOtp(code);
} catch (e) {
_smsListening = false;
debugPrint('SMS auto-read error: $e');
}
}

void cancelOtpAutoRead() {
if (!_smsListening) return;
_smsListening = false;
try {
SmartAuth.instance.removeUserConsentApiListener();
} catch (_) {}
}

Future<void> verifyOtp(String code) async {
final otp = code.replaceAll(RegExp(r'\D'), '');
if (otp.length < 6) {
Get.snackbar("Invalid OTP", "Please enter the 6-digit code",
backgroundColor: Colors.redAccent, colorText: Colors.white);
return;
}
if (isLoading.value) return;
isLoading.value = true;
try {
final res = await http
.post(
Uri.parse("${ApiEndpoints.baseUrl}/otp/verify"),
headers: {"Content-Type": "application/json"},
body: jsonEncode({
"phone": otpPhone,
"purpose": currentOtpFlow.value == OtpFlowType.registration ? "signup" : "reset",
"otp": otp,
}),
)
.timeout(const Duration(seconds: 20));
final data = jsonDecode(res.body);
if (res.statusCode == 200 && (data['otpToken'] ?? '').toString().isNotEmpty) {
otpToken = data['otpToken'].toString();
cancelOtpAutoRead();
_resendTimer?.cancel();
resendIn.value = 0;
_handleOtpSuccess();
} else {
isLoading.value = false;
otpController.clear();
Get.snackbar("Verification Failed", _serverMessage(res, "Invalid code"),
backgroundColor: Colors.redAccent, colorText: Colors.white);
}
} on TimeoutException {
isLoading.value = false;
Get.snackbar("Slow network", "Could not reach the server. Please try again.",
backgroundColor: Colors.redAccent, colorText: Colors.white);
} catch (e) {
isLoading.value = false;
Get.snackbar("Error", "Connection failed. Please try again.",
backgroundColor: Colors.redAccent, colorText: Colors.white);
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
"otpToken": otpToken, // 🔐 proof that this phone number was verified
}),
);

  final data = jsonDecode(response.body);

  if (response.statusCode == 201) {
    box.write('token', data['token']);
    box.write('user', data['user']);
    userData.value = data['user'];

    initSocket();
    selectedBatch.value = '';
    otpToken = '';

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
  // 🔐 Proof of the OTP the user just verified (our server checks it)
  if (otpToken.isEmpty) {
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
      "otpToken": otpToken,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    otpToken = '';
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

// ==========================================
// LIVE UPDATE FROM ADMIN → refresh quietly, tell the student only what changed
// ==========================================
Future<void> _applyPermissionUpdate() async {
  final before = Map<String, dynamic>.from(userData);
  await refreshProfile(); // stage locks, timings, fee status update live on every screen
  final after = Map<String, dynamic>.from(userData);

  final msg = _changeMessage(before, after);
  if (msg == null) return; // nothing the student needs to know → no popup

  // never two popups close together
  final now = DateTime.now();
  if (_lastSyncPopupAt != null && now.difference(_lastSyncPopupAt!) < const Duration(seconds: 8)) return;
  _lastSyncPopupAt = now;

  if (Get.isSnackbarOpen) Get.closeAllSnackbars();
  Get.snackbar(
    msg.$1,
    msg.$2,
    backgroundColor: AppColors.teal,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    snackPosition: SnackPosition.BOTTOM,
  );
}

int _stagesOn(dynamic access) {
  if (access is! Map) return 0;
  return access.values.where((v) => v == true).length;
}

String _sig(dynamic v) => v == null ? '' : jsonEncode(v);

/// (title, message) for a change the student should see, or null to stay quiet
(String, String)? _changeMessage(Map<String, dynamic> b, Map<String, dynamic> a) {
  final stagesBefore = _stagesOn(b['englishAccess']) + _stagesOn(b['hindiAccess']);
  final stagesAfter = _stagesOn(a['englishAccess']) + _stagesOn(a['hindiAccess']);
  if (stagesAfter > stagesBefore) {
    return ("New stage unlocked 🎉", "Your new class is ready in the app.");
  }
  if (stagesAfter < stagesBefore || _sig(b['englishAccess']) != _sig(a['englishAccess']) ||
      _sig(b['hindiAccess']) != _sig(a['hindiAccess'])) {
    return ("Course access updated", "Your stages were updated by the institute.");
  }
  if ((b['feeStatus'] ?? '') != 'paid' && a['feeStatus'] == 'paid') {
    return ("Fee verified ✅", "Thank you! Your payment is confirmed.");
  }
  if ((b['mode'] ?? '') != (a['mode'] ?? '') && (a['mode'] ?? '').toString().isNotEmpty) {
    return ("Class mode changed", "You are now an ${a['mode']} student.");
  }
  final selfChange = _selfUpdateAt != null && DateTime.now().difference(_selfUpdateAt!) < const Duration(seconds: 20);
  final timingChanged = (b['batchTime'] ?? '') != (a['batchTime'] ?? '') ||
      _sig(b['englishBatch']) != _sig(a['englishBatch']) ||
      _sig(b['hindiBatch']) != _sig(a['hindiBatch']);
  if (timingChanged && !selfChange) {
    return ("Class timing updated", "The institute changed your class timing. Check your home screen.");
  }
  if ((b['onlineSection'] ?? '') != (a['onlineSection'] ?? '') && !selfChange) {
    return ("Section updated", "You are now in Section ${a['onlineSection']}.");
  }
  return null; // e.g. fee screenshot status, same data again → quiet
}

// ==========================================
// 📢 MANAGER NOTICE (one place for every screen)
// ==========================================
String get _myMode {
  final raw = (userData['mode'] ?? box.read('user')?['mode'] ?? 'online').toString().toLowerCase().trim();
  return raw == 'offline' ? 'offline' : 'online';
}

/// Gets the current notice for this student's mode (or "all") from the server.
Future<void> fetchNotice() async {
  if (box.read('token') == null && userData.isEmpty) return;
  try {
    final res = await http
        .get(Uri.parse('${ApiEndpoints.userNotification}?mode=$_myMode&_t=${DateTime.now().millisecondsSinceEpoch}'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map) applyNotice(Map<String, dynamic>.from(data));
    }
  } catch (e) {
    debugPrint('Notice fetch error: $e');
  }
}

/// Shows / hides the notice. A notice the student closed (X) stays closed
/// until the manager posts a NEW one.
void applyNotice(Map<String, dynamic> data) {
  final target = (data['targetMode'] ?? 'all').toString().toLowerCase().trim();
  if (target != _myMode && target != 'all') return; // for the other mode
  final msg = (data['message'] ?? '').toString().trim();
  if (data['hasNotification'] == true && msg.isNotEmpty) {
    adminMessage.value = msg;
    isMessageVisible.value = msg != (box.read('dismissed_notice') ?? '').toString();
  } else {
    adminMessage.value = null;
    isMessageVisible.value = false;
  }
}

/// X on the notice card
void dismissNotice() {
  final msg = adminMessage.value;
  if (msg != null) box.write('dismissed_notice', msg);
  isMessageVisible.value = false;
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
_selfUpdateAt = DateTime.now(); // the update echo from the server is the student's own change
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
Get.back();
Get.offAll(() => const WelcomeScreen());
},
);
}
}