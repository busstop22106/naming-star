import 'package:flutter_test/flutter_test.dart';
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
  test('용신을 극하는 이름 오행은 경고가 뜬다', () {
    // 용신이 수인데 토 오행 한자를 쓰면 토극수라 경고
    final a = analyzeName(
      surname: '김',
      surnameStrokes: 8,
      saju: fakeSaju(yongsin: '수'),
      gender: Gender.boy,
      picks: const [
        HanjaPick(syllable: '도', char: '度', meaning: '헤아릴', strokes: 9, element: '토'),
        HanjaPick(syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
      ],
    );
    expect(a.warnings.any((w) => w.contains('극해요')), true);
  });

  test('용신을 보완하는 이름에는 극 경고가 안 뜬다', () {
    final a = analyzeName(
      surname: '김',
      surnameStrokes: 8,
      saju: fakeSaju(yongsin: '수'),
      gender: Gender.boy,
      picks: const [
        HanjaPick(syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '수'),
        HanjaPick(syllable: '윤', char: '潤', meaning: '윤택', strokes: 16, element: '금'),
      ],
    );
    expect(a.warnings.any((w) => w.contains('극해요')), false);
  });
}
