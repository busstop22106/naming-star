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
    // 가중치는 이름 있는 상수(_weightSuri 등)로 정의돼 있다 — 상수 정의에서
    // 값을 읽어 확인한다 (2026-11-17, 리터럴에서 상수화로 변경).
    final constWeights = <String, double>{};
    for (final m in RegExp(r'const double (_weight\w+) = (0\.\d+);')
        .allMatches(src)) {
      constWeights[m.group(1)!] = double.parse(m.group(2)!);
    }
    expect(constWeights, {
      '_weightSuri': 0.35, // 수리 35%
      '_weightResource': 0.25, // 사주 보완 25%
      '_weightSound': 0.20, // 발음 20%
      '_weightYinYang': 0.10, // 음양 10%
      '_weightUsability': 0.10, // 사용성 10%
    });
    // 종합 점수 계산이 이 상수들을 쓰는지 확인한다.
    for (final entry in {
      'suri.score': '_weightSuri',
      'resource.score': '_weightResource',
      'sound.score': '_weightSound',
      'yy.score': '_weightYinYang',
      'usa.score': '_weightUsability',
    }.entries) {
      expect(src.contains('${entry.key} * ${entry.value}'), isTrue,
          reason: '종합 점수에 ${entry.key} * ${entry.value}가 없다');
    }
    final sum = constWeights.values.fold(0.0, (a, b) => a + b);
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
