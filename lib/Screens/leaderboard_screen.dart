import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lets_talk/Screens/app_colors.dart';
import 'package:lets_talk/apis/api_endpoint.dart';

/// Student app: Best Student + Best Trainer of the month / year, and "your rank".
class StudentLeaderboardScreen extends StatefulWidget {
  const StudentLeaderboardScreen({super.key});

  @override
  State<StudentLeaderboardScreen> createState() => _StudentLeaderboardScreenState();
}

class _StudentLeaderboardScreenState extends State<StudentLeaderboardScreen> {
  static const Color gold = Color(0xFFE3B21B);
  static const Color silver = Color(0xFF9AAAB8);
  static const Color bronze = Color(0xFFC07A45);

  bool yearly = false;
  bool isLoading = true;
  String? errorText;
  Map<String, dynamic>? students;
  Map<String, dynamic>? trainers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String> get _headers {
    final token = (GetStorage().read('token') ?? '').toString();
    return {if (token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>?> _fetch(String role) async {
    final now = DateTime.now();
    final res = await http.get(
      Uri.parse(
        "${ApiEndpoints.baseUrl}/leaderboard?role=$role&period=${yearly ? 'year' : 'month'}"
        "&year=${now.year}&month=${now.month}&limit=10",
      ),
      headers: _headers,
    );
    if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
    throw Exception(res.statusCode == 401 ? 'Please log in again.' : 'Could not load (${res.statusCode})');
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      final results = await Future.wait([_fetch('student'), _fetch('teacher')]);
      if (!mounted) return;
      setState(() {
        students = results[0];
        trainers = results[1];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

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
          "Hall of Fame 🏆",
          style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
          children: [
            _periodToggle(context),
            const SizedBox(height: 14),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
              )
            else if (errorText != null)
              _infoBox(context, Icons.error_outline_rounded, errorText!, AppColors.error)
            else ...[
              if (students?['me'] != null) _myRankCard(context, Map<String, dynamic>.from(students!['me'])),
              if (students?['me'] != null) const SizedBox(height: 14),
              _winnerCard(context, 'BEST STUDENT', students, Icons.school_rounded, AppColors.teal),
              const SizedBox(height: 12),
              _winnerCard(context, 'BEST TRAINER', trainers, Icons.record_voice_over_rounded, AppColors.yellow),
              const SizedBox(height: 20),
              Text(
                "TOP STUDENTS",
                style: GoogleFonts.poppins(
                  color: textColor.withOpacity(.65),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ..._rankList(context, students),
              const SizedBox(height: 10),
              Text(
                "Ranked by attendance %, then on-time days, then minutes in class.",
                style: GoogleFonts.poppins(color: textColor.withOpacity(.5), fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _periodToggle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    Widget seg(String label, bool selected, VoidCallback onTap) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : textColor.withOpacity(.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.teal.withOpacity(.2)),
      ),
      child: Row(
        children: [
          seg('This Month', !yearly, () {
            if (!yearly) return;
            setState(() => yearly = false);
            _load();
          }),
          const SizedBox(width: 4),
          seg('This Year', yearly, () {
            if (yearly) return;
            setState(() => yearly = true);
            _load();
          }),
        ],
      ),
    );
  }

  Widget _infoBox(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: theme.colorScheme.onSurface, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _myRankCard(BuildContext context, Map<String, dynamic> me) {
    final total = students?['totalRanked'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.deepNavy, AppColors.navy]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.yellow, width: 2),
            ),
            child: Text(
              "#${me['rank']}",
              style: GoogleFonts.poppins(color: AppColors.yellow, fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "YOUR RANK • ${(students?['periodLabel'] ?? '').toString().toUpperCase()}",
                  style: GoogleFonts.poppins(
                    color: AppColors.yellow,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                Text(
                  "${me['rank']} of $total students",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  "${me['percentage']}% attendance • ${me['attended']}/${me['workingDays']} days",
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _winnerCard(
    BuildContext context,
    String title,
    Map<String, dynamic>? board,
    IconData icon,
    Color accent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final winner = board?['winner'] == null ? null : Map<String, dynamic>.from(board!['winner']);
    final name = (winner?['name'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(.45), width: 1.3),
        boxShadow: [
          BoxShadow(color: gold.withOpacity(isDark ? .10 : .15), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [gold, Color(0xFFF7DF55)]),
                ),
                child: CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  child: winner == null
                      ? Icon(icon, color: accent)
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(color: gold, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              if (winner != null)
                const Positioned(
                  top: -13,
                  left: 0,
                  right: 0,
                  child: Center(child: Text('👑', style: TextStyle(fontSize: 18))),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title • ${(board?['periodLabel'] ?? '').toString().toUpperCase()}",
                  style: GoogleFonts.poppins(
                    color: gold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  winner == null ? "Not decided yet" : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: textColor, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                if (winner != null)
                  Text(
                    "${winner['percentage']}% attendance • ${winner['attended']}/${winner['workingDays']} days",
                    style: GoogleFonts.poppins(color: textColor.withOpacity(.6), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rankList(BuildContext context, Map<String, dynamic>? board) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final ranking = List<Map<String, dynamic>>.from(
      ((board?['ranking'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
    final myId = (GetStorage().read('user')?['id'] ?? GetStorage().read('user')?['_id'] ?? '').toString();

    if (ranking.isEmpty) {
      return [
        _infoBox(context, Icons.hourglass_empty_rounded, "No ranking yet for this period.", AppColors.teal),
      ];
    }

    return ranking.map((p) {
      final int rank = (p['rank'] as num?)?.toInt() ?? 0;
      final int pct = (p['percentage'] as num?)?.toInt() ?? 0;
      final medal = rank == 1 ? gold : rank == 2 ? silver : rank == 3 ? bronze : null;
      final bool isMe = p['userId']?.toString() == myId;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isMe ? AppColors.teal.withOpacity(.12) : theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isMe ? AppColors.teal : (medal?.withOpacity(.5) ?? AppColors.teal.withOpacity(.15)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (medal ?? AppColors.navy).withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                "$rank",
                style: GoogleFonts.poppins(
                  color: medal ?? (theme.brightness == Brightness.dark ? AppColors.teal : AppColors.navy),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                isMe ? "${p['name']} (You)" : (p['name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: textColor, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              "$pct%",
              style: GoogleFonts.poppins(
                color: pct >= 75 ? AppColors.success : (pct >= 50 ? AppColors.warning : AppColors.error),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
