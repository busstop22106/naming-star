import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/compat.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/widgets/family_map_card.dart';

void main() {
  FamilyCompatResult sampleResult() {
    const picks = [
      HanjaPick(
          syllable: '도', char: '道', strokes: 13, element: '화', meaning: '길'),
      HanjaPick(
          syllable: '윤', char: '潤', strokes: 16, element: '수', meaning: '윤택'),
    ];
    return computeFamilyCompat(
      members: [
        (label: '아빠', saju: sajuOfBirth(DateTime(1987, 6, 15), 10)),
        (label: '엄마', saju: sajuOfBirth(DateTime(1990, 9, 20), null)),
      ],
      babySaju: sajuOfBirth(DateTime(2026, 10, 19), 8),
      picks: picks,
    );
  }

  /// 지도 가운데 뛰는 하트(크기 20)의 현재 스케일.
  double heartScale(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.ancestor(
        of: find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.favorite && w.size == 20,
        ),
        matching: find.byType(Transform),
      ),
    );
    return transform.transform.getMaxScaleOnAxis();
  }

  testWidgets('애니메이션 제거 설정에서는 하트 박동이 정지한다 (회귀)',
      (tester) async {
    // 시스템에서 '애니메이션 제거'가 켜져 있으면 하트 박동을 돌리지 않고
    // 정적 하트(기본 크기 1.0)를 보여야 한다 (오푸스·제미나이 리뷰,
    // 2026-11-20). 박동이 돌면 719ms 시점(두 번째 박동 정점)에
    // 스케일이 1.25 근처까지 커진다.
    final result = sampleResult();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(
                body: SizedBox(
                  width: 360,
                  child: FamilyMapCard(result: result),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 719));
    expect(heartScale(tester), 1.0);
  });

  testWidgets('애니메이션이 켜져 있으면 하트 박동이 돈다', (tester) async {
    final result = sampleResult();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: FamilyMapCard(result: result),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 719));
    expect(heartScale(tester), greaterThan(1.0));
  });
}
