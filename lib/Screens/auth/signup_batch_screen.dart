import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/batch_slots.dart';

/// Signup step 3: choose the class timing (one of the 7 daily batches).
/// Flow: Step 1 (details) → Step 2 (online/offline) → THIS → OTP → account created.
class SignupBatchScreen extends GetView<AuthController> {
  const SignupBatchScreen({super.key});

  static const Color navy = Color(0xFF155A88);
  static const Color deepNavy = Color(0xFF0E466D);
  static const Color teal = Color(0xFF28C2C2);
  static const Color yellow = Color(0xFFF7DF55);

  static const Color background = Color(0xFFE8F2F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4F9FC);
  static const Color border = Color(0xFFD5E5EE);
  static const Color text = Color(0xFF173A52);
  static const Color textSecondary = Color(0xFF678196);

  @override
  Widget build(BuildContext context) {
    final bool isOnline = controller.selectedMode == 'online';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Material(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back_rounded, color: text, size: 20),
            ),
          ),
        ),
        titleSpacing: 8,
        title: Text(
          "Create Account",
          style: GoogleFonts.poppins(color: text, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              color: navy.withOpacity(0.07),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: navy, shape: BoxShape.circle),
                          child: const Icon(Icons.schedule_rounded, color: yellow, size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        "Choose Your Class Timing",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: text,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        "Pick the batch you will attend every day. You can change it later from your profile.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: textSecondary, fontSize: 11.5, height: 1.45),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(child: _modeChip(isOnline)),
                    const SizedBox(height: 20),
                    _periodHeader("Morning", Icons.wb_sunny_rounded, yellow),
                    const SizedBox(height: 9),
                    ...BatchSlots.morning.map(_slotCard),
                    const SizedBox(height: 14),
                    _periodHeader("Evening", Icons.nights_stay_rounded, teal),
                    const SizedBox(height: 9),
                    ...BatchSlots.evening.map(_slotCard),
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(bool isOnline) {
    final color = isOnline ? navy : teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOnline ? Icons.wifi_rounded : Icons.location_on_rounded, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            isOnline ? "ONLINE STUDENT" : "OFFLINE STUDENT",
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color == yellow ? deepNavy : color, size: 15),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(color: text, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _slotCard(BatchSlot slot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Obx(() {
        final bool selected = controller.selectedBatch.value == slot.label;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => controller.selectedBatch.value = slot.label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? navy.withOpacity(0.07) : surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? navy : border, width: selected ? 1.5 : 1.1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? navy : surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? navy : border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "BATCH",
                          style: GoogleFonts.poppins(
                            color: selected ? yellow : textSecondary,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "${slot.number}",
                          style: GoogleFonts.poppins(
                            color: selected ? Colors.white : text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
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
                          "${slot.start} – ${slot.end} ${slot.period}",
                          style: GoogleFonts.poppins(
                            color: text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "90-minute class",
                          style: GoogleFonts.poppins(color: textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? teal : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? teal : border, width: 1.6),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: surface,
        border: const Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(color: navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, -4)),
        ],
      ),
      child: Obx(() {
        final String chosen = controller.selectedBatch.value;
        final bool loading = controller.isLoading.value;
        final slot = BatchSlots.find(chosen);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Selected: ${slot.title} • ${slot.shortLabel}",
                  style: GoogleFonts.poppins(color: navy, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (chosen.isEmpty || loading) ? null : controller.confirmBatchAndSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  disabledBackgroundColor: navy.withOpacity(0.45),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chosen.isEmpty ? "Select a timing" : "Continue & Verify Phone",
                            style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                          if (chosen.isNotEmpty) ...[
                            const SizedBox(width: 7),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
