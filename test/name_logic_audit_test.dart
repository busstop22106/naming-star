import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/data/hanja.dart';
import 'package:jakmyeongbyeol/engine/best_hanja.dart';
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

void main() {
  group('수리오행', () {
    test('끝자리 숫자로 오행을 정한다 (1·2 목, 3·4 화, 5·6 토, 7·8 금, 9·0 수)', () {
      expect(suriElement(1), '목');
      expect(suriElement(2), '목');
      expect(suriElement(3), '화');
      expect(suriElement(4), '화');
      expect(suriElement(5), '토');
      expect(suriElement(6), '토');
      expect(suriElement(7), '금');
      expect(suriElement(8), '금');
      expect(suriElement(9), '수');
      expect(suriElement(10), '수');
      expect(suriElement(21), '목');
      expect(suriElement(33), '화');
    });

    test('분석 결과의 수리 상세에 격 오행과 상생/상극이 표시된다', () {
      // 김 8획 + 度 9획 + 潤 16획 → 원격 25·형격 17·이격 24·정격 33
      // 원격 토 · 형격 금 · 이격 화 · 정격 화
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        saju: fakeSaju(),
        gender: Gender.boy,
        picks: const [
          HanjaPick(
              syllable: '도', char: '度', meaning: '헤아릴', strokes: 9, element: '토'),
          HanjaPick(
              syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
        ],
      );
      expect(
          a.suri.details
              .any((d) => d.contains('수리오행: 원격 토 · 형격 금 · 이격 화 · 정격 화')),
          isTrue);
      // 토는 금을 생하고, 화는 금을 극하고, 같은 오행은 비화다.
      expect(a.suri.details.any((d) => d.contains('원격(토)→형격(금): 상생')),
          isTrue);
      expect(a.suri.details.any((d) => d.contains('형격(금)→이격(화): 상극')),
          isTrue);
      expect(a.suri.details.any((d) => d.contains('이격(화)→정격(화): 비화')),
          isTrue);
    });

    test('같은 오행이면 비화(같은 기운)로 표시된다', () {
      // 김 8획 + 度 9획 + 旼 8획 → 원격 17·형격 17 (둘 다 금)
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        saju: fakeSaju(),
        gender: Gender.boy,
        picks: const [
          HanjaPick(
              syllable: '도', char: '度', meaning: '헤아릴', strokes: 9, element: '토'),
          HanjaPick(
              syllable: '민', char: '旼', meaning: '화할', strokes: 8, element: '수'),
        ],
      );
      expect(
          a.suri.details
              .any((d) => d.contains('수리오행: 원격 금 · 형격 금 · 이격 토 · 정격 토')),
          isTrue);
      expect(
          a.suri.details
              .any((d) => d.contains('원격(금)→형격(금): 비화(같은 기운)')),
          isTrue);
    });

    test('수리오행 표시는 점수를 바꾸지 않는다', () {
      // 같은 이름은 수리오행 표시 전후로 총점이 같아야 한다.
      // (상세만 추가되고 채점 공식은 그대로다. 아래 값은 실측 고정값이다.)
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        saju: fakeSaju(yongsin: '수'),
        gender: Gender.boy,
        picks: const [
          HanjaPick(
              syllable: '도', char: '度', meaning: '헤아릴', strokes: 9, element: '토'),
          HanjaPick(
              syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
        ],
      );
      expect(a.total, closeTo(77.64, 0.01));
      expect(a.suri.score, 78.0);
    });
  });

  group('불용문자', () {
    test('불용문자 집합이 비어 있지 않고 흉한 한자를 포함한다', () {
      expect(forbiddenHanjaChars.length, 45);
      expect(forbiddenHanjaChars.contains('死'), isTrue);
      expect(forbiddenHanjaChars.contains('凶'), isTrue);
      expect(forbiddenHanjaChars.contains('墓'), isTrue);
      expect(forbiddenHanjaChars.contains('亡'), isTrue);
      expect(forbiddenHanjaChars.contains('破'), isTrue);
    });

    test('추천용 curated DB에는 불용문자가 없다', () {
      for (final entries in hanjaBySyllable.values) {
        for (final h in entries) {
          expect(forbiddenHanjaChars.contains(h.char), isFalse,
              reason: 'curated DB에 불용문자 ${h.char}이 있다');
        }
      }
    });

    test('불용문자 한자를 쓰면 경고가 뜬다', () {
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        saju: fakeSaju(),
        gender: Gender.boy,
        picks: const [
          HanjaPick(syllable: '사', char: '死', meaning: '죽을', strokes: 6, element: '토'),
          HanjaPick(
              syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
        ],
      );
      expect(a.warnings.any((w) => w.contains('불용문자')), isTrue);
    });

    test('일반 한자에는 불용문자 경고가 안 뜬다', () {
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        saju: fakeSaju(),
        gender: Gender.boy,
        picks: const [
          HanjaPick(
              syllable: '도', char: '度', meaning: '헤아릴', strokes: 9, element: '토'),
          HanjaPick(
              syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
        ],
      );
      expect(a.warnings.any((w) => w.contains('불용문자')), isFalse);
    });

    test('순우리말 이름에는 불용문자 경고가 안 뜬다 (char이 비어 있음)', () {
      final a = analyzeName(
        surname: '김',
        surnameStrokes: 8,
        saju: fakeSaju(),
        gender: Gender.boy,
        isPureKorean: true,
        picks: const [
          HanjaPick(
              syllable: '하', char: '', meaning: '순우리말', strokes: 5, element: '토'),
          HanjaPick(
              syllable: '늘', char: '', meaning: '순우리말', strokes: 6, element: '수'),
        ],
      );
      expect(a.warnings.any((w) => w.contains('불용문자')), isFalse);
    });

    test('자동 한자 선택은 불용문자를 고르지 않는다', () {
      // '흉'은 curated에 없어서 전체 DB 상위 20자가 후보가 되고,
      // 필터가 없으면 凶이 1위로 뽑힌다 (프로브로 확인: 용신 목·화·금·수 모두).
      final result = bestHanjaCombo(
        surname: '김',
        surnameStrokes: 8,
        syllables: ['흉', '준'],
        saju: fakeSaju(yongsin: '목'),
        gender: Gender.boy,
      );
      expect(result, isNotNull);
      for (final p in result!.picks) {
        expect(forbiddenHanjaChars.contains(p.char), isFalse,
            reason: '자동 선택이 불용문자 ${p.char}을 골랐다');
      }
    });
  });
}
