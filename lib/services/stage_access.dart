// =====================================================================
// 🎓 STAGE ACCESS — same rules as the server (utils/stageAccess.js)
//
//   englishAccess / hindiAccess = CURRENT stage  → join class, attendance, tests
//   englishDone   / hindiDone   = FINISHED stage → study material only
//   isDropout = true            → no live class at all, material of every stage stays open
//
// Example: Venkat promoted Stage 1 → 2
//   Stage 1: material ✅  join class ❌  attendance ❌
//   Stage 2: material ✅  join class ✅  attendance ✅
// =====================================================================
class StageAccess {
  StageAccess._();

  static Map _map(dynamic v) => v is Map ? v : const {};
  static String _accessKey(String language) => language == 'Hindi' ? 'hindiAccess' : 'englishAccess';
  static String _doneKey(String language) => language == 'Hindi' ? 'hindiDone' : 'englishDone';

  static bool isDropout(Map user) => user['isDropout'] == true;

  /// Current stage → live class, attendance, tests
  static bool live(Map user, String language, String stageKey) =>
      !isDropout(user) && _map(user[_accessKey(language)])[stageKey] == true;

  /// Finished stage (promoted / dropout) → material only
  static bool finished(Map user, String language, String stageKey) =>
      _map(user[_accessKey(language)])[stageKey] != true && _map(user[_doneKey(language)])[stageKey] == true;

  /// Study material may be opened
  static bool material(Map user, String language, String stageKey) =>
      _map(user[_accessKey(language)])[stageKey] == true || _map(user[_doneKey(language)])[stageKey] == true;

  /// "Stage 1" / "stage1" / 1 → "stage1"
  static String key(dynamic stage) {
    final n = RegExp(r'\d').firstMatch(stage.toString())?.group(0) ?? '1';
    return 'stage$n';
  }
}
