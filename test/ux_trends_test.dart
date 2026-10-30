import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/engine/reason_line.dart';
import 'package:jakmyeongbyeol/engine/saju.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/favorites_screen.dart';
import 'package:jakmyeongbyeol/screens/recommend_screen.dart';

void main() {
  group('추천 근거 한 줄', () {
    test('막연한 문장 없이 계산 근거만 쓴다', () {
      final baby = BabyInfo(
        surname: '한',
        surnameHanja: '韓',
        surnameStrokes: 17,
        gender: Gender.boy,
        birth: DateTime(2024, 7, 11),
        birthHour: 15,
        birthMinute: 30,
      );
      final analysis = analyzeName(
        surname: '한',
        surnameStrokes: 17,
        picks: [
          orderedHanja('지').firstWhere((p) => p.char == '志'),
          orderedHanja('민').firstWhere((p) => p.char == '旻'),
        ],
        saju: computeSaju(baby),
        gender: Gender.boy,
      );
      final reason = recommendReason(analysis);
      expect(reason, contains('수리'));
      expect(reason, isNot(contains('AI')));
      // 용신 보완은 사주 보완 점수가 뒷받침할 때만 나온다.
      if (analysis.saju.yongsin != null &&
          analysis.resource.score >= 70) {
        expect(reason, contains('용신'));
      } else {
        expect(reason, isNot(contains('용신')));
      }
    });
  });

  group('보관함 빈 화면 CTA', () {
    testWidgets('이름 지으러 가기 버튼이 있다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          const MaterialApp(home: FavoritesScreen()));
      await tester.pumpAndSettle();
      expect(find.text('아직 저장한 이름이 없어요.'), findsOneWidget);
      final cta = find.text('이름 지으러 가기');
      expect(cta, findsOneWidget);
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.text('이름 지으러 가기'), findsNothing);
    });
  });

  group('추천 카드 북마크 제거', () {
    testWidgets('추천 카드에는 북마크 버튼이 없다 — 저장은 상세 화면에서만',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final baby = BabyInfo(
        surname: '한',
        surnameHanja: '韓',
        surnameStrokes: 17,
        gender: Gender.boy,
        birth: DateTime(2024, 7, 11),
        birthHour: 15,
        birthMinute: 30,
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: RecommendScreen(
              baby: baby, saju: computeSaju(baby))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      // [>] 진입 버튼은 그대로 있다.
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });
  });
}
