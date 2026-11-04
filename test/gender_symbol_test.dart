import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/engine/compat.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/compat_screen.dart';

void main() {
  group('genderSymbolForRole', () {
    test('남성 역할은 ♂', () {
      for (final role in ['아빠', '형', '오빠', '할아버지', '남편']) {
        expect(genderSymbolForRole(role), '♂', reason: role);
      }
    });

    test('여성 역할은 ♀', () {
      for (final role in ['엄마', '누나', '언니', '할머니', '아내']) {
        expect(genderSymbolForRole(role), '♀', reason: role);
      }
    });

    test('동생은 역할만으로 성별을 알 수 없어 빈 문자열', () {
      expect(genderSymbolForRole('동생'), '');
      expect(genderSymbolForRole('기타'), '');
    });
  });

  testWidgets('가족관계도 노드에 아빠 ♂·엄마 ♀가 보인다', (tester) async {
    tester.view.physicalSize = const Size(390, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final picks = [
      const HanjaPick(
          syllable: '도', char: '道', strokes: 13, element: '화', meaning: '길'),
      const HanjaPick(
          syllable: '윤', char: '潤', strokes: 16, element: '수', meaning: '윤택'),
    ];
    final result = computeFamilyCompat(
      members: [
        (label: '아빠', saju: sajuOfBirth(DateTime(1987, 6, 15), 10)),
        (label: '엄마', saju: sajuOfBirth(DateTime(1990, 9, 20), null)),
        (label: '동생', saju: sajuOfBirth(DateTime(2022, 5, 1), null)),
      ],
      babySaju: sajuOfBirth(DateTime(2026, 10, 19), 8),
      picks: picks,
    );
    await tester.pumpWidget(MaterialApp(
        home: CompatScreen(
            babyFullName: '김도윤',
            babyHanjaName: '道潤',
            isPureKorean: false,
            result: result)));
    // 지도의 두근두근 애니메이션이 반복돼 pumpAndSettle은 못 쓴다.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('♂'), findsOneWidget);
    expect(find.text('♀'), findsOneWidget);
  });
}
