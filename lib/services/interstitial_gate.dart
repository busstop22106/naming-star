import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';

/// 결과 직전 전면 광고 게이트.
/// 이름 짓기·이름 분석·가족 궁합 세 흐름이 공유하는 단일 카운터로,
/// 결과 시도마다 1씩 올리고 4의 배수(4·8·12…)면 광고 차례다.
class InterstitialGate {
  static const String countKey = 'jakmyeongbyeol_result_attempt_count';
  static const int adEvery = 4;

  static bool isAdTurn(int attemptCount) => attemptCount % adEvery == 0;

  static Future<int> readAttemptCount({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return p.getInt(countKey) ?? 0;
  }

  /// 시도 횟수를 1 올리고, 올린 뒤의 횟수를 반환한다.
  static Future<int> recordAttempt({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final next = (p.getInt(countKey) ?? 0) + 1;
    await p.setInt(countKey, next);
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
  }) async {
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
