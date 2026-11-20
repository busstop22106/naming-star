import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';
import 'adfree_service.dart';
import 'safe_prefs.dart';

/// 결과 직전 전면 광고 게이트.
/// 이름 분석·가족 궁합 두 흐름이 공유하는 단일 카운터로,
/// 결과 시도마다 1씩 올리고 4의 배수(4·8·12…)면 광고 차례다.
/// 이름 짓기는 전면 광고를 띄우지 않는다 (1위 확인은 보상형 광고로만 한다).
/// 평생 광고 제거를 구매했으면 광고를 안 보여주고 Reveal 경로로 바로 간다.
class InterstitialGate {
  static const String countKey = 'jakmyeongbyeol_result_attempt_count';
  static const int adEvery = 4;

  /// 세션 내 카운터. SharedPreferences 저장이 실패해도
  /// 세션 안에서는 4번째마다 광고가 뜨게 한다 (2026-11-20).
  /// 실기기에서 저장소 쓰기가 실패해 카운터가 안 올라가면
  /// 광고가 영원히 안 뜨는 문제가 재현됐다.
  static int? _memoryCount;

  @visibleForTesting
  static void resetForTest() {
    _memoryCount = null;
  }

  static bool isAdTurn(int attemptCount) => attemptCount % adEvery == 0;

  static Future<int> readAttemptCount({SharedPreferences? prefs}) async {
    if (_memoryCount != null) return _memoryCount!;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      _memoryCount = p.getInt(countKey) ?? 0;
    } catch (_) {
      _memoryCount = 0;
    }
    return _memoryCount!;
  }

  /// 시도 횟수를 1 올리고, 올린 뒤의 횟수를 반환한다.
  /// 저장은 최선을 다하고, 실패해도 세션 카운터는 유지한다 —
  /// 저장 실패가 광고 차례 자체를 막지 않게 한다 (2026-11-20).
  static Future<int> recordAttempt({SharedPreferences? prefs}) async {
    final next = await readAttemptCount(prefs: prefs) + 1;
    _memoryCount = next;
    // 저장은 SafePrefs로 통일한다 — getInstance() 예외나 setInt
    // 예외도 1회 재시도한다 (이전에는 setInt가 던지면 재시도를
    // 건너뛰었다. 제미나이 리뷰, 2026-11-20).
    // 저장 실패해도 세션 카운터로 광고 차례는 유지된다.
    await SafePrefs.setInt(countKey, next);
    return next;
  }

  /// 결과 화면으로 이동한다. 광고 차례(4의 배수)면 광고를 먼저 보여주고
  /// 닫히면 결과로 바로 가고, 광고가 준비 안 됐거나 표시에 실패해도
  /// 결과로 바로 간다(애니메이션으로 되돌아가지 않음).
  /// 광고 차례가 아니면 RevealScreen 애니메이션을 거쳐 결과로 간다.
  /// 카운터 저장에 실패해도 결과 보기를 막지 않는다(애니메이션 경로로 간다).
  static Future<void> goToResult(
    BuildContext context, {
    required WidgetBuilder resultBuilder,
    required WidgetBuilder revealBuilder,
    // false면 전면 광고를 띄우지 않고 카운터도 올리지 않는다.
    // (이름 짓기: 전면 광고 없이 항상 Reveal 경로로 간다.)
    bool showInterstitial = true,
  }) async {
    // 평생 광고 제거 상태면 광고 없이 Reveal 경로로 바로 간다.
    // 카운터도 올리지 않는다 (광고 차례 계산이 의미가 없어진다).
    if (AdFreeService.instance.isAdFree) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: revealBuilder),
      );
      return;
    }
    // 전면 광고를 안 띄우는 흐름은 카운터도 올리지 않고 Reveal 경로로 간다.
    if (!showInterstitial) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: revealBuilder),
      );
      return;
    }
    int attempt = 0;
    try {
      attempt = await recordAttempt();
    } catch (_) {
      attempt = 0;
    }
    if (!context.mounted) return;
    // attempt가 0이면 카운터 저장이 실패한 경우다. isAdTurn(0)은 true지만
    // 그건 광고 차례가 아니라 실패 신호이므로 애니메이션 경로로 간다.
    if (attempt > 0 && isAdTurn(attempt)) {
      await AdService.showInterstitialAd();
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: resultBuilder),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: revealBuilder),
    );
  }
}
