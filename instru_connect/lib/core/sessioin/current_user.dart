class CurrentUser {
  static String? uid;
  static String? role;
  static String? batchId;
  static int? academicYear;
  static String? email;
  static String? name;

  static bool get isCr => role == 'cr';
  static bool get isStudent => role == 'student';
}
