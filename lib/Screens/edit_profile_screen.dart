// =========================================================================
// ✏️ EDIT PROFILE — student changes own photo, name and phone number
//
//   Photo  → POST   /user/profile-photo  (multipart "photo")  / DELETE to remove
//   Name   → PUT    /user/profile        { name }
//   Phone  → POST   /otp/send   { phone: NEW, purpose: "change" }
//            POST   /otp/verify { phone: NEW, purpose: "change", otp } → otpToken
//            POST   /user/change-phone { otpToken }
//   Online / offline is shown but can NOT be changed here (only the institute).
// =========================================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/apis/api_headers.dart';

String _msg(http.Response r, String fallback) {
  try {
    final d = jsonDecode(r.body);
    if (d is Map && (d['message'] ?? d['error']) != null) return (d['message'] ?? d['error']).toString();
  } catch (_) {}
  return fallback;
}

String _ten(String p) {
  final d = p.replaceAll(RegExp(r'\D'), '');
  return d.length > 10 ? d.substring(d.length - 10) : d;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final auth = Get.find<AuthController>();
  final box = GetStorage();
  late final TextEditingController _name;
  bool _savingName = false;
  bool _photoBusy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: (auth.userData['name'] ?? '').toString());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// put the fresh user from the server into the app (all screens update)
  void _apply(dynamic user) {
    if (user is! Map) return;
    final updated = Map<String, dynamic>.from(auth.userData)..addAll(Map<String, dynamic>.from(user));
    auth.userData.value = updated;
    auth.userData.refresh();
    box.write('user', updated);
  }

  void _toast(String title, String text, {bool error = false}) {
    Get.snackbar(title, text,
        backgroundColor: error ? AppColors.error : AppColors.teal,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12));
  }

  // ---------------- PHOTO ----------------
  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final XFile? img = await ImagePicker().pickImage(source: src, imageQuality: 80, maxWidth: 900, maxHeight: 900);
      if (img == null) return;
      setState(() => _photoBusy = true);
      final bytes = await img.readAsBytes();
      final req = http.MultipartRequest('POST', Uri.parse('${ApiEndpoints.baseUrl}/user/profile-photo'))
        ..headers.addAll(ApiHeaders.auth())
        ..files.add(http.MultipartFile.fromBytes('photo', bytes, filename: 'profile.jpg'));
      final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
      if (res.statusCode == 200) {
        _apply(jsonDecode(res.body)['user']);
        _toast('Photo updated', 'Your new photo is saved ✅');
      } else {
        _toast('Not saved', _msg(res, 'Could not upload the photo'), error: true);
      }
    } catch (_) {
      _toast('Not saved', 'Could not upload the photo. Check internet.', error: true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _photoBusy = true);
    try {
      final res = await http
          .delete(Uri.parse('${ApiEndpoints.baseUrl}/user/profile-photo'), headers: ApiHeaders.auth())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        _apply(jsonDecode(res.body)['user']);
        _toast('Photo removed', 'Your photo was removed');
      } else {
        _toast('Error', _msg(res, 'Could not remove the photo'), error: true);
      }
    } catch (_) {
      _toast('Error', 'Check internet and try again', error: true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _photoMenu(bool hasPhoto) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.teal),
                title: Text('Take a photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.navy),
                title: Text('Choose from gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text('Remove photo',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- NAME ----------------
  Future<void> _saveName() async {
    final name = _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.length < 2) return _toast('Name', 'Please enter your full name', error: true);
    if (name == (auth.userData['name'] ?? '').toString()) return _toast('Name', 'No change to save');
    FocusScope.of(context).unfocus();
    setState(() => _savingName = true);
    try {
      final res = await http
          .put(Uri.parse('${ApiEndpoints.baseUrl}/user/profile'),
              headers: ApiHeaders.json(), body: jsonEncode({'name': name}))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        _apply(jsonDecode(res.body)['user']);
        _toast('Name updated', 'Saved ✅');
      } else {
        _toast('Not saved', _msg(res, 'Could not save the name'), error: true);
      }
    } catch (_) {
      _toast('Not saved', 'Check internet and try again', error: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  // ---------------- PHONE (with OTP) ----------------
  Future<void> _changePhone() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePhoneSheet(oldPhone: _ten((auth.userData['phone'] ?? '').toString()), onUser: _apply),
    );
    if (ok == true) _toast('Phone changed', 'Use your new number to log in from now ✅');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final card = isDark ? AppColors.darkSurface : AppColors.surface;
    final line = isDark ? AppColors.darkBorder : AppColors.border;
    final text = isDark ? AppColors.darkText : AppColors.text;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    Widget section(String title, Widget child) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: sub)),
              const SizedBox(height: 10),
              child,
            ],
          ),
        );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: Text('Edit profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Obx(() {
        final u = auth.userData;
        final name = (u['name'] ?? '').toString();
        final phone = _ten((u['phone'] ?? '').toString());
        final photo = (u['photoUrl'] ?? '').toString();
        final isOnline = (u['mode'] ?? 'online').toString().toLowerCase() == 'online';
        final initials = name
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
          children: [
            // ---- photo ----
            Center(
              child: GestureDetector(
                onTap: _photoBusy ? null : () => _photoMenu(photo.isNotEmpty),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppColors.teal, AppColors.yellow]),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: _photoBusy
                              ? const CircularProgressIndicator(strokeWidth: 2.5)
                              : photo.isNotEmpty
                                  ? Image.network(photo,
                                      width: 112,
                                      height: 112,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _initials(initials))
                                  : _initials(initials),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Tap the photo to change it', style: GoogleFonts.poppins(fontSize: 11.5, color: sub)),
            ),
            const SizedBox(height: 20),

            // ---- name ----
            section(
              'Full name',
              Column(
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 60,
                    style: GoogleFonts.poppins(fontSize: 15, color: text, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.teal),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: line)),
                      enabledBorder:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: line)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _savingName ? null : _saveName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      child: _savingName
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Save name', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            // ---- phone ----
            section(
              'Phone number',
              Row(
                children: [
                  const Icon(Icons.phone_rounded, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phone.isEmpty ? '—' : '+91 $phone',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                        Text('OTP is sent to the new number', style: GoogleFonts.poppins(fontSize: 11, color: sub)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _changePhone,
                    child: Text('Change', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ),
                ],
              ),
            ),

            // ---- mode (read only) ----
            section(
              'Class type',
              Row(
                children: [
                  Icon(isOnline ? Icons.wifi_rounded : Icons.location_on_rounded,
                      color: isOnline ? AppColors.teal : AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isOnline ? 'Online student' : 'Offline student',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                        Text('Only the institute can change this', style: GoogleFonts.poppins(fontSize: 11, color: sub)),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded, color: sub, size: 20),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _initials(String i) => Text(
        i.isEmpty ? 'U' : i,
        style: GoogleFonts.poppins(color: AppColors.navy, fontSize: i.length > 1 ? 36 : 42, fontWeight: FontWeight.w800),
      );
}

// =========================================================================
// CHANGE PHONE: step 1 new number → step 2 OTP → saved
// =========================================================================
class _ChangePhoneSheet extends StatefulWidget {
  final String oldPhone;
  final void Function(dynamic user) onUser;
  const _ChangePhoneSheet({required this.oldPhone, required this.onUser});

  @override
  State<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<_ChangePhoneSheet> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpStep = false;
  bool _busy = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _countdown(int s) {
    _timer?.cancel();
    setState(() => _resendIn = s);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) t.cancel();
    });
  }

  Future<void> _send() async {
    final p = _ten(_phone.text);
    if (p.length != 10) return setState(() => _error = 'Enter a valid 10-digit mobile number');
    if (p == widget.oldPhone) return setState(() => _error = 'This is already your number');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await http
          .post(Uri.parse('${ApiEndpoints.baseUrl}/otp/send'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone': p, 'purpose': 'change'}))
          .timeout(const Duration(seconds: 20));
      final d = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _otp.clear();
        setState(() => _otpStep = true);
        _countdown(int.tryParse('${d['resendIn'] ?? 60}') ?? 60);
      } else {
        if (d is Map && d['resendIn'] != null) _countdown(int.tryParse('${d['resendIn']}') ?? 60);
        setState(() => _error = _msg(res, 'Could not send the code. Try again.'));
      }
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final p = _ten(_phone.text);
    final code = _otp.text.replaceAll(RegExp(r'\D'), '');
    if (code.length < 6) return setState(() => _error = 'Enter the 6-digit code');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final v = await http
          .post(Uri.parse('${ApiEndpoints.baseUrl}/otp/verify'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': p, 'purpose': 'change', 'otp': code}))
          .timeout(const Duration(seconds: 20));
      final vd = jsonDecode(v.body);
      final token = (vd is Map ? vd['otpToken'] : null)?.toString() ?? '';
      if (v.statusCode != 200 || token.isEmpty) {
        _otp.clear();
        setState(() => _error = _msg(v, 'Wrong code. Try again.'));
        return;
      }
      final c = await http
          .post(Uri.parse('${ApiEndpoints.baseUrl}/user/change-phone'),
              headers: ApiHeaders.json(), body: jsonEncode({'otpToken': token}))
          .timeout(const Duration(seconds: 20));
      if (c.statusCode == 200) {
        widget.onUser(jsonDecode(c.body)['user']);
        if (mounted) Navigator.pop(context, true);
        return;
      }
      setState(() => _error = _msg(c, 'Could not change the number'));
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final line = isDark ? AppColors.darkBorder : AppColors.border;
    final text = isDark ? AppColors.darkText : AppColors.text;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    InputDecoration deco(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          counterText: '',
          prefixIcon: Icon(icon, color: AppColors.teal),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 16),
                Text(_otpStep ? 'Enter the code' : 'Change phone number',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
                const SizedBox(height: 4),
                Text(
                  _otpStep
                      ? 'We sent a 6-digit code to +91 ${_ten(_phone.text)}'
                      : 'We will send a code to the new number to check it is yours.',
                  style: GoogleFonts.poppins(fontSize: 12, color: sub),
                ),
                const SizedBox(height: 16),
                if (!_otpStep)
                  TextField(
                    controller: _phone,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: text, letterSpacing: 1),
                    decoration: deco('New mobile number', Icons.phone_iphone_rounded),
                  )
                else ...[
                  TextField(
                    controller: _otp,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.length == 6 && !_busy) _verify();
                    },
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: 8),
                    decoration: deco('••••••', Icons.lock_outline_rounded),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _otpStep = false;
                                  _error = null;
                                }),
                        child: Text('Change number', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navy)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _resendIn > 0 || _busy ? null : _send,
                        child: Text(_resendIn > 0 ? 'Resend in ${_resendIn}s' : 'Resend code',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _busy ? null : (_otpStep ? _verify : _send),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_otpStep ? 'Verify & change' : 'Send code',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
