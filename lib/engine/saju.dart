import '../models.dart';

/// 간이 만세력 기반 사주 계산기
///
/// - 연주: 입춘(2/4) 기준 변경
/// - 월주: 12절기 간이 날짜표 + 오호둔법 (절입 시각은 연도별 천문표가 필요해
///   경계일 ±1일 출생자는 전문 만세력 대조가 필요합니다)
/// - 일주: 2000-01-01 = 무오일 기준일 검증값 사용, 23시 이후는 다음날
/// - 시주: 오자둔법, 진태양시 보정 미적용
/// - 오행 분포: 천간 4 + 지지 본기 4 = 8자 카운트 (지장간 여·중기 미포함)
/// - 용신: 신강/신약 + 조후 간이 로직 (전문 감정 아님 — 앱 내 고지)

const List<String> _stems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
const List<String> _branches = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];

String stemElement(String stem) {
  final i = _stems.indexOf(stem);
  return ['목', '목', '화', '화', '토', '토', '금', '금', '수', '수'][i];
}

/// 지지 본기(本氣) 오행 — 간이법
String branchElement(String branch) {
  switch (branch) {
    case '자':
    case '해':
      return '수';
    case '인':
    case '묘':
      return '목';
    case '사':
    case '오':
      return '화';
    case '신':
    case '유':
      return '금';
    default:
      return '토'; // 축진술미
  }
}

const Map<String, String> _generates = {
  '목': '화', '화': '토', '토': '금', '금': '수', '수': '목',
};
const Map<String, String> _controls = {
  '목': '토', '토': '수', '수': '화', '화': '금', '금': '목',
};

/// a가 b를 생하는지 (오행 상생)
bool generatesTo(String a, String b) => _generates[a] == b;

/// a가 b를 극하는지 (오행 상극)
bool controlsTo(String a, String b) => _controls[a] == b;

String generatedBy(String e) =>
    _generates.entries.firstWhere((en) => en.value == e).key;
String controlledBy(String e) =>
    _controls.entries.firstWhere((en) => en.value == e).key;

/// 절기 간이표: (월, 일) → 월지
const List<(int, int, String)> _solarTerms = [
  (1, 6, '축'), // 소한
  (2, 4, '인'), // 입춘
  (3, 6, '묘'), // 경칩
  (4, 5, '진'), // 청명
  (5, 6, '사'), // 입하
  (6, 6, '오'), // 망종
  (7, 7, '미'), // 소서
  (8, 8, '신'), // 입추
  (9, 8, '유'), // 백로
  (10, 8, '술'), // 한로
  (11, 8, '해'), // 입동
  (12, 7, '자'), // 대설
];

String _monthBranch(int month, int day) {
  // 1월 1일~소한(1/6) 전은 전년도 자월(동지월)이다
  String branch = '자';
  for (final (m, d, b) in _solarTerms) {
    if (month > m || (month == m && day >= d)) {
      branch = b;
    } else {
      break;
    }
  }
  return branch;
}

/// 오호둔법: 연간 천간 → 정월(인월) 천간
String _firstMonthStem(String yearStem) {
  switch (yearStem) {
    case '갑':
    case '기':
      return '병';
    case '을':
    case '경':
      return '무';
    case '병':
    case '신':
      return '경';
    case '정':
    case '임':
      return '임';
    default: // 무, 계
      return '갑';
  }
}

/// 오자둔법: 일간 → 자시 천간
String _firstHourStem(String dayStem) {
  switch (dayStem) {
    case '갑':
    case '기':
      return '갑';
    case '을':
    case '경':
      return '병';
    case '병':
    case '신':
      return '무';
    case '정':
    case '임':
      return '경';
    default: // 무, 계
      return '임';
  }
}

SajuResult computeSaju(BabyInfo baby) {
  final notes = <String>[
    '간이 만세력으로 계산한 참고용 사주예요. 절기 경계일 출생이나 정확한 용신 감정은 전문가 상담을 권장해요.',
  ];

  // ── 연주 (입춘 기준) ──
  var y = baby.birth.year;
  if (baby.birth.month == 1 || (baby.birth.month == 2 && baby.birth.day < 4)) {
    y -= 1;
    notes.add('입춘(2/4) 이전 출생이라 연주는 전해 기준으로 계산했어요.');
  }
  final yearStem = _stems[(y - 4) % 10];
  final yearBranch = _branches[(y - 4) % 12];

  // ── 월주 ──
  final mBranch = _monthBranch(baby.birth.month, baby.birth.day);
  final mBranchIdx = _branches.indexOf(mBranch);
  final baseStem = _firstMonthStem(yearStem);
  final baseIdx = _stems.indexOf(baseStem);
  // 인월(인덱스 2)이 정월이므로 오프셋 계산 — 월지는 12순환이라
  // 음수 차이를 그대로 10으로 나누면 자·축월이 틀리니 12로 정규화한다
  final mStem = _stems[(baseIdx + (mBranchIdx - 2 + 12) % 12) % 10];

  // ── 일주 (기준일 2000-01-01 = 무오) ──
  var dayDate = DateTime(baby.birth.year, baby.birth.month, baby.birth.day);
  if (!baby.timeUnknown && baby.birthHour != null && baby.birthHour! >= 23) {
    dayDate = dayDate.add(const Duration(days: 1));
    notes.add('23시 이후 출생이라 일주는 다음날 기준으로 계산했어요.');
  }
  final anchor = DateTime(2000, 1, 1);
  final diff = dayDate.difference(anchor).inDays;
  final idx = (((55 + diff - 1) % 60) + 60) % 60 + 1; // 1=갑자 … 55=무오
  final dayStem = _stems[(idx - 1) % 10];
  final dayBranch = _branches[(idx - 1) % 12];

  // ── 시주 ──
  SajuPillar? hourPillar;
  if (!baby.timeUnknown && baby.birthHour != null) {
    final h = baby.birthHour!;
    final hBranchIdx = ((h + 1) ~/ 2) % 12; // 0=자
    final hBase = _firstHourStem(dayStem);
    final hStem =
        _stems[((_stems.indexOf(hBase) + hBranchIdx) % 10 + 10) % 10];
    hourPillar = SajuPillar(hStem, _branches[hBranchIdx]);
  } else {
    notes.add('태어난 시간을 입력하지 않아 시주 없이 6글자로 분석했어요.');
  }

  // ── 오행 분포 (천간 + 지지 본기) ──
  final counts = {'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};
  final pillars = [
    SajuPillar(yearStem, yearBranch),
    SajuPillar(mStem, mBranch),
    SajuPillar(dayStem, dayBranch),
    if (hourPillar != null) hourPillar,
  ];
  for (final p in pillars) {
    final se = stemElement(p.stem);
    final be = branchElement(p.branch);
    counts[se] = counts[se]! + 1;
    counts[be] = counts[be]! + 1;
  }

  // ── 신강 / 신약 ──
  final me = stemElement(dayStem);
  final help = counts[me]! + counts[generatedBy(me)]!;
  final drain = counts[_generates[me]]! +
      counts[_controls[me]]! +
      counts[controlledBy(me)]!;
  final strongBody = help > drain;

  // ── 조후 ──
  String? johu;
  if (['해', '자', '축'].contains(mBranch)) {
    johu = '화'; // 겨울생은 화 기운 필요
  } else if (['사', '오', '미'].contains(mBranch)) {
    johu = '수'; // 여름생은 수 기운 필요
  }

  // ── 용신 / 희신 (간이) ──
  String? yongsin;
  String? huishin;
  int cnt(String e) => counts[e] ?? 0;
  if (johu != null && cnt(johu) == 0) {
    yongsin = johu;
  } else if (strongBody) {
    // 설기(식상·재성·관성) 중 가장 부족한 오행
    // ignore: unnecessary_non_null_assertion
    final cands = <String>[_generates[me]!, _controls[me]!, controlledBy(me)!];
    cands.sort((a, b) => cnt(a).compareTo(cnt(b)));
    yongsin = cands.first;
    huishin = johu ?? (cands.length > 1 ? cands[1] : null);
  } else {
    // 생조(인성·비겁) 중 가장 부족한 오행
    // ignore: unnecessary_non_null_assertion
    final cands = <String>[generatedBy(me)!, me];
    cands.sort((a, b) => cnt(a).compareTo(cnt(b)));
    yongsin = cands.first;
    huishin = johu ?? (cands.length > 1 ? cands[1] : null);
  }
  if (huishin == yongsin) huishin = null;

  return SajuResult(
    year: SajuPillar(yearStem, yearBranch),
    month: SajuPillar(mStem, mBranch),
    day: SajuPillar(dayStem, dayBranch),
    hour: hourPillar,
    dayMaster: dayStem,
    dayElement: me,
    elementCounts: counts,
    strongBody: strongBody,
    yongsin: yongsin,
    huishin: huishin,
    johu: johu,
    notes: notes,
  );
}

/// 오행 이름 (화면에 표시용)
const Map<String, String> elementNames = {
  '목': '목(木)',
  '화': '화(火)',
  '토': '토(土)',
  '금': '금(金)',
  '수': '수(水)',
};

const Map<String, String> elementColors = {
  '목': '초록',
  '화': '빨강',
  '토': '노랑',
  '금': '흰색',
  '수': '검정',
};
