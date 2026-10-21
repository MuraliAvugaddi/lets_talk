import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Screens/Test_screens/TestTaking_widgetScreen.dart';
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

/// Tests home (no language switch): shows the student's OWN courses — English, Hindi or both —
/// unlocked stages first, locked ones folded into one line. Updates live when the admin publishes.
/// Every stage shows its real status from the server:
///   🔒 Locked • ⏳ No test yet • ▶ Start (questions • minutes) • ✅ Done with score
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AuthController authController = Get.find<AuthController>();
  final Map<String, bool> _showLocked = {'English': false, 'Hindi': false};

  // language → stage → status from /test/user/test-overview
  final Map<String, Map<String, Map<String, dynamic>>> _overview = {};
  final Map<String, bool> _loading = {'English': true, 'Hindi': true};

  /// Languages the student studies (any stage enabled). None yet → English.
  List<String> get _myLanguages {
    bool any(dynamic m) => m is Map && m.values.any((v) => v == true);
    final en = any(authController.userData['englishAccess']);
    final hi = any(authController.userData['hindiAccess']);
    // Both courses are always shown; the one the student studies comes first
    return (hi && !en) ? ['Hindi', 'English'] : ['English', 'Hindi'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.refreshProfile();
      _loadOverview('English');
      _loadOverview('Hindi');
    });
    // ⚡ Admin published / paused / deleted a test → refresh without pulling down
    authController.socket?.on('test_updated', _onTestUpdated);
  }

  @override
  void dispose() {
    authController.socket?.off('test_updated', _onTestUpdated);
    super.dispose();
  }

  void _onTestUpdated(dynamic data) {
    if (!mounted || data is! Map) return;
    final language = (data['language'] ?? '').toString();
    if (language != 'English' && language != 'Hindi') return;
    _loadOverview(language);
    final stage = (data['stage'] ?? '').toString();
    final n = stage.replaceAll(RegExp(r'[^0-9]'), '');
    final access = authController.userData[language == 'English' ? 'englishAccess' : 'hindiAccess'];
    final mine = access is Map && access[stage] == true;
    if (data['action'] == 'published' && mine) {
      Get.snackbar(
        "New test 📝",
        "$language Stage $n test is ready. Tap it to start.",
        backgroundColor: AppColors.teal,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Map<String, String> get _headers {
    final token = (GetStorage().read('token') ?? '').toString();
    return {if (token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }

  Future<void> _loadOverview(String language) async {
    final user = authController.userData;
    final userId = (user['id'] ?? user['_id'] ?? '').toString();
    try {
      final res = await http
          .get(
            Uri.parse("${ApiEndpoints.baseUrl}/test/user/test-overview?language=$language&userId=$userId"),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final map = <String, Map<String, dynamic>>{};
        for (final s in (data['stages'] as List? ?? const [])) {
          final m = Map<String, dynamic>.from(s as Map);
          map[m['stage'].toString()] = m;
        }
        _overview[language] = map;
      }
    } catch (e) {
      debugPrint('Test overview error: $e');
    } finally {
      _loading[language] = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _refresh() async {
    await authController.refreshProfile();
    await Future.wait([_loadOverview('English'), _loadOverview('Hindi')]);
  }

  bool _isLocked(String language, String stageKey) {
    final access = authController.userData[language == 'English' ? 'englishAccess' : 'hindiAccess'];
    if (access == null || access is! Map) return true;
    return access[stageKey] != true;
  }

  Future<void> _open(String language, int stage) async {
    await Get.to(() => TestTakingScreen(language: language, stage: 'stage$stage'));
    _loadOverview(language); // came back → show the new score right away
  }

  void _showAccessDeniedDialog(String testName) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final text = theme.colorScheme.onSurface;
    final secondary = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.65);

    Get.dialog(
      Dialog(
        backgroundColor: surface,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
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
                child: const Icon(Icons.lock_rounded, color: AppColors.warning, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                'Stage locked',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: text, fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '$testName opens when the institute enables this stage for you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: secondary, fontSize: 13, height: 1.5),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('OK', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
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
    final secondary = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(surface: surface, text: text, secondary: secondary, isDark: isDark),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.navy,
                backgroundColor: surface,
                onRefresh: _refresh,
                child: Obx(() {
                  authController.userData.length; // rebuild when access changes
                  final languages = _myLanguages;

                  int done = 0, open = 0;
                  for (final language in languages) {
                    final stages = _overview[language] ?? const {};
                    for (var n = 1; n <= 7; n++) {
                      final s = stages['stage$n'];
                      if (_isLocked(language, 'stage$n') || s == null) continue;
                      if (s['completed'] == true) {
                        done++;
                      } else if (s['available'] == true) {
                        open++;
                      }
                    }
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      _buildSummary(language: languages.first, done: done, open: open),
                      for (final language in languages) ...[
                        const SizedBox(height: 16),
                        ..._languageSection(language, true, surface, text, secondary, isDark),
                      ],
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

  /// One course: unlocked stages as cards, locked stages folded into a single line
  List<Widget> _languageSection(
      String language, bool showTitle, Color surface, Color text, Color secondary, bool isDark) {
    final stages = _overview[language] ?? const {};
    final loading = _loading[language] == true && stages.isEmpty;
    final unlocked = [for (var n = 1; n <= 7; n++) if (!_isLocked(language, 'stage$n')) n];
    final locked = [for (var n = 1; n <= 7; n++) if (_isLocked(language, 'stage$n')) n];
    final showLocked = _showLocked[language] == true;
    final enrolled = unlocked.isNotEmpty;

    Widget card(int n) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTestCard(
            stageNumber: n,
            language: language,
            isLocked: _isLocked(language, 'stage$n'),
            info: stages['stage$n'] ?? const <String, dynamic>{},
            surface: surface,
            text: text,
            secondary: secondary,
            isDark: isDark,
            onTap: () {
              if (_isLocked(language, 'stage$n')) {
                _showAccessDeniedDialog('$language Stage $n test');
              } else {
                _open(language, n);
              }
            },
          ),
        );

    return [
      if (showTitle)
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            children: [
              Icon(language == 'English' ? Icons.menu_book_rounded : Icons.translate_rounded,
                  size: 17, color: AppColors.navy),
              const SizedBox(width: 7),
              Text('$language course',
                  style: GoogleFonts.poppins(color: text, fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (enrolled ? AppColors.teal : AppColors.textSecondary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  enrolled ? '${unlocked.length} of 7 open' : 'Not enrolled',
                  style: GoogleFonts.poppins(
                    color: enrolled ? AppColors.teal : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      if (loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2.5)),
        )
      else ...[
        ...unlocked.map(card),
        if (locked.isNotEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _showLocked[language] = !(_showLocked[language] ?? false)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 15, color: secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      enrolled
                          ? '${locked.length} more stage${locked.length == 1 ? '' : 's'} locked'
                          : 'All 7 stages locked — ask the institute to join $language',
                      style: GoogleFonts.poppins(color: secondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(showLocked ? 'Hide' : 'Show',
                      style: GoogleFonts.poppins(color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.w700)),
                  Icon(showLocked ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.navy, size: 20),
                ],
              ),
            ),
          ),
        if (showLocked) ...locked.map(card),
      ],
    ];
  }

  Widget _buildHeader({
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
                ),
                child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assessment',
                        style: GoogleFonts.poppins(color: secondary, fontSize: 11, fontWeight: FontWeight.w500)),
                    Text('Take a Test',
                        style: GoogleFonts.poppins(
                            color: text, fontSize: 21, fontWeight: FontWeight.w700, height: 1.15)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary({required String language, required int done, required int open}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.deepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(language == 'English' ? Icons.menu_book_rounded : Icons.translate_rounded,
                color: AppColors.yellow, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open > 0 ? '$open test${open == 1 ? '' : 's'} waiting for you' : (done > 0 ? 'You are all caught up 🎉' : 'No tests right now'),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  open == 0 && done == 0 ? 'New tests appear here automatically' : '$done completed • results are saved forever',
                  style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.76), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required int stageNumber,
    required String language,
    required bool isLocked,
    required Map<String, dynamic> info,
    required Color surface,
    required Color text,
    required Color secondary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bool available = info['available'] == true;
    final bool completed = info['completed'] == true;
    final int questions = int.tryParse('${info['questions'] ?? 0}') ?? 0;
    final int minutes = int.tryParse('${info['durationMinutes'] ?? 25}') ?? 25;
    final int? score = int.tryParse('${info['score'] ?? ''}');
    final int? total = int.tryParse('${info['total'] ?? ''}');
    final int? lastScore = int.tryParse('${info['lastScore'] ?? ''}');
    final int? lastTotal = int.tryParse('${info['lastTotal'] ?? ''}');

    // status → colour, label, subtitle
    late final Color c;
    late final String badge;
    late final String subtitle;
    late final IconData icon;
    if (isLocked) {
      c = AppColors.textSecondary;
      badge = 'Locked';
      subtitle = 'Opens when this stage is enabled';
      icon = Icons.lock_outline_rounded;
    } else if (completed) {
      c = AppColors.success;
      badge = '${score ?? 0}/${total ?? 0}';
      subtitle = 'Completed • tap to see result & answers';
      icon = Icons.check_circle_rounded;
    } else if (available) {
      c = AppColors.teal;
      badge = 'Start';
      subtitle = '$questions questions • $minutes min';
      icon = Icons.play_arrow_rounded;
    } else {
      c = AppColors.warning;
      badge = 'Soon';
      subtitle = lastScore != null
          ? 'No new test • last score $lastScore/${lastTotal ?? 0}'
          : 'No test published yet';
      icon = Icons.hourglass_top_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: available && !completed && !isLocked
                  ? AppColors.teal.withValues(alpha: 0.55)
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: available && !completed && !isLocked ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  stageNumber.toString().padLeft(2, '0'),
                  style: GoogleFonts.poppins(color: c, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stage $stageNumber Assessment',
                      style: GoogleFonts.poppins(color: text, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: secondary, fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: c),
                    const SizedBox(width: 4),
                    Text(badge, style: GoogleFonts.poppins(color: c, fontSize: 11, fontWeight: FontWeight.w800)),
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