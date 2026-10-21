// 📲 App update check — moved to AppUpdateChecker (lib/services/app_update_checker.dart).
// The UpdateController itself now lives in home_screen.dart.
// This file only forwards to it, so any old import of this file keeps working.
export 'package:lets_talk/Screens/home_screen.dart' show UpdateController;