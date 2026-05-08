import 'package:shared_preferences/shared_preferences.dart';

import '../../config/routes/route_names.dart';
import '../sessioin/current_user.dart';

class CachedSession {
  const CachedSession({
    required this.uid,
    required this.role,
    required this.homeRoute,
    required this.profileComplete,
    this.batchId,
    this.academicYear,
    this.email,
    this.name,
  });

  final String uid;
  final String role;
  final String homeRoute;
  final bool profileComplete;
  final String? batchId;
  final int? academicYear;
  final String? email;
  final String? name;

  void applyToCurrentUser() {
    CurrentUser.uid = uid;
    CurrentUser.role = role;
    CurrentUser.batchId = batchId;
    CurrentUser.academicYear = academicYear;
    CurrentUser.email = email;
    CurrentUser.name = name;
  }
}

class SessionCacheService {
  SessionCacheService._();

  static final SessionCacheService instance = SessionCacheService._();

  static const String _uidKey = 'session_uid';
  static const String _roleKey = 'session_role';
  static const String _batchIdKey = 'session_batch_id';
  static const String _academicYearKey = 'session_academic_year';
  static const String _emailKey = 'session_email';
  static const String _nameKey = 'session_name';
  static const String _homeRouteKey = 'session_home_route';
  static const String _profileCompleteKey = 'session_profile_complete';

  Future<void> saveResolvedSession({
    required String uid,
    required String role,
    required String homeRoute,
    required bool profileComplete,
    String? batchId,
    int? academicYear,
    String? email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, uid);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_homeRouteKey, homeRoute);
    await prefs.setBool(_profileCompleteKey, profileComplete);

    await _setNullableString(prefs, _batchIdKey, batchId);
    await _setNullableInt(prefs, _academicYearKey, academicYear);
    await _setNullableString(prefs, _emailKey, email);
    await _setNullableString(prefs, _nameKey, name);
  }

  Future<CachedSession?> loadForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUid = prefs.getString(_uidKey);
    if (cachedUid == null || cachedUid != uid) return null;

    final role = prefs.getString(_roleKey);
    final homeRoute = prefs.getString(_homeRouteKey);
    if (role == null || role.isEmpty || homeRoute == null || homeRoute.isEmpty) {
      return null;
    }

    return CachedSession(
      uid: cachedUid,
      role: role,
      batchId: prefs.getString(_batchIdKey),
      academicYear: prefs.getInt(_academicYearKey),
      email: prefs.getString(_emailKey),
      name: prefs.getString(_nameKey),
      homeRoute: homeRoute,
      profileComplete: prefs.getBool(_profileCompleteKey) ?? false,
    );
  }

  Future<void> updateProfileCompletion({
    required String uid,
    required bool profileComplete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_uidKey) != uid) return;
    await prefs.setBool(_profileCompleteKey, profileComplete);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uidKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_batchIdKey);
    await prefs.remove(_academicYearKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_homeRouteKey);
    await prefs.remove(_profileCompleteKey);
    CurrentUser.uid = null;
    CurrentUser.role = null;
    CurrentUser.batchId = null;
    CurrentUser.academicYear = null;
    CurrentUser.email = null;
    CurrentUser.name = null;
  }

  Future<String?> initialRouteForUid(String uid) async {
    final cached = await loadForUid(uid);
    if (cached == null) return null;
    if (cached.profileComplete) return cached.homeRoute;
    return Routes.profile;
  }

  Future<void> _setNullableString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, normalized);
  }

  Future<void> _setNullableInt(
    SharedPreferences prefs,
    String key,
    int? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setInt(key, value);
  }
}
