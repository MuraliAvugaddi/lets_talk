import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Controllers/classModeController.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage1_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage2_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage3_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage4_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage5_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage6_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_meteral_5/Hindi_stage7_screen.dart';
import 'package:lets_talk/Screens/widgets/assembly_join_screen.dart';
import 'package:lets_talk/Screens/app_colors.dart';


// --- HINDI ONLINE STAGE SCREENS ---
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage1_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage2_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage3_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage4_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage5_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage6_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hindi_online5/Hindi_online_stage7_screen.dart';

// ============================================================
// INTERNET CONNECTION CHECKER HELPER
// ============================================================

Future<bool> _checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } catch (_) {}
  return false;
}

void _showNoInternetSnackbar() {
  Get.snackbar(
    "No Internet Connection",
    "Your internet is not working. Please check your connection.",
    backgroundColor: AppColors.error,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
  );
}

class HindiMainScreen extends StatefulWidget {
  const HindiMainScreen({super.key});

  @override
  State<HindiMainScreen> createState() => _HindiMainScreenState();
}

class _HindiMainScreenState extends State<HindiMainScreen> {
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    final bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
      return;
    }
    await Future.wait([
      authController.refreshProfile(),
      ClassModeController.to.fetch(), // 🌐 offline-online day / 🎙 special class
    ]);
  }

  bool _isLocked(String key) {
    final hindi = authController.userData['hindiAccess'];
    if (hindi == null || hindi is! Map) return true;
    return hindi[key] != true;
  }

  int _unlockedCount() {
    var count = 0;
    for (var i = 1; i <= 7; i++) {
      if (_isLocked('stage$i') == false) count++;
    }
    return count;
  }

  Future<void> _openStage(
    BuildContext context,
    String title,
    bool locked,
    Widget destination,
  ) async {
    final bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
      return;
    }

    if (locked) {
      _showAccessDeniedDialog(context, title);
      return;
    }

    Get.to(() => destination);
  }

  void _showAccessDeniedDialog(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final text = isDark ? AppColors.darkText : AppColors.text;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    Get.dialog(
      Dialog(
        backgroundColor: surface,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppColors.yellow.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow.withValues(alpha: 0.13),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: AppColors.yellow,
                  size: 29,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Stage Locked',
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Your access to $title is locked. Please contact your institute admin to unlock this stage.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: secondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 21),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: Get.back,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final soft = isDark ? AppColors.darkSurface2 : AppColors.surfaceSoft;
    final text = isDark ? AppColors.darkText : AppColors.text;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final stages = <Map<String, dynamic>>[
      {
        'title': 'Stage 1 – Foundation',
        'subtitle': 'Foundational Hindi',
        'description': 'Build your basic Hindi foundation',
        'icon': Icons.translate_rounded,
        'destination': const HindiStage1Screen(),
      },
      {
        'title': 'Stage 2 – Accuracy',
        'subtitle': 'Basic Grammar',
        'description': 'Understand sentence structure',
        'icon': Icons.menu_book_rounded,
        'destination': const HindiStage2Screen(),
      },
      {
        'title': 'Stage 3 – Progression',
        'subtitle': 'Conversational Skills',
        'description': 'Speak with more confidence',
        'icon': Icons.forum_rounded,
        'destination': const HindiStage3Screen(),
      },
      {
        'title': 'Stage 4 – Correctness',
        'subtitle': 'Vocabulary Expansion',
        'description': 'Grow your everyday vocabulary',
        'icon': Icons.auto_stories_rounded,
        'destination': const HindiStage4Screen(),
      },
      {
        'title': 'Stage 5 – Confidence',
        'subtitle': 'Fluency Practice',
        'description': 'Improve flow and accuracy',
        'icon': Icons.record_voice_over_rounded,
        'destination': const HindiStage5Screen(),
      },
      {
        'title': 'Stage 6 – Fluency',
        'subtitle': 'Advanced Speaking',
        'description': 'Strengthen advanced speaking',
        'icon': Icons.mic_rounded,
        'destination': const HindiStage6Screen(),
      },
      {
        'title': 'Stage 7 – Mastery',
        'subtitle': 'Mastery & Expression',
        'description': 'Reach confident expression',
        'icon': Icons.workspace_premium_rounded,
        'destination': const HindiStage7Screen(),
      },
    ];

    final onlineStages = <Map<String, dynamic>>[
      {
        'label': 'Stage 1 – Foundation',
        'destination': const HindiOnlineStage1Screen(),
      },
      {
        'label': 'Stage 2 – Accuracy',
        'destination': const HindiOnlineStage2Screen(),
      },
      {
        'label': 'Stage 3 – Progression',
        'destination': const HindiOnlineStage3Screen(),
      },
      {
        'label': 'Stage 4 – Correctness',
        'destination': const HindiOnlineStage4Screen(),
      },
      {
        'label': 'Stage 5 – Confidence',
        'destination': const HindiOnlineStage5Screen(),
      },
      {
        'label': 'Stage 6 – Fluency',
        'destination': const HindiOnlineStage6Screen(),
      },
      {
        'label': 'Stage 7 – Mastery',
        'destination': const HindiOnlineStage7Screen(),
      },
    ];

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          // FIXED APP BAR — this stays on screen while the content scrolls.
          _buildAppBar(
            context,
            isDark: isDark,
            text: text,
            secondary: secondary,
          ),

          // ONLY THIS AREA SCROLLS.
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: RefreshIndicator(
                color: AppColors.teal,
                backgroundColor: surface,
                onRefresh: _refreshAllData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      sliver: SliverToBoxAdapter(
                        child: Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ClassModeController.to.assemblyOn) _buildAssemblyCard(),
                              if (ClassModeController.to.rainOn &&
                                  (authController.userData['mode'] ?? 'online').toString().toLowerCase() == 'offline')
                                _buildRainNotice(),
                              _buildProgressHero(
                                isDark: isDark,
                                unlocked: _unlockedCount(),
                              ),
                              const SizedBox(height: 20),
                              _buildOnlineCard(
                                context,
                                isDark: isDark,
                                surface: surface,
                                soft: soft,
                                text: text,
                                secondary: secondary,
                                border: border,
                                stages: onlineStages,
                              ),
                              const SizedBox(height: 24),
                              _buildSectionHeader(
                                text: text,
                                secondary: secondary,
                                unlocked: _unlockedCount(),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(stages.length, (index) {
                                final item = stages[index];
                                final number = index + 1;
                                final locked = _isLocked('stage$number');

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildStageCard(
                                    context,
                                    isDark: isDark,
                                    surface: surface,
                                    soft: soft,
                                    text: text,
                                    secondary: secondary,
                                    border: border,
                                    number: number,
                                    title: item['title'] as String,
                                    subtitle: item['subtitle'] as String,
                                    description: item['description'] as String,
                                    icon: item['icon'] as IconData,
                                    locked: locked,
                                    destination: item['destination'] as Widget,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context, {
    required bool isDark,
    required Color text,
    required Color secondary,
  }) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.deepNavy, AppColors.navy]
              : const [AppColors.deepNavy, AppColors.navy],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Obx(() {
        final rawName = authController.userData['name']?.toString().trim();
        final name = (rawName == null || rawName.isEmpty) ? 'Learner' : rawName;
        final initial = name.substring(0, 1).toUpperCase();

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good to see you',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        color: AppColors.teal,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'हिंदी',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.yellow,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  'Hindi Learning',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '7 stages',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProgressHero({required bool isDark, required int unlocked}) {
    final progress = unlocked / 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: isDark ? 0.10 : 0.055),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.blue],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.yellow,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unlocked == 0
                          ? 'Start your Hindi journey'
                          : 'Keep your Hindi journey going',
                      style: GoogleFonts.poppins(
                        color: isDark ? AppColors.darkText : AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unlocked == 0
                          ? 'Your learning path starts here.'
                          : 'You have $unlocked of 7 stages unlocked.',
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.poppins(
                    color: AppColors.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.teal.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  // 🎙 Special class card (everyone joins one class)
  Widget _buildAssemblyCard() {
    final cm = ClassModeController.to;
    return GestureDetector(
      onTap: () => Get.to(() => AssemblyJoinScreen(title: cm.assemblyTitle, startTime: cm.assemblyTime)),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7B2FF7), Color(0xFFD6336C)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cm.assemblyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                  Text(
                    'Today ${cm.assemblyTime.isNotEmpty ? 'at ${cm.assemblyTime} ' : ''}• all students join one class',
                    maxLines: 2,
                    style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text('Join',
                  style: GoogleFonts.poppins(color: const Color(0xFF7B2FF7), fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  // 🌐 Offline classes online today (reason from admin)
  Widget _buildRainNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Text('🌐', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${ClassModeController.to.onlineReason.isNotEmpty ? '${ClassModeController.to.onlineReason} • ' : ''}Today your class is ONLINE. Join from "Interactive Classes" at your usual time — your trainer teaches there.',
              style: GoogleFonts.poppins(color: AppColors.blue, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineCard(
    BuildContext context, {
    required bool isDark,
    required Color surface,
    required Color soft,
    required Color text,
    required Color secondary,
    required Color border,
    required List<Map<String, dynamic>> stages,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: isDark ? 0.09 : 0.045),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.teal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Classes',
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Online practice sessions',
                      style: GoogleFonts.poppins(
                        color: secondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ONLINE',
                  style: GoogleFonts.poppins(
                    color: isDark ? AppColors.yellow : AppColors.deepNavy,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: stages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = stages[index];
                final number = index + 1;
                final locked = _isLocked('stage$number');

                return _buildOnlineStage(
                  context,
                  label: item['label'] as String,
                  number: number,
                  locked: locked,
                  soft: soft,
                  secondary: secondary,
                  onTap: () => _openStage(
                    context,
                    'Online ${item['label']}',
                    locked,
                    item['destination'] as Widget,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStage(
    BuildContext context, {
    required String label,
    required int number,
    required bool locked,
    required Color soft,
    required Color secondary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: locked
                        ? soft
                        : AppColors.navy.withValues(alpha: 0.075),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: locked
                          ? AppColors.border.withValues(alpha: 0.65)
                          : AppColors.teal.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Icon(
                    locked
                        ? Icons.lock_outline_rounded
                        : Icons.videocam_rounded,
                    color: locked ? secondary : AppColors.navy,
                    size: 21,
                  ),
                ),
                if (!locked)
                  Positioned(
                    right: -2,
                    top: -3,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: locked ? secondary : AppColors.navy,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required Color text,
    required Color secondary,
    required int unlocked,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hindi Learning Path',
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Learn step by step and build your confidence',
                style: GoogleFonts.poppins(color: secondary, fontSize: 10.5),
              ),
            ],
          ),
        ),
        if (unlocked > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$unlocked unlocked',
              style: GoogleFonts.poppins(
                color: AppColors.teal,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStageCard(
    BuildContext context, {
    required bool isDark,
    required Color surface,
    required Color soft,
    required Color text,
    required Color secondary,
    required Color border,
    required int number,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required bool locked,
    required Widget destination,
  }) {
    final accent = locked
        ? secondary
        : number == 7
        ? AppColors.yellow
        : AppColors.teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openStage(context, title, locked, destination),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: locked ? border : AppColors.teal.withValues(alpha: 0.23),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: isDark ? 0.075 : 0.04),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 57,
                  height: 57,
                  decoration: BoxDecoration(
                    color: locked ? soft : accent.withValues(alpha: 0.095),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: locked ? border : accent.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          icon,
                          color: locked ? secondary : accent,
                          size: 25,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 7,
                        child: Text(
                          number.toString().padLeft(2, '0'),
                          style: GoogleFonts.poppins(
                            color: locked
                                ? secondary.withValues(alpha: 0.48)
                                : accent.withValues(alpha: 0.70),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                          ),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!locked && number == 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'START',
                                style: GoogleFonts.poppins(
                                  color: AppColors.teal,
                                  fontSize: 6.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: secondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!locked)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.teal,
                                size: 12,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: locked
                                    ? secondary.withValues(alpha: 0.82)
                                    : AppColors.teal,
                                fontSize: 9.5,
                                fontWeight: locked
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: locked
                        ? soft
                        : AppColors.navy.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    locked
                        ? Icons.lock_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: locked ? secondary : AppColors.navy,
                    size: locked ? 14 : 13,
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