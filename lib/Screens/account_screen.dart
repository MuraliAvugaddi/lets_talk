import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/ThemeController.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/student_attendance_screen.dart';
import 'package:lets_talk/Screens/student_test_results_screen.dart';
import 'package:lets_talk/Screens/leaderboard_screen.dart';
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:lets_talk/apis/batch_slots.dart';
import 'package:url_launcher/url_launcher.dart';

/// One enabled stage and the timing the student attends it at
class _StageTiming {
  final String language; // "English" | "Hindi"
  final String stage; // "stage1".."stage7"
  final String title; // "English • Stage 1"
  final String timing; // canonical label or ""
  final bool own; // true = stage has its own timing, false = signup default

  const _StageTiming({
    required this.language,
    required this.stage,
    required this.title,
    required this.timing,
    required this.own,
  });
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthController controller = Get.find<AuthController>();

  // --- OFFICIAL CONTACT NUMBERS ---
  final String offlineManagerPhone = "7842941055";
  final String onlineManagerPhone = "7386172347";
  final String techSupportPhone = "9398315945";

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      Get.snackbar(
        "Error",
        "Could not dial $phoneNumber",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String message) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}",
    );
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        "Error",
        "Could not open WhatsApp for +91 $phoneNumber",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _launchCommunityLink(bool isOnline) async {
    final String link = isOnline
        ? "https://chat.whatsapp.com/KEb01Z5HqfOHkCFoztBFsX?mode=hqrc"
        : "https://chat.whatsapp.com/KEb01Z5HqfOHkCFoztBFsX?mode=hqrc";

    final Uri url = Uri.parse(link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        "Could Not Open",
        "Unable to launch WhatsApp Community link.",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _showFeedbackModal() {
    int selectedStars = 5;
    final feedbackController = TextEditingController();
    bool isSubmitting = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: AppColors.teal.withOpacity(0.3)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Student Feedback 💬",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.close_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tell us about your learning experience with Let's Speak.",
                    style: GoogleFonts.poppins(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.60),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedStars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.yellow,
                            size: 34,
                          ),
                          onPressed: () =>
                              setModalState(() => selectedStars = index + 1),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: "Write your feedback or review here...",
                      hintStyle: GoogleFonts.poppins(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.38),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSurface2
                          : AppColors.surfaceSoft,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.teal.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.yellow,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = feedbackController.text.trim();
                              if (text.isEmpty) {
                                Get.snackbar(
                                  "Missing Text",
                                  "Please write a few words.",
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final userData = controller.userData;
                                final response = await http.post(
                                  Uri.parse(ApiEndpoints.submitFeedback),
                                  headers: {
                                    "Content-Type": "application/json",
                                    if ((controller.box.read('token') ?? '').toString().isNotEmpty)
                                      "Authorization": "Bearer ${controller.box.read('token')}",
                                  },
                                  body: jsonEncode({
                                    "userId": userData['id'] ?? userData['_id'],
                                    "name": userData['name'] ?? "Student",
                                    "phone": userData['phone'] ?? "",
                                    "mode": userData['mode'] ?? "online",
                                    "rating": selectedStars,
                                    "comment": text,
                                  }),
                                );

                                if (response.statusCode == 201 ||
                                    response.statusCode == 200) {
                                  Get.back();
                                  Get.snackbar(
                                    "Thank You!",
                                    "Your feedback has been submitted to the management.",
                                    backgroundColor: AppColors.teal,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  Get.snackbar(
                                    "Notice",
                                    "Failed to submit. Try again later.",
                                    backgroundColor: AppColors.error,
                                    colorText: Colors.white,
                                  );
                                }
                              } catch (e) {
                                Get.snackbar(
                                  "Error",
                                  "Submission failed: $e",
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                );
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Submit Feedback",
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondaryText = textColor.withOpacity(0.62);
    final pageTop = isDark ? AppColors.darkBackground : const Color(0xFFDCEAF3);
    final pageBottom = isDark ? AppColors.darkSurface : const Color(0xFFC2D9E8);
    final heroTextColor = isDark ? AppColors.darkText : AppColors.text;
    final heroSecondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final card = theme.cardColor;

    return Scaffold(
      backgroundColor: pageTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Profile",
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              "Your Let's Speak account",
              style: GoogleFonts.poppins(
                color: secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        backgroundColor: card,
        onRefresh: () async => await controller.refreshProfile(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [pageTop, pageBottom],
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final name = (controller.userData['name'] ?? "User Name")
                      .toString();
                  final phone = (controller.userData['phone'] ?? "N/A")
                      .toString();
                  final mode = (controller.userData['mode'] ?? "online")
                      .toString();
                  final isOnline = mode.toLowerCase() == "online";

                  // ---- numbers for the quick-stats row ----
                  int stagesOn(dynamic m) => m is Map ? m.values.where((v) => v == true).length : 0;
                  final en = stagesOn(controller.userData['englishAccess']);
                  final hi = stagesOn(controller.userData['hindiAccess']);
                  final feePaid = (controller.userData['feeStatus'] ?? '').toString() == 'paid';
                  final joined = DateTime.tryParse((controller.userData['createdAt'] ?? '').toString())?.toLocal();
                  final initials = name
                      .trim()
                      .split(RegExp(r'\s+'))
                      .where((w) => w.isNotEmpty)
                      .take(2)
                      .map((w) => w[0].toUpperCase())
                      .join();

                  Widget stat(String value, String label, IconData icon) => Expanded(
                        child: Column(
                          children: [
                            Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
                            const SizedBox(height: 4),
                            Text(value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.1)),
                            Text(label,
                                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );

                  Widget chip(IconData icon, String text) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(text,
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                          ],
                        ),
                      );

                  // 🌟 Big, colourful profile card
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0E466D), Color(0xFF155A88), Color(0xFF1F9BA6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(isDark ? 0.35 : 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          // soft decorative circles
                          Positioned(
                            right: -40,
                            top: -40,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -50,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.yellow.withOpacity(0.10)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // avatar with teal → yellow ring
                                    Container(
                                      width: 82,
                                      height: 82,
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [AppColors.teal, AppColors.yellow],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                        alignment: Alignment.center,
                                        child: Text(
                                          initials.isEmpty ? "U" : initials,
                                          style: GoogleFonts.poppins(
                                            color: AppColors.navy,
                                            fontSize: initials.length > 1 ? 26 : 32,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hello 👋',
                                            style: GoogleFonts.poppins(
                                                color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              height: 1.15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.phone_rounded, size: 13, color: Colors.white.withOpacity(0.8)),
                                              const SizedBox(width: 4),
                                              Text(
                                                phone,
                                                style: GoogleFonts.poppins(
                                                    color: Colors.white.withOpacity(0.85), fontSize: 12.5, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      chip(isOnline ? Icons.wifi_rounded : Icons.location_on_rounded,
                                          isOnline ? 'ONLINE STUDENT' : 'OFFLINE STUDENT'),
                                      chip(Icons.verified_rounded, "LET'S SPEAK MEMBER"),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // quick stats
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      stat('${en + hi}', 'Classes', Icons.school_rounded),
                                      Container(width: 1, height: 36, color: Colors.white24),
                                      stat(
                                        en > 0 && hi > 0 ? 'Eng + Hin' : (hi > 0 ? 'Hindi' : 'English'),
                                        'Course',
                                        Icons.translate_rounded,
                                      ),
                                      Container(width: 1, height: 36, color: Colors.white24),
                                      stat(feePaid ? 'Paid ✓' : 'Due', 'This month', Icons.account_balance_wallet_rounded),
                                    ],
                                  ),
                                ),
                                if (joined != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Learning with us since ${DateFormat('d MMM yyyy').format(joined)}',
                                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 10.5),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // ⏰ CLASS TIMING — one timing per enabled stage (Stage 1 morning, Stage 2 evening…)
                Obx(() {
                  final stages = _enabledStages();
                  if (stages.isEmpty) {
                    final slot = BatchSlots.find(controller.userData['batchTime']);
                    return _classTimingCard(context, slot);
                  }
                  return _stageTimingsCard(context, stages);
                }),

                const SizedBox(height: 18),

                _sectionLabel(
                  context,
                  "ACCOUNT & LEARNING",
                  Icons.auto_awesome_rounded,
                ),

                const SizedBox(height: 10),

                Obx(() {
                  final isOnline =
                      (controller.userData['mode'] ?? "online")
                          .toString()
                          .toLowerCase() ==
                      "online";

                  return _actionCard(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.yellow,
                    title: "Tuition Fees & Payments",
                    subtitle: isOnline
                        ? "Online UPI payment & receipt"
                        : "Offline centre payment & receipt",
                    trailing: isOnline ? "ONLINE" : "OFFLINE",
                    onTap: () => Get.to(
                      () => PaymentDetailsScreen(
                        isOnline: isOnline,
                        managerPhone: isOnline
                            ? onlineManagerPhone
                            : offlineManagerPhone,
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 11),

                _actionCard(
                  context: context,
                  icon: Icons.fact_check_rounded,
                  iconColor: AppColors.teal,
                  title: "Attendance & Log",
                  subtitle: "View classes, attendance & club records",
                  onTap: () => Get.to(() => const StudentAttendanceScreen()),
                ),

                const SizedBox(height: 11),

                _actionCard(
                  context: context,
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.yellow,
                  title: "Test Results & Scores",
                  subtitle: "Review exams, marks & percentages",
                  onTap: () => Get.to(() => const StudentTestResultsScreen()),
                ),

                const SizedBox(height: 11),

                _actionCard(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFE3B21B),
                  title: "Hall of Fame",
                  subtitle: "Best student & trainer, and your rank",
                  onTap: () => Get.to(() => const StudentLeaderboardScreen()),
                ),

                const SizedBox(height: 11),

                _actionCard(
                  context: context,
                  icon: Icons.rate_review_rounded,
                  iconColor: AppColors.blue,
                  title: "Student Feedback",
                  subtitle: "Share your classroom experience",
                  onTap: _showFeedbackModal,
                ),

                const SizedBox(height: 24),

                _sectionLabel(context, "APP PREFERENCES", Icons.tune_rounded),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? card : const Color(0xFFF7FBFD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      _iconBox(
                        context,
                        Icons.dark_mode_rounded,
                        AppColors.teal,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "App Appearance",
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                themeController.isDarkMode.value
                                    ? "Dark mode is active"
                                    : "Light mode is active",
                                style: GoogleFonts.poppins(
                                  color: secondaryText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => Switch(
                          value: themeController.isDarkMode.value,
                          activeColor: AppColors.teal,
                          activeTrackColor: AppColors.teal.withOpacity(0.30),
                          inactiveThumbColor: AppColors.navy,
                          inactiveTrackColor: AppColors.navy.withOpacity(0.12),
                          onChanged: (_) {
                            themeController.toggleTheme();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 11),

                Obx(() {
                  final isOnline =
                      (controller.userData['mode'] ?? "online")
                          .toString()
                          .toLowerCase() ==
                      "online";

                  return _communityCard(context, isOnline: isOnline);
                }),

                const SizedBox(height: 24),

                _sectionLabel(
                  context,
                  "NEED HELP?",
                  Icons.support_agent_rounded,
                ),

                const SizedBox(height: 10),

                Obx(() {
                  final isOnline =
                      (controller.userData['mode'] ?? "online")
                          .toString()
                          .toLowerCase() ==
                      "online";

                  final managerPhone = isOnline
                      ? onlineManagerPhone
                      : offlineManagerPhone;

                  final managerTitle = isOnline
                      ? "Online Manager"
                      : "Offline Manager";

                  return _contactCard(
                    context,
                    managerTitle: managerTitle,
                    managerName: isOnline ? "Online Support" : "Branch Desk",
                    managerPhone: managerPhone,
                  );
                }),

                const SizedBox(height: 24),

                _dangerAction(
                  context,
                  icon: Icons.logout_rounded,
                  title: "Log Out",
                  subtitle: "Sign out from this device",
                  color: AppColors.warning,
                  onTap: () => controller.logout(),
                ),

                const SizedBox(height: 10),

                _dangerAction(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: "Delete Account",
                  subtitle: "Permanently remove your account",
                  color: AppColors.error,
                  onTap: () => _showDeleteConfirmation(context),
                ),

                const SizedBox(height: 22),

                Center(
                  child: Column(
                    children: [
                      Text(
                        "Designed and developed by",
                        style: GoogleFonts.poppins(
                          color: secondaryText.withOpacity(0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Avugaddi Software Systems",
                        style: GoogleFonts.poppins(
                          color: textColor.withOpacity(0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Enabled stages with their effective timing: (language, stageKey, title, timingLabel, isOwn)
  List<_StageTiming> _enabledStages() {
    final data = controller.userData;
    final defaultTiming = BatchSlots.labelOf(data['batchTime']);
    final out = <_StageTiming>[];
    for (final lang in const ['English', 'Hindi']) {
      final access = data[lang == 'English' ? 'englishAccess' : 'hindiAccess'];
      final batches = data[lang == 'English' ? 'englishBatch' : 'hindiBatch'];
      if (access is! Map) continue;
      for (int i = 1; i <= 7; i++) {
        final key = 'stage$i';
        if (access[key] != true) continue;
        final own = batches is Map ? BatchSlots.labelOf(batches[key]) : '';
        out.add(_StageTiming(
          language: lang,
          stage: key,
          title: '$lang • Stage $i',
          timing: own.isNotEmpty ? own : defaultTiming,
          own: own.isNotEmpty,
        ));
      }
    }
    return out;
  }

  Widget _miniChip(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.poppins(color: color, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.6),
            ),
          ],
        ),
      );

  /// ONE tap row: "My class timings • 7 classes" → opens the full timings page
  Widget _stageTimingsCard(
    BuildContext context,
    List<_StageTiming> stages,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final missing = stages.where((s) => BatchSlots.find(s.timing) == null).length;
    final en = stages.where((s) => s.language == 'English').length;
    final hi = stages.length - en;
    final next = _nextClass(stages);

    final subtitle = missing > 0
        ? '$missing timing${missing == 1 ? '' : 's'} not set — tap to choose'
        : next != null
            ? 'Next: ${next.$1} at ${next.$2}'
            : [if (en > 0) 'English $en', if (hi > 0) 'Hindi $hi'].join(' • ');
    final accent = missing > 0 ? AppColors.yellow : AppColors.teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Get.to(() => _MyTimingsPage(
              stages: _enabledStages,
              onChange: (ctx, st) => _showBatchPicker(ctx, language: st.language, stage: st.stage, title: st.title),
            )),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(missing > 0 ? 0.7 : 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: accent.withOpacity(0.14), borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.schedule_rounded,
                    color: missing > 0 ? (isDark ? AppColors.yellow : AppColors.deepNavy) : AppColors.teal, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My class timings',
                        style: GoogleFonts.poppins(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: textColor.withOpacity(0.6), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: accent.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                child: Text('${stages.length} class${stages.length == 1 ? '' : 'es'}',
                    style: GoogleFonts.poppins(
                        color: missing > 0 ? (isDark ? AppColors.yellow : AppColors.deepNavy) : AppColors.teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  /// Today's next class ("Hindi S2", "10:30 AM") or null
  (String, String)? _nextClass(List<_StageTiming> stages) {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) return null;
    final mins = now.hour * 60 + now.minute;
    _StageTiming? best;
    BatchSlot? bestSlot;
    for (final st in stages) {
      final slot = BatchSlots.find(st.timing);
      if (slot == null || slot.startMinutes + 90 < mins) continue; // already finished
      if (bestSlot == null || slot.startMinutes < bestSlot.startMinutes) {
        best = st;
        bestSlot = slot;
      }
    }
    if (best == null || bestSlot == null) return null;
    final short = '${best.language == 'Hindi' ? 'Hindi' : 'English'} Stage ${best.stage.replaceAll('stage', '')}';
    return (short, '${bestSlot.start} ${bestSlot.period}');
  }

  Widget _classTimingCard(BuildContext context, BatchSlot? slot) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final bool notSet = slot == null;
    final Color accent = notSet ? AppColors.yellow : AppColors.teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBatchPicker(context),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : const Color(0xFFF7FBFD),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(notSet ? 0.65 : 0.30), width: notSet ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: notSet
                    ? Icon(Icons.schedule_rounded, color: isDark ? AppColors.yellow : AppColors.deepNavy, size: 24)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "BATCH",
                            style: GoogleFonts.poppins(
                              color: AppColors.teal,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "${slot!.number}",
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MY CLASS TIMING",
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.55),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notSet ? "Not selected yet" : slot!.shortLabel,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      notSet ? "Tap to choose your daily batch" : "Tap to change your batch",
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.58),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  notSet ? "CHOOSE" : "CHANGE",
                  style: GoogleFonts.poppins(
                    color: notSet ? (isDark ? AppColors.yellow : AppColors.deepNavy) : AppColors.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One sheet for every stage: stage tabs on top (if more than one), all 7 timings in a
  /// 2-column grid (no scrolling), and the sheet CLOSES as soon as the timing is saved.
  void _showBatchPicker(BuildContext context, {String? language, String? stage, String? title}) {
    final all = _enabledStages();
    String? selLanguage = language;
    String? selStage = stage;

    String currentFor() {
      if (selStage == null) return BatchSlots.labelOf(controller.userData['batchTime']);
      for (final st in _enabledStages()) {
        if (st.language == selLanguage && st.stage == selStage) return st.timing;
      }
      return '';
    }

    // Timings used by my OTHER stages can't be picked (can't attend two classes at once)
    Map<String, String> takenFor() {
      final taken = <String, String>{};
      if (selStage == null) return taken;
      for (final st in _enabledStages()) {
        if (st.language == selLanguage && st.stage == selStage) continue;
        if (st.timing.isNotEmpty) taken.putIfAbsent(st.timing, () => st.title);
      }
      return taken;
    }

    String tempSelected = currentFor();
    final bothLanguages = all.map((s) => s.language).toSet().length > 1;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final theme = Theme.of(sheetContext);
          final isDark = theme.brightness == Brightness.dark;
          final textColor = theme.colorScheme.onSurface;
          final current = currentFor();
          final taken = takenFor();

          Widget slotTile(BatchSlot slot) {
            final bool selected = tempSelected == slot.label;
            final bool isCurrent = current == slot.label;
            final String? usedBy = taken[slot.label];
            final bool blocked = usedBy != null;
            final String endText = '${slot.end} ${slot.endPeriod ?? slot.period}';
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: blocked ? null : () => setSheetState(() => tempSelected = slot.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.teal
                      : blocked
                          ? (isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft).withOpacity(0.5)
                          : (isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.teal
                        : isCurrent
                            ? AppColors.navy.withOpacity(0.45)
                            : AppColors.teal.withOpacity(0.14),
                    width: selected || isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withOpacity(0.22) : AppColors.navy.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: blocked
                          ? Icon(Icons.lock_rounded, size: 13, color: textColor.withOpacity(0.35))
                          : Text(
                              "${slot.number}",
                              style: GoogleFonts.poppins(
                                color: selected ? Colors.white : textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "${slot.start} ${slot.period}",
                              style: GoogleFonts.poppins(
                                color: selected
                                    ? Colors.white
                                    : blocked
                                        ? textColor.withOpacity(0.35)
                                        : textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ),
                          Text(
                            blocked
                                ? "Used by ${(usedBy ?? '').replaceAll('English • ', '').replaceAll('Hindi • ', 'Hindi ')}"
                                : isCurrent
                                    ? "Current • till $endText"
                                    : "till $endText",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: selected
                                  ? Colors.white.withOpacity(0.85)
                                  : blocked
                                      ? AppColors.error.withOpacity(0.8)
                                      : isCurrent
                                          ? (isDark ? AppColors.teal : AppColors.navy)
                                          : textColor.withOpacity(0.55),
                              fontSize: 9.5,
                              fontWeight: isCurrent || blocked ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 17),
                  ],
                ),
              ),
            );
          }

          Widget grid(List<BatchSlot> slots) {
            final rows = <Widget>[];
            for (var i = 0; i < slots.length; i += 2) {
              rows.add(Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: slotTile(slots[i])),
                    const SizedBox(width: 8),
                    Expanded(child: i + 1 < slots.length ? slotTile(slots[i + 1]) : const SizedBox.shrink()),
                  ],
                ),
              ));
            }
            return Column(children: rows);
          }

          Widget periodTitle(String t, IconData icon) => Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 2),
                child: Row(
                  children: [
                    Icon(icon, size: 13, color: textColor.withOpacity(0.5)),
                    const SizedBox(width: 5),
                    Text(
                      t,
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.60),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );

          final stageTitle = selStage == null
              ? "Change Class Timing"
              : "${selLanguage ?? ''} • Stage ${selStage!.replaceAll('stage', '')}";

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                // fits on normal phones; scrolls only on very small screens
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title != null && all.length <= 1 ? "Timing for $title" : "Class timing",
                            style: GoogleFonts.poppins(color: textColor, fontSize: 16.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close_rounded, color: textColor.withOpacity(0.6)),
                        ),
                      ],
                    ),

                    // ---- stage tabs (only when the student has 2+ stages) ----
                    if (all.length > 1) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: all.map((st) {
                            final active = st.language == selLanguage && st.stage == selStage;
                            final n = st.stage.replaceAll('stage', '');
                            final label = bothLanguages ? "${st.language == 'Hindi' ? 'Hindi' : 'Eng'} S$n" : "Stage $n";
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setSheetState(() {
                                  selLanguage = st.language;
                                  selStage = st.stage;
                                  tempSelected = currentFor();
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: active ? AppColors.navy : AppColors.navy.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    label,
                                    style: GoogleFonts.poppins(
                                      color: active ? Colors.white : textColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      selStage == null
                          ? "Your trainer and attendance will follow the new batch."
                          : "Changing $stageTitle only. 🔒 = used by your other stage.",
                      style: GoogleFonts.poppins(color: textColor.withOpacity(0.60), fontSize: 10.5),
                    ),
                    const SizedBox(height: 10),
                    periodTitle("MORNING", Icons.wb_sunny_rounded),
                    grid(BatchSlots.morning),
                    periodTitle("EVENING", Icons.nights_stay_rounded),
                    grid(BatchSlots.evening),
                    const SizedBox(height: 4),
                    Obx(() {
                      final saving = controller.isSavingBatch.value;
                      final unchanged = tempSelected.isEmpty || tempSelected == current;
                      final picked = BatchSlots.find(tempSelected);
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (saving || unchanged)
                              ? null
                              : () async {
                                  // remember THIS sheet's route — a snackbar may be on top when saving ends
                                  final route = ModalRoute.of(sheetContext);
                                  final nav = Navigator.of(sheetContext);
                                  final ok = await controller.updateBatchTime(
                                    tempSelected,
                                    language: selLanguage,
                                    stage: selStage,
                                  );
                                  // ✅ close the sheet itself (Get.back() closed the snackbar instead → sheet stayed open)
                                  if (ok && route != null && route.isActive) nav.removeRoute(route);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            disabledBackgroundColor: AppColors.navy.withOpacity(0.40),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Text(
                                  unchanged ? "Pick a new timing" : "Save • ${picked?.shortLabel ?? ''}",
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondary = textColor.withOpacity(0.64);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF9FCFE),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.error.withOpacity(isDark ? 0.28 : 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.50 : 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Delete Account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Your account and related data will be permanently removed.\n'
                  'This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: secondary,
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: textColor,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.deleteAccount();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Delete Forever',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _sectionLabel(BuildContext context, String title, IconData icon) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.navy.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.12,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.navy, size: 16),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: textColor.withOpacity(0.68),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _iconBox(BuildContext context, IconData icon, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondary = textColor.withOpacity(0.60);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? theme.cardColor
                : const Color(0xFFF7FBFD),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: iconColor.withOpacity(0.20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(
                  theme.brightness == Brightness.dark ? 0.12 : 0.06,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _iconBox(context, icon, iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: secondary,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailing,
                    style: GoogleFonts.poppins(
                      color: iconColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: iconColor, size: 23),
            ],
          ),
        ),
      ),
    );
  }

  Widget _communityCard(BuildContext context, {required bool isOnline}) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchCommunityLink(isOnline),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success.withOpacity(0.14), theme.cardColor],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.24)),
          ),
          child: Row(
            children: [
              _iconBox(context, Icons.groups_rounded, AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline
                          ? "Online WhatsApp Community"
                          : "Offline WhatsApp Community",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Join discussions & spoken English groups",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.60),
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.success,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactCard(
    BuildContext context, {
    required String managerTitle,
    required String managerName,
    required String managerPhone,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          _buildContactRow(
            role: managerTitle,
            name: managerName,
            phone: managerPhone,
            onCall: () => _makePhoneCall(managerPhone),
            onWhatsApp: () => _openWhatsApp(
              managerPhone,
              "Hello $managerTitle, I am ${controller.userData['name'] ?? 'Student'}. I need assistance.",
            ),
          ),
          Divider(
            height: 22,
            color: Theme.of(context).dividerColor.withOpacity(0.7),
          ),
          _buildContactRow(
            role: "Technical App Support",
            name: "System Engineer",
            phone: techSupportPhone,
            onCall: () => _makePhoneCall(techSupportPhone),
            onWhatsApp: () => _openWhatsApp(
              techSupportPhone,
              "Hello Developer, I am experiencing an issue on the Let's Speak Mobile App.",
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.12) : const Color(0xFFFDF8F6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(isDark ? 0.30 : 0.25)),
          ),
          child: Row(
            children: [
              _iconBox(context, icon, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.65),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.85)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required String role,
    required String name,
    required String phone,
    required VoidCallback onCall,
    required VoidCallback onWhatsApp,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "$name • +91 $phone",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: textColor.withOpacity(0.54),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        _smallContactButton(
          icon: Icons.call_rounded,
          color: AppColors.blue,
          onTap: onCall,
          tooltip: "Call",
        ),
        const SizedBox(width: 3),
        _smallContactButton(
          icon: Icons.chat_rounded,
          color: AppColors.success,
          onTap: onWhatsApp,
          tooltip: "WhatsApp",
        ),
      ],
    );
  }

  Widget _smallContactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: 39,
            height: 39,
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// DEDICATED PAYMENT SCREEN
// Upload → asks "English or Hindi course?" → waiting for verification.
// A wrong screenshot can be deleted or replaced until the manager verifies it.
// ================================================================

class PaymentDetailsScreen extends StatefulWidget {
  final bool isOnline;
  final String managerPhone;

  const PaymentDetailsScreen({
    super.key,
    required this.isOnline,
    required this.managerPhone,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final AuthController auth = Get.find<AuthController>();

  bool loadingStatus = true;
  bool uploading = false;
  bool deleting = false;
  Map<String, dynamic> fee = {};

  String get _userId => (auth.userData['id'] ?? auth.userData['_id'] ?? '').toString();

  Map<String, String> get _authHeaders {
    final token = (auth.box.read('token') ?? '').toString();
    return {if (token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }

  String get _status => (fee['feePaymentStatus'] ?? 'not_submitted').toString();
  String get _screenshot => (fee['feePaymentScreenshot'] ?? '').toString();
  bool get _isVerified => _status == 'verified' || (fee['feeStatus'] ?? '') == 'paid';
  bool get _isPending => _status == 'pending_verification';
  bool get _isRejected => _status == 'rejected';
  bool get _hasScreenshot => _screenshot.isNotEmpty;

  Worker? _profileWorker;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    // ⚡ Admin verifies/rejects → server sends 'permissions_updated' → AuthController
    // refreshes the profile → this fires → status card updates by itself.
    _profileWorker = ever(auth.userData, (_) => _loadStatus(silent: true));
    // Safety net if the phone missed the live message: check every 20 s while waiting
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_isPending) _loadStatus(silent: true);
    });
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    _poll?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // NETWORK
  // ---------------------------------------------------------------
  String _serverMessage(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) return body['message'].toString();
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }

  Future<void> _loadStatus({bool silent = false}) async {
    if (_userId.isEmpty) {
      if (mounted) setState(() => loadingStatus = false);
      return;
    }
    final wasPending = _isPending;
    try {
      final res = await http.get(
        Uri.parse("${ApiEndpoints.baseUrl}/fee/my-status?userId=$_userId"),
        headers: _authHeaders,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => fee = Map<String, dynamic>.from(jsonDecode(res.body)));
        // tell the student right here when the manager just decided
        if (silent && wasPending && _isRejected) {
          Get.snackbar(
            "Screenshot not accepted",
            "Please check the payment and upload a clear screenshot again.",
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(12),
          );
        }
      }
    } catch (e) {
      debugPrint('Fee status error: $e');
    } finally {
      if (mounted) setState(() => loadingStatus = false);
    }
  }

  /// Which languages the student has enabled → pre-select when only one
  String? _defaultLanguage() {
    bool anyOn(dynamic m) => m is Map && m.values.any((v) => v == true);
    final en = anyOn(auth.userData['englishAccess']);
    final hi = anyOn(auth.userData['hindiAccess']);
    if (en && !hi) return 'English';
    if (hi && !en) return 'Hindi';
    final last = (fee['feeLanguage'] ?? '').toString();
    return last.isEmpty ? null : last;
  }

  Future<void> _startUpload() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image == null || !mounted) return;
    final language = await _askLanguage(image);
    if (language == null || !mounted) return;
    await _upload(image, language);
  }

  Future<void> _upload(XFile image, String language) async {
    setState(() => uploading = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiEndpoints.baseUrl}/fee/upload-fee-screenshot"),
      );
      request.headers.addAll(_authHeaders);
      request.fields['userId'] = _userId;
      request.fields['language'] = language;
      request.files.add(await http.MultipartFile.fromPath('screenshot', image.path, filename: image.name));

      final response = await http.Response.fromStream(await request.send());
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => fee = Map<String, dynamic>.from(jsonDecode(response.body)));
        Get.snackbar(
          "Uploaded ✅",
          "$language course fee screenshot sent. The manager will verify it shortly.",
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(14),
        );
        auth.refreshProfile();
      } else {
        Get.snackbar(
          "Upload failed",
          _serverMessage(response, "Could not upload the screenshot"),
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(14),
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Connection error",
        "Check your internet and try again.",
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(14),
      );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete screenshot?', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'Delete this screenshot if it is wrong. You can upload the correct one after.',
          style: GoogleFonts.poppins(fontSize: 12.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => deleting = true);
    try {
      final res = await http.delete(
        Uri.parse("${ApiEndpoints.baseUrl}/fee/my-screenshot?userId=$_userId"),
        headers: _authHeaders,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => fee = Map<String, dynamic>.from(jsonDecode(res.body)));
        Get.snackbar(
          "Deleted",
          "Now upload the correct payment screenshot.",
          backgroundColor: AppColors.navy,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(14),
        );
      } else {
        Get.snackbar(
          "Not deleted",
          _serverMessage(res, "Could not delete"),
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(14),
        );
      }
    } catch (_) {
      Get.snackbar("Connection error", "Try again.", backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  // ---------------------------------------------------------------
  // "English or Hindi?" sheet (with a preview of the chosen screenshot)
  // ---------------------------------------------------------------
  Future<String?> _askLanguage(XFile image) {
    String? picked = _defaultLanguage();

    return Get.bottomSheet<String>(
      StatefulBuilder(
        builder: (context, setSheet) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final textColor = theme.colorScheme.onSurface;

          Widget option(String lang, String emoji, String sub) {
            final selected = picked == lang;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setSheet(() => picked = lang),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.teal.withOpacity(0.12)
                        : (isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.teal : AppColors.teal.withOpacity(0.15),
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(lang,
                          style: GoogleFonts.poppins(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
                      Text(sub,
                          style: GoogleFonts.poppins(color: textColor.withOpacity(0.55), fontSize: 9.5)),
                      const SizedBox(height: 6),
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: selected ? AppColors.teal : textColor.withOpacity(0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Which course is this fee for?',
                        style: GoogleFonts.poppins(color: textColor, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('Choose the course you paid for, then upload.',
                        style: GoogleFonts.poppins(color: textColor.withOpacity(0.6), fontSize: 11.5)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        option('English', '🇬🇧', 'Spoken English'),
                        const SizedBox(width: 10),
                        option('Hindi', '🇮🇳', 'Spoken Hindi'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(image.path), width: 64, height: 86, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your screenshot',
                                  style: GoogleFonts.poppins(
                                      color: textColor, fontSize: 12.5, fontWeight: FontWeight.w700)),
                              Text('Make sure the amount, date and UPI ID are clearly visible.',
                                  style: GoogleFonts.poppins(
                                      color: textColor.withOpacity(0.6), fontSize: 10.5, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              side: BorderSide(color: textColor.withOpacity(0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: picked == null ? null : () => Get.back(result: picked),
                            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                            label: Text(
                              picked == null ? 'Choose a course' : 'Upload for $picked',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.teal.withOpacity(0.35),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _openScreenshot() {
    if (!_hasScreenshot) return;
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
        body: Center(
          child: InteractiveViewer(
            maxScale: 4,
            child: Image.network(_screenshot, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondary = textColor.withOpacity(0.62);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.isOnline ? "Online Tuition Fees" : "Offline Center Fees",
          style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              isDark ? AppColors.darkSurface : AppColors.periwinkle.withOpacity(0.10),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _loadStatus,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
                    child: Column(
                      children: [
                        _headerCard(),
                        const SizedBox(height: 11),
                        if (loadingStatus)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: LinearProgressIndicator(minHeight: 2, color: AppColors.teal),
                          )
                        else if (_hasScreenshot || _isVerified) ...[
                          _statusCard(context),
                          const SizedBox(height: 11),
                        ],
                        if (!_isVerified) _qrCard(context, isDark, textColor, secondary),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isVerified)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: (uploading || deleting) ? null : _startUpload,
                          icon: uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(_hasScreenshot ? Icons.sync_rounded : Icons.cloud_upload_rounded, size: 18),
                          label: Text(
                            uploading
                                ? "Uploading…"
                                : (_hasScreenshot ? "Upload a New Screenshot" : "Upload Payment Screenshot"),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.teal.withOpacity(0.5),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasScreenshot
                            ? "A new upload replaces your current screenshot."
                            : "You'll choose English or Hindi course after picking the screenshot.",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: secondary, fontSize: 9.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.deepNavy, AppColors.navy]),
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(color: AppColors.navy.withOpacity(0.20), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: AppColors.yellow, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Official Payment",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
                Text(widget.isOnline ? "Online UPI payment" : "Offline centre payment",
                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.72), fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- uploaded screenshot: status + delete / replace ----
  Widget _statusCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    final Color color = _isVerified ? AppColors.success : (_isRejected ? AppColors.error : AppColors.warning);
    final String label = _isVerified
        ? "Verified ✅"
        : _isRejected
            ? "Rejected"
            : "Waiting for verification";
    final String note = _isVerified
        ? "Your fee for this month is verified. Thank you!"
        : _isRejected
            ? "The manager rejected this screenshot. Delete it and upload the correct one."
            : "The manager will check it soon. Wrong screenshot? Delete it and upload again.";
    final lang = (fee['feeLanguage'] ?? '').toString();
    final submitted = DateTime.tryParse((fee['feeSubmittedAt'] ?? '').toString())?.toLocal();
    final canDelete = fee['canDelete'] == true || ((_isPending || _isRejected) && _hasScreenshot);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _openScreenshot,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 94,
                    color: textColor.withOpacity(0.06),
                    child: _hasScreenshot
                        ? Image.network(
                            _screenshot,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.broken_image_outlined, color: textColor.withOpacity(0.4)),
                          )
                        : Icon(Icons.verified_rounded, color: color, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your payment screenshot",
                        style: GoogleFonts.poppins(color: textColor, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _chip(label, color),
                        if (lang.isNotEmpty) _chip(lang == 'Hindi' ? '🇮🇳 Hindi course' : '🇬🇧 English course', AppColors.navy),
                      ],
                    ),
                    if (submitted != null) ...[
                      const SizedBox(height: 5),
                      Text("Uploaded ${DateFormat('d MMM, h:mm a').format(submitted)}",
                          style: GoogleFonts.poppins(color: textColor.withOpacity(0.55), fontSize: 10)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(note, style: GoogleFonts.poppins(color: textColor.withOpacity(0.7), fontSize: 11, height: 1.4)),
          if (canDelete) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (deleting || uploading) ? null : _delete,
                    icon: deleting
                        ? const SizedBox(
                            width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                        : const Icon(Icons.delete_outline_rounded, size: 17),
                    label: Text("Delete", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(0, 42),
                      side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openScreenshot,
                    icon: const Icon(Icons.zoom_in_rounded, size: 17),
                    label: Text("View", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      minimumSize: const Size(0, 42),
                      side: BorderSide(color: AppColors.navy.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: GoogleFonts.poppins(color: color, fontSize: 9.5, fontWeight: FontWeight.w800)),
      );

  Widget _qrCard(BuildContext context, bool isDark, Color textColor, Color secondary) {
    final width = MediaQuery.of(context).size.width;
    final qrSize = (width - 120).clamp(190.0, 260.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.teal.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(isDark ? 0.15 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text("Scan & Pay", style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            "PhonePe • Google Pay • Paytm • BHIM UPI",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: secondary, fontSize: 9.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Container(
            width: qrSize,
            height: qrSize,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.yellow, width: 3),
            ),
            child: Image.asset(
              "assets/images/paymentqrcode.png",
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 75, color: AppColors.navy),
                    Text("UPI Payment QR",
                        style: GoogleFonts.poppins(color: AppColors.navy, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _paymentStep(context, number: "1", title: "Scan the QR", subtitle: "Complete your course fee payment."),
          const SizedBox(height: 5),
          _paymentStep(context, number: "2", title: "Save the receipt", subtitle: "Take a screenshot after payment."),
          const SizedBox(height: 5),
          _paymentStep(context,
              number: "3", title: "Upload & choose course", subtitle: "Pick the screenshot, then English or Hindi."),
        ],
      ),
    );
  }

  Widget _paymentStep(
    BuildContext context, {
    required String number,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.teal.withOpacity(0.25)),
          ),
          child: Text(number,
              style: GoogleFonts.poppins(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(color: textColor, fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      color: textColor.withOpacity(0.56), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}


// =====================================================================
// ⏰ MY CLASS TIMINGS — full page (opened from the profile row)
// One clean card per class, grouped English / Hindi, "Change" on each.
// =====================================================================
class _MyTimingsPage extends StatelessWidget {
  final List<_StageTiming> Function() stages;
  final void Function(BuildContext context, _StageTiming stage) onChange;
  const _MyTimingsPage({required this.stages, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text('My class timings',
            style: GoogleFonts.poppins(color: textColor, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Obx(() {
        controller.userData.length; // rebuild right after a timing is saved
        final all = stages();
        final now = DateTime.now();
        final mins = now.hour * 60 + now.minute;
        final groups = <String, List<_StageTiming>>{};
        for (final st in all) {
          groups.putIfAbsent(st.language, () => []).add(st);
        }
        for (final g in groups.values) {
          g.sort((a, b) {
            final sa = BatchSlots.find(a.timing)?.startMinutes ?? 9999;
            final sb = BatchSlots.find(b.timing)?.startMinutes ?? 9999;
            return sa.compareTo(sb);
          });
        }

        if (all.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text('No classes enabled yet.\nThe institute will add your stages.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: textColor.withOpacity(0.6), fontSize: 13)),
            ),
          );
        }

        Widget card(_StageTiming st) {
          final slot = BatchSlots.find(st.timing);
          final notSet = slot == null;
          final live = !notSet && now.weekday != DateTime.sunday && mins >= slot!.startMinutes && mins <= slot!.startMinutes + 90;
          final morning = !notSet && slot!.period == 'AM';
          final accent = notSet ? AppColors.yellow : AppColors.teal;
          final endText = notSet ? '' : '${slot!.end} ${slot!.endPeriod ?? slot!.period}';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: live ? AppColors.teal : accent.withOpacity(notSet ? 0.7 : 0.25), width: live ? 1.6 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: accent.withOpacity(0.14), borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('STAGE',
                          style: GoogleFonts.poppins(
                              color: textColor.withOpacity(0.55), fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: .5)),
                      Text(st.stage.replaceAll('stage', ''),
                          style: GoogleFonts.poppins(color: textColor, fontSize: 18, fontWeight: FontWeight.w800, height: 1.05)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notSet ? 'Timing not set' : '${slot!.start} ${slot!.period}',
                          style: GoogleFonts.poppins(color: textColor, fontSize: 17, fontWeight: FontWeight.w800, height: 1.15)),
                      Row(
                        children: [
                          if (!notSet) ...[
                            Icon(morning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                                size: 13, color: morning ? const Color(0xFFE0A21B) : AppColors.teal),
                            const SizedBox(width: 4),
                            Text('till $endText',
                                style: GoogleFonts.poppins(color: textColor.withOpacity(0.6), fontSize: 11)),
                          ] else
                            Text('Choose a batch for this stage',
                                style: GoogleFonts.poppins(color: textColor.withOpacity(0.6), fontSize: 11)),
                          if (live) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
                              child: Text('NOW',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => onChange(context, st),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: notSet ? (isDark ? AppColors.yellow : AppColors.deepNavy) : AppColors.teal,
                    side: BorderSide(color: accent.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(notSet ? 'Choose' : 'Change',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Every class is 90 minutes. Tap Change to move a stage to another batch — two stages can\'t be at the same time.',
                      style: GoogleFonts.poppins(color: textColor.withOpacity(0.75), fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            for (final lang in ['English', 'Hindi'])
              if (groups[lang] != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
                  child: Row(
                    children: [
                      Text(lang == 'English' ? '🇬🇧' : '🇮🇳', style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text('$lang course',
                          style: GoogleFonts.poppins(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text('${groups[lang]!.length} class${groups[lang]!.length == 1 ? '' : 'es'}',
                          style: GoogleFonts.poppins(color: textColor.withOpacity(0.55), fontSize: 11)),
                    ],
                  ),
                ),
                ...groups[lang]!.map(card),
              ],
          ],
        );
      }),
    );
  }
}