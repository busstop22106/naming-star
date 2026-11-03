import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/engine/saju.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';
import 'favorites_flow_test.dart' show fakeSaju, testAnalysis, testBaby;

void main() {
  group('lackingElements', () {
    test('가장 적은 오행 하나를 돌려준다', () {
      expect(
          lackingElements({'목': 2, '화': 1, '토': 2, '금': 2, '수': 2}),
          ['화']);
    });

    test('동점인 오행은 모두 돌려준다', () {
      expect(
          lackingElements({'목': 2, '화': 1, '토': 1, '금': 2, '수': 2}),
          ['화', '토']);
    });

    test('없는 오행은 0개로 취급한다', () {
      expect(lackingElements({'화': 3}), ['목', '토', '금', '수']);
    });

    test('전부 같으면 다섯 오행을 모두 돌려준다', () {
      expect(
          lackingElements({'목': 2, '화': 2, '토': 2, '금': 2, '수': 2}),
          ['목', '화', '토', '금', '수']);
    });
  });

  group('상세 화면 부족한 오행 표시', () {
    Future<void> pumpDetail(WidgetTester tester,
        {required NameAnalysis analysis}) async {
      // 화면을 길게 잡아 사주 분석 섹션까지 한 번에 빌드되게 한다.
      tester.view.physicalSize = const Size(390, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: DetailScreen(baby: testBaby(), analysis: analysis)));
      await tester.pumpAndSettle();
    }

    testWidgets('부족한 오행이 있으면 이름과 함께 보인다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // fakeSaju: 목2 화1 토1 금2 수2 → 부족 화·토.
      // testAnalysis의 한자는 토·수라 토가 이미 포함돼 있다.
      await pumpDetail(tester, analysis: testAnalysis());
      expect(find.text('부족한 오행'), findsOneWidget);
      expect(find.text('화(火) · 토(土)'), findsOneWidget);
      expect(
          find.text('이 이름은 부족한 오행(화(火) · 토(土))을 이미 포함하고 있어요.'),
          findsOneWidget);
    });

    testWidgets('부족한 오행이 이름에 없으면 더하라는 안내가 보인다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      // 목·금 한자만 쓴 이름 → 부족한 화·토가 이름에 없다.
      final analysis = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        saju: fakeSaju(),
        gender: Gender.boy,
        picks: const [
          HanjaPick(
              syllable: '서',
              char: '徐',
              meaning: '천천히',
              strokes: 10,
              element: '목'),
          HanjaPick(
              syllable: '준',
              char: '俊',
              meaning: '준걸',
              strokes: 9,
              element: '금'),
        ],
      );
      await pumpDetail(tester, analysis: analysis);
      expect(find.text('부족한 오행'), findsOneWidget);
      expect(
          find.text('이름 한자에 화(火) · 토(土) 오행을 더하면 사주 보완에 도움이 돼요.'),
          findsOneWidget);
    });
  });
}
