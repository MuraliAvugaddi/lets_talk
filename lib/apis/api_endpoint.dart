class ApiEndpoints {
  static const String baseUrl = "http://192.168.1.4:5000/api";
  static const String socketUrl = "http://192.168.1.4:5000";

  // Auth & Profile
  static const String register = "$baseUrl/register";
  static const String login = "$baseUrl/login";
  static const String resetPassword = "$baseUrl/reset-password";
  static const String profile = "$baseUrl/profile";
  static const String deleteUser = "$baseUrl/users";

  // Notifications
  static const String userNotification = "$baseUrl/user/notification";

  // Feedback
  static const String submitFeedback = "$baseUrl/user/feedback";

  // Attendance
  static const String markAttendance = "$baseUrl/user/mark-attendance";
  static const String joinOnlineClass = "$baseUrl/user/join-online-class";
  static const String syncOnlineClass = "$baseUrl/user/sync-online-class";
  static const String leaveOnlineClass = "$baseUrl/user/leave-online-class";
  static const String myAttendance = "$baseUrl/user/my-attendance";

  // Tests
  static const String getTest = "$baseUrl/test/user/get-test";
  static const String submitTest = "$baseUrl/test/user/submit-test";
  static const String myResults = "$baseUrl/test/user/my-results";
}
