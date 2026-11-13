import '../models.dart';

/// 이름 한자 데이터베이스
/// - strokes: 강희자전 원획 기준 (부수 원형 획수 적용)
/// - element: 자원오행 — 부수·의미 기준 작명별 자체 분류
///   (학파별로 상이할 수 있어 disputed 표시한 한자는 상세 화면에 안내)
/// - gender: 'm' 남아 / 'f' 여아 / 'n' 공용 — 이름 생성 풀 구분용

class HanjaEntry extends HanjaPick {
  final String gender; // m, f, n
  const HanjaEntry({
    required super.syllable,
    required super.char,
    required super.strokes,
    required super.element,
    required super.meaning,
    super.disputed,
    required this.gender,
  });
}

const List<HanjaEntry> hanjaDb = [
  // ── 준 ──
  HanjaEntry(syllable: '준', char: '俊', strokes: 9, element: '목', meaning: '뛰어날', gender: 'm'),
  HanjaEntry(syllable: '준', char: '峻', strokes: 10, element: '토', meaning: '높을', gender: 'm'),
  // ── 서 ──
  HanjaEntry(syllable: '서', char: '瑞', strokes: 14, element: '토', meaning: '상서로울', gender: 'n'),
  HanjaEntry(syllable: '서', char: '徐', strokes: 10, element: '목', meaning: '천천히', gender: 'n'),
  HanjaEntry(syllable: '서', char: '書', strokes: 10, element: '목', meaning: '글', gender: 'n'),
  // ── 하 ──
  HanjaEntry(syllable: '하', char: '河', strokes: 9, element: '수', meaning: '강', gender: 'n'),
  HanjaEntry(syllable: '하', char: '夏', strokes: 10, element: '화', meaning: '여름', gender: 'n'),
  HanjaEntry(syllable: '하', char: '賀', strokes: 12, element: '수', meaning: '기뻐할', gender: 'n'),
  // ── 도 ──
  HanjaEntry(syllable: '도', char: '度', strokes: 9, element: '토', meaning: '헤아릴', gender: 'm'),
  HanjaEntry(syllable: '도', char: '到', strokes: 8, element: '토', meaning: '이를', gender: 'm'),
  // ── 윤 ──
  HanjaEntry(syllable: '윤', char: '允', strokes: 4, element: '토', meaning: '진실로', gender: 'n'),
  // ── 시 ──
  HanjaEntry(syllable: '시', char: '時', strokes: 10, element: '화', meaning: '때', gender: 'n'),
  HanjaEntry(syllable: '시', char: '始', strokes: 8, element: '토', meaning: '처음', gender: 'n'),
  HanjaEntry(syllable: '시', char: '施', strokes: 9, element: '목', meaning: '베풀', gender: 'n'),
  // ── 우 ──
  HanjaEntry(syllable: '우', char: '宇', strokes: 6, element: '토', meaning: '집', gender: 'm'),
  HanjaEntry(syllable: '우', char: '佑', strokes: 7, element: '목', meaning: '도울', gender: 'm'),
  HanjaEntry(syllable: '우', char: '雨', strokes: 8, element: '수', meaning: '비', gender: 'n'),
  // ── 이 ──
  HanjaEntry(syllable: '이', char: '李', strokes: 7, element: '목', meaning: '오얏', gender: 'n'),
  HanjaEntry(syllable: '이', char: '伊', strokes: 6, element: '토', meaning: '저', gender: 'n'),
  HanjaEntry(syllable: '이', char: '利', strokes: 7, element: '금', meaning: '이로울', gender: 'n'),
  // ── 현 ──
  HanjaEntry(syllable: '현', char: '賢', strokes: 15, element: '수', meaning: '어질', gender: 'm', disputed: true),
  HanjaEntry(syllable: '현', char: '玄', strokes: 5, element: '수', meaning: '검을', gender: 'm'),
  HanjaEntry(syllable: '현', char: '炫', strokes: 9, element: '화', meaning: '빛날', gender: 'm'),
  // ── 민 ──
  HanjaEntry(syllable: '민', char: '敏', strokes: 11, element: '목', meaning: '민첩할', gender: 'n'),
  HanjaEntry(syllable: '민', char: '民', strokes: 5, element: '토', meaning: '백성', gender: 'n'),
  HanjaEntry(syllable: '민', char: '旻', strokes: 8, element: '화', meaning: '하늘', gender: 'n'),
  // ── 재 ──
  HanjaEntry(syllable: '재', char: '在', strokes: 6, element: '토', meaning: '있을', gender: 'm'),
  HanjaEntry(syllable: '재', char: '宰', strokes: 10, element: '토', meaning: '주재할', gender: 'm'),
  HanjaEntry(syllable: '재', char: '材', strokes: 7, element: '목', meaning: '재목', gender: 'm'),
  // ── 건 ──
  HanjaEntry(syllable: '건', char: '乾', strokes: 11, element: '금', meaning: '하늘', gender: 'm'),
  HanjaEntry(syllable: '건', char: '健', strokes: 11, element: '목', meaning: '굳셀', gender: 'm'),
  HanjaEntry(syllable: '건', char: '建', strokes: 9, element: '목', meaning: '세울', gender: 'm'),
  // ── 성 ──
  HanjaEntry(syllable: '성', char: '成', strokes: 7, element: '금', meaning: '이룰', gender: 'm'),
  HanjaEntry(syllable: '성', char: '聖', strokes: 13, element: '토', meaning: '성스러울', gender: 'm'),
  HanjaEntry(syllable: '성', char: '星', strokes: 9, element: '화', meaning: '별', gender: 'n'),
  // ── 태 ──
  HanjaEntry(syllable: '태', char: '太', strokes: 4, element: '목', meaning: '클', gender: 'm'),
  HanjaEntry(syllable: '태', char: '泰', strokes: 9, element: '수', meaning: '클', gender: 'm'),
  HanjaEntry(syllable: '태', char: '兌', strokes: 7, element: '금', meaning: '바꿀', gender: 'm'),
  // ── 경 ──
  HanjaEntry(syllable: '경', char: '慶', strokes: 15, element: '화', meaning: '경사', gender: 'n'),
  HanjaEntry(syllable: '경', char: '景', strokes: 12, element: '화', meaning: '경치', gender: 'n'),
  HanjaEntry(syllable: '경', char: '敬', strokes: 13, element: '화', meaning: '공경할', gender: 'n'),
  // ── 수 ──
  HanjaEntry(syllable: '수', char: '秀', strokes: 7, element: '목', meaning: '빼어날', gender: 'n'),
  HanjaEntry(syllable: '수', char: '洙', strokes: 10, element: '수', meaning: '물 이름', gender: 'n'),
  HanjaEntry(syllable: '수', char: '守', strokes: 6, element: '토', meaning: '지킬', gender: 'm'),
  // ── 영 ──
  HanjaEntry(syllable: '영', char: '永', strokes: 5, element: '수', meaning: '길', gender: 'n'),
  HanjaEntry(syllable: '영', char: '榮', strokes: 14, element: '목', meaning: '영화로울', gender: 'n'),
  HanjaEntry(syllable: '영', char: '泳', strokes: 9, element: '수', meaning: '헤엄칠', gender: 'n'),
  // ── 호 ──
  HanjaEntry(syllable: '호', char: '昊', strokes: 8, element: '화', meaning: '하늘', gender: 'm'),
  HanjaEntry(syllable: '호', char: '浩', strokes: 11, element: '수', meaning: '넓을', gender: 'm'),
  // ── 혁 ──
  HanjaEntry(syllable: '혁', char: '赫', strokes: 14, element: '화', meaning: '밝을', gender: 'm'),
  HanjaEntry(syllable: '혁', char: '奕', strokes: 9, element: '목', meaning: '클', gender: 'm'),
  // ── 석 ──
  HanjaEntry(syllable: '석', char: '錫', strokes: 16, element: '금', meaning: '주석', gender: 'm'),
  HanjaEntry(syllable: '석', char: '碩', strokes: 14, element: '토', meaning: '클', gender: 'm'),
  // ── 규 ──
  HanjaEntry(syllable: '규', char: '奎', strokes: 9, element: '토', meaning: '별', gender: 'n'),
  HanjaEntry(syllable: '규', char: '圭', strokes: 6, element: '토', meaning: '홀', gender: 'n'),
  // ── 동 ──
  HanjaEntry(syllable: '동', char: '東', strokes: 8, element: '목', meaning: '동쪽', gender: 'm'),
  HanjaEntry(syllable: '동', char: '棟', strokes: 12, element: '목', meaning: '들보', gender: 'm'),
  // ── 훈 ──
  HanjaEntry(syllable: '훈', char: '訓', strokes: 10, element: '금', meaning: '가르칠', gender: 'm', disputed: true),
  // ── 율 ──
  HanjaEntry(syllable: '율', char: '律', strokes: 9, element: '금', meaning: '법', gender: 'n'),
  HanjaEntry(syllable: '율', char: '栗', strokes: 10, element: '목', meaning: '밤', gender: 'n'),
  // ── 한 ──
  HanjaEntry(syllable: '한', char: '翰', strokes: 16, element: '목', meaning: '문채', gender: 'm'),
  // ── 온 ──
  HanjaEntry(syllable: '온', char: '溫', strokes: 14, element: '수', meaning: '따뜻할', gender: 'n'),
  // ── 로 ──
  HanjaEntry(syllable: '로', char: '路', strokes: 13, element: '토', meaning: '길', gender: 'n'),
  // ── 선 ──
  HanjaEntry(syllable: '선', char: '善', strokes: 12, element: '토', meaning: '착할', gender: 'n', disputed: true),
  HanjaEntry(syllable: '선', char: '宣', strokes: 9, element: '목', meaning: '베풀', gender: 'n'),
  // ── 안 ──
  HanjaEntry(syllable: '안', char: '安', strokes: 6, element: '토', meaning: '편안할', gender: 'n'),
  // ── 오 ──
  HanjaEntry(syllable: '오', char: '午', strokes: 4, element: '화', meaning: '낮', gender: 'm'),
  // ── 주 ──
  HanjaEntry(syllable: '주', char: '周', strokes: 8, element: '토', meaning: '두루', gender: 'n'),
  HanjaEntry(syllable: '주', char: '珠', strokes: 11, element: '토', meaning: '구슬', gender: 'f'),
  HanjaEntry(syllable: '주', char: '主', strokes: 5, element: '목', meaning: '주인', gender: 'n'),
  // ── 원 ──
  HanjaEntry(syllable: '원', char: '元', strokes: 4, element: '목', meaning: '으뜸', gender: 'm'),
  HanjaEntry(syllable: '원', char: '源', strokes: 14, element: '수', meaning: '근원', gender: 'n'),
  HanjaEntry(syllable: '원', char: '媛', strokes: 12, element: '토', meaning: '예쁜 여인', gender: 'f'),
  // ── 운 ──
  HanjaEntry(syllable: '운', char: '雲', strokes: 12, element: '수', meaning: '구름', gender: 'n'),
  // ── 아 ──
  HanjaEntry(syllable: '아', char: '雅', strokes: 12, element: '목', meaning: '우아할', gender: 'f'),
  HanjaEntry(syllable: '아', char: '娥', strokes: 10, element: '토', meaning: '예쁠', gender: 'f'),
  HanjaEntry(syllable: '아', char: '我', strokes: 7, element: '금', meaning: '나', gender: 'n', disputed: true),
  // ── 은 ──
  HanjaEntry(syllable: '은', char: '恩', strokes: 10, element: '화', meaning: '은혜', gender: 'n'),
  HanjaEntry(syllable: '은', char: '銀', strokes: 14, element: '금', meaning: '은', gender: 'n'),
  HanjaEntry(syllable: '은', char: '垠', strokes: 9, element: '토', meaning: '언덕', gender: 'n'),
  // ── 지 ──
  HanjaEntry(syllable: '지', char: '智', strokes: 12, element: '화', meaning: '지혜', gender: 'n'),
  HanjaEntry(syllable: '지', char: '知', strokes: 8, element: '화', meaning: '알', gender: 'n'),
  HanjaEntry(syllable: '지', char: '志', strokes: 7, element: '화', meaning: '뜻', gender: 'n'),
  // ── 유 ──
  HanjaEntry(syllable: '유', char: '柔', strokes: 9, element: '목', meaning: '부드러울', gender: 'f'),
  HanjaEntry(syllable: '유', char: '宥', strokes: 9, element: '토', meaning: '용서할', gender: 'n'),
  HanjaEntry(syllable: '유', char: '悠', strokes: 11, element: '화', meaning: '멀', gender: 'n'),
  // ── 연 ──
  HanjaEntry(syllable: '연', char: '姸', strokes: 9, element: '토', meaning: '고울', gender: 'f'),
  HanjaEntry(syllable: '연', char: '妍', strokes: 9, element: '토', meaning: '고울', gender: 'f'),
  HanjaEntry(syllable: '연', char: '緣', strokes: 15, element: '목', meaning: '인연', gender: 'n'),
  // ── 예 ──
  HanjaEntry(syllable: '예', char: '睿', strokes: 14, element: '금', meaning: '슬기로울', gender: 'n'),
  HanjaEntry(syllable: '예', char: '叡', strokes: 16, element: '금', meaning: '슬기로울', gender: 'n'),
  // ── 채 ──
  HanjaEntry(syllable: '채', char: '采', strokes: 8, element: '목', meaning: '캘', gender: 'f'),
  HanjaEntry(syllable: '채', char: '彩', strokes: 11, element: '금', meaning: '빛깔', gender: 'f'),
  // ── 나 ──
  HanjaEntry(syllable: '나', char: '奈', strokes: 8, element: '목', meaning: '어찌', gender: 'f', disputed: true),
  // ── 린 ──
  HanjaEntry(syllable: '린', char: '麟', strokes: 23, element: '화', meaning: '기린', gender: 'f'),
  // ── 소 ──
  HanjaEntry(syllable: '소', char: '昭', strokes: 9, element: '화', meaning: '밝을', gender: 'f'),
  HanjaEntry(syllable: '소', char: '素', strokes: 10, element: '목', meaning: '흴', gender: 'f'),
  HanjaEntry(syllable: '소', char: '笑', strokes: 10, element: '목', meaning: '웃을', gender: 'f'),
  // ── 미 ──
  HanjaEntry(syllable: '미', char: '美', strokes: 9, element: '수', meaning: '아름다울', gender: 'f', disputed: true),
  HanjaEntry(syllable: '미', char: '微', strokes: 13, element: '목', meaning: '작을', gender: 'f'),
  // ── 다 ──
  HanjaEntry(syllable: '다', char: '多', strokes: 6, element: '화', meaning: '많을', gender: 'f'),
  // ── 리 ──
  HanjaEntry(syllable: '리', char: '利', strokes: 7, element: '금', meaning: '이로울', gender: 'f'),
  HanjaEntry(syllable: '리', char: '梨', strokes: 11, element: '목', meaning: '배나무', gender: 'f'),
  // ── 보 ──
  HanjaEntry(syllable: '보', char: '保', strokes: 9, element: '토', meaning: '지킬', gender: 'n'),
  HanjaEntry(syllable: '보', char: '普', strokes: 12, element: '화', meaning: '널리', gender: 'n'),
  // ── 단 ──
  HanjaEntry(syllable: '단', char: '丹', strokes: 4, element: '화', meaning: '붉을', gender: 'f'),
  // ── 희 ──
  HanjaEntry(syllable: '희', char: '希', strokes: 7, element: '수', meaning: '바랄', gender: 'f'),
  HanjaEntry(syllable: '희', char: '喜', strokes: 12, element: '화', meaning: '기뻐할', gender: 'f'),
  // ── 빈 ──
  HanjaEntry(syllable: '빈', char: '彬', strokes: 11, element: '목', meaning: '빛날', gender: 'm'),
  HanjaEntry(syllable: '빈', char: '斌', strokes: 11, element: '금', meaning: '무늬', gender: 'm'),
];

/// 음절 → 한자 후보 목록 (지연 초기화 캐시)
Map<String, List<HanjaEntry>>? _hanjaBySyllableCache;
Map<String, List<HanjaEntry>> get hanjaBySyllable {
  final cached = _hanjaBySyllableCache;
  if (cached != null) return cached;
  final map = <String, List<HanjaEntry>>{};
  for (final h in hanjaDb) {
    map.putIfAbsent(h.syllable, () => []).add(h);
  }
  _hanjaBySyllableCache = map;
  return map;
}

/// 어색한 음절 조합 (생성기에서 제외)
const List<String> awkwardPairs = [
  '아예', '리예', '예아', '예예', '수수', '미미', '다다', '보보',
  '희희', '나나', '소소', '지예', '예지', '유유', '은은', '서서',
];

/// 놀림감·부정 연상 필터 (이름 전체에 포함되면 경고)
const List<String> badWords = [
  '똥', '창녀', '창년', '김치', '주전', '임신', '변태', '고생',
  '분필', '대통', '모세', '총각', '보진', '지나', '아들나', '운기',
  '설희', '간난', '동연', '태놈', '팔련', '충희', '쌍연', '몽치',
  '대장', '기해', '고우니', '루미', '기생', '한심', '호구', '송아지',
  '입분', '치국', '년', '놈', '좆', '씹', '병신', '바보',
];

/// 불용문자 — 전통적으로 이름에 쓰지 않는 흉한 뜻의 한자.
/// 추천용 curated DB에는 원래 없어서, 주로 전체 DB를 쓰는 직접 분석·자동 한자
/// 선택에서 의미가 있다. 분석 시 경고를 띄우고, 자동 추천에서는 제외한다.
const Set<String> forbiddenHanjaChars = {
  '凶', '死', '病', '孤', '寡', '夭', '殤', '殘', '刑', '殺',
  '墓', '災', '禍', '惡', '醜', '愚', '癡', '狂', '毒', '魔',
  '鬼', '妖', '喪', '哀', '悲', '苦', '貧', '賤', '奴', '囚',
  '獄', '盜', '賊', '恨', '怨', '愁', '慘',
};
