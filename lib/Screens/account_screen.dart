import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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

  // --- BRAND COLORS ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color darkCard = const Color(0xff14141E);
  final Color backgroundColor = const Color(0xff0A0A0E);
  final Color accentGreen = const Color(0xff25D366);

  // --- OFFICIAL CONTACT NUMBERS ---
  final String offlineManagerPhone = "7842941055";
  final String onlineManagerPhone = "7093857473";
  final String mdPhone = "9959751194"; // Surendhra Sir (MD)
  final String techSupportPhone = "9959751194";

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      Get.snackbar("Error", "Could not dial $phoneNumber",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String message) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}",
    );
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not open WhatsApp for +91 $phoneNumber",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
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
        backgroundColor: Colors.redAccent,
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
              color: darkCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: tealMist.withOpacity(0.3)),
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
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tell us about your learning experience with Let's Speak.",
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: goldenYellow,
                            size: 34,
                          ),
                          onPressed: () => setModalState(() => selectedStars = index + 1),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Write your feedback or review here...",
                      hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xff0A0A0E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: tealMist.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: goldenYellow, width: 1.5),
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
                                Get.snackbar("Missing Text", "Please write a few words.",
                                    backgroundColor: Colors.redAccent, colorText: Colors.white);
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

                                if (response.statusCode == 201 || response.statusCode == 200) {
                                  Get.back();
                                  Get.snackbar(
                                    "Thank You!",
                                    "Your feedback has been submitted to the management.",
                                    backgroundColor: tealMist,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  Get.snackbar("Notice", "Failed to submit. Try again later.",
                                      backgroundColor: Colors.redAccent, colorText: Colors.white);
                                }
                              } catch (e) {
                                Get.snackbar("Error", "Submission failed: $e",
                                    backgroundColor: Colors.redAccent, colorText: Colors.white);
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepOceanBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Submit Feedback",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: tealMist,
        backgroundColor: darkCard,
        onRefresh: () async => await controller.refreshProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- 1. HERO PROFILE CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: tealMist.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: goldenYellow, width: 2),
                        color: deepOceanBlue.withOpacity(0.2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/account1.png",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Obx(() {
                              String name = controller.userData['name'] ?? 'U';
                              return Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: GoogleFonts.poppins(
                                    color: goldenYellow,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => Text(
                        controller.userData['name'] ?? "User Name",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Obx(
                      () => Text(
                        controller.userData['phone'] ?? "N/A",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      String mode = controller.userData['mode'] ?? "online";
                      bool isOnline = mode.toLowerCase() == "online";
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isOnline ? tealMist.withOpacity(0.18) : goldenYellow.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOnline ? tealMist.withOpacity(0.5) : goldenYellow.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnline ? Icons.wifi_rounded : Icons.location_on_rounded,
                              size: 13,
                              color: isOnline ? tealMist : goldenYellow,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${mode.toUpperCase()} STUDENT",
                              style: GoogleFonts.poppins(
                                color: isOnline ? tealMist : goldenYellow,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 2. PAYMENT & FEES NAVIGATION CONTAINER ---
              Obx(() {
                final bool isOnline =
                    (controller.userData['mode'] ?? "online").toString().toLowerCase() == "online";

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: goldenYellow.withOpacity(0.35)),
                    gradient: LinearGradient(
                      colors: [
                        goldenYellow.withOpacity(0.08),
                        darkCard,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Get.to(() => PaymentDetailsScreen(
                            isOnline: isOnline,
                            managerPhone: isOnline ? onlineManagerPhone : offlineManagerPhone,
                          )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: goldenYellow.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.qr_code_2_rounded, color: goldenYellow, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tuition Fees & Payments",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOnline ? "Mode: Online UPI QR" : "Mode: Offline Center UPI QR",
                                    style: GoogleFonts.poppins(
                                      color: goldenYellow,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: goldenYellow,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 14),

              // --- 3. ATTENDANCE NAVIGATION CARD ---
              _buildNavCard(
                icon: Icons.fact_check_rounded,
                iconColor: tealMist,
                title: "Attendance & Log",
                subtitle: "View monthly classes & club records",
                onTap: () => Get.to(() => const StudentAttendanceScreen()),
              ),

              const SizedBox(height: 14),

              // --- 4. TEST RESULTS NAVIGATION CARD ---
              _buildNavCard(
                icon: Icons.leaderboard_rounded,
                iconColor: goldenYellow,
                title: "Test Results & Scores",
                subtitle: "Review stage-wise exam marks & percentage",
                onTap: () => Get.to(() => const StudentTestResultsScreen()),
              ),

              const SizedBox(height: 14),

              // --- 5. STUDENT FEEDBACK TRIGGER CARD ---
              _buildNavCard(
                icon: Icons.rate_review_rounded,
                iconColor: const Color(0xff38BDF8),
                title: "Student Feedback & Rating",
                subtitle: "Share your classroom & learning review",
                onTap: _showFeedbackModal,
              ),

              const SizedBox(height: 14),

              // --- 6. COMMUNITY INVITATION CARD ---
              Obx(() {
                final bool isOnline =
                    (controller.userData['mode'] ?? "online").toString().toLowerCase() == "online";

                return GestureDetector(
                  onTap: () => _launchCommunityLink(isOnline),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentGreen.withOpacity(0.15),
                          const Color(0xff141E18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentGreen.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.groups_rounded, color: accentGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOnline
                                    ? "Online WhatsApp Community"
                                    : "Offline WhatsApp Community",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Join active discussions & spoken groups",
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: accentGreen, size: 14),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 18),

              // --- 7. HELPLINE & MANAGEMENT CONTACT SECTION ---
              Obx(() {
                final bool isOnline =
                    (controller.userData['mode'] ?? "online").toString().toLowerCase() == "online";
                final String managerPhone = isOnline ? onlineManagerPhone : offlineManagerPhone;
                final String managerTitle = isOnline ? "Online Manager" : "Offline Manager";

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Help & Institute Contacts",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Assigned Manager Row
                      _buildContactRow(
                        role: managerTitle,
                        name: isOnline ? "Online Support" : "Branch Desk",
                        phone: managerPhone,
                        onCall: () => _makePhoneCall(managerPhone),
                        onWhatsApp: () => _openWhatsApp(
                          managerPhone,
                          "Hello $managerTitle, I am ${controller.userData['name'] ?? 'Student'}. I need assistance.",
                        ),
                      ),

                      const Divider(color: Colors.white10, height: 20),

                      // Surendhra Sir (MD) Row
                      _buildContactRow(
                        role: "Managing Director (MD)",
                        name: "Surendhra Sir",
                        phone: mdPhone,
                        onCall: () => _makePhoneCall(mdPhone),
                        onWhatsApp: () => _openWhatsApp(
                          mdPhone,
                          "Respected Surendhra Sir, I am ${controller.userData['name'] ?? 'Student'}. Contacting regarding institute support.",
                        ),
                      ),

                      const Divider(color: Colors.white10, height: 20),

                      // Technical Support Line
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
              }),

              const SizedBox(height: 28),

              // --- 8. LOGOUT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => controller.logout(),
                  icon: const Icon(Icons.logout_rounded, color: Colors.amber, size: 18),
                  label: Text(
                    "Log Out",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff221C14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.amber.withOpacity(0.35)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --- 9. DELETE ACCOUNT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => controller.deleteAccount(),
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                  label: Text(
                    "Delete Account",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff221417),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
                    ),
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

  Widget _buildNavCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: iconColor, size: 16),
          ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              "$name • +91 $phone",
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11.5),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.call_rounded, color: Color(0xff158DFE), size: 20),
              onPressed: onCall,
              tooltip: "Call",
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_rounded, color: accentGreen, size: 20),
              onPressed: onWhatsApp,
              tooltip: "WhatsApp",
            ),
          ],
        ),
      ],
    );
  }
}

// --- DEDICATED FULL PAYMENT SCREEN ---
class PaymentDetailsScreen extends StatelessWidget {
  final bool isOnline;
  final String managerPhone;

  const PaymentDetailsScreen({
    super.key,
    required this.isOnline,
    required this.managerPhone,
  });

  Future<void> _openWhatsApp(String phoneNumber, String message) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}",
    );
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not open WhatsApp for +91 $phoneNumber",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkCard = Color(0xff14141E);
    const Color backgroundColor = Color(0xff0A0A0E);
    const Color deepOceanBlue = Color(0xff065381);
    const Color goldenYellow = Color(0xffF2C94C);
    const Color tealMist = Color(0xff508F97);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: darkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isOnline ? "Online Tuition Fees" : "Offline Center Fees",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tealMist.withOpacity(0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    isOnline ? "Official Online Payment QR" : "Official Offline Payment QR",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Scan via PhonePe, Google Pay, Paytm or BHIM UPI",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: goldenYellow, width: 2),
                    ),
                    child: Image.asset(
                      isOnline
                          ? "assets/images/qr_online.png"
                          : "assets/images/qr_offline.png",
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2_rounded, size: 100, color: deepOceanBlue),
                            const SizedBox(height: 8),
                            Text(
                              "UPI Payment QR",
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Step 1: Scan and complete payment\nStep 2: Take a screenshot of the receipt\nStep 3: Submit receipt to your manager below",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openWhatsApp(
                    managerPhone,
                    "Hello, I have completed the course fee payment. Please find the attached transaction screenshot.",
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  "Share Screenshot via WhatsApp",
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepOceanBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}