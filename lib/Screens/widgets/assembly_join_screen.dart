import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Controllers/assemblyCallController.dart';
import 'package:lets_talk/Screens/class_hand_chat.dart';

/// 🎙 Special class — everyone (all languages, stages, sections) in ONE live class.
/// • Students join muted. Mic works when Sir lets everyone talk (or allowed this student).
/// • Joins automatically the moment Sir goes live (socket), no refresh needed.
/// • Attendance is marked for every stage the student has.
/// • ➖ Minimize: go read your notes — the class keeps playing in a small bubble.
///
/// The live call itself lives in AssemblyCallController, so closing this page
/// does NOT leave the class. Only "Leave class" does.
class AssemblyJoinScreen extends StatefulWidget {
  /// true while the class page is on screen (so "class ended" knows to close it)
  static bool isOpen = false;

  final String title;
  final String startTime;
  const AssemblyJoinScreen({super.key, this.title = 'Surendra Sir Special Class', this.startTime = ''});

  @override
  State<AssemblyJoinScreen> createState() => _AssemblyJoinScreenState();
}

class _AssemblyJoinScreenState extends State<AssemblyJoinScreen> {
  final AssemblyCallController ctrl = AssemblyCallController.to;
  bool _leaving = false;
  Worker? _phaseWorker;

  // ✋ raise hand + 💬 ask Sir (same tools as the normal class)
  void _attachChat() {
    final c = ctrl.call;
    if (ctrl.phase.value != AssemblyPhase.live || c == null) return;
    final chat = StudentClassChat.instance;
    chat.attach(c);
    chat.onNotice = (text, kind) {
      if (!mounted) return;
      Get.snackbar(
        kind == 'msg' ? 'Message from Sir' : (kind == 'ok' ? 'You can speak now 🎤' : 'Hand lowered'),
        kind == 'msg' ? text.replaceFirst(RegExp(r'^Teacher( \(to you\))?: '), '') : text,
        backgroundColor: kind == 'ok' ? const Color(0xFF16A66A) : const Color(0xFF0E466D),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: kind == 'msg' ? 5 : 3),
      );
    };
  }

  Future<void> _toggleHand() async {
    final err = await StudentClassChat.instance.toggleHand();
    if (err != null) {
      Get.snackbar('Raise hand', err.replaceAll('Your teacher', 'Sir'),
          backgroundColor: const Color(0xFFE59E1B), colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } else if (StudentClassChat.instance.handUp.value) {
      Get.snackbar('Hand raised ✋', 'Sir can see it. Wait until Sir allows you to speak.',
          backgroundColor: const Color(0xFF0E466D), colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
  }

  @override
  void initState() {
    super.initState();
    AssemblyJoinScreen.isOpen = true;
    ctrl.pageOpened(); // came back from the bubble / home card → hide the bubble
    ctrl.start(title: widget.title, startTime: widget.startTime); // no-op if already in the class
    _attachChat();
    _phaseWorker = ever<AssemblyPhase>(ctrl.phase, (p) {
      if (p == AssemblyPhase.live) _attachChat();
    });
  }

  @override
  void dispose() {
    AssemblyJoinScreen.isOpen = false;
    _phaseWorker?.dispose();
    StudentClassChat.instance.onNotice = null;
    // Page closed (back arrow, phone back, Minimize) but still in the class → keep it running as a bubble
    if (!_leaving) {
      if (ctrl.phase.value == AssemblyPhase.live) {
        ctrl.minimize(); // class is ON → keep listening in the small bubble
      } else {
        ctrl.leave(); // not started yet / error → just go back, nothing keeps running
      }
    }
    super.dispose();
  }

  void _minimize() {
    if (ctrl.isActive) {
      Get.snackbar(
        'Class is still on 🎧',
        'Open your notes. Tap the floating bubble to come back.',
        backgroundColor: const Color(0xFF0E466D),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
    Get.back(); // dispose() turns it into the bubble
  }

  Future<void> _leave() async {
    _leaving = true;
    StudentClassChat.instance.detach();
    await ctrl.leave();
    if (mounted) Get.back();
  }

  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2E47),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B2E47), Color(0xFF155A88)],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            ctrl.tick.value; // refresh once a second (smooth with 2,500 people)
            final phase = ctrl.phase.value;
            final live = phase == AssemblyPhase.live;
            final canMinimize = live; // only a running class can be minimized
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: canMinimize ? 'Minimize (class keeps playing)' : 'Back',
                        onPressed: canMinimize ? _minimize : _leave,
                        icon: Icon(canMinimize ? Icons.keyboard_arrow_down_rounded : Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: canMinimize ? 28 : 20),
                      ),
                      Expanded(
                        child: Text('Special class',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      if (live) _liveBadge(),
                    ],
                  ),
                ),
                Expanded(child: Center(child: _body(phase))),
                if (!live) _goBackBar(phase),
                if (live) _bottomBar(),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// ⬅ Class not started yet → a clear way back home
  Widget _goBackBar(AssemblyPhase phase) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phase == AssemblyPhase.waiting)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'You can come back from the Home screen card when Sir starts.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _leave,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: Text('Go back',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF155A88),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _bottomBar() {
    final micOn = ctrl.micOn;
    final canSpeak = ctrl.canSpeak;
    final busy = ctrl.micBusy.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        children: [
          // 🎤 mute / unmute
          SizedBox(
            width: 64,
            height: 56,
            child: ElevatedButton(
              onPressed: busy ? null : ctrl.toggleMic,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: micOn ? Colors.white : Colors.white.withValues(alpha: canSpeak ? 0.18 : 0.08),
                foregroundColor: micOn ? const Color(0xFF155A88) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(micOn ? Icons.mic_rounded : (canSpeak ? Icons.mic_off_rounded : Icons.lock_rounded), size: 26),
            ),
          ),
          const SizedBox(width: 8),
          // ✋ raise hand
          Obx(() {
            final up = StudentClassChat.instance.handUp.value;
            return _squareButton(
              icon: up ? Icons.pan_tool_rounded : Icons.pan_tool_outlined,
              tooltip: up ? 'Lower hand' : 'Raise hand',
              background: up ? const Color(0xFFF5C542) : Colors.white.withValues(alpha: 0.18),
              color: up ? const Color(0xFF0B2E47) : Colors.white,
              onTap: _toggleHand,
            );
          }),
          const SizedBox(width: 8),
          // 💬 ask Sir
          Obx(() {
            final n = StudentClassChat.instance.unread.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _squareButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'Ask Sir',
                  background: Colors.white.withValues(alpha: 0.18),
                  color: Colors.white,
                  onTap: () => showStudentChatSheet(context),
                ),
                if (n > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFE45757), borderRadius: BorderRadius.circular(8)),
                      child: Text(n > 9 ? '9+' : '$n',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _leave,
                icon: const Icon(Icons.call_end_rounded),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Leave', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE45757),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareButton({
    required IconData icon,
    required String tooltip,
    required Color background,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 56,
          height: 56,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(56, 56),
              backgroundColor: background,
              foregroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Icon(icon, size: 24),
          ),
        ),
      );

  Widget _liveBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE45757), borderRadius: BorderRadius.circular(8)),
        child: Text('LIVE', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
      );

  Widget _body(AssemblyPhase phase) {
    switch (phase) {
      case AssemblyPhase.idle:
      case AssemblyPhase.preparing:
      case AssemblyPhase.joining:
        return _centerInfo(
          icon: null,
          title: phase == AssemblyPhase.joining ? 'Joining…' : 'Getting ready…',
          subtitle: ctrl.title,
        );
      case AssemblyPhase.waiting:
        return _centerInfo(
          icon: Icons.hourglass_top_rounded,
          title: 'Not started yet',
          subtitle:
              '${ctrl.title}${ctrl.startTime.isNotEmpty ? ' starts at ${ctrl.startTime}' : ''}.\nStay on this screen and you join automatically when Sir starts.',
        );
      case AssemblyPhase.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _centerInfo(icon: Icons.info_outline_rounded, title: 'Special class', subtitle: ctrl.errorText.value),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: ctrl.connect,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text('Try again', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)),
            ),
          ],
        );
      case AssemblyPhase.live:
        final speaking = ctrl.speakingName;
        final micOn = ctrl.micOn;
        final canSpeak = ctrl.canSpeak;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: speaking.isNotEmpty ? const Color(0xFF28C2C2) : Colors.white24,
                    width: speaking.isNotEmpty ? 4 : 2,
                  ),
                ),
                child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 18),
              Text(ctrl.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                speaking.isNotEmpty ? '🔊 $speaking is speaking' : 'Listening…',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _pill(Icons.groups_rounded, '${ctrl.peopleCount} in class'),
                  _pill(
                    micOn ? Icons.mic_rounded : (canSpeak ? Icons.mic_off_rounded : Icons.lock_rounded),
                    micOn ? 'You are talking' : (canSpeak ? 'You can unmute' : 'Mics locked by Sir'),
                  ),
                  _pill(Icons.check_circle_rounded, 'Attendance counted'),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _centerInfo({IconData? icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == null)
            const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          else
            Icon(icon, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.5, height: 1.45)),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
