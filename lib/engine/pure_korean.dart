import '../models.dart';
import 'scoring.dart';

/// ── 순우리말 이름 분석 ──
/// 한자가 없는 이름은 한글 자모 획수(통용 기준)로 수리·음양을 계산하고,
/// 사주 보완은 초성의 발음오행(오음오행)으로 판단하는 간이 분석이에요.

/// 초성 획수 (ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ)
const List<int> _choStrokes = [
  2, 4, 2, 3, 6, 5, 4, 4, 8,
  2, 4, 1, 3, 6, 4, 3, 4, 4, 3,
];

/// 중성 획수 — Unicode 중성 순서
/// (ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ, decompose()가 반환하는 인덱스와 동일)
/// 이중모음은 구성 단모음 획수의 합이다 (ㅘ 4 = ㅗ 2 + ㅏ 2, ㅟ 3 = ㅜ 2 + ㅣ 1).
const List<int> _jungStrokes = [
  2, 3, 3, 4, 2, 3, 3, 4, 2, 4, 5, 3, 3, 2, 4, 5, 3, 3, 1, 2, 1,
];

/// 종성 획수 (없음, ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ)
const List<int> _jongStrokes = [
  0,
  2, 4, 4,
  2, 5, 5,
  3,
  5, 7, 9, 9, 7, 9, 9, 8,
  4, 4, 6,
  2, 4,
  1,
  3, 4,
  3, 4, 4, 3,
];

/// 한글 음절 하나의 자모 획수 합
int hangulSyllableStrokes(String syllable) {
  final code = syllable.codeUnitAt(0);
  if (code < 0xAC00 || code > 0xD7A3) return 0;
  final (c, j, t) = decompose(syllable);
  return _choStrokes[c] + _jungStrokes[j] + _jongStrokes[t];
}

/// 순우리말 이름 2자를 HanjaPick 형태로 변환 (char 비움 = 순우리말 표시)
List<HanjaPick> pureKoreanPicks(String givenName) {
  const choList = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
    'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
  ];
  return givenName.split('').map((syl) {
    final (c, _, _) = decompose(syl);
    final cho = choList[c];
    return HanjaPick(
      syllable: syl,
      char: '', // 빈 값 = 순우리말
      strokes: hangulSyllableStrokes(syl),
      element: choElement(cho), // 오음오행
      meaning: '순우리말',
    );
  }).toList();
}

/// 순우리말 이름 종합 분석
NameAnalysis analyzePureKoreanName({
  required String surname,
  required int surnameStrokes,
  required String givenName, // 2음절
  required SajuResult saju,
  required Gender gender,
}) {
  assert(givenName.length == 2);
  final picks = pureKoreanPicks(givenName);
  return analyzeName(
    surname: surname,
    surnameStrokes: surnameStrokes,
    picks: picks,
    saju: saju,
    gender: gender,
    isPureKorean: true,
  );
}
