import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/apis/batch_slots.dart';

/// Signup step 3: choose the class timing (one of the 7 daily batches).
/// Flow: Step 1 (details) → Step 2 (online/offline) → THIS → OTP → account created.
/// All 7 timings fit on ONE screen (2 per row) — morning and evening visible together, no scrolling.
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
              // Fits on normal phones; scrolls only on very small screens as a safety net
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(isOnline),
                    const SizedBox(height: 16),
                    _periodHeader("Morning", "4 batches", Icons.wb_sunny_rounded, yellow),
                    const SizedBox(height: 8),
                    _grid(BatchSlots.morning),
                    const SizedBox(height: 14),
                    _periodHeader("Evening", "3 batches", Icons.nights_stay_rounded, teal),
                    const SizedBox(height: 8),
                    _grid(BatchSlots.evening),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Every class is 90 minutes • You can change it later",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: textSecondary, fontSize: 10.5),
                      ),
                    ),
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

  // ---------------- compact header ----------------
  Widget _header(bool isOnline) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: navy,
            shape: BoxShape.circle,
            border: Border.all(color: surface, width: 4),
            boxShadow: [
              BoxShadow(color: navy.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: const Icon(Icons.schedule_rounded, color: yellow, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose Your Class Timing",
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _modeChip(isOnline),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Pick one batch",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeChip(bool isOnline) {
    final color = isOnline ? navy : teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOnline ? Icons.wifi_rounded : Icons.location_on_rounded, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            isOnline ? "ONLINE" : "OFFLINE",
            style: GoogleFonts.poppins(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _periodHeader(String title, String count, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color == yellow ? deepNavy : color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(color: text, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text(count, style: GoogleFonts.poppins(color: textSecondary, fontSize: 10.5)),
      ],
    );
  }

  // ---------------- 2 timings per row ----------------
  Widget _grid(List<BatchSlot> slots) {
    final rows = <Widget>[];
    for (var i = 0; i < slots.length; i += 2) {
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: i + 2 < slots.length ? 8 : 0),
        child: Row(
          children: [
            Expanded(child: _slotTile(slots[i])),
            const SizedBox(width: 8),
            Expanded(child: i + 1 < slots.length ? _slotTile(slots[i + 1]) : const SizedBox.shrink()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }

  /// "5:30 AM" big, "till 7:00 AM" small — also correct for 10:30 AM – 12:00 PM
  Widget _slotTile(BatchSlot slot) {
    final String startText = '${slot.start} ${slot.period}';
    final String endText = '${slot.end} ${slot.endPeriod ?? slot.period}';

    return Obx(() {
      final bool selected = controller.selectedBatch.value == slot.label;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => controller.selectedBatch.value = slot.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? navy : surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? navy : border, width: selected ? 1.5 : 1.1),
              boxShadow: selected
                  ? [BoxShadow(color: navy.withOpacity(0.22), blurRadius: 12, offset: const Offset(0, 5))]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withOpacity(0.15) : surfaceSoft,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: selected ? Colors.white24 : border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${slot.number}",
                    style: GoogleFonts.poppins(
                      color: selected ? yellow : text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          startText,
                          style: GoogleFonts.poppins(
                            color: selected ? Colors.white : text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                      Text(
                        "till $endText",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: selected ? Colors.white70 : textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) const Icon(Icons.check_circle_rounded, color: teal, size: 18),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ---------------- bottom button ----------------
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