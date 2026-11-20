import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 안전 래퍼.
/// 저장소 실패(디스크·초기화·권한 등)가 앱 로직으로 예외를 전파하지 않게 한다.
/// 모든 신규 저장소 접근은 이 헬퍼를 통한다 (2026-11-20 저장소 전수 점검).
/// - 읽기는 실패 시 null을 돌려준다.
/// - 쓰기는 성공 여부를 bool로 돌려준다 (실패 시 false, 예외 없음).
/// - 쓰기 실패 시 1회 재시도한다.
///
/// 예외: favorites.dart와 interstitial_gate.dart는 이미 try/catch와
/// 재시도·복구 로직을 갖추고 테스트돼 있어 직접 접근을 유지한다.
/// architecture_test.dart가 직접 접근 허용 파일을 강제한다.
class SafePrefs {
  static Future<SharedPreferences?> _instance() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getString(String key) async {
    final prefs = await _instance();
    if (prefs == null) return null;
    try {
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await _instance();
    if (prefs == null) return null;
    try {
      return prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getInt(String key) async {
    final prefs = await _instance();
    if (prefs == null) return null;
    try {
      return prefs.getInt(key);
    } catch (_) {
      return null;
    }
  }

  /// 쓰기. 성공하면 true, 실패하면 false. 예외는 던지지 않는다.
  static Future<bool> setString(String key, String value) =>
      _set((p) => p.setString(key, value));

  static Future<bool> setBool(String key, bool value) =>
      _set((p) => p.setBool(key, value));

  static Future<bool> setInt(String key, int value) =>
      _set((p) => p.setInt(key, value));

  static Future<bool> remove(String key) => _set((p) => p.remove(key));

  static Future<bool> _set(
      Future<bool> Function(SharedPreferences p) write) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (await write(prefs)) return true;
      // 1차 쓰기 실패 시 한 번 더 시도한다.
      return await write(prefs);
    } catch (_) {
      return false;
    }
  }
}
