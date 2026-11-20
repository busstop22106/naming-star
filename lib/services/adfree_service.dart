import 'package:flutter/foundation.dart';

import 'safe_prefs.dart';

/// 평생 광고 제거 권한 상태.
/// 구매·복원은 purchase_service.dart가 담당하고, 여기는 권한의
/// 저장(SharedPreferences 플래그)과 메모리 캐시만 둔다.
/// 권한이 있으면 배너·전면 광고를 안 보여주고, 이름 짓기 1위 결과도
/// 가리지 않는다. 앱 시작 시 스토어 구매 내역으로 복원·갱신한다.
///
/// 저장 실패가 구매 흐름을 깨뜨리지 않게 SafePrefs를 쓴다
/// (2026-11-20 저장소 전수 점검). 저장에 실패해도 메모리 플래그는
/// 바로 바꾸고, 다음 시작 때 스토어 구매 내역으로 다시 맞춘다.
class AdFreeService {
  static final AdFreeService instance = AdFreeService._internal();
  AdFreeService._internal();

  /// SharedPreferences 키 (평생 광고 제거 여부).
  static const String prefsKey = 'jakmyeongbyeol_adfree_lifetime';

  final ValueNotifier<bool> isAdFreeNotifier = ValueNotifier(false);

  bool get isAdFree => isAdFreeNotifier.value;

  bool _loaded = false;

  /// 저장된 권한을 읽어 메모리에 올린다. 이미 읽었으면 바로 반환한다.
  /// 저장소를 못 읽으면 false 그대로 두고 던지지 않는다.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    isAdFreeNotifier.value = await SafePrefs.getBool(prefsKey) ?? false;
    _loaded = true;
  }

  /// 권한을 저장하고 화면들에 알린다.
  /// 저장이 실패해도 메모리 플래그는 바로 바꿔 구매 직후 화면에
  /// 바로 반영되게 하고, 다음 시작 때 스토어 내역으로 다시 맞춘다.
  /// 예외는 던지지 않는다.
  Future<void> setAdFree(bool value) async {
    isAdFreeNotifier.value = value;
    _loaded = true;
    await SafePrefs.setBool(prefsKey, value);
  }

  @visibleForTesting
  void resetForTest() {
    _loaded = false;
    isAdFreeNotifier.value = false;
  }

  @visibleForTesting
  void setForTest(bool value) {
    _loaded = true;
    isAdFreeNotifier.value = value;
  }
}
