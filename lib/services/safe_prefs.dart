import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 안전 래퍼.
/// 저장소 실패(디스크·초기화·권한 등)가 앱 로직으로 예외를 전파하지 않게 한다.
/// 모든 신규 저장소 접근은 이 헬퍼를 통한다 (2026-11-20 저장소 전수 점검).
/// - 읽기는 실패 시 null을 돌려준다.
/// - 쓰기는 성공 여부를 bool로 돌려준다 (실패 시 false, 예외 없음).
/// - 쓰기 실패 시 1회 재시도한다.
///
/// 예외: services/favorites.dart는 이미 try/catch와 재시도·복구 로직을 갖추고
/// 테스트돼 있어 직접 접근을 유지한다. interstitial_gate.dart는
/// 읽기(readAttemptCount)만 직접 접근하고, 쓰기(recordAttempt)는
/// SafePrefs를 쓴다 (2026-11-20 리뷰 반영).
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
    // 쓰기 실패 시 1회 재시도한다. getInstance()가 던지거나
    // write()가 던지는 경우도 다시 시도한다 — 이전에는 false를
    // 반환하는 경우만 재시도돼 예외 경로가 그대로 실패했다
    // (오푸스·제미나이 리뷰, 2026-11-20).
    for (var i = 0; i < 2; i++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (await write(prefs)) return true;
      } catch (_) {
        // 다음 시도에서 getInstance()부터 다시 한다.
      }
    }
    return false;
  }
}
