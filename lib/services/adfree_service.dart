import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 평생 광고 제거 권한 상태.
/// 구매·복원은 purchase_service.dart가 담당하고, 여기는 권한의
/// 저장(SharedPreferences 플래그)과 메모리 캐시만 둔다.
/// 권한이 있으면 배너·전면 광고를 안 보여주고, 이름 짓기 1위 결과도
/// 가리지 않는다. 앱 시작 시 스토어 구매 내역으로 복원·갱신한다.
class AdFreeService {
  static final AdFreeService instance = AdFreeService._internal();
  AdFreeService._internal();

  /// SharedPreferences 키 (평생 광고 제거 여부).
  static const String prefsKey = 'jakmyeongbyeol_adfree_lifetime';

  final ValueNotifier<bool> isAdFreeNotifier = ValueNotifier(false);

  bool get isAdFree => isAdFreeNotifier.value;

  bool _loaded = false;

  /// 저장된 권한을 읽어 메모리에 올린다. 이미 읽었으면 바로 반환한다.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    isAdFreeNotifier.value = prefs.getBool(prefsKey) ?? false;
    _loaded = true;
  }

  /// 권한을 저장하고 화면들에 알린다.
  Future<void> setAdFree(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, value);
    isAdFreeNotifier.value = value;
    _loaded = true;
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
