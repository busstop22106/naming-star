import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 채점 가중치 고정 테스트 (수리 35% · 사주 보완 25% · 발음 20% ·
/// 음양 10% · 사용성 10%).
///
/// 총점 절대값에는 의존하지 않는다 — 엔진의 총점 환산 방식이 바뀌어도
/// 이 테스트는 차원 가중치 자체만 확인한다. 그래서 가중치는
/// analyzeName 결과값이 아니라 총점 계산식에서 차원 점수 뒤에 붙은
/// 계수를 직접 읽어서 확인한다. (전체 총점에 곱해지는 환산 계수가
/// 생겨도 차원 가중치는 그대로 잡힌다.)
void main() {
  test('채점 가중치: 5개 차원의 합이 1.0이고 각 가중치가 35/25/20/10/10이다',
      () {
    final src = File('lib/engine/scoring.dart').readAsStringSync();
    final weights = <String, double>{};
    for (final m in RegExp(
            r'(suriScore|resourceScore|soundScore|yyScore|usa)\s*\*\s*(0\.\d+)')
        .allMatches(src)) {
      weights[m.group(1)!] = double.parse(m.group(2)!);
    }
    expect(weights, {
      'suriScore': 0.35, // 수리 35%
      'resourceScore': 0.25, // 사주 보완 25%
      'soundScore': 0.20, // 발음 20%
      'yyScore': 0.10, // 음양 10%
      'usa': 0.10, // 사용성 10%
    });
    final sum = weights.values.fold(0.0, (a, b) => a + b);
    expect(sum, closeTo(1.0, 1e-9));
  });

  test('채점 가중치: 상세 화면 부제와 엔진 가중치가 일치한다', () {
    final detail =
        File('lib/screens/detail_screen.dart').readAsStringSync();
    expect(
        detail.contains(
            '수리 35% · 사주 보완 25% · 발음 20% · 음양 10% · 사용성 10%'),
        isTrue);
  });
}
