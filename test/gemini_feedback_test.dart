import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jakmyeongbyeol/data/hanja.dart';
import 'package:jakmyeongbyeol/engine/best_hanja.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/engine/saju.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/favorites.dart';
import 'package:jakmyeongbyeol/main.dart';
import 'package:jakmyeongbyeol/models.dart';
import 'package:jakmyeongbyeol/screens/faq_screen.dart';
import 'package:jakmyeongbyeol/screens/favorites_screen.dart';
import 'package:jakmyeongbyeol/widgets/common.dart';
import 'package:jakmyeongbyeol/widgets/member_dialog.dart';

void main() {
  group('오전/오후 표기', () {
    test('오후 3시 30분은 신시로 명확히 보인다', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 15, minute: 30)),
          '오후 3시 30분');
    });
    test('오전/자정/정오 경계', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 3, minute: 30)),
          '오전 3시 30분');
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 0, minute: 5)), '오전 12시 5분');
      expect(formatTimeOfDay(const TimeOfDay(hour: 12, minute: 0)),
          '오후 12시 0분');
    });
  });

  group('공유 아기 정보', () {
    test('copyWith·동등 비교', () {
      final a = SharedBaby.initial();
      expect(a, a.copyWith());
      expect(a.copyWith(gender: Gender.girl).gender, Gender.girl);
      expect(a.copyWith(gender: Gender.girl) == a, isFalse);
    });
  });

  group('한자 뜻 우선 정렬', () {
    test('curated 뒤의 나머지 구간에서는 뜻 없는 한자가 뜻 있는 한자보다 앞에 오지 않는다',
        () {
      for (final syllable in ['도', '지', '윤']) {
        final ordered = orderedHanja(syllable);
        final curatedChars =
            hanjaBySyllable[syllable]!.map((e) => e.char).toSet();
        final rest =
            ordered.where((e) => !curatedChars.contains(e.char)).toList();
        final firstEmpty =
            rest.indexWhere((e) => e.meaning.isEmpty);
        if (firstEmpty >= 0) {
          expect(
              rest.skip(firstEmpty).every((e) => e.meaning.isEmpty), isTrue,
              reason: '$syllable: 뜻 없는 한자 뒤에 뜻 있는 한자가 오면 안 된다');
        }
        // 첫 항목(기본 선택)은 curated 순서라 바뀌지 않는다.
        expect(curatedChars.contains(ordered.first.char), isTrue);
      }
    });
  });

  group('자동 한자 선택', () {
    test('도윤의 최적 조합은 후보 중 최고 점수이다', () {
      final baby = BabyInfo(
        surname: '김',
        surnameHanja: '金',
        surnameStrokes: 8,
        gender: Gender.boy,
        birth: DateTime(2024, 7, 11),
        birthHour: 15,
        birthMinute: 30,
      );
      final saju = computeSaju(baby);
      final best = bestHanjaCombo(
        surname: '김',
        surnameStrokes: 8,
        syllables: ['도', '윤'],
        saju: saju,
        gender: Gender.boy,
      );
      expect(best, isNotNull);
      expect(best!.picks.map((p) => p.syllable).toList(), ['도', '윤']);
      final firstPicks = [
        orderedHanja('도').first,
        orderedHanja('윤').first,
      ];
      final firstTotal = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        picks: firstPicks,
        saju: saju,
        gender: Gender.boy,
      ).total;
      expect(best.total, greaterThanOrEqualTo(firstTotal));
    });
  });

  group('구성원 기본 연도', () {
    test('역할별 기본값', () {
      expect(memberDefaultYear('할아버지'), 1955);
      expect(memberDefaultYear('할머니'), 1955);
      expect(memberDefaultYear('아빠'), 1990);
      expect(memberDefaultYear('엄마'), 1990);
      expect(memberDefaultYear('형'), 2021);
      expect(memberDefaultYear('동생'), 2021);
    });
  });

  group('FAQ 펼침', () {
    testWidgets('이름 점수 항목을 펼치면 답변이 끝까지 보인다',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          const MaterialApp(home: FaqScreen()));
      await tester.tap(find.text('이름 점수는 어떻게 계산되나요?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('수리(35%)·사주 보완(25%)'), findsOneWidget);
      expect(find.textContaining('100점 만점으로 합산해요'), findsOneWidget);
    });
  });

  group('보관함 삭제 실행 취소', () {
    testWidgets('삭제 후 실행 취소를 누르면 원래 자리에 되돌아온다',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final item = FavoriteItem(
        baby: BabyInfo(
          surname: '한',
          surnameHanja: '韓',
          surnameStrokes: 17,
          gender: Gender.boy,
          birth: DateTime(2024, 7, 11),
        ),
        picks: [
          orderedHanja('지').firstWhere((p) => p.char == '志'),
          orderedHanja('민').firstWhere((p) => p.char == '旻'),
        ],
        total: 91,
        savedAt: DateTime.now(),
      );
      await saveFavorite(item);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          const MaterialApp(home: FavoritesScreen()));
      await tester.pumpAndSettle();
      expect(find.text('한지민'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('한지민'), findsNothing);
      await tester.tap(find.text('실행 취소'));
      await tester.pumpAndSettle();
      expect(find.text('한지민'), findsOneWidget);
    });
  });

  group('탭 간 아기 정보 공유', () {
    testWidgets('홈에서 바꾼 성별이 이름 분석 탭에도 이어진다',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const JakmyeongbyeolApp());
      await tester.pumpAndSettle();
      // 홈(처음 탭)에서 여아를 고른다.
      await tester.tap(find.text('여아').first);
      await tester.pumpAndSettle();
      // 이름 분석 탭으로 이동한다.
      await tester.tap(find.text('이름 분석').last);
      await tester.pumpAndSettle();
      // 두 탭의 여아 버튼이 모두 선택 상태여야 한다 (홈 것은 offstage).
      final girlButtons = tester
          .widgetList<GenderButton>(find.byType(GenderButton))
          .where((b) => b.label == '여아');
      expect(girlButtons, isNotEmpty);
      expect(girlButtons.every((b) => b.selected), isTrue);
    });

    testWidgets('랭킹 이름을 누르면 분석 탭에 이름이 채워진다',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const JakmyeongbyeolApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('랭킹').last);
      await tester.pumpAndSettle();
      // 2025년 남아 1위 도윤 행을 누른다.
      await tester.tap(find.text('도윤').first);
      await tester.pumpAndSettle();
      // 이름 분석 탭으로 이동했고 입력 폼에 도윤이 채워졌다.
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(
          fields.any((f) => f.controller?.text == '도윤'), isTrue);
      expect(find.text('이름 직접 분석하기'), findsOneWidget);
    });
  });
}
