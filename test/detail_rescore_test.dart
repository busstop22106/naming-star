import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/engine/saju.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/detail_screen.dart';
import 'package:jakmyeongbyeol/theme.dart';

/// 상세 화면 한자 바꾸기 실시간 재계산 (DetailScreen._rescore):
/// 한자를 바꾸면 점수가 다시 계산되고, '추천 한자로 되돌리기'로
/// 원래 조합·점수로 돌아가는지 확인한다.
/// 점수 절대값에는 의존하지 않는다 — 기대 점수는 테스트 안에서
/// analyzeName으로 그때그때 다시 계산한다.

void main() {
  final baby = BabyInfo(
    surname: '김',
    surnameHanja: '金',
    surnameStrokes: 8,
    gender: Gender.boy,
    // 부족한 오행이 1개(금)인 사주라 '부족한 오행' 행이 짧아
    // 390px 너비에서도 _SajuRow가 넘치지 않는다.
    birth: DateTime(2026, 10, 19),
    birthHour: 10,
    birthMinute: 30,
  );
  late SajuResult saju;
  late List<HanjaPick> initialPicks;
  late NameAnalysis initialAnalysis;

  NameAnalysis rescore(List<HanjaPick> picks) => analyzeName(
        surname: '김',
        surnameStrokes: 8,
        picks: picks,
        saju: saju,
        gender: Gender.boy,
      );

  /// '지금 조합:' 행에 보이는 'NN점 · 등급' 텍스트를 읽는다.
  /// (일대기에도 'NN점 · 등급' 형태가 있어 행을 한정해서 찾는다.)
  String currentScoreText(WidgetTester tester) {
    final row = find.ancestor(
      of: find.textContaining('지금 조합:'),
      matching: find.byType(Row),
    );
    final texts = tester.widgetList<Text>(
        find.descendant(of: row, matching: find.byType(Text)));
    return texts
        .map((t) => t.data ?? '')
        .firstWhere((s) => RegExp(r'^\d+점 · ').hasMatch(s));
  }

  String scoreTextOf(NameAnalysis a) =>
      '${a.total.toStringAsFixed(0)}점 · ${AppTheme.scoreWord(a.total)}';

  setUp(() {
    saju = computeSaju(baby);
    initialPicks = [orderedHanja('준').first, orderedHanja('서').first];
    initialAnalysis = rescore(initialPicks);
  });

  Future<void> pumpDetail(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: DetailScreen(baby: baby, analysis: initialAnalysis),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('한자를 바꾸면 점수가 다시 계산된다', (tester) async {
    // 처음과 점수(반올림 표시 기준)가 달라지는 대안 한자를 고른다.
    final initialText = scoreTextOf(initialAnalysis);
    HanjaPick? alt;
    NameAnalysis? altAnalysis;
    for (final o in orderedHanja('준').skip(1)) {
      final cand = rescore([o, initialPicks[1]]);
      if (scoreTextOf(cand) != initialText) {
        alt = o;
        altAnalysis = cand;
        break;
      }
    }
    expect(alt, isNotNull,
        reason: '준 음절에 점수가 달라지는 대안 한자가 없어 테스트를 만들 수 없다');

    await pumpDetail(tester);
    expect(currentScoreText(tester), initialText);
    expect(find.text('추천 한자로 되돌리기'), findsNothing);

    // 첫째 자 한자를 바꾼다.
    final altFinder = find.text(alt!.char);
    expect(altFinder, findsOneWidget);
    await tester.ensureVisible(altFinder);
    await tester.pumpAndSettle();
    await tester.tap(altFinder);
    await tester.pumpAndSettle();

    expect(currentScoreText(tester), scoreTextOf(altAnalysis!));
    expect(
        find.textContaining(
            '지금 조합: 김준서(${alt.char}${initialPicks[1].char})'),
        findsOneWidget);
    expect(find.text('추천 한자로 되돌리기'), findsOneWidget);
  });

  testWidgets('추천 한자로 되돌리면 원래 점수로 돌아간다', (tester) async {
    final initialText = scoreTextOf(initialAnalysis);
    HanjaPick? alt;
    for (final o in orderedHanja('준').skip(1)) {
      if (scoreTextOf(rescore([o, initialPicks[1]])) != initialText) {
        alt = o;
        break;
      }
    }
    expect(alt, isNotNull);

    await pumpDetail(tester);
    final altFinder = find.text(alt!.char);
    await tester.ensureVisible(altFinder);
    await tester.pumpAndSettle();
    await tester.tap(altFinder);
    await tester.pumpAndSettle();
    expect(currentScoreText(tester), isNot(initialText));

    await tester.tap(find.text('추천 한자로 되돌리기'));
    await tester.pumpAndSettle();
    expect(currentScoreText(tester), initialText);
    expect(find.text('추천 한자로 되돌리기'), findsNothing);
  });

  testWidgets('부족한 오행이 4개여도 사주 행이 넘치지 않는다', (tester) async {
    // 2024-03-10, 시간 모름 → 부족한 오행 4개(화·토·금·수).
    final baby4 = BabyInfo(
      surname: '김',
      surnameHanja: '金',
      surnameStrokes: 8,
      gender: Gender.boy,
      birth: DateTime(2024, 3, 10),
    );
    final saju4 = computeSaju(baby4);
    final lacking = lackingElements(saju4.elementCounts);
    expect(lacking, hasLength(4),
        reason: '전제: 이 생일은 부족한 오행이 4개여야 한다');
    final picks4 = [orderedHanja('준').first, orderedHanja('서').first];
    final analysis4 = analyzeName(
      surname: '김',
      surnameStrokes: 8,
      picks: picks4,
      saju: saju4,
      gender: Gender.boy,
    );

    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: DetailScreen(baby: baby4, analysis: analysis4),
    ));
    await tester.pumpAndSettle();

    // RenderFlex 오버플로우 같은 렌더링 예외가 없어야 한다.
    expect(tester.takeException(), isNull);
    // '부족한 오행' 행의 값 자체가 온전히 보인다
    // (같은 문구를 포함한 안내 문장이 따로 있어 정확 일치로 찾는다).
    expect(find.text('화(火) · 토(土) · 금(金) · 수(水)'), findsOneWidget);
  });
}
