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

const Set<int> _doubleVowels = {2, 3, 5, 8, 9, 10, 11, 13, 14, 15, 16, 18};

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

  // ══════════ 1. 수리 (35%) ══════════
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
    if (info.grade == 'mixed') hasMixed = true;
    if (info.grade == 'hyung') hasHyung = true;
    suriDetails.add(
        '$name ${strokesOf(name, strokes)}획 → $v수리 ${info.name}(${suriGradeLabel(info.grade)})');
  });
  final suriScore = suriSum / suriWeight;
  final suriGrade = hasHyung
      ? '흉수 포함'
      : hasMixed
          ? '반길반흉 포함'
          : (suriScore >= 90 ? '사격 대길' : '사격 길');
  if (hasMixed) {
    warnings.add('수리에 학파별 평가가 갈리는 반길반흉 수가 있어요. 보수적으로 보길 권해요.');
  }

  // ══════════ 2. 음양 (10%) ══════════
  final yy = strokes.map((s) => s.isOdd ? '양' : '음').toList();
  final pattern = yy.join('');
  final goodPatterns = {'양양음', '양음음', '음음양', '음양양', '양음양', '음양음'};
  final yyGood = goodPatterns.contains(pattern);
  final yyScore = yyGood ? 95.0 : 25.0;
  final yyDetails = [
    '성(${strokes[0]}획)→${yy[0]}, 이름1(${strokes[1]}획)→${yy[1]}, 이름2(${strokes[2]}획)→${yy[2]}',
    yyGood ? '음과 양이 조화를 이루는 길한 배열이에요.' : '전부 음 또는 전부 양으로 치우친 배열은 전통적으로 흉하게 봐요.',
  ];

  // ══════════ 3. 발음 (20%) ══════════
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
  final jongs = syls.map((s) => decompose(s).$3).toList();
  final jungs = syls.map((s) => decompose(s).$2).toList();
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
  final soundGrade =
      soundScore >= 80 ? '좋음' : (soundScore >= 60 ? '보통' : '주의');

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

  // ══════════ 4. 사주 보완 — 자원오행 (25%) ══════════
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
      ? '보완 우수'
      : (resourceScore >= 50 ? '부분 보완' : '보완 미흡');

  // ══════════ 5. 사용성 (10%) ══════════
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
  final usaGrade = usa >= 80 ? '좋음' : (usa >= 65 ? '보통' : '주의');

  // ══════════ 종합 ══════════
  var total = suriScore * 0.35 +
      resourceScore * 0.25 +
      soundScore * 0.20 +
      yyScore * 0.10 +
      usa * 0.10;
  if (badHit != null) total *= 0.7; // 부정 연상은 큰 감점
  total = _clamp(total);

  return NameAnalysis(
    surname: surname,
    picks: picks,
    total: total,
    suri: DimensionScore(
      key: 'suri', title: '수리', score: suriScore, grade: suriGrade,
      summary: isPureKorean
          ? '한글 자모 획수의 길흉 (원격·형격·이격·정격)'
          : '한자 획수의 길흉 (원격·형격·이격·정격)',
      details: [
        if (isPureKorean)
          '순우리말 이름은 한자 획수 대신 한글 자모 획수(통용 기준)로 계산한 간이 분석이에요.',
        ...suriDetails,
      ],
    ),
    yinyang: DimensionScore(
      key: 'yinyang', title: '음양', score: yyScore,
      grade: yyGood ? '조화' : '치우침',
      summary: '획수 홀짝의 음양 조화',
      details: yyDetails,
    ),
    sound: DimensionScore(
      key: 'sound', title: '발음', score: soundScore, grade: soundGrade,
      summary: '소리의 오행 흐름과 부르기 쉬움',
      details: [...chainDetails, ...pronDetails],
    ),
    resource: DimensionScore(
      key: 'resource', title: '사주 보완', score: resourceScore,
      grade: resourceGrade,
      summary: '사주에 부족한 오행을 한자로 보완',
      details: resourceDetails,
    ),
    usability: DimensionScore(
      key: 'usability', title: '사용성', score: usa, grade: usaGrade,
      summary: '유행도·읽기 쉬움·부정 연상',
      details: usaDetails,
    ),
    saju: saju,
    warnings: warnings,
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
