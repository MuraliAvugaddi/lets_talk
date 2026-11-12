// =========================================================================
// ✋ RAISE HAND + 💬 ASK THE TRAINER — student side of the live class
//
// Messages go only to the trainer (not to 100 classmates), the trainer's
// messages come to everyone. Uses LiveKit data messages (no server call).
// =========================================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/rtc/live_room.dart';

class StudentChatMsg {
  final String text;
  final bool mine;
  final bool private; // trainer replied only to me
  final DateTime at;
  const StudentChatMsg(this.text, this.mine, this.private, this.at);
}

class StudentClassChat {
  StudentClassChat._();
  static final StudentClassChat instance = StudentClassChat._();

  final RxBool handUp = false.obs;
  final RxList<StudentChatMsg> messages = <StudentChatMsg>[].obs;
  final RxInt unread = 0.obs;
  bool chatOpen = false;

  /// The screen shows these as a snackbar (text, kind: ok / down / msg)
  void Function(String text, String kind)? onNotice;

  Call? _call;
  StreamSubscription<ClassSignal>? _sub;
  Timer? _resend;

  void attach(Call call) {
    if (identical(_call, call) && _sub != null) return;
    _sub?.cancel();
    _resend?.cancel();
    _call = call;
    handUp.value = false;
    messages.clear();
    unread.value = 0;
    _sub = call.signals.listen(_onSignal);
  }

  void detach() {
    _sub?.cancel();
    _sub = null;
    _resend?.cancel();
    _call = null;
    handUp.value = false;
  }

  void _onSignal(ClassSignal s) {
    if (!s.fromStaff) return; // only the trainer can talk to me here
    switch (s.type) {
      case 'hand_ok':
        _setHand(false);
        HapticFeedback.heavyImpact();
        onNotice?.call('Your trainer says: speak now! Tap the mic 🎤', 'ok');
        break;
      case 'hand_down':
        _setHand(false);
        onNotice?.call('Your trainer lowered your hand.', 'down');
        break;
      case 'msg':
        final text = (s.data['text'] ?? '').toString().trim();
        if (text.isEmpty) return;
        final private = s.data['private'] == true;
        messages.add(StudentChatMsg(text, false, private, DateTime.now()));
        if (messages.length > 200) messages.removeAt(0);
        if (!chatOpen) {
          unread.value++;
          onNotice?.call(
            '${private ? 'Trainer (to you)' : 'Trainer'}: $text',
            'msg',
          );
        }
        break;
    }
  }

  void _setHand(bool up) {
    handUp.value = up;
    _resend?.cancel();
    if (up) {
      // trainer may join late / reconnect → remind every 20 s while the hand is up
      _resend = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _sendHand(true),
      );
    }
  }

  Future<bool> _sendHand(bool up) async {
    final c = _call;
    if (c == null) return false;
    return c.sendSignal({'t': 'hand', 'up': up}, to: c.staffIds);
  }

  /// Returns a message to show if it did not work
  Future<String?> toggleHand() async {
    final c = _call;
    if (c == null) return 'You are not in a class.';
    final up = !handUp.value;
    if (up && c.staffIds.isEmpty)
      return 'Your trainer is not in the class right now.';
    final ok = await _sendHand(up);
    if (!ok && up) return 'Could not raise your hand. Check your internet.';
    _setHand(up);
    if (up) HapticFeedback.selectionClick();
    return null;
  }

  Future<String?> send(String text) async {
    final c = _call;
    final t = text.trim();
    if (c == null || t.isEmpty) return null;
    if (c.staffIds.isEmpty)
      return 'Your trainer is not in the class right now.';
    final ok = await c.sendSignal({'t': 'msg', 'text': t}, to: c.staffIds);
    if (!ok) return 'Could not send. Check your internet.';
    messages.add(StudentChatMsg(t, true, false, DateTime.now()));
    return null;
  }
}

// -------------------------------------------------------------------------
// 💬 Sheet: my questions + trainer messages
// -------------------------------------------------------------------------
Future<void> showStudentChatSheet(BuildContext context) async {
  final chat = StudentClassChat.instance;
  chat.chatOpen = true;
  chat.unread.value = 0;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Get.isDarkMode ? AppColors.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _StudentChatSheet(),
  );
  chat.chatOpen = false;
  chat.unread.value = 0;
}

class _StudentChatSheet extends StatefulWidget {
  const _StudentChatSheet();

  @override
  State<_StudentChatSheet> createState() => _StudentChatSheetState();
}

class _StudentChatSheetState extends State<_StudentChatSheet> {
  final chat = StudentClassChat.instance;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  Worker? _worker;

  bool get isDark => Get.isDarkMode;
  Color get textColor => isDark ? AppColors.darkText : AppColors.text;
  Color get secondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _worker = ever(chat.messages, (_) => _toBottom());
    _toBottom();
  }

  @override
  void dispose() {
    _worker?.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    if (_sending || _text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final err = await chat.send(_text.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err == null) {
      _text.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .65,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondary.withOpacity(.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ask your trainer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  'Only your trainer sees your message.',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: secondary),
                ),
              ),
              Divider(height: 1, color: secondary.withOpacity(.2)),
              Expanded(
                child: Obx(() {
                  final list = chat.messages.toList();
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet.\nType your doubt below.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: secondary,
                          fontSize: 12.5,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      return Align(
                        alignment: m.mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * .75,
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          decoration: BoxDecoration(
                            color: m.mine
                                ? AppColors.navy
                                : (isDark
                                      ? Colors.white.withOpacity(.08)
                                      : const Color(0xFFF2F5F9)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.mine
                                    ? 'You'
                                    : (m.private
                                          ? 'Trainer (only to you)'
                                          : 'Trainer'),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: m.mine
                                      ? Colors.white70
                                      : AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: m.mine ? Colors.white : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        maxLength: 300,
                        minLines: 1,
                        maxLines: 3,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: textColor,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Type your doubt…',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: secondary,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(.06)
                              : const Color(0xFFF2F5F9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.navy,
                      ),
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
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
}
