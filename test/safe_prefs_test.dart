import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/services/safe_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// 첫 getAll 호출에서만 예외를 던지는 테스트용 저장소.
/// SafePrefs의 재시도가 getInstance() 예외를 복구하는지 검증한다
/// (오푸스·제미나이 리뷰, 2026-11-20).
class _FlakyStore extends InMemorySharedPreferencesStore {
  _FlakyStore() : super.withData(<String, Object>{});
  int _getAllCalls = 0;

  @override
  Future<Map<String, Object>> getAll() async {
    _getAllCalls++;
    if (_getAllCalls == 1) {
      throw Exception('simulated getAll failure');
    }
    return super.getAll();
  }
}

void main() {
  test('setBool: getInstance 1차 실패 시 재시도해 성공한다', () async {
    // setMockInitialValues는 completer를 초기화하고 저장소를
    // 인메모리로 바꾼다 — 그 뒤에 flaky 저장소로 교체한다.
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _FlakyStore();
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    expect(await SafePrefs.setBool('k', true), isTrue);
    expect(await SafePrefs.getBool('k'), isTrue);
  });

  test('setBool: 두 번 다 실패하면 false를 돌려주고 던지지 않는다', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _AlwaysFailingStore();
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    expect(await SafePrefs.setBool('k', true), isFalse);
  });

  test('getBool: 저장소를 못 읽으면 null을 돌려준다', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _AlwaysFailingStore();
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    expect(await SafePrefs.getBool('k'), isNull);
  });
}

/// getAll이 항상 실패하는 저장소.
class _AlwaysFailingStore extends InMemorySharedPreferencesStore {
  _AlwaysFailingStore() : super.withData(<String, Object>{});

  @override
  Future<Map<String, Object>> getAll() async {
    throw Exception('simulated persistent getAll failure');
  }
}
