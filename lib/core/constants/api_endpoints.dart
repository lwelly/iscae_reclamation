class ApiEndpoints {
  // الرابط الأساسي للسيرفر
  // Pour Web/Émulateur Android sur le même ordinateur
  static const String baseUrl = 'http://192.168.100.59:8000/api/v1';

  // ── Auth Endpoints ─────────────────────────────────
  static const String verifyIdentity = '/auth/verify-identity';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String getMe = '/auth/me';

  // ── Student Endpoints ──────────────────────────────
  static const String dashboard = '/student/dashboard';
  static const String semestres = '/student/semestres';
  static const String notes = '/student/notes';
  static const String reclamations = '/student/reclamations';
  static const String notifications = '/student/notifications';
  static const String notificationCounts = '/student/notifications/counts';
  static const String readAllNotifications = '/student/notifications/read-all';
  static const String profile = '/student/profile';
  static const String modules = '/student/modules';
  static const String documents = '/student/documents';

  // ── Student Profile Endpoints ─────────────────────
  static const String profilePhoto = '/student/profile/photo';
  static const String profilePassword = '/student/profile/password';

  // دالة مساعدة للمسارات التي تحتوي على ID ديناميكي
  static String showReclamation(int id) => '$reclamations/$id';
  static String updateReclamation(int id) => '$reclamations/$id';
  static String showNote(int id) => '$notes/$id';
  static String showNotification(int id) => '$notifications/$id';
  static String readNotification(int id) => '$notifications/$id/read';
  static String deleteNotification(int id) => '$notifications/$id';
  static String showDocument(int id) => '$documents/$id';
}