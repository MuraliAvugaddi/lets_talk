import 'dart:convert';
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
import 'package:lets_talk/apis/api_endpoint.dart';
import 'package:url_launcher/url_launcher.dart';

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
                                  headers: {"Content-Type": "application/json"},
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

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      border: Border.all(
                        color: isDark
                            ? AppColors.teal.withOpacity(0.28)
                            : AppColors.navy.withOpacity(0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(
                            isDark ? 0.25 : 0.10,
                          ),
                          blurRadius: isDark ? 24 : 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.teal, AppColors.yellow],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withOpacity(0.22),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.background,
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : "U",
                                style: GoogleFonts.poppins(
                                  color: AppColors.teal,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: heroTextColor,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: GoogleFonts.poppins(
                            color: heroSecondaryText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withOpacity(
                              isDark ? 0.12 : 0.07,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: isDark ? AppColors.teal : AppColors.navy,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "LET'S SPEAK MEMBER",
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? AppColors.teal
                                      : AppColors.navy,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.teal.withOpacity(0.12)
                                : AppColors.yellow.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isOnline
                                  ? AppColors.teal.withOpacity(0.42)
                                  : AppColors.yellow.withOpacity(0.50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOnline
                                    ? Icons.wifi_rounded
                                    : Icons.location_on_rounded,
                                size: 14,
                                color: isOnline
                                    ? AppColors.teal
                                    : AppColors.yellow,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${mode.toUpperCase()} STUDENT",
                                style: GoogleFonts.poppins(
                                  color: isOnline
                                      ? AppColors.teal
                                      : AppColors.yellow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

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
// ================================================================

class PaymentDetailsScreen extends StatelessWidget {
  final bool isOnline;
  final String managerPhone;

  const PaymentDetailsScreen({
    super.key,
    required this.isOnline,
    required this.managerPhone,
  });

  Future<void> _uploadScreenshot(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (image == null) return;

    final authController = Get.find<AuthController>();
    final userId = authController.userData['id'] ?? authController.userData['_id'];

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiEndpoints.baseUrl}/fee/upload-fee-screenshot"),
      );

      request.fields['userId'] = userId.toString();
      request.files.add(await http.MultipartFile.fromPath('screenshot', image.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (Get.isDialogOpen ?? false) Get.back(); // close loader

      if (response.statusCode == 200) {
        Get.snackbar(
          "Success", 
          "Screenshot uploaded successfully! Management will verify shortly.", 
          backgroundColor: Colors.green, 
          colorText: Colors.white
        );
      } else {
        Get.snackbar("Error", "Failed to upload screenshot.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", "Connection error: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

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
          isOnline ? "Online Tuition Fees" : "Offline Center Fees",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              isDark
                  ? AppColors.darkSurface
                  : AppColors.periwinkle.withOpacity(0.10),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final veryCompact = constraints.maxHeight < 650;
              final availableQr = constraints.maxHeight - 320;
              final qrSize = availableQr
                  .clamp(veryCompact ? 190.0 : 215.0, 270.0)
                  .toDouble();

              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 5, 14, 7),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        veryCompact ? 9 : 12,
                        16,
                        veryCompact ? 9 : 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.deepNavy, AppColors.navy],
                        ),
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withOpacity(0.20),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: veryCompact ? 40 : 44,
                            height: veryCompact ? 40 : 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: AppColors.yellow,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Official Payment",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  isOnline
                                      ? "Online UPI payment"
                                      : "Offline centre payment",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.72),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: veryCompact ? 8 : 11),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          13,
                          veryCompact ? 7 : 10,
                          13,
                          veryCompact ? 7 : 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : const Color(0xFFF7FBFD),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.teal.withOpacity(0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withOpacity(
                                isDark ? 0.15 : 0.07,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Scan & Pay",
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: veryCompact ? 15 : 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "PhonePe • Google Pay • Paytm • BHIM UPI",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: secondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: veryCompact ? 7 : 10),

                            Container(
                              width: qrSize,
                              height: qrSize,
                              padding: EdgeInsets.all(veryCompact ? 6 : 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.yellow,
                                  width: 3,
                                ),
                              ),
                              child: Image.asset(
                                "assets/images/paymentqrcode.png",
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 75,
                                        color: AppColors.navy,
                                      ),
                                      Text(
                                        "UPI Payment QR",
                                        style: GoogleFonts.poppins(
                                          color: AppColors.navy,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: veryCompact ? 6 : 9),

                            _paymentStep(
                              context,
                              number: "1",
                              title: "Scan the QR",
                              subtitle: "Complete your course fee payment.",
                            ),
                            SizedBox(height: veryCompact ? 3 : 5),
                            _paymentStep(
                              context,
                              number: "2",
                              title: "Save the receipt",
                              subtitle: "Take a screenshot after payment.",
                            ),
                            SizedBox(height: veryCompact ? 3 : 5),
                            _paymentStep(
                              context,
                              number: "3",
                              title: "Upload to app",
                              subtitle: "Submit screenshot for automated verification.",
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: veryCompact ? 44 : 46,
                      child: ElevatedButton.icon(
                        onPressed: () => _uploadScreenshot(context),
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          "Upload Payment Screenshot",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Upload your payment receipt screenshot for instant review.",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
          child: Text(
            number,
            style: GoogleFonts.poppins(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: textColor.withOpacity(0.56),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}