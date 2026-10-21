import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

/// 📲 "A new version of Let's Speak is available — Update"
///
/// The admin sets the newest build in the admin app (Settings → App update).
/// On every app open / return to the app, this compares the phone's build
/// number (pubspec "1.0.1+6" → 6) with the server:
///   • older than latestBuild  → popup with "Update" + "Later" (asked again after 1 day)
///   • older than minimumBuild → popup WITHOUT "Later" — must update to continue
/// Works the same on Android (Play Store) and iPhone (App Store).
class AppUpdateChecker {
  AppUpdateChecker._();

  static const Duration _snooze = Duration(hours: 24);
  static const Duration _minGap = Duration(minutes: 30); // don't ask the server on every resume
  static DateTime? _lastCheck;
  static bool _showing = false;

  /// Call when the home screen opens and when the app comes back to the front.
  static Future<void> check({bool force = false}) async {
    if (kIsWeb || _showing) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final now = DateTime.now();
    if (!force && _lastCheck != null && now.difference(_lastCheck!) < _minGap) return;
    _lastCheck = now;

    try {
      final info = await PackageInfo.fromPlatform();
      final myBuild = int.tryParse(info.buildNumber) ?? 0;
      if (myBuild == 0) return;

      final res = await http
          .get(Uri.parse('${ApiEndpoints.baseUrl}/app-version?_t=${now.millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final p = data is Map ? data[Platform.isIOS ? 'ios' : 'android'] : null;
      if (p is! Map) return;

      final latest = int.tryParse('${p['latestBuild'] ?? 0}') ?? 0;
      final minimum = int.tryParse('${p['minimumBuild'] ?? 0}') ?? 0;
      if (latest <= myBuild) return; // up to date

      final mustUpdate = minimum > myBuild;
      final box = GetStorage();

      // "Later" pressed for THIS version less than a day ago → don't nag
      if (!mustUpdate) {
        final snoozedBuild = box.read('update_snoozed_build');
        final snoozedAt = DateTime.tryParse('${box.read('update_snoozed_at') ?? ''}');
        if (snoozedBuild == latest && snoozedAt != null && now.difference(snoozedAt) < _snooze) return;
      }

      await _showDialog(
        versionName: (p['versionName'] ?? '').toString(),
        currentVersion: info.version,
        notes: (p['notes'] ?? '').toString(),
        storeUrl: (p['storeUrl'] ?? '').toString(),
        mustUpdate: mustUpdate,
        onLater: () {
          box.write('update_snoozed_build', latest);
          box.write('update_snoozed_at', DateTime.now().toIso8601String());
        },
      );
    } catch (e) {
      debugPrint('App update check error: $e');
    }
  }

  static Future<void> _openStore(String url) async {
    final fallback = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=com.surendra.letsspeak'
        : '';
    final link = url.isNotEmpty ? url : fallback;
    if (link.isEmpty) return;
    try {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Open store error: $e');
    }
  }

  static Future<void> _showDialog({
    required String versionName,
    required String currentVersion,
    required String notes,
    required String storeUrl,
    required bool mustUpdate,
    required VoidCallback onLater,
  }) async {
    if (Get.context == null) return;
    _showing = true;
    final isDark = Get.isDarkMode;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final text = isDark ? AppColors.darkText : AppColors.text;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final store = Platform.isIOS ? 'App Store' : 'Play Store';

    try {
      await Get.dialog(
        PopScope(
          canPop: !mustUpdate, // must update → back button does nothing
          child: Dialog(
            backgroundColor: surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.deepNavy, AppColors.navy]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mustUpdate ? 'Update required' : 'New update available',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: text, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mustUpdate
                        ? 'This version of Let\'s Speak is no longer supported. Please update to continue your classes.'
                        : 'A new version of Let\'s Speak${versionName.isNotEmpty ? ' ($versionName)' : ''} is ready on the $store.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: secondary, fontSize: 12.5, height: 1.45),
                  ),
                  if (notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("What's new",
                              style: GoogleFonts.poppins(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 140),
                            child: SingleChildScrollView(
                              child: Text(notes,
                                  style: GoogleFonts.poppins(color: text, fontSize: 12, height: 1.45)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Your version: $currentVersion',
                    style: GoogleFonts.poppins(color: secondary.withValues(alpha: 0.8), fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _openStore(storeUrl), // dialog stays if they come back without updating
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text('Update now', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (!mustUpdate)
                    TextButton(
                      onPressed: () {
                        onLater();
                        Get.back();
                      },
                      child: Text('Later', style: GoogleFonts.poppins(color: secondary, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: !mustUpdate,
      );
    } finally {
      _showing = false;
    }
  }
}
