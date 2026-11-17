import '../data/hanja.dart';
import '../data/rankings.dart';
import '../data/suri81.dart';
import '../models.dart';
import 'saju.dart';

/// ── 한글 음절 분해 ──
const List<String> _choList = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
  'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
];
(int cho, int jung, int jong) decompose(String syllable) {
  final code = syllable.codeUnitAt(0) - 0xAC00;
  return (code ~/ (21 * 28), (code % (21 * 28)) ~/ 28, code % 28);
}

/// 초성 발음오행 (훈민정음운해 기준 — 작명가 다수 사용)
String choElement(String cho) {
  if ('ㄱㄲㅋ'.contains(cho)) return '목';
  if ('ㄴㄷㄸㄹㅌ'.contains(cho)) return '화';
  if ('ㅇㅎ'.contains(cho)) return '토';
  if ('ㅅㅆㅈㅉㅊ'.contains(cho)) return '금';
  return '수'; // ㅁㅂㅃㅍ
}

/// 수리오행 — 격 수의 끝자리 오행 (1·2 목, 3·4 화, 5·6 토, 7·8 금, 9·0 수)
String suriElement(int value) {
  final d = value % 10;
  if (d == 1 || d == 2) return '목';
  if (d == 3 || d == 4) return '화';
  if (d == 5 || d == 6) return '토';
  if (d == 7 || d == 8) return '금';
  return '수'; // 9, 0
}

/// 이중모음 중성 인덱스 (Unicode 중성 순서 기준)
/// ㅑ(2) ㅒ(3) ㅕ(6) ㅖ(7) ㅘ(9) ㅙ(10) ㅚ(11) ㅛ(12) ㅝ(14) ㅞ(15) ㅟ(16)
/// ㅠ(17) ㅢ(19). 단모음 ㅔ(5)·ㅗ(8)·ㅜ(13)·ㅡ(18)는 들어가지 않는다.
const Set<int> _doubleVowels = {2, 3, 6, 7, 9, 10, 11, 12, 14, 15, 16, 17, 19};

/// 종합 점수 이론 상한 (100점 만점 환산용).
/// 각 차원의 도달 가능한 최대값에 가중치를 곱한 합이다.
/// - 수리: suriGradeScore 최대 100 (대길) × 0.35 = 35
/// - 사주 보완: 용신 45점 × 이름 2자 = 90 × 0.25 = 22.5
/// - 발음: chain 최대 100 × 0.55 + pron 최대 80 × 0.45 = 91 × 0.20 = 18.2
///   (pron은 기본 75 + 받침 없는 글자 보너스 5 = 80이 상한)
/// - 음양: 길한 배열 95 × 0.10 = 9.5
/// - 사용성: 기본 85 (감점만 있음) × 0.10 = 8.5
/// 합계 35 + 22.5 + 18.2 + 9.5 + 8.5 = 93.7.
/// 차원 점수 자체는 바꾸지 않고 종합 점수만 이 상한으로 나눠 100점 만점으로
/// 환산한다 (부정 연상 30% 감점은 환산 전에 원점수에 적용).
const double _theoreticalMaxTotal = 35.0 + 22.5 + 18.2 + 9.5 + 8.5; // = 93.7

/// 5차원 채점 가중치. 종합 점수 계산에서 쓴다 (2026-11-17).
/// 위 `_theoreticalMaxTotal`의 각 항은 차원별 이론 만점 × 아래 가중치로
/// 산출된다 (예: 수리 100 × 0.35 = 35).
const double _weightSuri = 0.35;
const double _weightResource = 0.25;
const double _weightSound = 0.20;
const double _weightYinYang = 0.10;
const double _weightUsability = 0.10;

double _clamp(double v, [double min = 0, double max = 100]) =>
    v < min ? min : (v > max ? max : v);

/// 이름 종합 분석
NameAnalysis analyzeName({
  required String surname,
  required int surnameStrokes,
  required List<HanjaPick> picks, // 이름 2자
  required SajuResult saju,
  required Gender gender,
  bool isPureKorean = false, // 순우리말 이름이면 true
}) {
  assert(picks.length == 2);
  final warnings = <String>[];
  final strokes = [surnameStrokes, picks[0].strokes, picks[1].strokes];

  // 음절 분해 — 발음·사용성이 공유하는 받침·중성 (2026-11-17, 오푸스 리뷰 반영).
  // 성씨 + 이름 2자라 인덱스 1·2가 이름 음절이다.
  final syls = [surname, picks[0].syllable, picks[1].syllable];
  final jongs = syls.map((s) => decompose(s).$3).toList();
  final jungs = syls.map((s) => decompose(s).$2).toList();

  // 1. 수리 (35%)
  final suri = _scoreSuri(strokes);
  // 2. 음양 (10%)
  final yy = _scoreYinYang(strokes);
  // 3. 발음 (20%) — 부정 연상·불용문자 경고도 함께 모은다.
  final sound = _scoreSound(surname, picks, jongs, jungs, warnings);
  // 4. 사주 보완 (25%) — 용신 극 경고도 함께 모은다.
  final resource = _scoreResource(saju, picks, isPureKorean, warnings);
  // 5. 사용성 (10%)
  final usa = _scoreUsability(picks, jongs, jungs);

  // ══════════ 종합 ══════════
  var total = suri.score * _weightSuri +
      resource.score * _weightResource +
      sound.score * _weightSound +
      yy.score * _weightYinYang +
      usa.score * _weightUsability;
  if (sound.badHit != null) total *= 0.7; // 부정 연상은 큰 감점
  total = _clamp(total / _theoreticalMaxTotal * 100);

  return NameAnalysis(
    surname: surname,
    picks: picks,
    total: total,
    suri: DimensionScore(
      key: 'suri', title: '수리', score: suri.score, grade: suri.grade,
      summary: isPureKorean
          ? '한글 자모 획수의 길흉 (원격·형격·이격·정격)'
          : '한자 획수의 길흉 (원격·형격·이격·정격)',
      details: [
        if (isPureKorean)
          '순우리말 이름은 한자 획수 대신 한글 자모 획수(통용 기준)로 계산한 간이 분석이에요.',
        ...suri.details,
      ],
    ),
    yinyang: DimensionScore(
      key: 'yinyang', title: '음양', score: yy.score, grade: yy.grade,
      summary: '획수 홀짝의 음양 조화',
      details: yy.details,
    ),
    sound: DimensionScore(
      key: 'sound', title: '발음', score: sound.score, grade: sound.grade,
      summary: '소리의 오행 흐름과 부르기 쉬움',
      details: sound.details,
    ),
    resource: DimensionScore(
      key: 'resource', title: '사주 보완', score: resource.score,
      grade: resource.grade,
      summary: '사주에 부족한 오행을 한자로 보완',
      details: resource.details,
    ),
    usability: DimensionScore(
      key: 'usability', title: '사용성', score: usa.score, grade: usa.grade,
      summary: '유행도·읽기 쉬움·부정 연상',
      details: usa.details,
    ),
    saju: saju,
    warnings: warnings,
    rankBoy: usa.rankBoy,
    rankGirl: usa.rankGirl,
  );
}

/// 1. 수리 (35%) — 원격·형격·이격·정격 4격의 81수리.
/// 반길반흉 안내는 warnings(상단 노란 배너)에 넣지 않고, 상세 화면의
/// '수리 상세' 안에서 보여준다 (2026-11-15). 판정은 suri.grade.code == SuriGradeCode.mixed로 본다.
({double score, DimensionGrade grade, List<String> details}) _scoreSuri(
  List<int> strokes,
) {
  final won = normalizeSuri(strokes[1] + strokes[2]);
  final hyung = normalizeSuri(strokes[0] + strokes[1]);
  final yi = normalizeSuri(strokes[0] + strokes[2]);
  final jung = normalizeSuri(strokes[0] + strokes[1] + strokes[2]);
  final suriVals = {'원격': won, '형격': hyung, '이격': yi, '정격': jung};
  double suriSum = 0, suriWeight = 0;
  final suriDetails = <String>[];
  var hasMixed = false, hasHyung = false;
  suriVals.forEach((name, v) {
    final info = suri81[v]!;
    final w = name == '형격' ? 2.0 : 1.0; // 형격(사회운) 가중
    suriSum += suriGradeScore(info.grade) * w;
    suriWeight += w;
    if (info.grade == SuriGradeCode.mixed) hasMixed = true;
    if (info.grade == SuriGradeCode.hyung) hasHyung = true;
    suriDetails.add(
        '$name ${strokesOf(name, strokes)}획 → $v수리 ${info.name}(${suriGradeLabel(info.grade)})');
  });
  final suriScore = suriSum / suriWeight;
  // 수리오행 — 각 격 수의 끝자리 오행과 시간순 흐름(원격 초년→형격 청년→
  // 이격 중년→정격 말년)의 상생/상극. 상세에만 표시하고 점수에는 반영하지
  // 않는다 (81수리 채점 체계 유지).
  final suriEls = {
    '원격': suriElement(won),
    '형격': suriElement(hyung),
    '이격': suriElement(yi),
    '정격': suriElement(jung),
  };
  suriDetails.add(
      '수리오행: 원격 ${suriEls['원격']} · 형격 ${suriEls['형격']} · 이격 ${suriEls['이격']} · 정격 ${suriEls['정격']}');
  for (final pair in [('원격', '형격'), ('형격', '이격'), ('이격', '정격')]) {
    final a = suriEls[pair.$1]!;
    final b = suriEls[pair.$2]!;
    final rel = a == b
        ? '비화(같은 기운)'
        : (generatesTo(a, b) || generatesTo(b, a) ? '상생' : '상극');
    suriDetails.add('${pair.$1}($a)→${pair.$2}($b): $rel');
  }
  final suriGrade = _suriGrade(hasHyung, hasMixed, suriScore);
  return (score: suriScore, grade: suriGrade, details: suriDetails);
}

/// 수리 등급 판정 — 흉수 포함 > 반길반흉 포함 > 대길(90점 이상) > 길.
/// (원래 4단 삼항 연산자였던 것을 읽히게 풀었다, 2026-11-17)
DimensionGrade _suriGrade(bool hasHyung, bool hasMixed, double suriScore) {
  if (hasHyung) {
    return const DimensionGrade(code: SuriGradeCode.hyung, label: '흉수 포함');
  }
  if (hasMixed) {
    return const DimensionGrade(
        code: SuriGradeCode.mixed, label: '반길반흉 포함');
  }
  if (suriScore >= 90) {
    return const DimensionGrade(
        code: SuriGradeCode.daegil, label: '사격 대길');
  }
  return const DimensionGrade(code: SuriGradeCode.gil, label: '사격 길');
}

/// 2. 음양 (10%) — 획수 홀짝의 음양 조화.
({double score, DimensionGrade grade, List<String> details}) _scoreYinYang(
  List<int> strokes,
) {
  final yy = strokes.map((s) => s.isOdd ? '양' : '음').toList();
  final pattern = yy.join('');
  final goodPatterns = {'양양음', '양음음', '음음양', '음양양', '양음양', '음양음'};
  final yyGood = goodPatterns.contains(pattern);
  final yyScore = yyGood ? 95.0 : 25.0;
  final yyDetails = [
    '성(${strokes[0]}획)→${yy[0]}, 이름1(${strokes[1]}획)→${yy[1]}, 이름2(${strokes[2]}획)→${yy[2]}',
    yyGood ? '음과 양이 조화를 이루는 길한 배열이에요.' : '전부 음 또는 전부 양으로 치우친 배열은 전통적으로 흉하게 봐요.',
  ];
  final yyGrade = yyGood
      ? const DimensionGrade(code: 'harmony', label: '조화')
      : const DimensionGrade(code: 'skewed', label: '치우침');
  return (score: yyScore, grade: yyGrade, details: yyDetails);
}

/// 3. 발음 (20%) — 초성 오행 흐름(chain) + 부르기 쉬움(pron).
/// 부정 연상·불용문자 경고는 `warnings`에 모아주고, 종합 감점에 쓰는
/// `badHit`을 반환한다. 받침·중성(`jongs`·`jungs`)은 analyzeName에서
/// 계산해 넘긴다 (사용성과 공유, 2026-11-17 오푸스 리뷰 반영).
({
  double score,
  DimensionGrade grade,
  List<String> details,
  String? badHit,
}) _scoreSound(
  String surname,
  List<HanjaPick> picks,
  List<int> jongs,
  List<int> jungs,
  List<String> warnings,
) {
  final syls = [surname, picks[0].syllable, picks[1].syllable];
  final choEls = syls.map((s) {
    final (c, _, _) = decompose(s);
    return choElement(_choList[c]);
  }).toList();
  double chain = 60;
  final chainDetails = <String>[];
  for (var i = 0; i < 2; i++) {
    final a = choEls[i], b = choEls[i + 1];
    if (generatesTo(a, b) || generatesTo(b, a)) {
      chain += 20;
      chainDetails.add('${syls[i]}($a)→${syls[i + 1]}($b): 상생');
    } else if (a == b) {
      chain += 5;
      chainDetails.add('${syls[i]}($a)→${syls[i + 1]}($b): 비화(같은 기운)');
    } else {
      chain -= 25;
      chainDetails.add('${syls[i]}($a)→${syls[i + 1]}($b): 상극');
    }
  }
  chain = _clamp(chain, 10, 100);

  double pron = 75;
  final pronDetails = <String>[];
  final chos = syls.map((s) => decompose(s).$1).toList();
  if (jongs.any((j) => j == 0)) {
    pron += 5;
    pronDetails.add('받침 없는 글자가 있어 발음이 부드러워요.');
  }
  for (var i = 0; i < 2; i++) {
    if (jongs[i] != 0 && jongs[i] == jongs[i + 1]) {
      pron -= 10;
      pronDetails.add('${syls[i]}·${syls[i + 1]}: 같은 받침이 이어져 발음이 막혀요.');
    }
    if (chos[i] == chos[i + 1] && jungs[i] == jungs[i + 1]) {
      pron -= 15;
      pronDetails.add('${syls[i]}·${syls[i + 1]}: 같은 음절 구조가 반복돼요.');
    }
  }
  final doubleVowelCount =
      jungs.where((j) => _doubleVowels.contains(j)).length;
  if (doubleVowelCount >= 2) {
    pron -= 8;
    pronDetails.add('이중모음이 겹쳐 발음이 다소 어려울 수 있어요.');
  }
  pron = _clamp(pron, 10, 100);

  final soundScore = _clamp(chain * 0.55 + pron * 0.45);
  final soundGrade = soundScore >= 80
      ? const DimensionGrade(code: 'good', label: '좋음')
      : (soundScore >= 60
          ? const DimensionGrade(code: 'normal', label: '보통')
          : const DimensionGrade(code: 'caution', label: '주의'));

  // 놀림감·부정 연상 체크
  final fullName = '$surname${picks[0].syllable}${picks[1].syllable}';
  String? badHit;
  for (final w in badWords) {
    if (fullName.contains(w)) {
      badHit = w;
      break;
    }
  }
  if (badHit != null) {
    warnings.add('\'$badHit\'(이)라는 부정적 연상이 들 수 있어요. 다시 생각해보세요.');
  }

  // 불용문자 체크 — 전통적으로 이름에 쓰지 않는 흉한 뜻의 한자.
  // 순우리말 이름은 char이 비어 있어 해당하지 않는다.
  for (final p in picks) {
    if (forbiddenHanjaChars.contains(p.char)) {
      final label =
          p.meaning.isEmpty ? p.char : '${p.char}(${p.meaning})';
      warnings.add(
          '\'$label\'은 전통적으로 이름에 쓰지 않는 불용문자예요. 다른 한자를 고려해보세요.');
    }
  }

  return (
    score: soundScore,
    grade: soundGrade,
    details: [...chainDetails, ...pronDetails],
    badHit: badHit,
  );
}

/// 4. 사주 보완 — 자원오행 (25%).
/// 용신을 극하는 오행 경고는 `warnings`에 모아준다.
({double score, DimensionGrade grade, List<String> details}) _scoreResource(
  SajuResult saju,
  List<HanjaPick> picks,
  bool isPureKorean,
  List<String> warnings,
) {
  final yongsin = saju.yongsin;
  final huishin = saju.huishin;
  double resourceScore;
  final resourceDetails = <String>[];
  if (yongsin == null) {
    resourceScore = 60;
    resourceDetails.add('사주 분석에서 보완 오행을 특정하기 어려워 기본 점수를 드렸어요.');
  } else {
    var got = 0;
    for (final p in picks) {
      final label =
          isPureKorean ? '${p.syllable}(발음오행)' : '${p.char}(${p.meaning})';
      if (p.element == yongsin) {
        got += 45;
        resourceDetails.add('$label: 용신 ${elementNames[yongsin]} 보완 ✓');
      } else if (p.element == huishin) {
        got += 25;
        resourceDetails.add('$label: 희신 ${elementNames[huishin]} 보완 ✓');
      } else {
        resourceDetails.add('$label: ${elementNames[p.element]}');
      }
      // 용신을 극하는 오행은 이름에 피하는 것이 원칙이라 경고해요
      if (controlsTo(p.element, yongsin)) {
        warnings.add(
            '이름의 ${elementNames[p.element]} 기운이 용신 ${elementNames[yongsin]}을 극해요. 다른 한자를 고려해보세요.');
      }
    }
    resourceScore = got == 0 ? 30 : _clamp(got.toDouble());
    resourceDetails.insert(
        0,
        '이 아기의 사주에 필요한 기운: 용신 ${elementNames[yongsin]}'
        '${huishin != null ? ', 희신 ${elementNames[huishin]}' : ''}');
  }
  final resourceGrade = resourceScore >= 80
      ? const DimensionGrade(code: 'excellent', label: '보완 우수')
      : (resourceScore >= 50
          ? const DimensionGrade(code: 'partial', label: '부분 보완')
          : const DimensionGrade(code: 'lacking', label: '보완 미흡'));
  return (
    score: resourceScore,
    grade: resourceGrade,
    details: resourceDetails,
  );
}

/// 5. 사용성 (10%) — 유행도·읽기 쉬움·부정 연상.
({
  double score,
  DimensionGrade grade,
  List<String> details,
  int? rankBoy,
  int? rankGirl,
}) _scoreUsability(
  List<HanjaPick> picks,
  List<int> jongs,
  List<int> jungs,
) {
  double usa = 85;
  final usaDetails = <String>[];
  final givenName = '${picks[0].syllable}${picks[1].syllable}';
  final rb = boyRankOf(givenName);
  final rg = girlRankOf(givenName);
  int? rankBoy, rankGirl;
  if (rb != null) {
    rankBoy = rb;
    usa -= 20;
    usaDetails.add(
        '$latestRankingYear년 남자 아기 이름 $rb위 — 또래에 같은 이름이 많을 수 있어요.');
  }
  if (rg != null) {
    rankGirl = rg;
    usa -= 20;
    usaDetails.add(
        '$latestRankingYear년 여자 아기 이름 $rg위 — 또래에 같은 이름이 많을 수 있어요.');
  }
  if (rb == null && rg == null) {
    usaDetails.add(
        '$latestRankingYear년 출생신고 TOP20에 없는 이름이라 흔하지 않아요.');
  }
  for (final p in picks) {
    if (p.disputed) {
      usaDetails.add('${p.char}: 자원오행이 학파별로 달라요 (상세 화면 참고).');
    }
  }
  final hardToRead = jongs[1] != 0 &&
      jongs[2] != 0 &&
      _doubleVowels.contains(jungs[1]) &&
      _doubleVowels.contains(jungs[2]);
  if (hardToRead) {
    usa -= 5;
    usaDetails.add('읽기·쓰기가 조금 어려울 수 있는 조합이에요.');
  }
  usa = _clamp(usa);
  final usaGrade = usa >= 80
      ? const DimensionGrade(code: 'good', label: '좋음')
      : (usa >= 65
          ? const DimensionGrade(code: 'normal', label: '보통')
          : const DimensionGrade(code: 'caution', label: '주의'));
  return (
    score: usa,
    grade: usaGrade,
    details: usaDetails,
    rankBoy: rankBoy,
    rankGirl: rankGirl,
  );
}

String strokesOf(String gyeok, List<int> strokes) {
  switch (gyeok) {
    case '원격':
      return '${strokes[1]}+${strokes[2]}';
    case '형격':
      return '${strokes[0]}+${strokes[1]}';
    case '이격':
      return '${strokes[0]}+${strokes[2]}';
    default:
      return '${strokes[0]}+${strokes[1]}+${strokes[2]}';
  }
}
