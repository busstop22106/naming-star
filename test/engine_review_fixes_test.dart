import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/data/hanja.dart';
import 'package:jakmyeongbyeol/data/hanja_full.dart';
import 'package:jakmyeongbyeol/engine/compat.dart';
import 'package:jakmyeongbyeol/engine/hanja_order.dart';
import 'package:jakmyeongbyeol/engine/pure_korean.dart';
import 'package:jakmyeongbyeol/engine/reason_line.dart';
import 'package:jakmyeongbyeol/engine/saju.dart';
import 'package:jakmyeongbyeol/engine/scoring.dart';
import 'package:jakmyeongbyeol/models.dart';

SajuResult fakeSaju({String? yongsin}) => SajuResult(
      year: const SajuPillar('갑', '진'),
      month: const SajuPillar('병', '인'),
      day: const SajuPillar('갑', '자'),
      hour: null,
      dayMaster: '갑',
      dayElement: '목',
      elementCounts: {'목': 2, '화': 1, '토': 1, '금': 2, '수': 2},
      strongBody: false,
      yongsin: yongsin,
      huishin: null,
      johu: null,
      notes: const [],
    );

NameAnalysis analyze({
  required List<HanjaPick> picks,
  int surnameStrokes = 8,
  String? yongsin,
}) =>
    analyzeName(
      surname: '김',
      surnameStrokes: surnameStrokes,
      picks: picks,
      saju: fakeSaju(yongsin: yongsin),
      gender: Gender.boy,
    );

void main() {
  group('1. 수리 흉 라벨', () {
    test('사격 대길 이름은 "수리 대길"로 표시된다 (흉이 아니다)', () {
      // 성 8획 + 이름 5·8획 → 원격 13·형격 13·이격 16·정격 21, 모두 대길
      final a = analyze(picks: const [
        HanjaPick(syllable: '가', char: '加', strokes: 5, element: '목', meaning: '더할'),
        HanjaPick(syllable: '나', char: '佳', strokes: 8, element: '목', meaning: '아름다울'),
      ]);
      expect(a.suri.grade.label, '사격 대길');
      expect(a.suri.grade.code, 'daegil');
      expect(a.suri.score, 100);
      expect(recommendReason(a), contains('수리 대길'));
      expect(recommendReason(a), isNot(contains('수리 흉')));
    });

    test('흉수 포함 이름은 "수리 흉"으로 표시된다', () {
      // 김도윤(스모크 테스트와 같은 구성): 수리 66점·등급 '흉수 포함'
      final baby = BabyInfo(
        surname: '김', surnameStrokes: 8, gender: Gender.boy,
        birth: DateTime(2026, 10, 19), birthHour: 10, birthMinute: 30,
      );
      final bySyl = hanjaBySyllable;
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        picks: [bySyl['도']!.first, bySyl['윤']!.first],
        saju: computeSaju(baby),
        gender: Gender.boy,
      );
      expect(a.suri.grade.label, '흉수 포함');
      expect(a.suri.grade.code, 'hyung');
      expect(recommendReason(a), contains('수리 흉'));
    });

    test('반길반흉 포함 이름은 "수리 반길반흉"으로 표시된다', () {
      // 성 8획 + 이름 9·8획 → 원격 17·형격 17(반길반흉), 이격 16·정격 25
      final a = analyze(picks: const [
        HanjaPick(syllable: '가', char: '加', strokes: 9, element: '목', meaning: '더할'),
        HanjaPick(syllable: '나', char: '佳', strokes: 8, element: '목', meaning: '아름다울'),
      ]);
      expect(a.suri.grade.label, '반길반흉 포함');
      expect(a.suri.grade.code, 'mixed');
      expect(recommendReason(a), contains('수리 반길반흉'));
      expect(recommendReason(a), isNot(contains('수리 흉')));
    });

    test('사격 길 이름은 "수리 길"로 표시된다', () {
      // 성 5획 + 이름 3·3획 → 원격 6·형격 8·이격 8(길), 정격 11(대길)
      // 수리 84점이라 '사격 길'이다.
      final a = analyze(
        surnameStrokes: 5,
        picks: const [
          HanjaPick(syllable: '가', char: '加', strokes: 3, element: '목', meaning: '더할'),
          HanjaPick(syllable: '나', char: '佳', strokes: 3, element: '목', meaning: '아름다울'),
        ],
      );
      expect(a.suri.grade.label, '사격 길');
      expect(a.suri.grade.code, 'gil');
      expect(a.suri.score, 84);
      expect(recommendReason(a), contains('수리 길'));
      expect(recommendReason(a), isNot(contains('수리 흉')));
    });
  });

  group('2. 순우리말 중성 획수표', () {
    test('재현 값: 쇼·쉬·시·효', () {
      expect(hangulSyllableStrokes('쇼'), 5); // ㅅ 2 + ㅛ 3 (수정 전 3)
      expect(hangulSyllableStrokes('쉬'), 5); // ㅅ 2 + ㅟ 3 (수정 전 7)
      expect(hangulSyllableStrokes('시'), 3); // ㅅ 2 + ㅣ 1 (수정 전 6)
      expect(hangulSyllableStrokes('효'), 6); // ㅎ 3 + ㅛ 3 (수정 전 4)
    });

    test('단모음은 그대로: 하 5획', () {
      expect(hangulSyllableStrokes('하'), 5); // ㅎ 3 + ㅏ 2
    });
  });

  group('3. 이중모음 집합', () {
    test('재현 값: 소수는 이중모음 0개, 셔유는 2개', () {
      HanjaPick pick(
              {required String syllable,
              int strokes = 10,
              String element = '목'}) =>
          HanjaPick(
              syllable: syllable,
              char: '加',
              strokes: strokes,
              element: element,
              meaning: '더할');
      final a = analyze(picks: [pick(syllable: '소'), pick(syllable: '수')]);
      final b = analyze(picks: [pick(syllable: '셔'), pick(syllable: '유')]);
      expect(a.sound.details.any((d) => d.contains('이중모음')), isFalse);
      expect(b.sound.details.any((d) => d.contains('이중모음')), isTrue);
    });

    test('받침 있는 이중모음 2개면 읽기 어려움 감점 −5점', () {
      HanjaPick pick({required String syllable}) => HanjaPick(
          syllable: syllable,
          char: '加',
          strokes: 10,
          element: '목',
          meaning: '더할');
      final a = analyze(picks: [pick(syllable: '손'), pick(syllable: '순')]);
      final b = analyze(picks: [pick(syllable: '션'), pick(syllable: '슌')]);
      expect(b.usability.score, a.usability.score - 5);
      expect(
          b.usability.details.any((d) => d.contains('읽기·쓰기가 조금 어려울')),
          isTrue);
    });
  });

  group('4. 절기 전날 23시 자시 기준일', () {
    BabyInfo babyAt(DateTime birth, int? hour) => BabyInfo(
          surname: '김', surnameStrokes: 8, gender: Gender.boy,
          birth: birth, birthHour: hour, birthMinute: 0,
        );

    test('2024-02-03 23시생은 다음날(입춘) 기준 갑진년 병인월', () {
      final s = computeSaju(babyAt(DateTime(2024, 2, 3), 23));
      expect(s.year.label, '갑진');
      expect(s.month.label, '병인');
      expect(s.day.label, '무술'); // 일주는 원래부터 다음날 기준이었다
    });

    test('같은 날 22시생은 출생일 기준 계묘년 을축월로 그대로', () {
      final s = computeSaju(babyAt(DateTime(2024, 2, 3), 22));
      expect(s.year.label, '계묘');
      expect(s.month.label, '을축');
    });

    test('시간 모름이면 출생일 기준으로 그대로', () {
      final s = computeSaju(babyAt(DateTime(2024, 2, 3), null));
      expect(s.year.label, '계묘');
      expect(s.month.label, '을축');
    });
  });

  group('9. 100점 만점 상한 환산', () {
    test('김도윤: 환산 전 64.8 → 환산 후 약 69.2', () {
      final baby = BabyInfo(
        surname: '김', surnameStrokes: 8, gender: Gender.boy,
        birth: DateTime(2026, 10, 19), birthHour: 10, birthMinute: 30,
      );
      final bySyl = hanjaBySyllable;
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        picks: [bySyl['도']!.first, bySyl['윤']!.first],
        saju: computeSaju(baby),
        gender: Gender.boy,
      );
      // 차원 점수는 그대로이고 종합만 93.7로 나눠 환산한다.
      final raw = a.suri.score * 0.35 +
          a.resource.score * 0.25 +
          a.sound.score * 0.20 +
          a.yinyang.score * 0.10 +
          a.usability.score * 0.10;
      expect(raw, closeTo(64.8, 0.05));
      expect(a.total, closeTo(raw / 93.7 * 100, 1e-9));
      expect(a.total, closeTo(69.2, 0.2));
      expect(a.total, inInclusiveRange(0, 100));
    });

    test('이론 상한 93.7: 각 차원 최대 기여도의 합과 일치', () {
      // 수리 100×0.35 + 자원 90×0.25 + 발음 91×0.20 + 음양 95×0.10 + 사용성 85×0.10
      expect(35.0 + 22.5 + 18.2 + 9.5 + 8.5, closeTo(93.7, 1e-9));
    });
  });

  group('14. 궁합 균형 문구', () {
    SajuResult memberSaju(Map<String, int> counts) => SajuResult(
          year: const SajuPillar('갑', '진'),
          month: const SajuPillar('병', '인'),
          day: const SajuPillar('갑', '자'),
          hour: null,
          dayMaster: '갑',
          dayElement: '목',
          elementCounts: counts,
          strongBody: false,
          yongsin: '화',
          huishin: null,
          johu: null,
          notes: const [],
        );

    test('분포가 더 불균등해지면 "한쪽으로 더 치우쳐요"라고 한다', () {
      final r = computeFamilyCompat(
        members: [
          (
            label: '아빠',
            saju: memberSaju({'목': 2, '화': 2, '토': 2, '금': 1, '수': 1}),
          ),
        ],
        babySaju: memberSaju({'목': 2, '화': 2, '토': 2, '금': 1, '수': 1}),
        picks: const [
          HanjaPick(syllable: '가', char: '加', strokes: 5, element: '목', meaning: '더할'),
          HanjaPick(syllable: '나', char: '佳', strokes: 8, element: '목', meaning: '아름다울'),
        ],
      );
      expect(r.familyCountsAfter['목'], 4);
      expect(r.balanceNote, contains('한쪽으로 더 치우쳐요'));
      expect(r.balanceNote, isNot(contains('크게 달라지지 않아요')));
    });

    test('분포가 더 고르게 되면 기존 "더 고르게" 문구가 유지된다', () {
      final r = computeFamilyCompat(
        members: [
          (
            label: '아빠',
            saju: memberSaju({'목': 0, '화': 2, '토': 2, '금': 2, '수': 2}),
          ),
        ],
        babySaju: memberSaju({'목': 0, '화': 2, '토': 2, '금': 2, '수': 2}),
        picks: const [
          HanjaPick(syllable: '가', char: '加', strokes: 5, element: '목', meaning: '더할'),
          HanjaPick(syllable: '나', char: '佳', strokes: 8, element: '목', meaning: '아름다울'),
        ],
      );
      expect(r.balanceNote, contains('더 고르게 균형 잡혀요'));
    });
  });

  group('8. 호환 이체자 처리', () {
    bool isCompat(String char) {
      final code = char.codeUnitAt(0);
      return code >= 0xF900 && code <= 0xFAFF;
    }

    test('호환자는 선택 목록에서 빠지고 정자 쌍둥이는 남는다', () {
      final yoon = orderedHanja('윤');
      expect(yoon.any((p) => isCompat(p.char)), isFalse);
      expect(yoon.length, 23); // 전체 27건 중 호환자 4건 제외
      expect(yoon.map((p) => p.char), contains('倫')); // 倫의 정자
      expect(yoon.map((p) => p.char), isNot(contains('倫')));
    });

    test('전체 음절을 훑어도 호환자가 없고 270건이 빠진다', () {
      var total = 0;
      for (final syl in hanjaFullBySyllable.keys) {
        final list = orderedHanja(syl);
        expect(list.any((p) => isCompat(p.char)), isFalse);
        total += list.length;
      }
      expect(total, 8917 - 270);
    });

    test('획수 검색에도 호환자가 안 나온다', () {
      final byStrokes = filterHanjaOptions(orderedHanja('윤'), '10');
      expect(byStrokes.map((e) => e.value.char).toSet(), {'倫'});
    });

    test('curated 뒤 나머지는 뜻 있는 한자 먼저, 각 그룹 안은 획수 오름차순', () {
      final list = orderedHanja('준');
      final curatedOrder =
          hanjaBySyllable['준']!.map((e) => e.char).toSet();
      final rest = list.where((e) => !curatedOrder.contains(e.char)).toList();
      final firstNoMeaning = rest.indexWhere((e) => e.meaning.isEmpty);
      expect(firstNoMeaning, greaterThan(0));
      expect(rest.sublist(0, firstNoMeaning).every((e) => e.meaning.isNotEmpty),
          isTrue);
      for (final group in [
        rest.sublist(0, firstNoMeaning),
        rest.sublist(firstNoMeaning),
      ]) {
        for (var i = 0; i + 1 < group.length; i++) {
          expect(group[i].strokes <= group[i + 1].strokes, isTrue);
        }
      }
    });

    test('이미 저장된 호환자 pick도 엔진 재계산은 그대로 된다', () {
      final a = analyze(picks: const [
        HanjaPick(syllable: '윤', char: '倫', strokes: 10, element: '목', meaning: ''),
        HanjaPick(syllable: '도', char: '度', strokes: 9, element: '토', meaning: '헤아릴'),
      ]);
      expect(a.hanjaName, contains('倫'));
      expect(a.total, inInclusiveRange(0, 100));
    });
  });
}
