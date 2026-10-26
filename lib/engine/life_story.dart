import '../models.dart';
import 'saju.dart';

/// 이름의 나이대별 흐름 (일대기) — 기존 5차원 점수와 사주를
/// 나이대별 테마에 연결한 규칙 기반 해석이에요.
/// 운세를 단정하는 것이 아니라 '이런 흐름일 수 있다'는 참고용 풀이로,
/// 점수가 바뀌면(한자 바꾸기) 풀이도 함께 다시 계산돼요.

class LifeStage {
  final String title; // 유년기
  final String ageRange; // 0~12세
  final double score; // 0~100
  final String grade; // 좋은 흐름 / 무난한 흐름 / 신중하면 좋은 시기
  final String headline; // 한 줄 요약
  final String body; // 2~3문장 풀이
  const LifeStage({
    required this.title,
    required this.ageRange,
    required this.score,
    required this.grade,
    required this.headline,
    required this.body,
  });
}

String _gradeOf(double score) {
  if (score >= 80) return '좋은 흐름';
  if (score >= 60) return '무난한 흐름';
  return '신중하면 좋은 시기';
}

int _bandOf(double score) => score >= 80 ? 0 : (score >= 60 ? 1 : 2);

List<LifeStage> buildLifeStory(NameAnalysis a) {
  final s = a.saju;
  final yong = s.yongsin != null ? elementNames[s.yongsin] : null;

  // 유년기: 부르기 쉬운 이름이 또래·학교생활에서 편안함
  final childScore =
      a.sound.score * 0.5 + a.usability.score * 0.3 + a.resource.score * 0.2;
  const childHeadlines = [
    '부르기 쉽고 편안한 첫인상',
    '무난하게 스며드는 이름',
    '별명과 함께 쓰면 더 편안해요',
  ];
  const childBodies = [
    '발음이 밝고 부르기 쉬워 또래와 선생님에게 쉽게 각인돼요. 이름 자체가 아이의 첫인상을 편안하게 만들어 주는 시기예요.',
    '발음이나 사용성에서 크게 거슬리는 부분은 없어요. 이름이 아이의 일상에 자연스럽게 스며드는 시기예요.',
    '발음이나 사용성에서 다소 어색한 구석이 있을 수 있어요. 애칭이나 부르기 쉬운 별명을 함께 쓰면 편안해져요.',
  ];

  // 청년기: 학업·진로·새로운 환경
  final youthScore =
      a.suri.score * 0.4 + a.resource.score * 0.4 + a.sound.score * 0.2;
  const youthHeadlines = [
    '도전 앞에 든든한 이름',
    '꾸준함이 빛나는 시기',
    '자기 페이스가 중요한 시기',
  ];
  const youthBodies = [
    '학업과 진로에서 이름의 기운이 든든하게 받쳐 줘요. 새로운 환경에서도 자기 색을 잃지 않고 나아가는 흐름이에요.',
    '도전과 배움의 시기에 무리 없이 나아가는 흐름이에요. 꾸준히 쌓은 것이 빛을 보기 시작하는 때예요.',
    '진로와 인간관계에서 시행착오가 있을 수 있는 시기예요. 서두르기보다 자기 페이스를 지키는 것이 도움이 돼요.',
  ];

  // 중년기: 일·가정·재물
  final midScore =
      a.total * 0.5 + a.resource.score * 0.3 + a.yinyang.score * 0.2;
  const midHeadlines = [
    '신뢰가 결실로 이어지는 시기',
    '균형을 맞춰 나가는 시기',
    '한 박자 쉬어가는 것이 좋은 시기',
  ];
  const midBodies = [
    '일과 가정에서 이름의 기운이 안정적으로 받쳐 줘요. 쌓아온 신뢰가 결실로 이어지기 쉬운 시기예요.',
    '일과 가정 사이에서 균형을 맞춰 나가는 시기예요. 큰 파도 없이 차근차근 자기 자리를 다져요.',
    '일과 가정에서 변수가 생기기 쉬운 시기예요. 중요한 결정은 한 박자 쉬어가며 살펴보는 것이 좋아요.',
  ];

  // 말년기: 안정·건강·가족
  final lateScore =
      a.yinyang.score * 0.4 + a.total * 0.4 + a.usability.score * 0.2;
  const lateHeadlines = [
    '마음이 안정되는 따뜻한 시기',
    '편안하게 이어지는 시기',
    '자기 속도를 지키는 시기',
  ];
  const lateBodies = [
    '이름의 음양이 편안하게 조화를 이뤄 마음이 안정되는 시기예요. 가족과 주변에 따뜻함을 나누는 흐름이에요.',
    '크게 흔들리지 않고 편안하게 이어지는 시기예요. 일상의 소소한 즐거움이 삶을 채워요.',
    '건강과 마음 챙김이 중요해지는 시기예요. 무리하지 않고 자기 속도를 지키면 편안하게 지나가요.',
  ];

  LifeStage stage(String title, String ageRange, double score,
      List<String> headlines, List<String> bodies,
      [String? extra]) {
    final band = _bandOf(score);
    var body = bodies[band];
    if (extra != null) body = '$body $extra';
    return LifeStage(
      title: title,
      ageRange: ageRange,
      score: score,
      grade: _gradeOf(score),
      headline: headlines[band],
      body: body,
    );
  }

  return [
    stage('유년기', '0~12세', childScore, childHeadlines, childBodies),
    stage('청년기', '13~29세', youthScore, youthHeadlines, youthBodies,
        yong == null
            ? null
            : '사주에 필요한 $yong 기운을 이름이 보완해 주어 도전하는 일에서 한결 수월한 흐름을 기대할 수 있어요.'),
    stage('중년기', '30~54세', midScore, midHeadlines, midBodies,
        yong == null
            ? null
            : '사주에 필요한 $yong 기운을 이름이 보완해 주어 일과 결단에서 든든한 뒷받침이 돼요.'),
    stage('말년기', '55세 이후', lateScore, lateHeadlines, lateBodies),
  ];
}
