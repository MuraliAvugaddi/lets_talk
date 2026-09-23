import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/Test_screens/test_all_screen_teststart.dart';
import 'package:lets_talk/Screens/app_colors.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AuthController authController = Get.find<AuthController>();
  final RxInt selectedTab = 0.obs; // 0 = English, 1 = Hindi

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.refreshProfile();
    });
  }

  bool _isEnglishLocked(String stageKey) {
    final access = authController.userData['englishAccess'];
    if (access == null || access is! Map) return true;
    return access[stageKey] != true;
  }

  bool _isHindiLocked(String stageKey) {
    final access = authController.userData['hindiAccess'];
    if (access == null || access is! Map) return true;
    return access[stageKey] != true;
  }

  void _showAccessDeniedDialog(String testName) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final text = theme.colorScheme.onSurface;
    final secondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    Get.dialog(
      Dialog(
        backgroundColor: surface,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.warning,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Access Restricted',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin approval is required to access $testName.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: secondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Understood',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final text = theme.colorScheme.onSurface;
    final secondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    final List<Map<String, dynamic>> englishStages = [
      {'stage': 1, 'key': 'stage1', 'dest': const EnglishTestStage1Screen()},
      {'stage': 2, 'key': 'stage2', 'dest': const EnglishTestStage2Screen()},
      {'stage': 3, 'key': 'stage3', 'dest': const EnglishTestStage3Screen()},
      {'stage': 4, 'key': 'stage4', 'dest': const EnglishTestStage4Screen()},
      {'stage': 5, 'key': 'stage5', 'dest': const EnglishTestStage5Screen()},
      {'stage': 6, 'key': 'stage6', 'dest': const EnglishTestStage6Screen()},
      {'stage': 7, 'key': 'stage7', 'dest': const EnglishTestStage7Screen()},
    ];

    final List<Map<String, dynamic>> hindiStages = [
      {'stage': 1, 'key': 'stage1', 'dest': const HindiTestStage1Screen()},
      {'stage': 2, 'key': 'stage2', 'dest': const HindiTestStage2Screen()},
      {'stage': 3, 'key': 'stage3', 'dest': const HindiTestStage3Screen()},
      {'stage': 4, 'key': 'stage4', 'dest': const HindiTestStage4Screen()},
      {'stage': 5, 'key': 'stage5', 'dest': const HindiTestStage5Screen()},
      {'stage': 6, 'key': 'stage6', 'dest': const HindiTestStage6Screen()},
      {'stage': 7, 'key': 'stage7', 'dest': const HindiTestStage7Screen()},
    ];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(
              context,
              surface: surface,
              text: text,
              secondary: secondary,
              isDark: isDark,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.navy,
                backgroundColor: surface,
                onRefresh: () async {
                  await authController.refreshProfile();
                  if (mounted) setState(() {});
                },
                child: Obx(() {
                  final isEnglish = selectedTab.value == 0;
                  final currentList = isEnglish ? englishStages : hindiStages;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      _buildIntroCard(
                        context,
                        isEnglish: isEnglish,
                        surface: surface,
                        text: text,
                        secondary: secondary,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              isEnglish ? 'English Tests' : 'Hindi Tests',
                              style: GoogleFonts.poppins(
                                color: text,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${currentList.length} Stages',
                              style: GoogleFonts.poppins(
                                color: AppColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...currentList.map((item) {
                        final int stageNum = item['stage'];
                        final String key = item['key'];
                        final Widget destination = item['dest'];

                        final bool isLocked = isEnglish
                            ? _isEnglishLocked(key)
                            : _isHindiLocked(key);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTestCard(
                            context,
                            stageNumber: stageNum,
                            language: isEnglish ? 'English' : 'Hindi',
                            isLocked: isLocked,
                            surface: surface,
                            text: text,
                            secondary: secondary,
                            onTap: () {
                              if (isLocked) {
                                _showAccessDeniedDialog('Stage $stageNum Test');
                              } else {
                                Get.to(() => destination);
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color surface,
    required Color text,
    required Color secondary,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.deepNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment',
                      style: GoogleFonts.poppins(
                        color: secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Take a Test',
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.teal,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildLanguageSelector(
            context,
            surface: surface,
            secondary: secondary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context, {
    required Color surface,
    required Color secondary,
    required bool isDark,
  }) {
    return Obx(
      () => Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildLanguageTab(
                context,
                label: 'English',
                icon: Icons.language_rounded,
                selected: selectedTab.value == 0,
                secondary: secondary,
                onTap: () => selectedTab.value = 0,
              ),
            ),
            Expanded(
              child: _buildLanguageTab(
                context,
                label: 'Hindi',
                icon: Icons.translate_rounded,
                selected: selectedTab.value == 1,
                secondary: secondary,
                onTap: () => selectedTab.value = 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTab(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required Color secondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? Colors.white : secondary),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : secondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(
    BuildContext context, {
    required bool isEnglish,
    required Color surface,
    required Color text,
    required Color secondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.deepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Icon(
              isEnglish ? Icons.menu_book_rounded : Icons.translate_rounded,
              color: AppColors.yellow,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish
                      ? 'Build your English skills'
                      : 'अपनी हिन्दी skills बेहतर करें',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete each stage to measure your progress.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white54,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required int stageNumber,
    required String language,
    required bool isLocked,
    required Color surface,
    required Color text,
    required Color secondary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLocked
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.border)
                  : AppColors.navy.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.16
                      : 0.055,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildStageNumber(stageNumber, isLocked: isLocked),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stage $stageNumber Assessment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: secondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$language  •  25 minutes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: secondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildActionBadge(isLocked: isLocked),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageNumber(int stageNumber, {required bool isLocked}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.navy.withValues(alpha: 0.07)
            : AppColors.navy.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked
              ? AppColors.border
              : AppColors.navy.withValues(alpha: 0.20),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        stageNumber.toString().padLeft(2, '0'),
        style: GoogleFonts.poppins(
          color: isLocked ? AppColors.textSecondary : AppColors.navy,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActionBadge({required bool isLocked}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.yellow.withValues(alpha: 0.12)
            : AppColors.teal.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_rounded,
        color: isLocked ? AppColors.yellow : AppColors.teal,
        size: 19,
      ),
    );
  }
}
